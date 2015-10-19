require 'stringio'
require 'puppet_x/puppetlabs/azure/config'
require 'puppet_x/puppetlabs/azure/not_finished'

require 'azure_mgmt_compute'
require 'azure_mgmt_resources'
require 'azure_mgmt_storage'
require 'azure_mgmt_network'
require 'ms_rest_azure'

include MsRest
include MsRestAzure
include Azure::ARM::Resources
include Azure::ARM::Compute
include Azure::ARM::Compute::Models
include Azure::ARM::Storage
include Azure::ARM::Network
include Azure::ARM::Network::Models

include Azure
require 'pry'

module PuppetX
  module Puppetlabs
    module Azure
      class LoggerAdapter
        def info(msg)
          Puppet.info("azure-sdk: " + msg)
        end

        def warn(msg)
          Puppet.warning("azure-sdk: " + msg)
        end

        def error(msg)
          Puppet.err("azure-sdk: " + msg)
        end
      end

      class ProviderBase < Puppet::Provider
        # all of this needs to happen once in the life-time of the runtime,
        # but Puppet.feature does not allow us to add a feature-conditional
        # initialization, so we need to be a little bit circumspect here.
        begin
          require 'azure'

          # re-route azure's messages to puppet
          ::Azure::Core::Logger.initialize_external_logger(LoggerAdapter.new)
        rescue LoadError
          Puppet.debug("Couldn't load azure SDK")
        end

        def self.read_only(*methods)
          methods.each do |method|
            define_method("#{method}=") do |v|
              fail "#{method} property is read-only once #{resource.type} created."
            end
          end
        end

        def self.config
          PuppetX::Puppetlabs::Azure::Config.new
        end
      end

=begin
      Azure Resource Management API

      The ARM API requires
      subscription_id
      tenant_id => Found in the URI of the portal along with the client subscrition_id
      client_id => A application must be created on the default account ActiveDirectory for this to be created
      client_secret => This is generated on the application created on the default account as well, once its saved.

      The application MUST be granted at least a contributor role for the ARM API to allow you access. This is done through
      windows powershell.

      See the Readme.md
