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

        def build(klass, data={})
          model = klass.new
          data.each do |k,v|
            model.send "#{k}=", v
          end
          model
        end

        def create_resource_group(args)
          params = ::Azure::ARM::Resources::Models::ResourceGroup.new
          params.location = args[:location]
          promise = ProviderArm.resource_client.resource_groups.create_or_update(args[:resource_group], params)
          promise.value!.body
        end

        def build_os_vhd_uri(args)
          container = "https://#{args[:storage_account]}.blob.core.windows.net/#{args[:os_disk_vhd_container_name]}"
          "#{container}/os#{args[:os_disk_vhd_name]}.vhd"
        end

        def build_image_reference(args) # rubocop:disable Metrics/AbcSize
          ref = ::Azure::ARM::Compute::Models::ImageReference.new
          ref.publisher = args[:image].split(':')[0]
          ref.offer = args[:image].split(':')[1]
          ref.sku = args[:image].split(':')[2]
          ref.version = args[:image].split(':')[3]
          ref
        end

        def build_storage_account_create_parameters(args)
          params = ::Azure::ARM::Storage::Models::StorageAccountCreateParameters.new
          params.location = args[:location]
          params.name = args[:storage_account]
          props = ::Azure::ARM::Storage::Models::StorageAccountPropertiesCreateParameters.new
          props.account_type = args[:storage_account_type]
          params.properties = props
          params
        end

        def create_storage_account(args)
          params = build_storage_account_create_parameters(args)
          promise = ProviderArm.storage_client.storage_accounts.create(args[:resource_group], args[:storage_account], params)
          result = promise.value!.body
          result.name = args[:storage_account]
          result
        end

        def build_storage_profile(args) # rubocop:disable Metrics/AbcSize
          storage_profile = ::Azure::ARM::Compute::Models::StorageProfile.new
          storage_profile.image_reference = build_image_reference(args)
          os_disk = ::Azure::ARM::Compute::Models::OSDisk.new
          os_disk.caching = args[:os_disk_caching]
          os_disk.create_option = args[:os_disk_create_option]
          os_disk.name = args[:os_disk_name]
          virtual_hard_disk = ::Azure::ARM::Compute::Models::VirtualHardDisk.new
          virtual_hard_disk.uri = build_os_vhd_uri(args)
          os_disk.vhd = virtual_hard_disk
          storage_profile.os_disk = os_disk
          storage_profile
        end

        def build_public_ip_params(args)
          public_ip = ::Azure::ARM::Network::Models::PublicIpAddress.new
          public_ip.location = args[:location]
          props = ::Azure::ARM::Network::Models::PublicIpAddressPropertiesFormat.new
          props.public_ipallocation_method = args[:public_ip_allocation_method]
          dns_settings = ::Azure::ARM::Network::Models::PublicIpAddressDnsSettings.new
          dns_settings.domain_name_label = args[:dns_domain_name]
          props.dns_settings = dns_settings
          public_ip.properties = props
          public_ip
        end

        def build_virtual_network_params(args) # rubocop:disable Metrics/AbcSize
          params = ::Azure::ARM::Network::Models::VirtualNetwork.new
          props = ::Azure::ARM::Network::Models::VirtualNetworkPropertiesFormat.new
          params.location = args[:location]
          address_space = ::Azure::ARM::Network::Models::AddressSpace.new
          address_space.address_prefixes = [args[:virtual_network_address_space]]
          props.address_space = address_space
          dhcp_options = ::Azure::ARM::Network::Models::DhcpOptions.new
          dhcp_options.dns_servers = args[:dns_servers].split
          props.dhcp_options = dhcp_options
          sub2 = ::Azure::ARM::Network::Models::Subnet.new
          sub2_prop = ::Azure::ARM::Network::Models::SubnetPropertiesFormat.new
          sub2.name = args[:subnet_name]
          sub2_prop.address_prefix = args[:subnet_address_prefix]
          sub2.properties = sub2_prop
          props.subnets = [sub2]
          params.properties = props
          params
        end

        def create_virtual_network(args)
          params = build_virtual_network_params(args)
          promise = ProviderArm.network_client.virtual_networks.create_or_update(args[:resource_group], args[:virtual_network_name], params)
          promise.value!.body
        end

        def build_subnet_params(args)
          params = ::Azure::ARM::Network::Models::Subnet.new
          prop = ::Azure::ARM::Network::Models::SubnetPropertiesFormat.new
          params.properties = prop
          prop.address_prefix = args[:subnet_address_prefix]
          params
        end

        def create_public_ip_address(args)
          params = build_public_ip_params(args)
          promise = ProviderArm.network_client.public_ip_addresses.create_or_update(args[:resource_group], args[:public_ip_address_name], params)
          promise.value!.body
        end

        def create_subnet(virtual_network, args)
          params = build_subnet_params(args)
          ProviderArm.network_client.subnets.create_or_update(
            args[:resource_group],
            virtual_network.name,
            args[:subnet_name],
            params
          ).value!.body
        end

        def build_network_interface_param(args, subnet) # rubocop:disable Metrics/AbcSize
          params = ::Azure::ARM::Network::Models::NetworkInterface.new
          params.location = args[:location]
          params.name = args[:network_interface_name]

          ip_configuration = ::Azure::ARM::Network::Models::NetworkInterfaceIpConfiguration.new
          ip_configuration.properties = ::Azure::ARM::Network::Models::NetworkInterfaceIpConfigurationPropertiesFormat.new
          ip_configuration.name = args[:ip_configuration_name]
          ip_configuration.properties.private_ipallocation_method = 'Dynamic'
          ip_configuration.properties.public_ipaddress = create_public_ip_address(args)
          ip_configuration.properties.subnet = subnet

          props = ::Azure::ARM::Network::Models::NetworkInterfacePropertiesFormat.new
          props.ip_configurations = [ip_configuration]

          params.properties = props
          params
        end

        def create_network_interface(args, subnet)
          params = build_network_interface_param(args, subnet)
          ProviderArm.network_client.network_interfaces.create_or_update(args[:resource_group], params.name, params).value!.body
        end

        def build_network_profile(args)
          vn = create_virtual_network(args)
          network_interface = create_network_interface(args, create_subnet(vn, args))
          profile = ::Azure::ARM::Compute::Models::NetworkProfile.new
          profile.network_interfaces = [network_interface]
          profile
        end

        def build_props(args) # rubocop:disable Metrics/AbcSize
          props = ::Azure::ARM::Compute::Models::VirtualMachineProperties.new

          windows_config = ::Azure::ARM::Compute::Models::WindowsConfiguration.new
          windows_config.provision_vmagent = false
          windows_config.enable_automatic_updates = false

          os_profile = ::Azure::ARM::Compute::Models::OSProfile.new
          os_profile.computer_name = args[:name]
          os_profile.admin_username = args[:user]
          os_profile.admin_password = args[:password]

          os_profile.secrets = []
          props.os_profile = os_profile

          hardware_profile = ::Azure::ARM::Compute::Models::HardwareProfile.new
          hardware_profile.vm_size = args[:size]
          props.hardware_profile = hardware_profile
          props.storage_profile = build_storage_profile(args)
          props.network_profile = build_network_profile(args)
          props
        end

        def build_params(args)
          build ::Azure::ARM::Compute::Models::VirtualMachine, {
            type: 'Microsoft.Compute/virtualMachines',
            properties: build_props(args),
            location: args[:location],
          }
        end

        def create_vm(args)
          register_providers
          create_resource_group(args)
          create_storage_account(args)

          params = build_params(args)

          ProviderArm.compute_client.virtual_machines.create_or_update(args[:resource_group], args[:name], params).value!
        end

        def delete_vm(machine)
          ProviderArm.compute_client.virtual_machines.delete(resource_group, machine.name).value!
        end

        def stop_vm(machine)
          ProviderArm.compute_client.virtual_machines.power_off(resource_group, machine.name).value!
        end

        def start_vm(machine)
          ProviderArm.compute_client.virtual_machines.start(resource_group, machine.name).value!
        end

        def get_all_vms
          vms = ProviderArm.compute_client.virtual_machines.list_all.value!.body.value
          vms.collect do |vm|
            ProviderArm.compute_client.virtual_machines.get(resource_group_from(vm), vm.name, 'instanceView').value!.body
          end
        end

        def resource_group_from(machine)
          machine.id.split('/')[4].downcase
        end

        def get_vm(name)
          get_all_vms.find { |vm| vm.name == name }
        end
      end
    end
  end
end
