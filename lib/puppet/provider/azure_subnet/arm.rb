require 'puppet_x/puppetlabs/azure/prefetch_error'
require 'puppet_x/puppetlabs/azure/provider_arm'

Puppet::Type.type(:azure_subnet).provide(:arm, :parent => PuppetX::Puppetlabs::Azure::ProviderArm) do
  confine feature: :azure
  confine feature: :azure_hocon
  confine feature: :azure_retries

  mk_resource_methods

  read_only(:resource_group, :virtual_network, :provisioning_state)

  def self.instances
    begin
      PuppetX::Puppetlabs::Azure::ProviderArm.new.get_all_subnets.collect do |subnet|
        hash = subnet_to_hash(subnet)
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

  def self.subnet_to_hash(subnet) # rubocop:disable Metrics/AbcSize
    {
      name: subnet.name,
      ensure: :present,
      resource_group: subnet.id.split('/')[4].downcase,
      virtual_network: subnet.id.split('/')[8].downcase,
      address_prefix: subnet.address_prefix,
      network_security_group: subnet.network_security_group.nil? ? nil : subnet.network_security_group.name,
      route_table: subnet.route_table.nil? ? nil : subnet.route_table.name,
      provisioning_state: subnet.provisioning_state,
    }
  end

  def create_hash
    {
      resource_group: resource[:resource_group],
      virtual_network: resource[:virtual_network],
      name: resource[:name],
      address_prefix: resource[:address_prefix],
      network_security_group: resource[:network_security_group],
      route_table: resource[:route_table],
    }
  end

  def create
    Puppet.info("Creating subnet #{resource[:name]} in virtual network #{resource[:virtual_network]}")
    create_subnet(create_hash)
    @property_hash[:ensure] = :present
  end

  def flush
    if @property_hash[:ensure] != :absent
      Puppet.info("Updating subnet #{resource[:name]} in virtual network #{resource[:virtual_network]}")
      create_subnet(create_hash)
    end
  end

  def destroy
    Puppet.info("Deleting subnet #{resource[:name]} from virtual network #{resource[:virtual_network]}")
    delete_subnet({
      resource_group: resource[:resource_group],
      virtual_network: resource[:virtual_network],
      name: resource[:name],
    })
    @property_hash[:ensure] = :absent
  end
end
