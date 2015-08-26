require 'azure'
require 'mustache'
require 'open3'

# cheapest as of 2015-08
CHEAPEST_AZURE_LOCATION="East US"

if ENV['PUPPET_AZURE_USE_BEAKER'] and ENV['PUPPET_AZURE_USE_BEAKER'] == 'yes'
  require 'beaker-rspec'
  unless ENV['BEAKER_provision'] == 'no'
    # require 'beaker/puppet_install_helper'
    install_pe

    hosts.each do |host|
      on(host, 'apt-get install zlib1g-dev')
      on(host, 'apt-get install patch')

      path = host.file_exist?("#{host['privatebindir']}/gem") ? host['privatebindir'] : host['puppetbindir']
      on(host, "#{path}/gem install azure")
    end
  end

  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
  hosts.each do |host|
    # set :target_module_path manually to work around beaker-rspec bug that does not
    # persist distmoduledir across runs with reused nodes
    # TODO: ticket up this bug for beaker-rspec
    install_dev_puppet_module_on(host, :source => proj_root, :module_name => 'azure', :target_module_path => '/etc/puppetlabs/code/modules')
  end

  # Deploy Azure credentials to all hosts
  if ENV['AZURE_MANAGEMENT_CERTIFICATE']
    hosts.each do |host|
      scp_to(host, ENV['AZURE_MANAGEMENT_CERTIFICATE'], '/tmp/azure_cert.pem')
    end
  end
end

class PuppetManifest < Mustache
  def initialize(file, config)
    @template_file = File.join(Dir.getwd, 'spec', 'acceptance', 'fixtures', file)
    config.each do |key, value|
      config_value = self.class.to_generalized_data(value)
      instance_variable_set("@#{key}".to_sym, config_value)
      self.class.send(:attr_accessor, key)
    end
  end

  def apply
    PuppetRunProxy.apply(self.render)
  end

  def self.to_generalized_data(val)
    case val
    when Hash
      to_generalized_hash_list(val)
    when Array
      to_generalized_array_list(val)
    else
      val
    end
  end

  # returns an array of :k =>, :v => hashes given a Hash
  # { :a => 'b', :c => 'd' } -> [{:k => 'a', :v => 'b'}, {:k => 'c', :v => 'd'}]
  def self.to_generalized_hash_list(hash)
    hash.map { |k, v| { :k => k, :v => v }}
  end

  # necessary to build like [{ :values => Array }] rather than [[]] when there
  # are nested hashes, for the sake of Mustache being able to render
  # otherwise, simply return the item
  def self.to_generalized_array_list(arr)
    arr.map do |item|
      if item.class == Hash
        {
          :values => to_generalized_hash_list(item)
        }
      else
        item
      end
    end
  end

  def self.env_id
    @env_id ||= (
      ENV['BUILD_DISPLAY_NAME'] ||
      (ENV['USER'] + '@' + Socket.gethostname.split('.')[0])
    ).delete("'")
  end

  def self.rds_id
    @rds_id ||= (
      ENV['BUILD_DISPLAY_NAME'] ||
      (ENV['USER'])
    ).gsub(/\W+/, '')
  end

  def self.env_dns_id
    @env_dns_id ||= @env_id.gsub(/[^\\dA-Za-z-]/, '')
  end
end

class AzureHelper
  def initialize
    @azure_vm = Azure.vm_management
  end

  # This can return > 1 virtual machines if there are naming clashes.
  def get_virtual_machine(name)
    @azure_vm.list_virtual_machines.select { |x| x.vm_name == name }
  end

  def destroy_virtual_machine(machine)
    @azure_vm.delete_virtual_machine(machine.vm_name, machine.cloud_service_name)
  end
end

class TestExecutor
  # build and apply complex puppet resource commands
  # the arguement resource is the type of the resource
  # the opts hash must include a key 'name'
  def self.puppet_resource(resource, opts = {}, command_flags = '')
    raise 'A name for the resource must be specified' unless opts[:name]
    cmd = "puppet resource #{resource} "
    options = String.new
    opts.each do |k,v|
      if k.to_s == 'name'
        @name = v
      else
        options << "#{k.to_s}=#{v.to_s} "
      end
    end
    cmd << "#{@name} "
    cmd << options
    cmd << " #{command_flags}"
    # apply the command
    response = PuppetRunProxy.resource(cmd)
    response
  end
