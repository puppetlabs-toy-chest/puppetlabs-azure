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
      #
      # See the Readme.md

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
          promise = ProviderArm.resource_client.providers.register(name)
          promise.value!.body
        end

        def register_providers
          register_azure_provider('Microsoft.Storage')
          register_azure_provider('Microsoft.Network')
          register_azure_provider('Microsoft.Compute')
        end

        def create_resource_group
          params = ::Azure::ARM::Resources::Models::ResourceGroup.new
          params.location = @vm_context[:location]
          promise = ProviderArm.resource_client.resource_groups.create_or_update(@vm_context[:resource_group], params)
          promise.value!.body
        end

        def find_resource_group(name)
          promise = ProviderArm.resource_client.resource_groups.list.value!.body
          resource_groups = promise.value!.body
          resource_groups.value.find { |x| x.name == name }
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
          list_storage_accounts.find { |x| x.name == name }
        end

        # ARM launch params and profiles
        def generate_os_vhd_uri
          vhd_container = "https://#{@vm_context[:storage_account]}.blob.core.windows.net/#{@vm_context[:os_disk_vhd_container_name]}"
          "#{vhd_container}/os#{@vm_context[:os_disk_vhd_name]}.vhd"
        end

        # image reference format for ARM images canonical:ubuntuserver:14.04.2-LTS:latest
        def get_image_reference
          ref = ::Azure::ARM::Compute::Models::ImageReference.new
          ref.publisher, ref.offer, ref.sku, ref.version = ProviderBase.config.image_reference.split(':')
          ref
        end

        def build_storage_account_create_parameters
          params = ::Azure::ARM::Storage::Models::StorageAccountCreateParameters.new
          params.location = @vm_context[:location]
          params.name = @vm_context[:storage_account]
          props = ::Azure::ARM::Storage::Models::StorageAccountPropertiesCreateParameters.new
          params.properties = props
          props.account_type = @vm_context[:storage_account_type]
          params
        end

        def create_storage_account
          params = build_storage_account_create_parameters
          promise = ProviderArm.storage_client.storage_accounts.create(@vm_context[:resource_group], @vm_context[:storage_account], params)
          result = promise.value!.body
          result.name = @vm_context[:storage_account]
          result
        end

        def create_osdisk
          virtual_hard_disk = ::Azure::ARM::Compute::Models::VirtualHardDisk.new
          virtual_hard_disk.uri = generate_os_vhd_uri

          os_disk = ::Azure::ARM::Compute::Models::OSDisk.new
          os_disk.caching = @vm_context[:os_disk_caching]
          os_disk.create_option = @vm_context[:os_disk_create_option]
          os_disk.name = @vm_context[:os_disk_name]
          os_disk.vhd = virtual_hard_disk
          os_disk
        end

        def create_storage_profile
          storage_profile = ::Azure::ARM::Compute::Models::StorageProfile.new
          storage_profile.image_reference = get_image_reference
          storage_profile.os_disk = create_osdisk
          storage_profile
        end

        # Network helpers
        def build_public_ip_params
          public_ip = ::Azure::ARM::Network::Models::PublicIpAddress.new
          public_ip.location = @vm_context[:location]
          props = ::Azure::ARM::Network::Models::PublicIpAddressPropertiesFormat.new
          props.public_ipallocation_method = @vm_context[:public_ipallocation_method]
          public_ip.properties = props
          dns_settings = ::Azure::ARM::Network::Models::PublicIpAddressDnsSettings.new
          dns_settings.domain_name_label = @vm_context[:dns_domain_name]
          props.dns_settings = dns_settings
          public_ip
        end

        def create_public_ip_address
          params = build_public_ip_params
          promise = ProviderArm.network_client.public_ip_addresses.create_or_update(@vm_context[:resource_group], @vm_context[:public_ip_address_name], params)
          promise.value!.body
        end

        def build_virtual_subnet
          subnet = ::Azure::ARM::Network::Models::Subnet.new
          subnet_prop = ::Azure::ARM::Network::Models::SubnetPropertiesFormat.new
          subnet.name = @vm_context[:subnet_name]
          subnet_prop.address_prefix = @vm_context[:subnet_address_prefix]
          subnet.properties = subnet_prop
          subnet
        end

        def build_dhcp_options
          dhcp_options = ::Azure::ARM::Network::Models::DhcpOptions.new
          dhcp_options.dns_servers = @vm_context[:dns_servers].split
          dhcp_options
        end

        def build_address_space
          address_space = ::Azure::ARM::Network::Models::AddressSpace.new
          address_space.address_prefixes = [@vm_context[:virtual_network_address_space]]
          address_space
        end

        def build_network_properties
          props = ::Azure::ARM::Network::Models::VirtualNetworkPropertiesFormat.new
          props.address_space = build_address_space
          props.dhcp_options = build_dhcp_options
          props.subnets = [build_virtual_subnet]
          props
        end

        def create_virtual_network
          params = ::Azure::ARM::Network::Models::VirtualNetwork.new
          params.location = @vm_context[:location]
          params.properties = build_network_properties
          promise = ProviderArm.network_client.virtual_networks.create_or_update(@vm_context[:resource_group],@vm_context[:virtual_network_name], params)
          promise.value!.body
        end

        def build_subnet_params
          params = ::Azure::ARM::Network::Models::Subnet.new
          prop = ::Azure::ARM::Network::Models::SubnetPropertiesFormat.new
          params.properties = prop
          prop.address_prefix = @vm_context[:subnet_address_prefix]
          params
        end

        def create_subnet(virtual_network)
          params = build_subnet_params
          promise = ProviderArm.network_client.subnets.create_or_update(@vm_context[:resource_group],
            virtual_network.name, @vm_context[:subnet_name], params)
          promise.value!.body
        end

        def create_network_interface
          params = build_network_interface_param
          promise = ProviderArm.network_client.network_interfaces.create_or_update(@vm_context[:resource_group], params.name, params)
          promise.value!.body
        end

        def build_network_interface_properties(ip_configuration)
          props = ::Azure::ARM::Network::Models::NetworkInterfacePropertiesFormat.new
          props.ip_configurations = [ip_configuration]
          props
        end

        def build_ip_configuration(ip_configuration_properties)
          ip_configuration = ::Azure::ARM::Network::Models::NetworkInterfaceIpConfiguration.new
          ip_configuration.properties = ip_configuration_properties
          ip_configuration.name = @vm_context[:ip_configuration_name]
          ip_configuration
        end

        def build_ip_config_properties
          ip_configuration_properties = ::Azure::ARM::Network::Models::NetworkInterfaceIpConfigurationPropertiesFormat.new
          ip_configuration_properties.private_ipallocation_method = @vm_context[:private_ipallocation_method]
          ip_configuration_properties.public_ipaddress = create_public_ip_address
          ip_configuration_properties.subnet = @created_subnet
          ip_configuration_properties
        end

        def build_network_interface_param
          ip_configuration_properties = build_ip_config_properties
          ip_configuration = build_ip_configuration(ip_configuration_properties)

          params = ::Azure::ARM::Network::Models::NetworkInterface.new
          params.location = @vm_context[:location]
          params.name = @vm_context[:network_interface_name]
          params.properties = build_network_interface_properties(ip_configuration)
          params
        end

        def create_network_profile
          vn = create_virtual_network
          @created_subnet = create_subnet(vn)
          network_interface = create_network_interface
          profile = ::Azure::ARM::Compute::Models::NetworkProfile.new
          profile.network_interfaces = [network_interface]
          profile
        end

        def build_os_profile
          os_profile = ::Azure::ARM::Compute::Models::OSProfile.new
          os_profile.computer_name = @vm_context[:name]
          os_profile.admin_username = @vm_context[:user]
          os_profile.admin_password = @vm_context[:password]
          os_profile.secrets = []
          os_profile
        end

        def build_hardware_profile
          hardware_profile = ::Azure::ARM::Compute::Models::HardwareProfile.new
          hardware_profile.vm_size = @vm_context[:size]
          hardware_profile
        end

        def build_props
          props = ::Azure::ARM::Compute::Models::VirtualMachineProperties.new
          props.os_profile = build_os_profile
          props.hardware_profile = build_hardware_profile
          props.storage_profile = create_storage_profile
          props.network_profile = create_network_profile
          props
        end

        def build_params
          props = build_props

          params = ::Azure::ARM::Compute::Models::VirtualMachine.new
          params.type = 'Microsoft.Compute/virtualMachines'
          params.properties = props
          params.location = @vm_context[:location]
          params
        end

        #
        # Create/Update/Destroy VM
        #

        def create_arm_vm(args)
          @vm_context = args

          register_providers
          create_resource_group
          create_storage_account
          params = build_params

          promise = ProviderArm.compute_client.virtual_machines.create_or_update(@vm_context[:resource_group], @vm_context[:name], params)
          promise.value!.body
        end

        def delete_vm(args)
          @vm_context = args
          promise = ProviderArm.compute_client.virtual_machines.delete(@vm_context[:resource_group], @vm_context[:name])
          promise.value!.body
        end

        def stop_vm(args)
          @vm_context = args
          ProviderArm.compute_client.virtual_machines.poweroff(@vm_context[:resource_group], @vm_context[:name])
        end

        def start_vm(args)
          @vm_context = args
          ProviderArm.compute_client.virtual_machines.start(@vm_context[:resource_group], @vm_context[:name])
        end

        def get_all_vms
          promise = ProviderArm.compute_client.virtual_machines.list_all
          promise.value!.body.value
        end

        def get_vm(name)
          get_all_vms.find { |vm| vm.properties.os_profile.computerName == name }
        end
      end
    end
  end
end
