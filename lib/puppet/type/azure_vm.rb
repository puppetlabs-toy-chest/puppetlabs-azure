require_relative '../../puppet_x/puppetlabs/azure/property/read_only'
require_relative '../../puppet_x/puppetlabs/azure/property/positive_integer'
require_relative '../../puppet_x/puppetlabs/azure/property/string'

=begin
azure_vm { 'sample':
  user                  => 'azureuser',
  image                 => '5112500ae3b842c8b9c604889f8753c3__OpenLogic-CentOS-63APR20130415',
  password              => 'Password',
  location              => 'West US'
  storage_account_name  => 'storage_suse',
  winrm_transport       => ['https','http'],
  winrm_https_port      => 5999,
  winrm_http_port       => 6999,
  cloud_service_name    => 'cloud_service_name',
  deployment_name       =>'vm_name',
  tcp_endpoints         => '80,3389:3390',
  private_key_file      => './private_key.key', # required for ssh
  ssh_port              => 2222,
  vm_size               => 'Small',
  affinity_group_name   => 'affinity1',
  virtual_network_name  => 'xplattestvnet',
  subnet_name           => 'subnet1',
  availability_set_name => 'availabiltyset1',
  reserved_ip_name      => 'reservedipname'
  endpoints             => [{
    :name        => 'ep-1',
    :public_port => 996,
    :local_port  => 998,
    :protocol    => 'TCP',
  },{
    :name               => 'ep-2',
    :public_port        => 997,
    :local_port         => 997,
    :protocol           => 'TCP',
    :load_balancer_name => 'lb-ep2',
    :load_balancer      => {:protocol => 'http', :path => 'hello'},
  }],
   disks                => [{
    'label'  => 'disk-label',
    'size'   => 100, #In GB
    'import' => false,
    'name'   => 'Disk name', #Required when import is true
  }],
}
=end

Puppet::Type.newtype(:azure_vm) do
  @doc = 'Type representing a virtual machine in Microsoft Azure.'

  ensurable

  newparam(:name, namevar: true, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'Name of the virtual machine.'
  end

  newproperty(:image, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'Name of the disk image to use to create the virtual machine.'
  end

  newproperty(:user, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'User name for the virtual machine.'
  end

  newparam(:password, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The password for the virtual machine.'
  end

  newparam(:private_key_file) do
    desc 'Path to the private key file.'
  end

  newproperty(:location, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The location where the virtual machine will be created.'
  end

  newproperty(:storage_account, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The storage account to associate the virtual machine with.'
  end

  newproperty(:winrm_transport, :parent => PuppetX::PuppetLabs::Azure::Property::String, :array_matching => :all) do
    desc 'A list of transport protocols for WINRM.'
  end

  newproperty(:winrm_https_port, :parent => PuppetX::PuppetLabs::Azure::Property::PositiveInteger) do
    desc 'The port number of WINRM https communication.'
  end

  newproperty(:winrm_http_port, :parent => PuppetX::PuppetLabs::Azure::Property::PositiveInteger) do
    desc 'The port number of WINRM http communication.'
  end

  newproperty(:cloud_service, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The name of the associated cloud service.'
  end

  newproperty(:deployment, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The name for the deployment.'
  end

  newproperty(:ssh_port, :parent => PuppetX::PuppetLabs::Azure::Property::PositiveInteger) do
    desc 'The port number for SSH.'
  end

  newproperty(:vm_size, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The size of the virtual machine instance.'
  end

  newproperty(:affinity_group, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The affinity group to be used for the cloud service and the storage account if these do not exist.'
  end

  newproperty(:virtual_network, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The virtual network to which the virtual machine should be connected.'
  end

  newproperty(:subnet, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The subnet to which the virtual machine should be associated.'
  end

  newproperty(:availability_set, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The availability set for the virtual machine.'
  end

  newproperty(:reserved_ip, :parent => PuppetX::PuppetLabs::Azure::Property::String) do
    desc 'The name of the reserved IP to associate with the virtual machine.'
  end

  # Could also be represented by a separate type. Best approach still to be determined.
  # disks => [{
  #  'label'  => 'disk-label',
  #  'size'   => 100,
  #  'import' => false,
  #  'name'   => 'Disk name', #Required when import is true
  # }],
  newproperty(:disks, :array_matching => :all) do
    desc 'A list of disks which should be attached to the virtual machine.'
    validate do |value|
      fail 'disks should be a Hash' unless value.is_a? Hash
      stringified_value = Hash.new
      value.each{|k,v| stringified_value[k.to_s] = v}
      required = ['label', 'size']
      missing = required - stringified_value.keys.map(&:to_s)
      unless missing.empty?
        fail "for disks you are missing the following keys: #{missing.join(',')}"
      end
      ['label', 'name'].each do |key|
        if stringified_value[key]
          fail "#{key} for disks should be a String" unless stringified_value[key].is_a? String
        end
      end
      fail 'size for disks should be an Integer' unless stringified_value['size'].to_i.to_s == stringified_value['size'].to_s
      if stringified_value.keys.include? 'import'
        fail 'import for disks must be true or false' unless stringified_value['import'].to_s =~ /^true|false$/
        if stringified_value['import'].to_s == 'true'
          fail 'if import is true a name must be provided for disks' unless stringified_value.keys.include?('name')
        end
      end
    end
  end

  # Could also be represented by a separate type. Best approach still to be determined.
  # endpoints => [{
  #   'name'        => 'ep-1',
  #   'public_port' => 996,
  #   'local_port'  => 998,
  #   'protocol'    => 'TCP',
  # },{
  #   'name'               => 'ep-2',
  #   'public_port'        => 997,
  #   'local_port'         => 997,
  #   'protocol'           => 'TCP',
  #   'load_balancer_name' => 'lb-ep2',
  #   'load_balancer'      => {:protocol => 'http', :path => 'hello'},
  # }],
  newproperty(:endpoints, :array_matching => :all) do
    desc 'A list of endpoints which should be associated with the virtual machine.'
    validate do |value|
      fail 'endpoints should be a Hash' unless value.is_a? Hash
      stringified_value = Hash.new
      value.each{|k,v| stringified_value[k.to_s] = v}
      required = ['name', 'public_port', 'local_port', 'protocol']
      missing = required - stringified_value.keys.map(&:to_s)
      unless missing.empty?
        fail "for endpoints you are missing the following keys: #{missing.join(',')}"
      end
      ['name', 'protocol', 'load_balancer_name'].each do |key|
        if stringified_value.keys.include? key
          fail "#{key} for endpoints should be a String" unless stringified_value[key].is_a? String
        end
      end
      ['public_port', 'local_port'].each do |key|
        fail "#{key} for endpoints should be an Integer" unless stringified_value[key].to_i.to_s == stringified_value[key].to_s
      end
      if stringified_value.keys.include? 'load_balancer'
        fail 'load_balancer for endpoints should be a Hash' unless stringified_value['load_balancer'].is_a? Hash
      end
    end
  end

  [].each do |property|
    newproperty(property, :parent => PuppetX::PuppetLabs::Azure::Property::ReadOnly) do
    end
  end

end
