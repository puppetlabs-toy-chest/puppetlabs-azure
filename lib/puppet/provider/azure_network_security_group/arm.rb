require 'puppet_x/puppetlabs/azure/prefetch_error'
require 'puppet_x/puppetlabs/azure/provider_arm'

Puppet::Type.type(:azure_network_security_group).provide(:arm, :parent => PuppetX::Puppetlabs::Azure::ProviderArm) do
  confine feature: :azure
  confine feature: :azure_hocon
  confine feature: :azure_retries

  mk_resource_methods

  read_only(:location, :resource_group, :etag, :default_security_rules, :security_rules, :network_interfaces, :subnets, :tags)

  def self.instances
    begin
      PuppetX::Puppetlabs::Azure::ProviderArm.new.get_all_network_security_groups.collect do |nsg|
        hash = nsg_to_hash(nsg)
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

  def self.nsg_to_hash(nsg)
    {
      ensure: :present,
      id: nsg.id,
      name: nsg.name,
      resource_group: nsg.id.split('/')[4].downcase,
      guid: nsg.resource_guid,
      location: nsg.location,
      default_security_rules: nsg.default_security_rules,
      security_rules: nsg.security_rules,
      network_interfaces: nsg.network_interfaces,
      subnets: nsg.subnets,
      tags: nsg.tags,
      object: nsg,
    }
  end

  def create
    Puppet.info("Creating network security group #{resource[:name]}")
    create_network_security_group(create_hash)
    @property_hash[:ensure] = :present
  end

  def create_hash
    {
      name: resource[:name],
      resource_group: resource[:resource_group],
      location: resource[:location],
      tags: resource[:tags],
    }
  end

  def flush
    if @property_hash[:ensure] != :absent
      Puppet.info("Updating network security group #{resource[:name]}")
      create_network_security_group(create_hash)
    end
  end

  def dns_servers=(value)
    Puppet.debug("Updating dns servers to be #{value.join(', ')} on network_security_group #{resource[:name]}")
    @property_hash[:dns_servers] = value
  end

  def destroy
    Puppet.info("Deleting network security group #{name}")
    delete_network_security_group({
      resource_group: resource[:resource_group],
      name: resource[:name],
    })
    @property_hash[:ensure] = :absent
  end
end
