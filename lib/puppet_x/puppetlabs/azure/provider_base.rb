require 'stringio'
require 'puppet_x/puppetlabs/azure/config'
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

      class ProviderBase < Puppet::Provider
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

        def self.prefetch(resources)
          instances.each do |prov|
            if resource = resources[prov.name] # rubocop:disable Lint/AssignmentInCondition
              resource.provider = prov
            end
          end
        end

        def exists?
          Puppet.info("Checking if #{name} exists")
          @property_hash[:ensure] and @property_hash[:ensure] != :absent
        end

        def running?
          !stopped?
        end

        def stop
          Puppet.info("Stopping #{name}")
          stop_vm(machine)
          @property_hash[:ensure] = :stopped
        end

        def start
          Puppet.info("Starting #{name}")
          start_vm(machine)
          @property_hash[:ensure] = :running
        end

        private
        def machine
          vm = if @property_hash[:object]
                 @property_hash[:object]
               else
                 Puppet.debug("Looking up #{name}")
                 get_vm(name)
               end
          raise Puppet::Error, "No virtual machine called #{name}" unless vm
          vm
        end
      end
    end
  end
end
