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

        def self.ensure_from(status)
          case status
          when 'StoppedDeallocated', 'Stopped'
            :stopped
          else
            :running
          end
        end

        def exists?
          Puppet.info("Checking if #{name} exists")
          @property_hash[:ensure] and @property_hash[:ensure] != :absent
        end

        def running?
          !stopped?
        end

        def stopped?
          ['StoppedDeallocated', 'Stopped'].include? machine.status
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
