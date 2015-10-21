require 'stringio'
require 'puppet_x/puppetlabs/azure/config'
require 'puppet_x/puppetlabs/azure/not_finished'

require 'azure_mgmt_compute'
require 'azure_mgmt_resources'
require 'azure_mgmt_storage'
require 'azure_mgmt_network'
require 'ms_rest_azure'

include MsRest
include MsRestAzure
include Azure::ARM::Resources
include Azure::ARM::Compute
include Azure::ARM::Compute::Models
include Azure::ARM::Storage
include Azure::ARM::Network
include Azure::ARM::Network::Models

require 'pry'

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
      end
    end
  end
end