=end

      class Provider_ARM < ProviderBase

        MICROSOFT_PROVIDER_STORAGE="Microsoft.Storage"
        MICROSOFT_PROVIDER_NETWORK="Microsoft.Network"
        MICROSOFT_PROVIDER_COMPUTE="Microsoft.Compute"

        @location = "eastus" # GH:: check mapping. these seem to not match the regions??!
        @resource_group_name = "puppet_msazure_res_group"
        @storage_account = "puppet_msazure_storage_account" # TO DO : add a uuid
        @storage_account_type =  'Standard_GRS'

        def initialise(location, size)
          @location = location
          @size = size
        end

        def self.credentials
          token_provider = ::MsRestAzure::ApplicationTokenProvider.new(config.tenant_id, config.client_id, config.client_secret)
          credentials = ::MsRest::TokenCredentials.new(token_provider)
        end

        def self.with_subscription_id(client)
          client.subscription_id = config.subscription_id
          client
        end

        def self.compute_client
          @compute_client ||= with_subscription_id ::Azure::ARM::Compute::ComputeManagementClient.new(credentials)
        end

        def self.network_client
          @network_client ||= with_subscription_id ::Azure::ARM::Network::NetworkResourceProviderClient.new(credentials)
        end

        def self.storage_client
         @storage_client ||= with_subscription_id ::Azure::ARM::Storage::StorageManagementClient.new(credentials)
        end

        def self.resource_client
          @resource_client ||= with_subscription_id ::Azure::ARM::Resources::ResourceManagementClient.new(credentials)
        end

        def self.get_random_name(prefix = "puppet", length = 1000)
          prefix + SecureRandom.uuid.downcase.delete('^a-zA-Z0-9')[0...length]
        end

        def self.register_azure_provider(name)
          promise = @resource_client.providers.register(name)
          promise.value!.body
        end

        def self.register_providers
          register_azure_provider(MICROSOFT_PROVIDER_STORAGE)
          register_azure_provider(MICROSOFT_PROVIDER_NETWORK)
          register_azure_provider(MICROSOFT_PROVIDER_COMPUTE)
        end


        def self.list_resource_providers
          provider_worker = @resource_client.providers.list
          result = provider_worker.value!.body.value
          result
        end

        def self.create_resource_group
          params = Azure::ARM::Resources::Models::ResourceGroup.new
          params.location = @location
          @resource_client.resource_groups.create_or_update(@resource_group_name, params).value!.body
        end

        def self.find_resource_group(name)
          resource_groups = @resource_client.resource_groups.list.value!.body
          rg = resource_groups.value.find { |x| x.name == name }
          rg
        end

        def self.delete_resource_group(name)
          @resource_client.resource_groups.delete(name).value!
        end

        def self.list_storage_accounts
          promise = @storage_client.storage_accounts.list
          result = promise.value!.body
          result.value
        end

        def self.get_storage_account(name)
          accounts = list_storage_accounts
          account = accounts.find { |x| x.name == name }
          account
        end

        #
        # ARM launch params and profiles
        #

        def generate_os_vhd_uri
          container_name = get_random_name 'cont'
          vhd_container = "https://#{@storage_account}.blob.core.windows.net/#{container_name}"
          os_vhduri = "#{vhd_container}/os#{get_random_name 'test'}.vhd"
          os_vhduri
        end

        #image reference format for ARM images canonical:ubuntuserver:14.04.2-LTS:latest
        def get_image_reference()
          ref = ImageReference.new
          ref.publisher = config.image_reference.split(':')[0]
          ref.offer = config.image_reference.split(':')[1]
          ref.sku = config.image_reference.split(':')[2]
          ref.version = config.image_reference.split(':')[3]
          ref
        end

        def build_storage_account_create_parameters(name, location)
          params = Azure::ARM::Storage::Models::StorageAccountCreateParameters.new
          params.location = location
          params.name = name
          props = Azure::ARM::Storage::Models::StorageAccountPropertiesCreateParameters.new
          params.properties = props
          props.account_type = @storage_account_type
          params
        end

        def create_storage_account
          params = build_storage_account_create_parameters(@storage_account, location)
          storage_worker = STORAGE_CLIENT.storage_accounts.create(resource_group.name, @storage_account, params)
          result = storage_worker.value!.body
          result.name = @storage_account #similar problem in dot net tests
          result
        end

        def create_storage_profile
          storage_profile = StorageProfile.new
          storage_profile.image_reference = get_image_reference
          os_disk = OSDisk.new
          os_disk.caching = 'ReadWrite'
          os_disk.create_option = 'fromImage'
          os_disk.name = 'myosdisk1'
          virtual_hard_disk = VirtualHardDisk.new
          virtual_hard_disk.uri = generate_os_vhd_uri
          os_disk.vhd = virtual_hard_disk
          storage_profile.os_disk = os_disk
          storage_profile
        end

        # Network helpers
        def build_public_ip_params
          public_ip = PublicIpAddress.new
          public_ip.location = @location
          props = PublicIpAddressPropertiesFormat.new
          props.public_ipallocation_method = 'Dynamic'
          public_ip.properties = props
          domain_name = get_random_name 'domain'
          dns_settings = PublicIpAddressDnsSettings.new
          dns_settings.domain_name_label = domain_name
          props.dns_settings = dns_settings
          public_ip
        end

        def create_public_ip_address
          public_ip_address_name = get_random_name('ip_name')
          params = build_public_ip_params(@location)
          @network_client.public_ip_addresses.create_or_update(@resource_group_name, public_ip_address_name, params).value!.body
        end

        def build_virtual_network_params
          params = VirtualNetwork.new
          props = VirtualNetworkPropertiesFormat.new
          params.location = @location
          address_space = AddressSpace.new
          address_space.address_prefixes = ['10.0.0.0/16']
          props.address_space = address_space
          dhcp_options = DhcpOptions.new
          dhcp_options.dns_servers = %w(10.1.1.1 10.1.2.4)
          props.dhcp_options = dhcp_options
          sub2 = Subnet.new
          sub2_prop = SubnetPropertiesFormat.new
          sub2.name = get_random_name('subnet')
          sub2_prop.address_prefix = '10.0.2.0/24'
          sub2.properties = sub2_prop
          props.subnets = [sub2]
          params.properties = props
          params
        end

        def create_virtual_network(resource_group_name)
          virtualNetworkName = get_random_name("vnet")
          params = build_virtual_network_params
          promise = @network_client.virtual_networks.create_or_update(resource_group_name, virtualNetworkName, params)
          promise.value!.body
        end

        def build_subnet_params
          params = Subnet.new
          prop = SubnetPropertiesFormat.new
          params.properties = prop
          prop.address_prefix = '10.0.1.0/24'
          params
        end

        def self.create_subnet(virtual_network)
          subnet_name = get_random_name('subnet')
          params = build_subnet_params
          @network_client.subnets.create_or_update(@resource_group_name, virtual_network.name, subnet_name, params).value!.body
        end

        def self.create_network_interface
          params = build_network_interface_param
          @network_client.network_interfaces.create_or_update(@resource_group_name, params.name, params).value!.body
        end

        def build_network_interface_param
          params = NetworkInterface.new
          params.location = @location
          network_interface_name = get_random_name('nic')
          ip_config_name = get_random_name('ip_name')
          params.name = network_interface_name
          props = NetworkInterfacePropertiesFormat.new
          ip_configuration = NetworkInterfaceIpConfiguration.new
          params.properties = props
          props.ip_configurations = [ip_configuration]
          ip_configuration_properties = NetworkInterfaceIpConfigurationPropertiesFormat.new
          ip_configuration.properties = ip_configuration_properties
          ip_configuration.name = ip_config_name
          ip_configuration_properties.private_ipallocation_method = 'Dynamic'
          ip_configuration_properties.public_ipaddress = create_public_ip_address
          ip_configuration_properties.subnet = @created_subnet
          params
        end

        def create_network_profile
          vn = create_virtual_network
          @created_subnet = create_subnet(vn)
          network_interface = create_network_interface

          profile = NetworkProfile.new
          profile.network_interfaces = [network_interface]

          profile
        end

        def build_props
          props = VirtualMachineProperties.new

          windows_config = WindowsConfiguration.new
          windows_config.provision_vmagent = false
          windows_config.enable_automatic_updates = false

          os_profile = OSProfile.new
          os_profile.computer_name = vm_name
          os_profile.admin_username = @user
          os_profile.admin_password = @password

          os_profile.secrets = []
          props.os_profile = os_profile

          hardware_profile = HardwareProfile.new
          hardware_profile.vm_size = @size
          props.hardware_profile = hardware_profile
          props.storage_profile = create_storage_profile
          props.network_profile = create_network_profile
          props
        end

        def build_params
          props = build_props

          params = VirtualMachine.new
          params.type = 'Microsoft.Compute/virtualMachines'
          params.properties = props
          params.location = @location
          params
        end

        #
        # Create/Update/Destroy VM
        #

        def self.create_vm(vm_name)
          create_resource_group
          create_storage_account

          params = build_params

          promise = @compute_client.virtual_machines.begin_create_or_update(@resource_group_name, vm_name, params)
          promise.value!.body
        end

        def self.delete_vm(vm_name)
          promise = @compute_client.virtual_machines.delete(@resource_group_name, vm_name)
          promise.value!.body
        end

        def stop_vm(vm_name)
          @compute_client.virtual_machines.poweroff(@resource_group_name, vm_name)
        end

        def start_vm(vm_name)
          @compute_client.virtual_machines.start(@resource_group_name, vm_name)
        end

        def self.get_all_vms
          promise = @compute_client.virtual_machines.list_all
          promise.value!.body.value
        end

        def self.get_vm(name)
          list_all_vms.find { |vm| vm.name == name }
        end
      end

