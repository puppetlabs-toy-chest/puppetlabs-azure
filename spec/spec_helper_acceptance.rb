
require 'azure'
require 'mustache'
require 'open3'
require 'master_manipulator'
require 'beaker'
require 'net/ssh'
require 'ssh-exec'
require 'retries'
require 'shellwords'
require 'winrm'

require 'puppet_x/puppetlabs/azure/config'
require 'puppet_x/puppetlabs/azure/not_finished'

require 'azure_mgmt_compute'
require 'azure_mgmt_resources'
require 'azure_mgmt_storage'
require 'azure_mgmt_network'
require 'ms_rest_azure'

# automatically load any shared examples or contexts
Dir["./spec/support/**/*.rb"].sort.each { |f| require f }

# Workaround https://github.com/Azure/azure-sdk-for-ruby/issues/269
require 'azure/virtual_machine_image_management/virtual_machine_image_management_service'

# cheapest as of 2015-08
CHEAPEST_AZURE_LOCATION="East US"

UBUNTU_IMAGE='b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-14_04_3-LTS-amd64-server-20150908-en-us-30GB'
WINDOWS_IMAGE='a699494373c04fc0bc8f2bb1389d6106__Windows-Server-2012-R2-20150825-en.us-127GB.vhd'

unless ENV['PUPPET_AZURE_BEAKER_MODE'] == 'local'
  require 'beaker-rspec'
  unless ENV['BEAKER_provision'] == 'no'
    install_pe

    hosts.each do |host|
      on(host, 'apt-get install zlib1g-dev')
      on(host, 'apt-get install patch')
      on(host, 'apt-get install -y g++')

      path = host.file_exist?("#{host['privatebindir']}/gem") ? host['privatebindir'] : host['puppetbindir']
      on(host, "#{path}/gem install azure_mgmt_compute azure_mgmt_network azure_mgmt_resources azure_mgmt_storage hocon retries azure")
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
  attr_accessor :optional_endpoints, :endpoints

  def initialize(file, config) # rubocop:disable Metrics/AbcSize
    @template_file = File.join(Dir.getwd, 'spec', 'acceptance', 'fixtures', file)

    # decouple the config we're munging from the value used in the tests
    config = Marshal.load( Marshal.dump(config) )

    endpoints = config.delete(:endpoints)
    @optional_endpoints = endpoints.is_a?(Array) and !endpoints.empty?
    if @optional_endpoints
      @endpoints = endpoints.collect do |ep|
        lb = ep.delete(:load_balancer)
        {
          values: self.class.to_generalized_data(ep),
          has_load_balancer: !!lb,
          load_balancer: self.class.to_generalized_data(lb),
        }
      end
    end

    config.each do |key, value|
      config_value = self.class.to_generalized_data(value)
      instance_variable_set("@#{key}".to_sym, config_value)
      self.class.send(:attr_accessor, key)
    end
  end

  def execute
    PuppetRunProxy.execute(self.render)
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

