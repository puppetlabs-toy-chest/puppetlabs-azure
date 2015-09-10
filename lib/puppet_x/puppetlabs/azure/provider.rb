require 'stringio'

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
        # re-route azure's messages to puppet
        ::Azure::Core::Logger.initialize_external_logger(LoggerAdapter.new)

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

        def create_vm(args)
          param_names = [:vm_name, :image, :location, :vm_user, :password]
          params = (args.keys & param_names).each_with_object({}) { |k,h| h.update(k=>args.delete(k)) }
          sanitised_params = params.delete_if { |k, v| v.nil? }
          sanitised_args = args.delete_if { |k, v| v.nil? }
          Provider.vm_manager.create_virtual_machine(sanitised_params, sanitised_args)
        end

        def delete_vm(machine)
          Provider.vm_manager.delete_virtual_machine(machine.vm_name, machine.cloud_service_name)
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
