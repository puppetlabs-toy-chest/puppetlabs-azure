require_relative '../../puppet_x/puppetlabs/property/read_only'
require_relative '../../puppet_x/puppetlabs/property/positive_integer'
require_relative '../../puppet_x/puppetlabs/property/string'

=begin
azure_virtual_network { 'virtual-network-name':
  address_space => [
    '172.16.0.0/12',
    '10.0.0.0/8',
    '192.168.0.0/24',
  ],
  dns_servers => [{
    name       => 'dns-1',
    ip_address => '1.2.3.4',
  },{
    name       => 'dns-2',
    ip_address => '8.7.6.5',
  }],
  subnets => [{
    name       => 'subnet-1',
    ip_address => '172.16.0.0',
    cidr       => 12,
  },{
    name       => 'subnet-2',
    ip_address => '10.0.0.0',
    cidr       => 8,
  }],
=end

Puppet::Type.newtype(:azure_virtual_network) do
  @doc = 'Type representing a Virtual Network in Microsoft Azure.'
  ensurable

  newparam(:name, namevar: true, :parent => PuppetX::Property::String) do
    desc 'Name of the virtual network.'
  end

  newproperty(:address_space, :parent => PuppetX::Property::String, :array_matching => :all) do
    desc 'The IP address space defined by this network.'
  end

  newproperty(:dns_servers, :array_matching => :all) do
    desc 'A list of DNS servers for use by the virtual network.'
    validate do |value|
      fail 'dns_servers should be a Hash' unless value.is_a? Hash
      stringified_value = Hash.new
      value.each{|k,v| stringified_value[k.to_s] = v}
      required = ['name', 'ip_address']
      missing = required - stringified_value.keys.map(&:to_s)
      unless missing.empty?
        fail "for dns_servers you are missing the following keys: #{missing.join(',')}"
      end
      ['name', 'ip_address'].each do |key|
        if stringified_value[key]
          fail "#{key} for dns_servers should be a String" unless stringified_value[key].is_a? String
        end
      end
    end
  end

  newproperty(:subnets, :array_matching => :all) do
    desc 'A list of subnets for use by the virtual network.'
    validate do |value|
      fail 'subnets should be a Hash' unless value.is_a? Hash
      stringified_value = Hash.new
      value.each{|k,v| stringified_value[k.to_s] = v}
      required = ['name', 'ip_address', 'cidr']
      missing = required - stringified_value.keys.map(&:to_s)
      unless missing.empty?
        fail "for subnets you are missing the following keys: #{missing.join(',')}"
      end
      ['name', 'ip_address'].each do |key|
        if stringified_value[key]
          fail "#{key} for subnets should be a String" unless stringified_value[key].is_a? String
        end
      end
      ['cidr'].each do |key|
        fail "#{key} for subnets should be an Integer" unless stringified_value[key].to_i.to_s == stringified_value[key].to_s
      end
    end
  end

end
