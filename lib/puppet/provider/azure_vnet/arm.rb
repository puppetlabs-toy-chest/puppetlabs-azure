require 'puppet_x/puppetlabs/azure/prefetch_error'
require 'puppet_x/puppetlabs/azure/provider_arm'

Puppet::Type.type(:azure_vnet).provide(:arm, :parent => PuppetX::Puppetlabs::Azure::ProviderArm) do
  confine feature: :azure
  confine feature: :azure_hocon
  confine feature: :azure_retries

  mk_resource_methods

  read_only(:location, :resource_group, :etag, :subnets)

  def self.instances
    begin
      PuppetX::Puppetlabs::Azure::ProviderArm.new.get_all_vnets.collect do |vnet|
        hash = vnet_to_hash(vnet)
        Puppet.debug("Ignoring #{name} due to invalid or incomplete response from Azure") unless hash
        new(hash) if hash
      end.compact
    rescue Timeout::Error, StandardError => e
      raise PuppetX::Puppetlabs::Azure::PrefetchError.new(self.resource_type.name.to_s, e)
    end
  end

  # Allow differing case
  def self.prefetch(resources)
    instances.each do |prov|
      if resource = (resources.find { |k,v| k.casecmp(prov.name).zero? } || [])[1] # rubocop:disable Lint/AssignmentInCondition
        resource.provider = prov
      end
    end
  end

  def self.vnet_to_hash(vnet) # rubocop:disable Metrics/AbcSize
    subnets = []
    vnet.subnets.each do |subnet|
      subnets << {
        'name' => subnet.name,
        'address_prefix' => subnet.address_prefix,
      }
    end

    {
      ensure: :present,
      id: vnet.id,
      name: vnet.name,
      etag: vnet.etag,
      resource_group: vnet.id.split('/')[4].downcase,
      location: vnet.location,
      address_prefixes: vnet.address_space.address_prefixes,
      dns_servers: vnet.dhcp_options.nil? ? nil : vnet.dhcp_options.dns_servers,
      subnets: subnets,
      object: vnet,
    }
  end

  def create
    Puppet.info("Creating virtual network #{resource[:name]}")
    create_virtual_network(create_hash)
    @property_hash[:ensure] = :present
  end

  def create_hash
    {
      name: resource[:name],
      resource_group: resource[:resource_group],
      location: resource[:location],
      address_prefixes: resource[:address_prefixes],
      dns_servers: resource[:dns_servers],
    }
  end

  def flush
    if @property_hash[:ensure] != :absent
      Puppet.info("Updating virtual network #{resource[:name]}")
      create_virtual_network(create_hash)
    end
  end

  def address_prefixes=(value)
    Puppet.debug("Updating address prefixes to be #{value.join(', ')} on vnet #{resource[:name]}")
    @property_hash[:address_prefixes] = value
  end

  def dns_servers=(value)
    Puppet.debug("Updating dns servers to be #{value.join(', ')} on vnet #{resource[:name]}")
    @property_hash[:dns_servers] = value
  end

  def destroy
    Puppet.info("Deleting virtual network #{name}")
    delete_virtual_network(resource[:resource_group], resource[:name])
    @property_hash[:ensure] = :absent
  end
end