=begin
      Azure Classic API
=end
      class Provider < ProviderBase

        # Workaround https://github.com/Azure/azure-sdk-for-ruby/issues/269
        # This needs to be separate from the rescue above, as this might
        # get fixed on a different schedule.
        begin
          require 'azure/virtual_machine_image_management/virtual_machine_image_management_service'
        rescue LoadError
          Puppet.debug("Couldn't load azure SDK")
        end

        def self.vm_manager
          ::Azure.vm_management
        end

        def self.cloud_service_manager
          ::Azure.cloud_service_management
        end

        def self.disk_manager
          ::Azure.vm_disk_management
        end

        def self.sql_manager
          ::Azure.sql_database_management
        end

        def self.list_vms
          vm_manager.list_virtual_machines
        end

        def self.get_cloud_service(service_name)
          @services ||= Hash.new do |h, key|
            h[key] = cloud_service_manager.get_cloud_service(key) if key
          end
          @services[service_name]
        end

        def find_vm(name)
          Provider.vm_manager.list_virtual_machines.find { |x| x.vm_name == name }
        end

        def create_disk(vm_name, cloud_service_name, data_disk_size_gb)
          Provider.vm_manager.add_data_disk(
            vm_name,
            cloud_service_name,
            {
              disk_label: "data-disk-for-#{vm_name}",
              disk_size: data_disk_size_gb,
              import: false,
            })
        end

        def create_vm(args) # rubocop:disable Metrics/AbcSize
          param_names = [:vm_name, :image, :location, :vm_user, :password, :custom_data]
          params = (args.keys & param_names).each_with_object({}) { |k,h| h.update(k=>args.delete(k)) }
          sanitised_params = params.delete_if { |k, v| v.nil? }
          sanitised_args = args.delete_if { |k, v| v.nil? }
          data_disk_size_gb = sanitised_args.delete(:data_disk_size_gb)
          Provider.vm_manager.create_virtual_machine(sanitised_params, sanitised_args)
          if data_disk_size_gb
            create_disk(params[:vm_name], args[:cloud_service_name], data_disk_size_gb)
          end
        end

        def delete_vm(machine)
          Provider.vm_manager.delete_virtual_machine(machine.vm_name, machine.cloud_service_name)
        end

        def delete_disk(disk_name) # rubocop:disable Metrics/AbcSize
          # Since the API does not guarantee the removal of the disk, we need to take
          # extra care to clean up. Additionally, when touching disks of VMs going out,
          # Azure sometimes has a lock on them, causing API calls to fail with API errors.
          with_retries(:max_tries => 10,
                       :base_sleep_seconds => 20,
                       :max_sleep_seconds => 20,
                       :rescue => [
                         NotFinished,
                         ::Azure::Core::Error,
                         # The following errors can occur when there are network issues
                         Errno::ECONNREFUSED,
                         Errno::ECONNRESET,
                         Errno::ETIMEDOUT,]) do
            Puppet.debug("Trying to deleting disk #{disk_name}")
            begin
              Provider.disk_manager.delete_virtual_machine_disk(disk_name)
              if Provider.disk_manager.get_virtual_machine_disk(disk_name)
                Puppet.debug("Disk was not deleted. Retrying to deleting disk #{disk_name}")
                raise NotFinished.new
              end
            rescue RuntimeError => err
              # The disk may already be in the process of being deleted by Azure,
              # therefore we might have lost that race
              # Note: pattern cannot be anchored, since the azure-sdk adds its own
              # escape sequences for coloring it
              case err.message
              when /ConflictError : Windows Azure is currently performing an operation/
                raise NotFinished.new
              when /ResourceNotFound : The disk with the specified name does not exist/
                return # it's gone!
              else
                raise
              end
            rescue NotFinished
              raise
            rescue ::Azure::Core::Error
              raise
            rescue => err
              # Sometimes azure throws weird ConflictErrors that do not seem to be
              # ::Azure::Core::Error . Of course as soon as I added these debugs
              # Azure stopped conflicting. I'll leave these in for now, to maybe
              # catch this later
              Puppet.info("Please report this - leaking disk #{disk_name}")
              Puppet.info("CAUGHT: class #{err.class}")
              Puppet.info("CAUGHT: inspc #{err.inspect}")
              Puppet.info("CAUGHT: to_s  #{err}")
              raise
            end
          end
          if Provider.disk_manager.get_virtual_machine_disk(disk_name)
            Puppet.warning("Disk #{disk_name} was not deleted")
          else
            Puppet.debug("Disk #{disk_name} was deleted")
          end
        end

        def update_endpoints(should) # rubocop:disable Metrics/AbcSize
          Puppet.debug("Updating endpoints for #{name}: from #{endpoints} to #{should.inspect}")
          unless endpoints == :absent
            to_delete = endpoints.collect { |ep| ep[:name] } - should.collect { |ep| ep[:name] }
            to_delete.each do |name|
              Provider.vm_manager.delete_endpoint(resource[:name], resource[:cloud_service], name)
            end
          end
          Provider.vm_manager.update_endpoints(resource[:name], resource[:cloud_service], should)
        end

        def stop_vm(machine)
          Provider.vm_manager.shutdown_virtual_machine(machine.vm_name, machine.cloud_service_name)
        end

        def start_vm(machine)
          Provider.vm_manager.start_virtual_machine(machine.vm_name, machine.cloud_service_name)
        end
      end
    end
  end
end
