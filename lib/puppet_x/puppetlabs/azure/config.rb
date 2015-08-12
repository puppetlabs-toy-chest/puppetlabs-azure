module PuppetX
  module Puppetlabs
    module Azure
      class Config
        REQUIRED = {
          names: [:subscription_id, :management_certificate],
          envs: ['AZURE_MANAGEMENT_CERTIFICATE', 'AZURE_SUBSCRIPTION_ID'],
        }

        attr_reader :subscription_id, :management_certificate

        def default_config_file
          Puppet.initialize_settings unless Puppet[:confdir]
          File.join(Puppet[:confdir], 'azure.conf')
        end

        def initialize(config_file=nil)
          settings = process_environment_variables || process_config_file(config_file || default_config_file)
          if settings.nil?
            raise Puppet::Error, 'You must provide credentials in either environment variables or a config file.'
          else
            settings = settings.delete_if { |k, v| v.nil? }
            check_settings(settings)
            @subscription_id = settings[:subscription_id]
            @management_certificate = settings[:management_certificate]
          end
        end

        def check_settings(settings)
          missing = REQUIRED[:names] - settings.keys
          unless missing.empty?
            message = 'To use this module you must provide the following settings:'
            missing.each do |var|
              message += " #{var}"
            end
            raise Puppet::Error, message
          end
        end

        def process_config_file(file_path)
          Puppet.debug("Checking for config file at #{file_path}")
          azure_config = read_config_file(file_path)
          if azure_config
            {
              subscription_id: azure_config['subscription_id'],
              management_certificate: azure_config['management_certificate'],
            }
          end
        end

        def read_config_file(file_path)
          if File.file?(file_path)
            begin
              conf = ::Hocon::ConfigFactory.parse_file(file_path)
              conf.root.unwrapped['azure']
            rescue Hocon::ConfigError::ConfigParseError => e
              raise Puppet::Error, """Your configuration file at #{file_path} is invalid. The error from the parser is
  #{e.message}"""
            end
          end
        end

        def process_environment_variables
          required = REQUIRED[:envs]
          Puppet.debug("Checking for ENV variables: #{required.join(', ')}")
          available = required & ENV.keys
          unless available.empty?
            {
              subscription_id: ENV['AZURE_SUBSCRIPTION_ID'],
              management_certificate: ENV['AZURE_MANAGEMENT_CERTIFICATE'],
            }
          end
        end
      end
    end
  end
end
