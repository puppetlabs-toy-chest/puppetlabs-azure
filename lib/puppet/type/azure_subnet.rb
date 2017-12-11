require 'puppet/parameter/boolean'

require_relative '../../puppet_x/puppetlabs/azure/property/read_only'
require_relative '../../puppet_x/puppetlabs/azure/property/positive_integer'
require_relative '../../puppet_x/puppetlabs/azure/property/string'
require_relative '../../puppet_x/puppetlabs/azure/property/hash'

# azure_subnet { 'sample':
#   virtual_network        => '[Required]: The virtual network name',
#   address_prefix         => undef,           # If omitted, automatically reserves a /24 within address-prefixes
#   route_table            => undef,           # routing table for the subnet to use (default)
#   network_security_group => undef,           # default network security group for nodes on the subnet (none)
# }

Puppet::Type.newtype(:azure_subnet) do
  @doc = 'Type representing a virtual network in Microsoft Azure.'

  validate do
    required_properties = [
      :resource_group,
      :virtual_network,
      :name,
    ]
    required_properties.each do |property|
      # We check for both places so as to cover the puppet resource path as well
      if self[:ensure] == :present and self[property].nil? and self.provider.send(property) == :absent
        fail "You must provide a #{property}"
      end
    end
  end

  newproperty(:ensure) do
    defaultto :present
    newvalue(:present) do
      provider.create unless provider.exists?
    end
    newvalue(:absent) do
      provider.destroy if provider.exists?
    end
  end

  newparam(:name, namevar: true, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'Name of the virtual network subnet'
    validate do |value|
      super value
      fail("the name must be between 1 and 64 characters long") if value.size > 64
    end
  end

  newproperty(:resource_group, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'Name of the associated resource group'
    validate do |value|
      super value
      fail 'the resource_group must not be empty' if value.empty?
      fail("the resource_group must be less that 65 characters in length") if value.size > 64
    end
    def insync?(is)
      is.casecmp(should).zero?
    end
  end

  newproperty(:virtual_network, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The name of the virtual network the subnet resides in'
    validate do |value|
      super value
      fail 'the virtual_network must not be empty' if value.empty?
      fail("the virtual_network must be less that 65 characters in length") if value.size > 64
    end
    def insync?(is)
      is.casecmp(should).zero?
    end
  end

  newproperty(:address_prefix, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'IP address prefix for the subnet'

    validate do |value|
      super value
      fail 'address_prefix must be an IP v4 subnet' unless value =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/\d{1,2}$/
    end
  end

  newproperty(:route_table, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'Route table used by the subnet'

    validate do |value|
      super value
      fail("the route_table must be less that 65 characters in length") if value.size > 64
    end
  end

  newproperty(:network_security_group, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'Network Security Group applied to the subnet traffic'

    validate do |value|
      super value
      fail("the network_security_group must be less that 65 characters in length") if value.size > 64
    end
  end

  autorequire(:azure_resource_group) do
    self[:resource_group]
  end
  autorequire(:azure_vnet) do
    self[:virtual_network]
  end
end
