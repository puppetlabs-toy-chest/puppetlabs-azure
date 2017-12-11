require 'puppet/parameter/boolean'

require_relative '../../puppet_x/puppetlabs/azure/property/read_only'
require_relative '../../puppet_x/puppetlabs/azure/property/positive_integer'
require_relative '../../puppet_x/puppetlabs/azure/property/string'
require_relative '../../puppet_x/puppetlabs/azure/property/hash'

# azure_vnet { 'sample':
#   resource_group   => '[Required]: Name of resource group',
#   address_prefixes => ['10.0.0.0/16'], # Array of IP address prefixes for the VNet
#   dns_servers      => [],              # Array of DNS server IP addresses
#   subnets          => [],              # Array of azure subnets
# }

Puppet::Type.newtype(:azure_vnet) do
  @doc = 'Type representing a virtual network in Microsoft Azure.'

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

  newproperty(:resource_group, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The name of the associated resource group'
    validate do |value|
      super value
      fail 'the resource group must not be empty' if value.empty?
      fail 'the resource group must be less that 65 characters in length' if value.size > 64
    end
    def insync?(is)
      is.casecmp(should).zero?
    end
  end

  newproperty(:etag, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'A string that changes every time the object changes.'
    validate do |value|
      super value
      fail 'etag is a read-only property' unless value.empty?
    end
  end

  newparam(:name, namevar: true, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'Name of the virtual network.'
    validate do |value|
      super value
      fail("the name must be between 1 and 64 characters long") if value.size > 64
    end
  end

  newproperty(:location, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'Location of the virtual network.'
    validate do |value|
      super value
      fail 'the location must not be empty' if value.empty?
    end
  end

  newproperty(:address_prefixes, :array_matching => :all) do
    desc 'Array of IP address prefixes for the VNet'
    defaultto ['10.0.0.0/16']
    validate do |value|
      super value
      fail 'address_prefixes must be an Array of IP v4 subnets' unless value =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/\d{1,2}$/
    end
  end

  newproperty(:dns_servers, :array_matching => :all) do
    desc 'Array of DNS server IP addresses'
    defaultto []
    validate do |value|
      super value
      fail 'dns_servers must be an Array of DNS server IPs' unless value =~ Resolv::IPv4::Regex
    end
  end

  newproperty(:subnets, :array_matching => :all) do
    desc 'Hash of subnets within the virtual network'
    defaultto {}
    validate do |value|
      super value
      fail 'subnets is a read-only property' unless value.empty?
    end
  end

  autorequire(:azure_resource_group) do
    self[:resource_group]
  end
end
