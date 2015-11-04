require 'stringio'
require 'puppet_x/puppetlabs/azure/config'
require 'puppet_x/puppetlabs/azure/not_finished'
require 'puppet_x/puppetlabs/azure/provider_base'
require 'puppet_x/puppetlabs/azure/provider'

require 'azure_mgmt_compute'
require 'azure_mgmt_resources'
require 'azure_mgmt_storage'
require 'azure_mgmt_network'
require 'ms_rest_azure'

# TODO remove these
include MsRest
include MsRestAzure
include Azure::ARM::Resources
include Azure::ARM::Compute
include Azure::ARM::Compute::Models
include Azure::ARM::Storage
include Azure::ARM::Network
include Azure::ARM::Network::Models

module PuppetX
  module Puppetlabs
    module Azure
      # Azure Resource Management API
      #
      # The ARM API requires
      # subscription_id
      # tenant_id => Found in the URI of the portal along with the client subscrition_id
      # client_id => A application must be created on the default account ActiveDirectory for this to be created
      # client_secret => This is generated on the application created on the default account as well, once its saved.
      #
      # The application MUST be granted at least a contributor role for the ARM API to allow you access. This is done through
      # windows powershell.
      class ProviderArm < ::PuppetX::Puppetlabs::Azure::ProviderBase
        def self.credentials
          token_provider = ::MsRestAzure::ApplicationTokenProvider.new(ProviderBase.config.tenant_id,
            ProviderBase.config.client_id, ProviderBase.config.client_secret)

          ::MsRest::TokenCredentials.new(token_provider)
        end

        def self.with_subscription_id(client)
          client.subscription_id = ProviderBase.config.subscription_id
          client
        end

        def self.compute_client
          @compute_client ||= ProviderArm.with_subscription_id ::Azure::ARM::Compute::ComputeManagementClient.new(ProviderArm.credentials)
        end

        def self.network_client
          @network_client ||= ProviderArm.with_subscription_id ::Azure::ARM::Network::NetworkResourceProviderClient.new(ProviderArm.credentials)
        end

        def self.storage_client
         @storage_client ||= ProviderArm.with_subscription_id ::Azure::ARM::Storage::StorageManagementClient.new(ProviderArm.credentials)
        end

        def self.resource_client
          @resource_client ||= ProviderArm.with_subscription_id ::Azure::ARM::Resources::ResourceManagementClient.new(ProviderArm.credentials)
        end

        def register_azure_provider(name)
          ProviderArm.resource_client.providers.register(name).value!.body
        end

        def register_providers
          register_azure_provider('Microsoft.Storage')
          register_azure_provider('Microsoft.Network')
          register_azure_provider('Microsoft.Compute')
        end

        def list_resource_providers
          promise = ProviderArm.resource_client.providers.list
          result = promise.value!.body.value
          result
        end

        def create_resource_group(location)
          params = ::Azure::ARM::Resources::Models::ResourceGroup.new
          params.location = location
          promise = ProviderArm.resource_client.resource_groups.create_or_update(@resource_group_name, params)
          promise.value!.body
        end

        def find_resource_group(name)
          promise = ProviderArm.resource_client.resource_groups.list.value!.body
          resource_groups = promise.value!.body
          rg = resource_groups.value.find { |x| x.name == name }
          rg
        end

        def delete_resource_group(name)
          ProviderArm.resource_client.resource_groups.delete(name).value!
        end

        def list_storage_accounts
          promise = ProviderArm.storage_client.storage_accounts.list
          result = promise.value!.body
          result.value
        end

        def get_storage_account(name)
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
        def get_image_reference
          ref = ImageReference.new
          ref.publisher = resource[:image].split(':')[0]
          ref.offer = resource[:image].split(':')[1]
          ref.sku = resource[:image].split(':')[2]
          ref.version = resource[:image].split(':')[3]
          ref
        end

        def build_storage_account_create_parameters(location)
          params = ::Azure::ARM::Storage::Models::StorageAccountCreateParameters.new
          params.location = location
          params.name = @storage_account
          props = ::Azure::ARM::Storage::Models::StorageAccountPropertiesCreateParameters.new
          params.properties = props
          props.account_type = @storage_account_type
          params
        end

        def create_storage_account(location)
          params = build_storage_account_create_parameters(location)
          promise = ProviderArm.storage_client.storage_accounts.create(@resource_group_name, @storage_account, params)
          result = promise.value!.body
          result.name = @storage_account #similar problem in dot net tests
          result
        end

        def create_storage_profile
          storage_profile = StorageProfile.new
          storage_profile.image_reference = get_image_reference
          os_disk = OSDisk.new
          os_disk.caching = 'ReadWrite'
          os_disk.create_option = 'FromImage'
          os_disk.name = 'osdisk01'
          virtual_hard_disk = VirtualHardDisk.new
          virtual_hard_disk.uri = generate_os_vhd_uri
          os_disk.vhd = virtual_hard_disk
          storage_profile.os_disk = os_disk
          storage_profile
        end

        # Network helpers
        def build_public_ip_params(location)
          public_ip = PublicIpAddress.new
          public_ip.location = location
          props = PublicIpAddressPropertiesFormat.new
          props.public_ipallocation_method = 'Dynamic'
          public_ip.properties = props
          domain_name = get_random_name 'domain'
          dns_settings = PublicIpAddressDnsSettings.new
          dns_settings.domain_name_label = domain_name
          props.dns_settings = dns_settings
          public_ip
        end

        def create_public_ip_address(location)
          public_ip_address_name = get_random_name('ip_name')
          params = build_public_ip_params(location)

          promise = ProviderArm.network_client.public_ip_addresses.create_or_update(@resource_group_name, public_ip_address_name, params)
          promise.value!.body
        end

        def build_virtual_network_params(location)
          params = VirtualNetwork.new
          props = VirtualNetworkPropertiesFormat.new
          params.location = location
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

        def create_virtual_network(location)
          virtualNetworkName = get_random_name("vnet")
          params = build_virtual_network_params(location)
          promise = ProviderArm.network_client.virtual_networks.create_or_update(@resource_group_name, virtualNetworkName, params)
          promise.value!.body
        end

        def build_subnet_params
          params = Subnet.new
          prop = SubnetPropertiesFormat.new
          params.properties = prop
          prop.address_prefix = '10.0.1.0/24'
          params
        end

        def create_subnet(virtual_network)
          subnet_name = get_random_name('subnet')
          params = build_subnet_params
          ProviderArm.network_client.subnets.create_or_update(@resource_group_name, virtual_network.name, subnet_name, params).value!.body
        end

        def create_network_interface(location)
          params = build_network_interface_param(location)
          ProviderArm.network_client.network_interfaces.create_or_update(@resource_group_name, params.name, params).value!.body
        end

        def build_network_interface_param(location)
          params = NetworkInterface.new
          params.location = location
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
          ip_configuration_properties.public_ipaddress = create_public_ip_address(location)
          ip_configuration_properties.subnet = @created_subnet
          params
        end

        def create_network_profile(location)
          vn = create_virtual_network(location)
          @created_subnet = create_subnet(vn)
          network_interface = create_network_interface(location)

          profile = NetworkProfile.new
          profile.network_interfaces = [network_interface]

          profile
        end

        def build_props(vm_name, location, size, user, password)
          props = VirtualMachineProperties.new

          windows_config = WindowsConfiguration.new
          windows_config.provision_vmagent = false
          windows_config.enable_automatic_updates = false

          os_profile = OSProfile.new
          os_profile.computer_name = vm_name
          os_profile.admin_username = user
          os_profile.admin_password = password

          os_profile.secrets = []
          props.os_profile = os_profile

          hardware_profile = HardwareProfile.new
          hardware_profile.vm_size = size
          props.hardware_profile = hardware_profile
          props.storage_profile = create_storage_profile
          props.network_profile = create_network_profile(location)
          props
        end

        def build_params(vm_name, location, size, user, password)
          props = build_props(vm_name, location, size, user, password)

          params = VirtualMachine.new
          params.type = 'Microsoft.Compute/virtualMachines'
          params.properties = props
          params.location = location
          params
        end

        #
        # Create/Update/Destroy VM
        #

        def get_random_name(prefix = "puppet", length = 1000)
          prefix + SecureRandom.uuid.downcase.delete('^a-zA-Z0-9')[0...length]
        end

        def create_vm(args)
          @resource_group_name = 'puppettestresacc02'
          @storage_account = 'puppetteststoracc02'
          @storage_account_type =  'Standard_GRS'

          location = args[:location]
          size = args[:size]
          user = args[:user]
          password = args[:password]
          vm_name = args[:name]

          register_providers
          create_resource_group(location)
          create_storage_account(location)
          params = build_params(vm_name, location, size, user, password)

          promise = ProviderArm.compute_client.virtual_machines.create_or_update(@resource_group_name, vm_name, params)
          result = promise.value!.body
        end

        def delete_vm(machine)
          ProviderArm.compute_client.virtual_machines.delete(get_resource_group_from(machine), machine.name).value!
        end

        def stop_vm(machine)
          ProviderArm.compute_client.virtual_machines.power_off(get_resource_group_from(machine), machine.name).value!
        end

        def start_vm(machine)
          ProviderArm.compute_client.virtual_machines.start(get_resource_group_from(machine), machine.name).value!
        end

        def get_all_vms
          vms = ProviderArm.compute_client.virtual_machines.list_all.value!.body.value
          vms.collect do |vm|
            ProviderArm.compute_client.virtual_machines.get(get_resource_group_from(vm), vm.name, 'instanceView').value!.body
          end
        end

        def get_resource_group_from(machine)
          machine.id.split('/')[4].downcase
        end

        def get_vm(name)
          get_all_vms.select { |vm| vm.name == name }
        end
      end
    end
  end
end