end

# This is a prototype to emulate a "local" hypervisor in beaker, and at the same time
# provide a way to use a single set of "commands" to either run puppet agent against a master
# or puppet apply standalone.
# this is deliberately not done as a proper top-level DSL to make usage of this easily greppable
class PuppetRunProxy
  # proxy all other calls through to the runner
  def self.method_missing(*args)
    runner.send(*args)
  end

  def self.runner
    @runner ||= if ENV['PUPPET_AZURE_USE_BEAKER'] and ENV['PUPPET_AZURE_USE_BEAKER'] == 'yes'
                  BeakerApplyRunner.new
                else
                  LocalRunner.new
                end
  end
end

# local commands use bundler to isolate the ruby runtime environment
class LocalRunner
  def create_remote_file_ex(file_path, file_content, options={})
    File.open(file_path, 'w') { |file| file.write(file_content) }
    if options[:mode]
      use_local_shell("chmod #{options[:mode]} '#{file_path}'")
    else
      BeakerLikeResponse.success
    end
  end

  def scp_to_ex(from, to)
    FileUtils.cp(from, to)
    BeakerLikeResponse.success
  end

  def apply(manifest)
    cmd = "bundle exec puppet apply --detailed-exitcodes -e \"#{manifest.delete("\n")}\" --modulepath ../ --debug --trace"
    use_local_shell(cmd)
  end

  def resource(cmd)
    use_local_shell('bundle exec ' + cmd)
  end

  def shell_ex(cmd)
    use_local_shell(cmd)
  end

  private
    def use_local_shell(cmd)
      Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
        @out = read_stream(stdout)
        @error = read_stream(stderr)
        @code = /(exit)(\s)(\d+)/.match(wait_thr.value.to_s)[3]
      end
      BeakerLikeResponse.new(@out, @error, @code, cmd)
    end

    def read_stream(stream)
      result = String.new
      while line = stream.gets # rubocop:disable Lint/AssignmentInCondition
        result << line if line.class == String
        puts line
      end
      result
    end
end

class BeakerRunnerBase
  def create_remote_file_ex(file_path, file_content, **options)
    hosts.each do |host|
      if !options[:mode] or options[:mode] == '0644'
        scp_to host, from, to
      elsif options[:mode]
        file_content.gsub!(/\\/, '\\')
        file_content.gsub!(/\n/, '\\n')
        apply_manifest "file { '#{file_path}': ensure => present, content => '#{file_content}', mode => '#{options[:mode]}' }", :catch_failures => true
      end
    end
  end

  def scp_to_ex(from, to)
    hosts.each do |host|
      scp_to host, from, to
    end
  end

  def shell_ex(cmd)
    shell(cmd)
  end
end

class BeakerAgentRunner < BeakerRunnerBase
  def apply(manifest)
    # TODO: insert greg's code here
  end

  def resource(cmd)
    # TODO: insert greg's code here
  end
end

class BeakerApplyRunner < BeakerRunnerBase
  def apply(manifest)
    # acceptable_exit_codes and expect_changes are passed because we want detailed-exit-codes but want to
    # make our own assertions about the responses
    apply_manifest(manifest, {
      :acceptable_exit_codes => (0...256),
      :expect_changes => true,
      :debug => true,
      :trace => true,
      :environment => {
        'AZURE_MANAGEMENT_CERTIFICATE' => '/tmp/azure_cert.pem',
        'AZURE_SUBSCRIPTION_ID' => ENV['AZURE_SUBSCRIPTION_ID'],
      },
      })
  end

  def resource(cmd)
    # beaker has a puppet helper to run puppet on the remote system so we remove the explicit puppet part of the command
    cmd = "#{cmd.split('puppet ').join}"
    # when running under beaker we install the module via the package, so need to use the default module path
    cmd ="#{cmd.split(/--modulepath \S*/).join}"
    on(default, puppet(cmd))
  end
end

class BeakerLikeResponse
  def self.success
    BeakerLikeResponse.new('', '', 0, '')
  end

  attr_reader :stdout , :stderr, :output, :exit_code, :command

  def initialize(standard_out, standard_error, exit, cmd)
    @stdout = standard_out
    @stderr = standard_error
    @output = standard_out + "\n" + standard_error
    @exit_code = exit.to_i
    @command = cmd
  end
end
