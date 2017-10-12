require 'puppet/parameter/boolean'

require_relative '../../puppet_x/puppetlabs/azure/property/read_only'
require_relative '../../puppet_x/puppetlabs/azure/property/positive_integer'
require_relative '../../puppet_x/puppetlabs/azure/property/string'
require_relative '../../puppet_x/puppetlabs/azure/property/hash'
require_relative '../../puppet_x/puppetlabs/azure/property/boolean'

Puppet::Type.newtype(:azure_storage_account) do
  @doc = 'Type representing a storage account in Microsoft Azure.'

  ensurable

  validate do
    required_properties = [
      :location,
      :resource_group,
    ]
    required_properties.each do |property|
      # We check for both places so as to cover the puppet resource path as well
      if self[:ensure] == :present and self[property].nil? and self.provider.send(property) == :absent
        fail "You must provide a #{property}"
      end
    end
  end

  newparam(:name, namevar: true, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'Name of the storage account.'
    validate do |value|
      super value
      fail 'the name must not be empty' if value.empty?
      fail("The name must be between 3 and 24 characters in length") if value.size > 24 or value.size < 3
      fail("The name can contain only alphanumeric characters") unless value =~ %r{^[\w]+$}
    end
    def insync?(is)
      is.casecmp(should).zero?
    end
  end

  newproperty(:resource_group, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The name of the associated resource group'
    validate do |value|
      super value
      fail 'the resource group must not be empty' if value.empty?
    end
    def insync?(is)
      is.casecmp(should).zero?
    end
  end

  newproperty(:account_type, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'DEPRECATED name of the storage account performance & replication SKU (replaced by sku_name)'
  end

  newproperty(:sku_name, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The name of the storage account performance & replication SKU (account type)'
    newvalues('Standard_LRS', 'Standard_ZRS', 'Standard_GRS', 'Standard_RAGRS', 'Premium_LRS')
    defaultto 'Standard_GRS'
  end

  newproperty(:account_kind, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The kind of storage account'
    newvalues('Storage', 'BlobStorage')
    defaultto 'Storage'
  end

  newproperty(:access_tier, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The access tier for Blob storage accounts'
    newvalues('Hot', 'Cool')
  end

  newproperty(:https_traffic_only, :parent => PuppetX::PuppetLabs::Azure::Property::Boolean) do
    desc 'Allows https traffic only to storage service if set'
    defaultto false
  end

  newproperty(:location, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The location where the storage account will be created.'
    validate do |value|
      super value
      fail 'the location must not be empty' if value.empty?
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
