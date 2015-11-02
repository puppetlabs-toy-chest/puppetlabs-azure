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
          ProviderArm.resource_client.providers.register(name).value!.body
        end

        def register_providers
          register_azure_provider('Microsoft.Storage')
          register_azure_provider('Microsoft.Network')
          register_azure_provider('Microsoft.Compute')
        end

        def create_resource_group(vm_context)
          params = ::Azure::ARM::Resources::Models::ResourceGroup.new
          params.location = vm_context[:location]
          promise = ProviderArm.resource_client.resource_groups.create_or_update(vm_context[:resource_group], params)
          promise.value!.body
        end

        def delete_resource_group(name)
          ProviderArm.resource_client.resource_groups.delete(name).value!
        end

        def list_storage_accounts
          promise = ProviderArm.storage_client.storage_accounts.list
          promise.value!.body.value
        end

        def get_storage_account(name)
          list_storage_accounts.find { |x| x.name == name }
        end

        def build(model, data={})
          data.each do |k,v|
            model.send "#{k}=", v
          end
        end

        # ARM launch params and profiles
        def generate_os_vhd_uri(vm_context)
          vhd_container = "https://#{vm_context[:storage_account]}.blob.core.windows.net/#{vm_context[:os_disk_vhd_container_name]}"
          "#{vhd_container}/os#{vm_context[:os_disk_vhd_name]}.vhd"
        end

        # image reference format for ARM images canonical:ubuntuserver:14.04.2-LTS:latest
        def get_image_reference(vm_context)
          ref = ::Azure::ARM::Compute::Models::ImageReference.new
          ref.publisher, ref.offer, ref.sku, ref.version = vm_context.image.split(':')
          ref
        end

        def build_storage_account_create_parameters(vm_context)
          build ::Azure::ARM::Storage::Models::StorageAccountPropertiesCreateParameters.new, {
            properties: (build ::Azure::ARM::Storage::Models::StorageAccountCreateParameters.new, {
              location: vm_context[:location],
              name: vm_context[:storage_account],
            }),
            account_type: vm_context[:storage_account_type],
          }
        end

        def create_storage_account(vm_context)
          params = build_storage_account_create_parameters(vm_context)
          promise = ProviderArm.storage_client.storage_accounts.create(vm_context[:resource_group], vm_context[:storage_account], params)
          result = promise.value!.body
          result.name = vm_context[:storage_account]
          result
        end

        def create_osdisk(vm_context)
          build ::Azure::ARM::Compute::Models::OSDisk.new, {
            caching: vm_context[:os_disk_caching],
            create_option: vm_context[:os_disk_create_option],
            name: vm_context[:os_disk_name],
            vhd: (build ::Azure::ARM::Compute::Models::VirtualHardDisk.new, {
              uri: generate_os_vhd_uri(vm_context),
            }),
          }
        end

        def build_storage_profile(vm_context)
          build ::Azure::ARM::Compute::Models::StorageProfile.new, {
            image_reference: get_image_reference(vm_context),
            os_disk: create_osdisk(vm_context),
          }
        end

        # Network helpers
        def build_public_ip_params(vm_context)
          build ::Azure::ARM::Network::Models::PublicIpAddress.new, {
            location: vm_context[:location],
            properties: (build ::Azure::ARM::Network::Models::PublicIpAddressPropertiesFormat.new, {
              public_ipallocation_method: vm_context[:public_ipallocation_method],
              dns_settings: (build ::Azure::ARM::Network::Models::PublicIpAddressDnsSettings.new, {
                domain_name_label: vm_context[:dns_domain_name],
              }),
            }),
          }
        end

        def create_public_ip_address(vm_context)
          params = build_public_ip_params(vm_context)
          promise = ProviderArm.network_client.public_ip_addresses.create_or_update(vm_context[:resource_group], vm_context[:public_ip_address_name], params)
          promise.value!.body
        end

        def build_virtual_subnet(vm_context)
          build ::Azure::ARM::Network::Models::Subnet.new, {
            name: vm_context[:subnet_name],
            properties: (build ::Azure::ARM::Network::Models::SubnetPropertiesFormat.new, {
              address_prefix: vm_context[:subnet_address_prefix],
            }),
          }
        end

        def build_dhcp_options(vm_context)
          build ::Azure::ARM::Network::Models::DhcpOptions.new, {
            dns_servers: vm_context[:dns_servers].split,
          }
        end

        def build_address_space(vm_context)
          build ::Azure::ARM::Network::Models::AddressSpace.new, {
            address_prefixes: [vm_context[:virtual_network_address_space]],
          }
        end

        def build_network_properties(vm_context)
          build ::Azure::ARM::Network::Models::VirtualNetworkPropertiesFormat.new, {
            address_space: build_address_space(vm_context),
            dhcp_options: build_dhcp_options(vm_context),
            subnets: [build_virtual_subnet(vm_context)],
          }
        end

        def build_virtual_network(vm_context)
          build ::Azure::ARM::Network::Models::VirtualNetwork.new, {
            location: vm_context[:location],
            properties: build_network_properties(vm_context),
          }
        end

        def create_virtual_network(vm_context)
          promise = ProviderArm.network_client.virtual_networks.create_or_update(vm_context[:resource_group],
            vm_context[:virtual_network_name], build_virtual_network(vm_context))
          promise.value!.body
        end

        def build_subnet_params(vm_context)
          build ::Azure::ARM::Network::Models::Subnet.new, {
            properties: (build ::Azure::ARM::Network::Models::SubnetPropertiesFormat.new, {
              address_prefix: vm_context[:subnet_address_prefix],
            }),
          }
        end

        def create_subnet(virtual_network, vm_context)
          params = build_subnet_params(vm_context)
          promise = ProviderArm.network_client.subnets.create_or_update(vm_context[:resource_group],
            virtual_network.name, vm_context[:subnet_name], params)
          promise.value!.body
        end

        def create_network_interface(vm_context, created_subnet)
          params = build_network_interface_param(vm_context, created_subnet)
          promise = ProviderArm.network_client.network_interfaces.create_or_update(vm_context[:resource_group], params.name, params)
          promise.value!.body
        end

        def build_network_interface_properties(ip_configuration)
          build ::Azure::ARM::Network::Models::NetworkInterfacePropertiesFormat.new, {
            ip_configurations: [ip_configuration],
          }
        end

        def build_ip_configuration(ip_configuration_properties, vm_context)
          build ::Azure::ARM::Network::Models::NetworkInterfaceIpConfiguration.new, {
            properties: ip_configuration_properties,
            name: vm_context[:ip_configuration_name],
          }
        end

        def build_ip_config_properties(vm_context, created_subnet)
          build ::Azure::ARM::Network::Models::NetworkInterfaceIpConfigurationPropertiesFormat.new, {
            private_ipallocation_method: vm_context[:private_ipallocation_method],
            public_ipaddress: create_public_ip_address(vm_context),
            subnet: created_subnet,
          }
        end

        def build_network_interface_param(vm_context, created_subnet)
          ip_configuration = build_ip_configuration(build_ip_config_properties(vm_context, created_subnet), vm_context)

          build ::Azure::ARM::Network::Models::NetworkInterface.new, {
            location: vm_context[:location],
            name: vm_context[:network_interface_name],
            properties: build_network_interface_properties(ip_configuration, vm_context),
          }
        end

        def build_network_profile(vm_context)
          build ::Azure::ARM::Compute::Models::NetworkProfile.new, {
            network_interfaces: [create_network_interface(vm_context), create_subnet(create_virtual_network(vm_context))],
          }
        end

        def build_os_profile(vm_context)
          build ::Azure::ARM::Compute::Models::OSProfile.new, {
            computer_name: vm_context[:name],
            admin_username: vm_context[:user],
            admin_password: vm_context[:password],
          }
        end

        def build_hardware_profile(vm_context)
          build ::Azure::ARM::Compute::Models::HardwareProfile.new, {
            vm_size: vm_context[:size],
          }
        end

        def build_props(vm_context)
          build ::Azure::ARM::Compute::Models::VirtualMachineProperties.new, {
            os_profile: build_os_profile(vm_context),
            hardware_profile: build_hardware_profile(vm_context),
            storage_profile: build_storage_profile(vm_context),
            network_profile: build_network_profile(vm_context),
          }
        end

        def build_params
          build ::Azure::ARM::Compute::Models::VirtualMachine.new, {
            type: 'Microsoft.Compute/virtualMachines',
            properties: build_props(vm_context),
            location: vm_context[:location],
          }
        end

        #
        # Create/Update/Destroy VM
        #

        def create_arm_vm(args)
          register_providers
          create_resource_group(args)
          create_storage_account(args)
          params = build_params(args)

          promise = ProviderArm.compute_client.virtual_machines.create_or_update(args[:resource_group], args[:name], params)
          promise.value!.body
        end

        def delete_vm
          promise = ProviderArm.compute_client.virtual_machines.delete(resource_group, name)
          promise.value!.body
        end

        def stop_vm
          ProviderArm.compute_client.virtual_machines.power_off(resource_group, name)
        end

        def start_vm
          ProviderArm.compute_client.virtual_machines.start(resource_group, name)
        end

        def get_all_vms
          vms = ProviderArm.compute_client.virtual_machines.list_all.value!.body.value
          vms.collect do |vm|
            resource_group = vm.id.split('/')[4].downcase
            ProviderArm.compute_client.virtual_machines.get(resource_group, vm.name, 'instanceView').value!.body
          end
        end

        def get_vm(name)
          get_all_vms.select { |vm| vm.name == name }
        end
      end
    end
  end
end
