require 'puppet/parameter/boolean'

require_relative '../../puppet_x/puppetlabs/azure/property/read_only'
require_relative '../../puppet_x/puppetlabs/azure/property/positive_integer'
require_relative '../../puppet_x/puppetlabs/azure/property/string'

# azure_vm { 'sample':
#   location         => 'West US'
#   image            => 'canonical:ubuntuserver:14.04.2-LTS:latest',
#   user             => 'azureuser',
#   password         => 'Password',
#   size             => 'Standard_A0',
#   resource_group   => 'myresourcegroup',
# }

Puppet::Type.newtype(:azure_vm) do
  @doc = 'Type representing a virtual machine in Microsoft Azure.'

  validate do
    required_properties = [
      :location,
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
    newvalue(:running) do
      if provider.exists?
        provider.start unless provider.running?
      else
        provider.create
      end
    end
    newvalue(:stopped) do
      if provider.exists?
        provider.stop unless provider.stopped?
      else
        provider.create
        provider.stop
      end
    end
    def change_to_s(current, desired)
      current = :running if current == :present
      desired = current if desired == :present and current != :absent
      current == desired ? current : "changed #{current} to #{desired}"
    end
    def insync?(is)
      is.to_s == should.to_s or
        (is.to_s == 'running' and should.to_s == 'present') or
        (is.to_s == 'stopped' and should.to_s == 'present')
    end
  end

  newparam(:name, namevar: true, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'Name of the virtual machine.'
    validate do |value|
      super value
      fail("the name must be between 1 and 64 characters long") if value.size > 64
    end
  end

  newproperty(:image, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'Name of the image to use to create the virtual machine.'
    validate do |value|
      super value
      fail("the image name must not be empty") if value.empty?
    end
    def insync?(is)
      is.casecmp(should).zero?
    end
  end

  newproperty(:user, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'User name for the virtual machine. This value is only used when creating the VM initially.'
  end

  newparam(:password, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The password for the virtual machine. This value is only used when creating the VM initially.'
    validate do |value|
      super value
      fail 'the password must not be empty' if value.empty?
    end
  end

  newproperty(:location, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The location where the virtual machine will be created.'
    validate do |value|
      super value
      fail 'the location must not be empty' if value.empty?
    end
  end

  newproperty(:size, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The size of the virtual machine instance.'
    validate do |value|
      super value
      fail 'the size must not be empty' if value.empty?
    end
  end

  newproperty(:resource_group, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The name of the associated resource group'
    validate do |value|
      super value
      fail 'the resource group must not be empty' if value.empty?
      fail("the resource group must be less that 65 characters in length") if value.size > 64
    end
    def insync?(is)
      is.casecmp(should).zero?
    end
  end

  newparam(:storage_account, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The name of the associated storage account'
    validate do |value|
      super value
      fail 'the storage account must not be empty' if value.empty?
    end
  end

  newparam(:storage_account_type, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The name of the associated storage account type'
    defaultto 'Standard_GRS'
  end

  newproperty(:os_disk_name, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The name of the associated os disk name'
  end

  newproperty(:os_disk_caching, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The disk cache setting'
    defaultto 'ReadWrite'
  end

  newproperty(:os_disk_create_option, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The os disk create option'
    defaultto 'FromImage'
  end

  newproperty(:os_disk_vhd_container_name, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The os disk vhd container name'
    defaultto 'vhds'
  end

  newproperty(:os_disk_vhd_name, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The os disk vhd name'
  end

  newparam(:public_ip_address_name, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The public ip address name'
  end

  newparam(:dns_domain_name, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The dns domain name for the vm'
  end

  newparam(:dns_servers, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The dns servers for the vm'
    defaultto '10.1.1.1 10.1.2.4'
  end

  newparam(:public_ip_allocation_method, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The public ip allocation method'
    defaultto 'Dynamic'
  end

  newparam(:virtual_network_name, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The virtual network name'
  end

  newparam(:virtual_network_address_space, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The virtual network address space'
    defaultto '10.0.0.0/16'
  end

  newparam(:subnet_name, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The subnet name'
    defaultto 'default'
  end

  newparam(:subnet_address_prefix, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The subnet address prefix'
    defaultto '10.0.2.0/24'
  end

  newparam(:ip_configuration_name, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The ip configuration name'
  end

  newparam(:private_ip_allocation_method, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The private ip allocation method'
    defaultto 'Dynamic'
  end

  newproperty(:network_interface_name, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The network interface name'
  end
end