class AzureARMHelper
  def self.config
    PuppetX::Puppetlabs::Azure::Config.new
  end

  def self.compute_client
    @compute_client ||= AzureARMHelper.with_subscription_id ::Azure::ARM::Compute::ComputeManagementClient.new(credentials)
  end

  def self.network_client
    @network_client ||= AzureARMHelper.with_subscription_id ::Azure::ARM::Network::NetworkResourceProviderClient.new(credentials)
  end

  def self.storage_client
    @storage_client ||= AzureARMHelper.with_subscription_id ::Azure::ARM::Storage::StorageManagementClient.new(credentials)
  end

  def self.resource_client
    @resource_client ||= AzureARMHelper.with_subscription_id ::Azure::ARM::Resources::ResourceManagementClient.new(credentials)
  end

  def self.credentials
    token_provider = ::MsRestAzure::ApplicationTokenProvider.new(AzureARMHelper.config.tenant_id, AzureARMHelper.config.client_id, AzureARMHelper.config.client_secret)
    ::MsRest::TokenCredentials.new(token_provider)
  end

  def self.with_subscription_id(client)
    client.subscription_id = AzureARMHelper.config.subscription_id
    client
  end

  def list_resource_providers
    promise = AzureARMHelper.resource_client.providers.list
    promise.value!.body.value
  end

  def get_resource_group(name)
    resource_groups = AzureARMHelper.resource_client.resource_groups.list.value!.body
    resource_groups.value.find { |x| x.name == name }
  end

  def destroy_resource_group(resource_group_name)
    promise = AzureARMHelper.resource_client.resource_groups.delete(resource_group_name)
    promise.value!.body
  end

  def list_storage_accounts
    promise = AzureARMHelper.storage_client.storage_accounts.list
    promise.value!.body.value
  end

  def get_storage_account(name)
    accounts = list_storage_accounts
    accounts.find { |x| x.name == name }
  end

  def destroy_storage_account(resource_group_name, name)
    promise = AzureARMHelper.storage_client.storage_accounts.delete(resource_group_name, name)
    promise.value!.body
  end

  def get_all_vms
    vms = AzureARMHelper.compute_client.virtual_machines.list_all.value!.body.value
    vms.collect do |vm|
      AzureARMHelper.compute_client.virtual_machines.get(get_resource_group_from(vm), vm.name, 'instanceView').value!.body
    end
  end

  def get_resource_group_from(machine)
    machine.id.split('/')[4].downcase
  end

  def get_vm(name)
    get_all_vms.find { |vm| vm.name == name }
  end

  def destroy_vm(machine)
    AzureARMHelper.compute_client.virtual_machines.delete(get_resource_group_from_vm(machine), machine.name).value!
  end

  def vm_running?(vm)
    ! vm.properties.instance_view.statuses.find { |s| s.code =~ /PowerState\/running/ }.nil?
  end

  def vm_stopped?(vm)
    ! vm.properties.instance_view.statuses.find { |s| s.code =~ /PowerState\/stopped/ }.nil?
  end
end

