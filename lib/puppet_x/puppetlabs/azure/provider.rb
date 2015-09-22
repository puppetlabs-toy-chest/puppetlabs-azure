require 'stringio'

require 'puppet_x/puppetlabs/azure/not_finished'

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

      class Provider < Puppet::Provider
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

        # Workaround https://github.com/Azure/azure-sdk-for-ruby/issues/269
        # This needs to be separate from the rescue above, as this might
        # get fixed on a different schedule.
        begin
          require 'azure/virtual_machine_image_management/virtual_machine_image_management_service'
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

        def self.vm_manager
          ::Azure.vm_management
        end

        def self.cloud_service_manager
          ::Azure.cloud_service_management
        end

        def self.disk_manager
          ::Azure.vm_disk_management
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
                       :rescue => [NotFinished, ::Azure::Core::Error]) do
            Puppet.debug("Trying to deleting disk #{disk_name}")
            begin
              Provider.disk_manager.delete_virtual_machine_disk(disk_name)
              if Provider.disk_manager.get_virtual_machine_disk(disk_name)
                Puppet.debug("Disk was not deleted. Retrying to deleting disk #{disk_name}")
                raise NotFinished.new
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
