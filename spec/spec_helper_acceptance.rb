require 'azure'
require 'mustache'
require 'open3'

if ENV['PUPPET_AZURE_USE_BEAKER'] and ENV['PUPPET_AZURE_USE_BEAKER'] == 'yes'
  require 'beaker-rspec'
  require 'beaker/puppet_install_helper'
  unless ENV['BEAKER_provision'] == 'no'
    install_pe

    proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
    puppet_module_install(:source => proj_root, :module_name => 'azure')
    agents.each do |agent|
      path = agent.file_exist?("#{agent['privatebindir']}/gem") ? agent['privatebindir'] : agent['puppetbindir']
      on(master, 'apt-get install zlib1g-dev')
      on(master, 'apt-get install patch')
      on(master, "#{path}/gem install azure")
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
    PuppetRunProxy.new.apply(self.render)
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
    @azure_vm_images = Azure.vm_image_management
  end

  # This can return > 1 images if there is naming clashes.
  def get_image(name)
    @azure_vm_images.list_virtual_machine_images.select { |x| x.name == name.downcase }
  end

  # This can return > 1 virtual machines if there are naming clashes.
  def get_virtual_machine(name)
    @azure_vm.list_virtual_machines.select { |x| x.vm_name == name.downcase }
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
    response = PuppetRunProxy.new.resource(cmd)
    response
  end
end

class PuppetRunProxy
  attr_accessor :mode

  def initialize
    @mode = if ENV['PUPPET_AZURE_USE_BEAKER'] and ENV['PUPPET_AZURE_USE_BEAKER'] == 'yes'
      :beaker
            else
      :local
    end
  end

  def apply(manifest)
    case @mode
    when :local
      cmd = "bundle exec puppet apply --detailed-exitcodes -e \"#{manifest.delete("\n")}\" --modulepath ../ --debug"
      use_local_shell(cmd)
    else
      # acceptable_exit_codes and expect_changes are passed because we want detailed-exit-codes but want to
      # make our own assertions about the responses
      apply_manifest(manifest, {:acceptable_exit_codes => (0...256), :expect_changes => true, :debug => true,})
    end
  end

  def resource(cmd)
    case @mode
    when :local
      # local commands use bundler to isolate the  puppet environment
      cmd.prepend('bundle exec ')
      use_local_shell(cmd)
    else
      # beaker has a puppet helper to run puppet on the remote system so we remove the explicit puppet part of the command
      cmd = "#{cmd.split('puppet ').join}"
      # when running under beaker we install the module via the package, so need to use the default module path
      cmd ="#{cmd.split(/--modulepath \S*/).join}"
      on(default, puppet(cmd))
    end
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

class BeakerLikeResponse
  attr_reader :stdout , :stderr, :exit_code, :command

  def initialize(standard_out, standard_error, exit, cmd)
    @stdout = standard_out
    @stderr = standard_error
    @exit_code = exit.to_i
    @command = cmd
  end
end


