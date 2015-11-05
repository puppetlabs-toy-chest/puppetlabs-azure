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

        def create_storage_account(args)
          params = build_storage_account_create_parameters(args)
          promise = ProviderArm.storage_client.storage_accounts.create(args[:resource_group], args[:storage_account], params)
          result = promise.value!.body
          result.name = args[:storage_account]
          result
        end

        def create_virtual_network(args)
          params = build_virtual_network_params(args)
          promise = ProviderArm.network_client.virtual_networks.create_or_update(args[:resource_group], args[:virtual_network_name], params)
          promise.value!.body
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

        def create_network_interface(args, subnet)
          params = build_network_interface_param(args, subnet)
          ProviderArm.network_client.network_interfaces.create_or_update(args[:resource_group], params.name, params).value!.body
        end

        def build_os_vhd_uri(args)
          container = "https://#{args[:storage_account]}.blob.core.windows.net/#{args[:os_disk_vhd_container_name]}"
          "#{container}/#{args[:os_disk_vhd_name]}.vhd"
        end

        def build_image_reference(args)
          build(::Azure::ARM::Compute::Models::ImageReference, {
            publisher: args[:image].split(':')[0],
            offer: args[:image].split(':')[1],
            sku: args[:image].split(':')[2],
            version: args[:image].split(':')[3],
          })
        end

        def build_storage_account_create_parameters(args)
          build(::Azure::ARM::Storage::Models::StorageAccountCreateParameters, {
            location: args[:location],
            name: args[:storage_account],
            properties: build(::Azure::ARM::Storage::Models::StorageAccountPropertiesCreateParameters, {
              account_type: args[:storage_account_type],
            })
          })
        end

        def build_storage_profile(args)
          build(::Azure::ARM::Compute::Models::StorageProfile, {
            image_reference: build_image_reference(args),
            os_disk: build(::Azure::ARM::Compute::Models::OSDisk, {
              caching: args[:os_disk_caching],
              create_option: args[:os_disk_create_option],
              name: args[:os_disk_name],
              vhd: build(::Azure::ARM::Compute::Models::VirtualHardDisk, {
                uri: build_os_vhd_uri(args),
              })
            })
          })
        end

        def build_public_ip_params(args)
          build(::Azure::ARM::Network::Models::PublicIpAddress, {
            location: args[:location],
            properties: build(::Azure::ARM::Network::Models::PublicIpAddressPropertiesFormat, {
              public_ipallocation_method: args[:public_ip_allocation_method],
              dns_settings: build(::Azure::ARM::Network::Models::PublicIpAddressDnsSettings, {
                domain_name_label: args[:dns_domain_name],
              })
            })
          })
        end

        def build_virtual_network_params(args)
          build(::Azure::ARM::Network::Models::VirtualNetwork, {
            location: args[:location],
            properties: build(::Azure::ARM::Network::Models::VirtualNetworkPropertiesFormat, {
              address_space: build(::Azure::ARM::Network::Models::AddressSpace, {
                address_prefixes: [args[:virtual_network_address_space]],
              }),
              dhcp_options: build(::Azure::ARM::Network::Models::DhcpOptions, {
                dns_servers: args[:dns_servers].split,
              }),
              subnets: [build(::Azure::ARM::Network::Models::Subnet, {
                name: args[:subnet_name],
                properties: build(::Azure::ARM::Network::Models::SubnetPropertiesFormat, {
                  address_prefix: args[:subnet_address_prefix],
                })
              })]
            })
          })
        end

        def build_subnet_params(args)
          build(::Azure::ARM::Network::Models::Subnet, {
            properties: build(::Azure::ARM::Network::Models::SubnetPropertiesFormat, {
              address_prefix: args[:subnet_address_prefix],
            })
          })
        end

        def build_network_interface_param(args, subnet)
          build(::Azure::ARM::Network::Models::NetworkInterface, {
            location: args[:location],
            name: args[:network_interface_name],
            properties: build(::Azure::ARM::Network::Models::NetworkInterfacePropertiesFormat, {
              ip_configurations: [build(::Azure::ARM::Network::Models::NetworkInterfaceIpConfiguration, {
                name: args[:ip_configuration_name],
                properties: build(::Azure::ARM::Network::Models::NetworkInterfaceIpConfigurationPropertiesFormat, {
                  private_ipallocation_method: 'Dynamic',
                  public_ipaddress: create_public_ip_address(args),
                  subnet: subnet,
                }),
              })],
            })
          })
        end

        def build_network_profile(args)
          build(::Azure::ARM::Compute::Models::NetworkProfile, {
            network_interfaces: [
              create_network_interface(
                args,
                create_subnet(create_virtual_network(args), args)
              )
            ]
          })
        end

        def build_props(args)
          build(::Azure::ARM::Compute::Models::VirtualMachineProperties, {
            os_profile: build(::Azure::ARM::Compute::Models::OSProfile, {
              computer_name: args[:name],
              admin_username: args[:user],
              admin_password: args[:password],
              secrets: [],
            }),
            hardware_profile: build(::Azure::ARM::Compute::Models::HardwareProfile, {
              vm_size: args[:size],
            }),
            storage_profile: build_storage_profile(args),
            network_profile: build_network_profile(args),
          })
        end

        def build_params(args)
          build(::Azure::ARM::Compute::Models::VirtualMachine, {
            type: 'Microsoft.Compute/virtualMachines',
            properties: build_props(args),
            location: args[:location],
          })
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
