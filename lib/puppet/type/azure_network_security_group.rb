require 'puppet/parameter/boolean'

require_relative '../../puppet_x/puppetlabs/azure/property/read_only'
require_relative '../../puppet_x/puppetlabs/azure/property/positive_integer'
require_relative '../../puppet_x/puppetlabs/azure/property/string'
require_relative '../../puppet_x/puppetlabs/azure/property/hash'

# azure_network_security_group { 'sample':
#   resource_group => '[Required]: Name of resource group',
#   location       => 'West US',     # Azure region
#   tags           => [],            # Tags associated with the security group
# }

Puppet::Type.newtype(:azure_network_security_group) do
  @doc = 'Type representing a network security group in Microsoft Azure.'

  validate do
    required_properties = [
      :resource_group,
      :location,
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
    desc 'Name of the network security group.'
    validate do |value|
      super value
      fail 'the name must be between 1 and 64 characters long' if value.size > 64
    end
  end

  newproperty(:resource_group, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The name of the associated resource group'
    validate do |value|
      super value
      fail 'the resource_group must not be empty' if value.empty?
      fail 'the resource_group must be between 1 and 64 characters long' if value.size > 64
    end
    def insync?(is)
      is.casecmp(should).zero?
    end
  end

  newproperty(:location, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'Location of the network security group.'
    validate do |value|
      super value
      fail 'the location must not be empty' if value.empty?
      fail 'the location must be between 1 and 64 characters long' if value.size > 64
    end
  end

  newproperty(:etag, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'A string that changes every time the object changes.'
    validate do |value|
      super value
      fail 'etag is a read-only property' unless value.empty?
    end
  end

  newproperty(:guid, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'Unique resource guid for this group'
    validate do |value|
      super value
      fail 'guid is a read-only property' unless value.empty?
    end
  end

  newproperty(:default_security_rules, :array_matching => :all) do
    desc 'Array of default rules in this network security group'
    defaultto []
    validate do |value|
      super value
      fail 'default_security_rules is a read-only property' unless value.empty?
    end
  end

  newproperty(:security_rules, :array_matching => :all) do
    desc 'Array of rules in this network security group'
    defaultto []
    validate do |value|
      super value
      fail 'security_rules is a read-only property' unless value.empty?
    end
  end

  newproperty(:network_interfaces, :array_matching => :all) do
    desc 'Array of network interfaces  using this network security group'
    defaultto []
    validate do |value|
      super value
      fail 'network_interfaces is a read-only property' unless value.empty?
    end
  end

  newproperty(:subnets, :array_matching => :all) do
    desc 'Array of subnets using this network security group'
    defaultto []
    validate do |value|
      super value
      fail 'subnets is a read-only property' unless value.empty?
    end
  end

  newproperty(:tags, :parent => PuppetX::PuppetLabs::Azure::Property::Hash) do
    desc 'The tags for the instance'
    defaultto {}
  end

  autorequire(:azure_resource_group) do
    self[:resource_group]
  end
end
