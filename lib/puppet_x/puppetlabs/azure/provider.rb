require 'stringio'

module PuppetX
  module Puppetlabs
    module Azure
      class Provider < Puppet::Provider
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

        def self.list_vms
          manager.list_virtual_machines
        end

        def create_vm(args)
          param_names = [:vm_name, :image, :location, :vm_user, :password]
          params = (args.keys & param_names).each_with_object({}) { |k,h| h.update(k=>args.delete(k)) }
          capture_stdout do
            manager.create_virtual_machine(params, args)
          end
        end

        def delete_vm(machine)
          capture_stdout do
            manager.delete_virtual_machine(machine.vm_name, machine.cloud_service_name)
          end
        end

        private
          def vm_manager
            self.class.vm_manager
          end

          # the Azure Ruby SDK has a logger module which puts all over the place
          # The following prevents that output being displayed in the Puppet log
          # unless you are running in debug mode
          def capture_stdout
            real_stdout = $stdout
            $stdout = StringIO.new unless Puppet[:debug]
            yield
            $stdout.string unless Puppet[:debug]
          ensure
            $stdout = real_stdout
          end

      end
    end
  end
end
