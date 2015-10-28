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
#   storage_account  => 'mystorageaccount',
#   storage_account_type => 'Standard_GRS',
#   os_disk_name    => 'myosdisk1',
#   os_disk_caching => 'ReadWrite',
#   os_disk_create_option => 'fromImage',
#   os_disk_vhd_container_name => 'conttest1',
#   os_disk_vhd_name => 'vhdtest1',
#   dns_domain_name => 'mydomain01',
#   dns_servers => '10.1.1.1.1 10.1.2.4',
#   public_ip_allocation_method => 'Dynamic',
#   public_ip_address_name => 'ip_name_test01pubip',
#   virtual_network_name => 'vnettest01',
#   virtual_network_address_space => '10.0.0.0/16',
#   subnet_name => 'subnet111',
#   subnet_address_prefix => '10.0.2.0/24',
# }

Puppet::Type.newtype(:azure_vm) do
  @doc = 'Type representing a virtual machine in Microsoft Azure.'

  validate do
    required_properties = [
      :location,
      :size,
      :user,
      :password,
      :resource_group,
      :storage_account,
      :storage_account_type,
      :os_disk_name,
      :os_disk_caching,
      :os_disk_create_option,
      :os_disk_vhd_container_name,
      :os_disk_vhd_name,
      :dns_domain_name,
      :dns_servers,
      :public_ip_allocation_method,
      :public_ip_address_name,
      :virtual_network_name,
      :virtual_network_address_space,
      :subnet_name,
      :subnet_address_prefix,
      :ip_configuration_name,
      :private_ipallocation_method,
      :network_interface_name,
    ]
    required_properties.each do |property|
      # We check for both places so as to cover the puppet resource path as well
      if self[property].nil? and self.provider.send(property) == :absent
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
  end

  newproperty(:image, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'Name of the image to use to create the virtual machine.'
    validate do |value|
      super value
      fail("the image name must not be empty") if value.empty?
    end
  end

  newparam(:user, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
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
    end
  end

  newproperty(:storage_account, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The name of the associated storage account'
    validate do |value|
      super value
      fail 'the storage account must not be empty' if value.empty?
    end
  end

  newproperty(:storage_account_type, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The name of the associated storage account type'
    validate do |value|
      super value
      fail 'the storage account type must not be empty' if value.empty?
    end
  end

  newproperty(:os_disk_name, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The name of the associated os disk name'
    validate do |value|
      super value
      fail 'the os disk name must not be empty' if value.empty?
    end
  end

  newproperty(:os_disk_caching, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The disk cache setting'
    validate do |value|
      super value
      fail 'the os disk cache setting must not be empty' if value.empty?
    end
  end

  newproperty(:os_disk_create_option, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The os disk create option'
    validate do |value|
      super value
      fail 'the os disk create option must not be empty' if value.empty?
    end
  end

  newproperty(:os_disk_vhd_container_name, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The os disk vhd container name'
    validate do |value|
      super value
      fail 'the os disk vhd container name must not be empty' if value.empty?
    end
  end

  newproperty(:os_disk_vhd_name, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The os disk vhd name'
    validate do |value|
      super value
      fail 'the os disk vhd name must not be empty' if value.empty?
    end
  end

  newproperty(:public_ip_address_name, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The public ip address name'
    validate do |value|
      super value
      fail 'the public ip address name not be empty' if value.empty?
    end
  end

  newproperty(:dns_domain_name, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The dns domain name for the vm'
    validate do |value|
      super value
      fail 'the dns domain name must not be empty' if value.empty?
    end
  end

  newproperty(:dns_servers, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The dns servers for the vm'
    validate do |value|
      super value
      fail 'the dns servers must not be empty' if value.empty?
    end
  end

  newproperty(:public_ip_allocation_method, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The public ip allocation method'
    validate do |value|
      super value
      fail 'the public ip allocation method must not be empty' if value.empty?
    end
  end

  newproperty(:public_ip_allocation_name, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The public ip allocation name'
    validate do |value|
      super value
      fail 'the public ip allocation name must not be empty' if value.empty?
    end
  end

  newproperty(:virtual_network_name, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The virtual network name'
    validate do |value|
      super value
      fail 'the virtual network name must not be empty' if value.empty?
    end
  end

  newproperty(:virtual_network_address_space, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The virtual network address space'
    validate do |value|
      super value
      fail 'the virtual network address space must not be empty' if value.empty?
    end
  end

  newproperty(:subnet_name, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The subnet name'
    validate do |value|
      super value
      fail 'the subnet name must not be empty' if value.empty?
    end
  end

  newproperty(:subnet_address_prefix, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The subnet address prefix'
    validate do |value|
      super value
      fail 'the subnet address prefix must not be empty' if value.empty?
    end
  end

  newproperty(:ip_configuration_name, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The ip configuration name'
    validate do |value|
      super value
      fail 'the ip configuration name must not be empty' if value.empty?
    end
  end

  newproperty(:private_ipallocation_method, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The private ip allocation method'
    validate do |value|
      super value
      fail 'the private ip allocation method must not be empty' if value.empty?
    end
  end

  newproperty(:network_interface_name, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The network interface name'
    validate do |value|
      super value
      fail 'the network interface name must not be empty' if value.empty?
    end
  end
end