class AzureHelper
  def initialize
    configuration_from_env_or_file = ::PuppetX::Puppetlabs::Azure::Config.new
    Azure.subscription_id = configuration_from_env_or_file.subscription_id
    Azure.management_certificate = configuration_from_env_or_file.management_certificate

    @azure_vm = Azure.vm_management
    @azure_affinity_group = Azure.base_management
    @azure_cloud_service = Azure.cloud_service_management
    @azure_storage = Azure.storage_management
    @azure_disk = Azure.vm_disk_management
    @azure_network = Azure.network_management
  end

  # This can return > 1 virtual machines if there are naming clashes.
  def get_virtual_machine(name)
    @azure_vm.list_virtual_machines.select { |x| x.vm_name == name }
  end

  def destroy_virtual_machine(machine)
    @azure_vm.delete_virtual_machine(machine.vm_name, machine.cloud_service_name)
  end

  def get_cloud_service(machine)
    @azure_cloud_service.get_cloud_service(machine.cloud_service_name)
  end

  def get_storage_account(name)
    @azure_storage.get_storage_account(name)
  end

  def get_disk(name)
    @azure_disk.get_virtual_machine_disk(name)
  end

  def destroy_disk(name)
    if @azure_disk.get_virtual_machine_disk(name)
      @azure_disk.delete_virtual_machine_disk(name)
    end
  end

  def destroy_storage_account(name)
    @azure_storage.delete_storage_account(name)
  end

  def get_virtual_network(name)
    @azure_network.list_virtual_networks.find { |network| network.name == name }
  end

  def ensure_network(name)
    # This should ideally be create_network, with a corresponding delete_network. However
    # the SDK doesn't support deleteing virtual networks. Nor does the lower-level
    # REST API https://msdn.microsoft.com/en-us/library/azure/jj157182.aspx
    # With that in mind we reuse a known network between tests, which is horrible but works
    # given we don't need to mutate it, just for it to exist
    unless get_virtual_network(name)
      address_space = ['172.16.0.0/12', '10.0.0.0/8', '192.168.0.0/24']
      subnets = [
        {name: "#{name}-1", ip_address: '172.16.0.0', cidr: 12},
        {name: "#{name}-2", ip_address: '10.0.0.0', cidr: 8}
      ]
      dns_servers = [{name: 'dns', ip_address: '1.2.3.4'}]
      options = {:subnet => subnets, :dns => dns_servers}
      @azure_network.set_network_configuration(name, CHEAPEST_AZURE_LOCATION, address_space, options)
    end
  end

  def get_affinity_group(name)
    @azure_affinity_group.get_affinity_group(name)
  end

  def create_affinity_group(name)
    @azure_affinity_group.create_affinity_group(name, CHEAPEST_AZURE_LOCATION, 'Temporary group for acceptance tests')
  end

  def destroy_affinity_group(name)
    @azure_affinity_group.delete_affinity_group(name)
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

  def self.create_runner(mode)
    case mode
    when 'apply' then
      BeakerApplyRunner.new
    when 'agent' then
      BeakerAgentRunner.new
    when 'local'
      LocalRunner.new
    else
      # Exception as the switch supplied is invalid
      raise ArgumentException.new "Unknown PUPPET_AZURE_BEAKER_MODE supplied '#{mode}''"
    end
  end

  def self.runner
    @runner ||= create_runner(ENV['PUPPET_AZURE_BEAKER_MODE'] || 'apply')
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

  def execute(manifest)
    puts "Applied manifest [#{manifest}]" if ENV['DEBUG_MANIFEST']
    cmd = "bundle exec puppet apply --detailed-exitcodes -e #{manifest.delete("\n").shellescape} --modulepath spec/fixtures/modules --libdir lib --debug --trace"
    use_local_shell(cmd)
  end

  # build and apply complex puppet resource commands
  # the arguement resource is the type of the resource
  # the opts hash must include a key 'name'
  def resource(type, opts = {}, command_flags = '')
    raise 'A name for the resource must be specified' unless opts[:name]
    cmd = "bundle exec puppet resource #{type} "
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
    cmd << " --modulepath spec/fixtures/modules --libdir lib"
    cmd << " #{command_flags}"

    # apply the command
    use_local_shell(cmd)
  end

  def shell_ex(cmd)
    use_local_shell(cmd)
  end

  private
    def use_local_shell(cmd) # rubocop:disable Metrics/AbcSize
      blocks = {
        out: [],
        err: [],
      }

      exit_code = -1

      Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
        stdin.close_write

        files = [stdout, stderr]

        until files.all?(&:eof) do
          ready = IO.select(files)

          if ready
            ready[0].each do |f|
              fileno = f.fileno
              begin
                data = f.read_nonblock(1024)
                $stdout.write(data)

                if fileno == stdout.fileno
                  blocks[:out] << data
                else
                  blocks[:err] << data
                end
              rescue EOFError # rubocop:disable Lint/HandleExceptions
                # pass on EOF
              end
            end
          end
        end

        exit_code = wait_thr.value.exitstatus
      end

      BeakerLikeResponse.new(blocks[:out].join, blocks[:err].join, exit_code, cmd)
    end
end

class BeakerRunnerBase
  include Beaker::DSL
  include MasterManipulator::Site

  def remote_environment
    @env ||= {
      'AZURE_MANAGEMENT_CERTIFICATE' => '/tmp/azure_cert.pem',
      'AZURE_SUBSCRIPTION_ID' => ENV['AZURE_SUBSCRIPTION_ID'],
      'AZURE_TENANT_ID' => ENV['AZURE_TENANT_ID'],
      'AZURE_CLIENT_ID' => ENV['AZURE_CLIENT_ID'],
      'AZURE_CLIENT_SECRET' => ENV['AZURE_CLIENT_SECRET'],
    }
  end

  def create_remote_file_ex(file_path, file_content, options={})
    hosts.each do |host|
      mode = options[:mode] || '0644'
      file_content.gsub!(/\\/, '\\')
      file_content.gsub!(/\n/, '\\n')
      apply_manifest "file { '#{file_path}': ensure => present, content => '#{file_content}', mode => '#{mode}' }", :catch_failures => true
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

  def resource(type, opts = {}, command_flags = '') # rubocop:disable Metrics/AbcSize
    raise 'A name for the resource must be specified' unless opts[:name]
    cmd = "resource #{type} "
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

    on(default,
      puppet(cmd),
      :environment => remote_environment,
      :acceptable_exit_codes => (0...256),
      )
  end
