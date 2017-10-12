require 'stringio'
require 'puppet_x/puppetlabs/azure/config'
require 'puppet_x/puppetlabs/azure/not_finished'
require 'puppet_x/puppetlabs/azure/provider_base'

require 'azure_mgmt_compute' if Puppet.features.azure?
require 'azure_mgmt_resources' if Puppet.features.azure?
require 'azure_mgmt_storage' if Puppet.features.azure?
require 'azure_mgmt_network' if Puppet.features.azure?
require 'ms_rest_azure' if Puppet.features.azure?

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
        # Class Methods
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
          @network_client ||= ProviderArm.with_subscription_id ::Azure::ARM::Network::NetworkManagementClient.new(ProviderArm.credentials)
        end

        def self.storage_client
         @storage_client ||= ProviderArm.with_subscription_id ::Azure::ARM::Storage::StorageManagementClient.new(ProviderArm.credentials)
        end

        def self.resource_client
          @resource_client ||= ProviderArm.with_subscription_id ::Azure::ARM::Resources::ResourceManagementClient.new(ProviderArm.credentials)
        end

        # Public instance methods
        def create_vm(args) # rubocop:disable Metrics/AbcSize
          begin
            register_providers
            create_resource_group(args)
            params = build_params(args)

            if ! args[:managed_disks]
              # ensure the storage account is set up
              get_or_create_storage_account({
                name: args[:storage_account],
                resource_group: args[:resource_group],
                sku_name: args[:storage_account_type],
                location: args[:location],
                tags: args[:tags],
              })
            end
            ProviderArm.compute_client.virtual_machines.create_or_update(args[:resource_group], args[:name], params)
          rescue MsRest::DeserializationError => err
            raise Puppet::Error, err.response_body
          rescue MsRest::RestError => err
            raise Puppet::Error, err.to_s
          end
        end

        def update_vm_storage_profile(args)
          # never appears to be called, changing data_disks parameter after VM
          # creation has no effect
          params = build(::Azure::ARM::Compute::Models::VirtualMachine, {
            type: 'Microsoft.Compute/virtualMachines',
            location: args[:location],
            storage_profile: build(::Azure::ARM::Compute::Models::StorageProfile, {
              data_disks: build_data_disks(args),
            })
          })
          ProviderArm.compute_client.virtual_machines.create_or_update(args[:resource_group], args[:vm_name], params)
        rescue MsRest::DeserializationError => err
          raise Puppet::Error, err.response_body
        rescue MsRest::RestError => err
          raise Puppet::Error, err.to_s
        end

        def delete_vm(machine)
          begin
            ProviderArm.compute_client.virtual_machines.delete(resource_group, machine.name)
          rescue MsRest::DeserializationError => err
            raise Puppet::Error, err.response_body
          rescue MsRest::RestError => err
            raise Puppet::Error, err.to_s
          end
        end

        def stop_vm(machine)
          begin
            ProviderArm.compute_client.virtual_machines.power_off(resource_group, machine.name)
          rescue MsRest::DeserializationError => err
            raise Puppet::Error, err.response_body
          rescue MsRest::RestError => err
            raise Puppet::Error, err.to_s
          end
        end

        def start_vm(machine)
          begin
            ProviderArm.compute_client.virtual_machines.start(resource_group, machine.name)
          rescue MsRest::DeserializationError => err
            raise Puppet::Error, err.response_body
          rescue MsRest::RestError => err
            raise Puppet::Error, err.to_s
          end
        end

        def get_all_sas # rubocop:disable Metrics/AbcSize
          begin
            sas = ProviderArm.storage_client.storage_accounts.list.value
            sas.collect do |sa|
              ProviderArm.storage_client.storage_accounts.get_properties(resource_group_from(sa), sa.name)
            end
          rescue MsRestAzure::AzureOperationError => err
            raise Puppet::Error, JSON.parse(err.message)['message']
          rescue MsRest::DeserializationError => err
            raise Puppet::Error, err.response_body
          rescue MsRest::RestError => err
            raise Puppet::Error, err.to_s
          end
        end

        def get_all_deployments
          deployments = []
          rgs = get_all_rgs.collect(&:name)
          rgs.each do |rg|
            any_deps = get_deployments(rg)
            deployments += any_deps if any_deps
          end
          deployments
        end

        def get_deployments(resource_group)
          begin
            ProviderArm.resource_client.deployments.list_by_resource_group(resource_group)
          rescue MsRest::DeserializationError => err
            raise Puppet::Error, err.response_body
          rescue MsRest::RestError => err
            raise Puppet::Error, err.to_s
          end
        end

        def get_all_rgs
          begin
            ProviderArm.resource_client.resource_groups.list
          rescue MsRest::DeserializationError => err
            raise Puppet::Error, err.response_body
          rescue MsRest::RestError => err
            raise Puppet::Error, err.to_s
          end
        end

        def get_all_vms # rubocop:disable Metrics/AbcSize
          begin
            vms = []
            result = ProviderArm.compute_client.virtual_machines.list_all_as_lazy
            vms += result.value

            while ! result.next_link.nil? and ! result.next_link.empty? do
              result = ProviderArm.compute_client.virtual_machines.list_all_next(result.next_link)
              vms += result.value
            end
            vms.collect do |vm|
              ProviderArm.compute_client.virtual_machines.get(resource_group_from(vm), vm.name, 'instanceView')
            end
          rescue MsRest::DeserializationError => err
            raise Puppet::Error, err.response_body
          rescue MsRest::RestError => err
            raise Puppet::Error, err.to_s
          end
        end

        def resource_group_from(machine)
          machine.id.split('/')[4].downcase
        end

        # support for slash delimted resource names, eg:
        #   virtual networks: myrg/myvn
        #   subnets: myrg/myvn/mysn
        # when name parameter is slash delimited, split it and use directly.  in
        # all other cases, append the original name to the array of defaults
        # passed in - this will give you a name in the 'default' resource group
        # which is the one the azure_vm was created in
        def expand_name(defaults, name)
          name_split = name.split('/')
          expanded =
            if name_split.size > 1
              name_split
            else
              defaults.concat([name])
            end

          expanded
        end

        def get_vm(name)
          get_all_vms.find { |vm| vm.name == name }
        end

        # Private Methods
        private

        def register_providers
          register_azure_provider('Microsoft.Storage')
          register_azure_provider('Microsoft.Network')
          register_azure_provider('Microsoft.Compute')
        end

        def register_azure_provider(name)
          ProviderArm.resource_client.providers.register(name)
        end

        def create_resource_template(args) # rubocop:disable Metrics/AbcSize
          params = build_template_deployment(args)
          Puppet.debug("Validating template deployment and parameters")
          validation = ProviderArm.resource_client.deployments.validate(args[:resource_group], args[:template_deployment_name], params)
          if validation.error
            message = [validation.error.message]
            if validation.error.details
              deets = validation.error.details.collect(&:message)
              message << "Further information:"
              message += deets
            end
            fail message
          else
            ProviderArm.resource_client.deployments.create_or_update(args[:resource_group], args[:template_deployment_name], params)
          end
        end

        def delete_resource_template(rg, name)
          begin
            ProviderArm.resource_client.deployments.delete(rg, name)
          rescue MsRest::DeserializationError => err
            raise Puppet::Error, err.response_body
          rescue MsRest::RestError => err
            raise Puppet::Error, err.to_s
          end
        end

        def create_resource_group(args)
          params = ::Azure::ARM::Resources::Models::ResourceGroup.new
          params.location = args[:location]
          ProviderArm.resource_client.resource_groups.create_or_update(args[:resource_group], params)
        end

        def delete_resource_group(rg)
          begin
            ProviderArm.resource_client.resource_groups.delete(rg.name)
          rescue MsRest::DeserializationError => err
            raise Puppet::Error, err.response_body
          rescue MsRest::RestError => err
            raise Puppet::Error, err.to_s
          end
        end

        def get_or_create_storage_account(args) # rubocop:disable Metrics/AbcSize
          # ensure the storage account exists
          begin
            get_storage_account({
              name: args[:name],
              resource_group: args[:resource_group],
            })
          rescue MsRestAzure::AzureOperationError
            create_storage_account({
              name: args[:name],
              resource_group: args[:resource_group],
              sku_name: args[:sku_name],
              location: args[:location],
            })
          rescue MsRestAzure::AzureOperationError => err
            raise Puppet::Error, JSON.parse(err.message)['message']
          rescue MsRest::DeserializationError => err
            raise Puppet::Error, err.response_body
          rescue MsRest::RestError => err
            raise Puppet::Error, err.to_s
          end
        end

        def get_storage_account(args)
          ProviderArm.storage_client.storage_accounts.get_properties(args[:resource_group], args[:name])
        end

        def create_storage_account(args)
          params = build_storage_account_create_parameters(args)
          begin
            ProviderArm.storage_client.storage_accounts.create(args[:resource_group], args[:name], params)
          rescue MsRestAzure::AzureOperationError => err
            raise Puppet::Error, JSON.parse(err.message)['message']
          rescue MsRest::DeserializationError => err
            raise Puppet::Error, err.response_body
          rescue MsRest::RestError => err
            raise Puppet::Error, err.to_s
          end
        end

        def delete_storage_account(args)
          begin
            ProviderArm.storage_client.storage_accounts.delete(args[:resource_group], args[:name])
          rescue MsRestAzure::AzureOperationError => err
            raise Puppet::Error, JSON.parse(err.message)['message']
          rescue MsRest::DeserializationError => err
            raise Puppet::Error, err.response_body
          rescue MsRest::RestError => err
            raise Puppet::Error, err.to_s
          end
        end

        def create_extension(args)
          params = build_virtual_machine_extensions(args)
          ProviderArm.compute_client.virtual_machine_extensions.create_or_update(args[:resource_group], args[:vm_name], args[:name], params)
        end

        def delete_extension(sa)
          begin
            ProviderArm.storage_client.storage_accounts.delete(resource_group, sa.name)
          rescue MsRest::HttpOperationError => err
            raise Puppet::Error, err.body
          rescue MsRest::DeserializationError => err
            raise Puppet::Error, err.response_body
          rescue MsRest::RestError => err
            raise Puppet::Error, err.to_s
          end
        end

        def retrieve_virtual_network(args)
          begin
            ProviderArm.network_client.virtual_networks.get(
              *expand_name([args[:resource_group]], args[:virtual_network_name]),
            )
          rescue MsRestAzure::AzureOperationError
            create_virtual_network(args)
          end
        end

        def create_virtual_network(args)
          Puppet.debug("Creating vnet '#{args[:virtual_network_name]}'")
          params = build_virtual_network_params(args)
          ProviderArm.network_client.virtual_networks.create_or_update(args[:resource_group], args[:virtual_network_name], params)
        end

        def create_public_ip_address(args)
          params = build_public_ip_params(args)
          ProviderArm.network_client.public_ipaddresses.create_or_update(args[:resource_group], args[:public_ip_address_name], params)
        end

        def get_network_interface(resource_group, network_interface_name)
          ProviderArm.network_client.network_interfaces.get(resource_group, network_interface_name)
        end

        def get_public_ip_address(resource_group, public_ip_address_name)
          ProviderArm.network_client.public_ipaddresses.get(resource_group, public_ip_address_name)
        end

        def retrieve_subnet(virtual_network, args)
          begin
            ProviderArm.network_client.subnets.get(
              *expand_name([args[:resource_group], args[:virtual_network_name]], args[:subnet_name]),
            )
          rescue MsRestAzure::AzureOperationError
            create_subnet(virtual_network, args)
          end
        end

        def create_subnet(virtual_network, args)
          Puppet.debug("Creating subnet '#{args[:subnet_name]}' on vnet '#{virtual_network.name}'")
          params = build_subnet_params(args)
          ProviderArm.network_client.subnets.create_or_update(
            args[:resource_group],
            virtual_network.name,
            args[:subnet_name],
            params
          )
        end

        def retrieve_network_security_group(args)
          begin
            ProviderArm.network_client.network_security_groups.get(
              *expand_name([args[:resource_group]], args[:network_security_group_name])
            )
          rescue MsRestAzure::AzureOperationError
            create_network_security_group(args)
          end
        end

        def create_network_security_group(args)
          Puppet.debug("Creating network security group '#{args[:network_security_group_name]}'")
          params = build_network_security_group_params(args)
          ProviderArm.network_client.network_security_groups.create_or_update(
            args[:resource_group],
            args[:network_security_group_name],
            params
          )
        end


        def create_network_interface(args, subnet)
          params = build_network_interface_param(args, subnet)
          ProviderArm.network_client.network_interfaces.create_or_update(args[:resource_group], params.name, params)
        end

        def build(klass, data={})
          model = klass.new
          data.each do |k,v|
            model.send "#{k}=", v
          end
          model
        end

        def build_os_vhd_uri(args)
          container = "https://#{args[:storage_account]}.blob.core.windows.net/#{args[:os_disk_vhd_container_name]}"
          "#{container}/#{args[:os_disk_vhd_name]}.vhd"
        end

        def build_image_reference(args) # rubocop:disable Metrics/AbcSize
          if ! args[:plan]
            publisher, offer, sku, version = args[:image].split(':')
          else
            publisher = args[:plan]['publisher']
            offer = args[:plan]['product']
            sku = args[:plan]['name']
            version = args[:plan]['version'] || 'latest'
          end
          build(::Azure::ARM::Compute::Models::ImageReference, {
            publisher: publisher,
            offer: offer,
            sku: sku,
            version: version,
          })
        end

        def build_template_deployment(args)
          build(::Azure::ARM::Resources::Models::Deployment, {
            properties: build_template_deployment_properties(args),
          })
        end

        def build_template_deployment_properties(args)
          if args[:source]
            templateLink = build(::Azure::ARM::Resources::Models::TemplateLink, {
                uri: args[:source],
            })
          end

          # seems to be the last *properties named class still in use - keep an
          # eye on this one it might be deleted upstream eventually
          build(::Azure::ARM::Resources::Models::DeploymentProperties, {
            template: args[:content],
            template_link: templateLink,
            parameters: args[:params],
            mode: 'Incremental', #design decision
          })
        end

        def build_storage_account_create_parameters(args)
          buildparams = {
            location: args[:location],
            tags: args[:tags],
            kind: Object.const_get("::Azure::ARM::Storage::Models::Kind::#{args[:account_kind] || :Storage}"),
            sku: build(::Azure::ARM::Storage::Models::Sku, {
              name: args[:sku_name],
            })
          }
          if args[:account_kind] == :BlobStorage
            buildparams[:access_tier] = Object.const_get("::Azure::ARM::Storage::Models::AccessTier::#{args[:access_tier] || :Hot}")
          end
          build(::Azure::ARM::Storage::Models::StorageAccountCreateParameters, buildparams)
        end

        def build_virtual_machine_extensions(args) # rubocop:disable Metrics/AbcSize
          props =
            if args[:properties].is_a?(Hash)
              {
                force_update_tag: args[:properties]['force_update_tag'],
                publisher: args[:properties]['publisher'],
                virtual_machine_extension_type: args[:properties]['type'],
                type_handler_version: args[:properties]['type_handler_version'],
                auto_upgrade_minor_version: args[:properties]['auto_upgrade_minor_version'],
                settings: args[:properties]['settings'],
                protected_settings: args[:properties]['protected_settings'],
              }
            else
              {}
            end
          build(::Azure::ARM::Compute::Models::VirtualMachineExtension, {
            location: args[:location],
            name: args[:name],
            **props
          })
        end

        def build_storage_profile(args) # rubocop:disable Metrics/AbcSize
          begin
            os_disk =
              if args[:managed_disks]
                build(::Azure::ARM::Compute::Models::OSDisk, {
                  create_option: 'FromImage',
                  managed_disk: build(::Azure::ARM::Compute::Models::ManagedDiskParameters, {
                    storage_account_type: args[:storage_account_type],
                  }),
                })
              else
                build(::Azure::ARM::Compute::Models::OSDisk, {
                  caching: args[:os_disk_caching],
                  create_option: args[:os_disk_create_option],
                  name: args[:os_disk_name],
                  vhd: build(::Azure::ARM::Compute::Models::VirtualHardDisk, {
                    uri: build_os_vhd_uri(args),
                  }),
                })
              end

            build(::Azure::ARM::Compute::Models::StorageProfile, {
              image_reference: build_image_reference(args),
              os_disk: os_disk,
              data_disks: build_data_disks(args),
            })
          rescue MsRestAzure::AzureOperationError => err
            raise Puppet::Error, JSON.parse(err.message)['message']
          rescue MsRest::DeserializationError => err
            raise Puppet::Error, err.response_body
          rescue MsRest::RestError => err
            raise Puppet::Error, err.to_s
          end
        end

        def build_data_disks(args)
          args[:data_disks].collect do |name,props|
            buildprops = {
              lun: props['lun'],
              name: name,
              disk_size_gb: props['disk_size_gb'],
              create_option: Object.const_get("::Azure::ARM::Compute::Models::DiskCreateOptionTypes::#{props['create_option']}"),
              vhd: build(::Azure::ARM::Compute::Models::VirtualHardDisk, {
                uri: props['vhd'],
              }),
            }
            if props['caching']
              buildprops[:caching] = Object.const_get("::Azure::ARM::Compute::Models::CachingTypes::#{props['caching']}")
            end
            build(::Azure::ARM::Compute::Models::DataDisk, buildprops)
          end unless args[:data_disks].nil?
        end

        def build_public_ip_params(args)
          build(::Azure::ARM::Network::Models::PublicIPAddress, {
            location: args[:location],
            public_ipallocation_method: args[:public_ip_allocation_method],
            dns_settings: build(::Azure::ARM::Network::Models::PublicIPAddressDnsSettings, {
              domain_name_label: args[:dns_domain_name],
            }),
            tags: args[:tags],
          })
        end

        def build_virtual_network_params(args)
          build(::Azure::ARM::Network::Models::VirtualNetwork, {
            location: args[:location],
            address_space: build(::Azure::ARM::Network::Models::AddressSpace, {
              address_prefixes: args[:virtual_network_address_space],
            }),
            dhcp_options: build(::Azure::ARM::Network::Models::DhcpOptions, {
              dns_servers: args[:dns_servers].split,
            }),
            #XXX This should handle arrays
            subnets: [build(::Azure::ARM::Network::Models::Subnet, {
              name: args[:subnet_name],
              address_prefix: args[:subnet_address_prefix],
            })]
          })
        end

        def build_subnet_params(args)
          build(::Azure::ARM::Network::Models::Subnet, {
            address_prefix: args[:subnet_address_prefix],
          })
        end

        # Just create a 'blank' group for the moment.  There is scope
        # to setup the whole security group here though
        def build_network_security_group_params(args)
          build(::Azure::ARM::Network::Models::NetworkSecurityGroup, {
            location: args[:location],
            tags: args[:tags],
          })
        end

        def build_network_interface_param(args, subnet)
          public_ipaddress = unless args[:public_ip_allocation_method] == 'None'
            create_public_ip_address(args)
          end

          network_security_group = unless args[:network_security_group_name] == 'None'
            retrieve_network_security_group(args)
          end

          build(::Azure::ARM::Network::Models::NetworkInterface, {
            location: args[:location],
            name: args[:network_interface_name],
            ip_configurations: [build(::Azure::ARM::Network::Models::NetworkInterfaceIPConfiguration, {
              name: args[:ip_configuration_name],
              private_ipallocation_method: args[:private_ip_allocation_method],
              subnet: subnet,
              public_ipaddress: public_ipaddress,
            })],
            network_security_group: network_security_group,
            tags: args[:tags],
          })
        end

        def build_network_profile(args)
          build(::Azure::ARM::Compute::Models::NetworkProfile, {
            #XXX This should handle multiple network interfaces
            network_interfaces: [
              create_network_interface(
                args,
                retrieve_subnet(retrieve_virtual_network(args), args),
              )
            ]
          })
        end

        def build_plan(args)
          if args[:plan]
            build(::Azure::ARM::Compute::Models::Plan, {
              name: args[:plan]['name'],
              publisher: args[:plan]['publisher'],
              product: args[:plan]['product'],
              promotion_code: args[:plan]['promotion_code'],
            })
          end
        end

        def build_props(args)
          build(::Azure::ARM::Compute::Models::VirtualMachine, {
            os_profile: build(::Azure::ARM::Compute::Models::OSProfile, {
              computer_name: args[:name],
              admin_username: args[:user],
              admin_password: args[:password],
              custom_data: args[:custom_data],
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
          properties = build_props(args)

          build(::Azure::ARM::Compute::Models::VirtualMachine, {
            type: 'Microsoft.Compute/virtualMachines',
            os_profile: properties.os_profile,
            hardware_profile: properties.hardware_profile,
            storage_profile: properties.storage_profile,
            network_profile: properties.network_profile,
            plan: build_plan(args),
            location: args[:location],
            tags: args[:tags],
          })
        end
      end
    end
  end
end
