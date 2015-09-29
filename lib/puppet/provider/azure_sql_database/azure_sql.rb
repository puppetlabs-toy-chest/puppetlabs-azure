require 'base64'

require 'puppet_x/puppetlabs/azure/prefetch_error'
require 'puppet_x/puppetlabs/azure/provider'

SQL_USER = 'azure_sql_user'


Puppet::Type.type(:azure_sql_database).provide(:azure_sql, :parent => PuppetX::Puppetlabs::Azure::Provider) do
  confine feature: :azure
  confine feature: :azure_hocon
  confine feature: :azure_retries

  mk_resource_methods

  read_only(:name, :location)

  def self.instances
    begin
      list_servers.collect do |server|
        begin
          hash = server_to_hash(server)
          Puppet.debug("Ignoring #{name} due to invalid or incomplete response from Azure") unless hash
          new(hash) if hash
        end
      end.compact
    rescue StandardError => e
      raise PuppetX::Puppetlabs::Azure::PrefetchError.new(self.resource_type.name.to_s, e)
    end
  end

  def self.server_to_hash(machine) # rubocop:disable Metrics/AbcSize
    ## GH:: TO DO
  end

  def exists?
    Puppet.info("Checking if #{name} exists")
    @property_hash[:ensure] and @property_hash[:ensure] != :absent
  end

  def create
    Puppet.info("Creating #{name}")
    create_server(AZURE_SQL_USER, :password, :location)
  end

  def destroy
    Puppet.info("Deleting #{name}")
    delete_server(:name)
    @property_hash[:ensure] = :absent
  end

end