end

class BeakerAgentRunner < BeakerRunnerBase
  def execute(manifest)
    environment_base_path = on(master, puppet('config', 'print', 'environmentpath')).stdout.rstrip
    prod_env_site_pp_path = File.join(environment_base_path, 'production', 'manifests', 'site.pp')
    site_pp = create_site_pp(master, :manifest => manifest)
    inject_site_pp(master, prod_env_site_pp_path, site_pp)

    on(default,
      puppet('agent', '-t', '--environment production'),
      :environment => remote_environment,
      :acceptable_exit_codes => (0...256),
      )
  end
end

class BeakerApplyRunner < BeakerRunnerBase
  def execute(manifest)
    # acceptable_exit_codes and expect_changes are passed because we want detailed-exit-codes but want to
    # make our own assertions about the responses
    apply_manifest(
      manifest,
      :expect_changes => true,
      :debug => true,
      :trace => true,
      :environment => remote_environment,
      :acceptable_exit_codes => (0...256),
    )
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

def expect_failed_apply(config)
  result = PuppetManifest.new(@template, config).execute
  expect(result.exit_code).not_to eq 0
end

def run_command_over_ssh(host, command, auth_method, port=22)
  # We retry failed attempts as although the VM has booted it takes some
  # time to start and expose SSH. This mirrors the behaviour of a typical SSH client
  allowed_errors = [
    # The following errors can occur if we try and connect after the machine has
    # been created but before cloud-init provisions the machine
    Net::SSH::HostKeyMismatch,
    Net::SSH::AuthenticationFailed,
    # The following errors can occur before the machine has been created
    # and we retry until it exists
    Errno::ECONNREFUSED,
    Errno::ECONNRESET,
    Errno::ETIMEDOUT,
  ]
  handler = Proc.new do |exception, attempt_number, total_delay|
    puts "Handler saw a #{exception.class}; retry attempt #{attempt_number}; #{total_delay} seconds have passed."
    puts exception
  end
  with_retries(:max_tries => 10,
               :base_sleep_seconds => 20,
               :max_sleep_seconds => 20,
               :rescue => allowed_errors,
               :handler => handler) do
    Net::SSH.start(host,
                   @config[:optional][:user],
                   :port => port,
                   :password => @config[:optional][:password],
                   :keys => [@local_private_key_path],
                   :auth_methods => [auth_method],
                   :verbose => :info) do |ssh|
      SshExec.ssh_exec!(ssh, command)
    end
  end
end

def run_command_over_winrm(command, port=5986)
  endpoint = "https://#{@machine.ipaddress}:#{port}/wsman"
  winrm = WinRM::WinRMWebService.new(
    endpoint,
    :ssl,
    user: @config[:optional][:user],
    pass: @config[:optional][:password],
    disable_sspi: true,
  )
  with_retries(:max_tries => 5) do
    winrm.cmd(command)
  end
end

def puppet_resource_should_show(property_name, value=nil)
  it "should report the correct #{property_name} value" do
    # this overloading allows for passing either a key or a key and value
    # and naively picks the key from @config if it exists. This is because
    # @config is only available in the context of a test, and not in the context
    # of describe or context
    real_value = @config[:optional][property_name.to_sym] || value
    regex = if real_value.nil?
              /(#{property_name})(\s*)(=>)(\s*)/
            else
              /(#{property_name})(\s*)(=>)(\s*)('#{real_value}'|#{real_value})/
            end
    expect(@result.stdout).to match(regex)
  end
end
