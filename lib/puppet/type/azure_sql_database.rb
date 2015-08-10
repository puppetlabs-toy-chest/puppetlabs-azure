require_relative '../../puppet_x/puppetlabs/property/read_only'
require_relative '../../puppet_x/puppetlabs/property/positive_integer'
require_relative '../../puppet_x/puppetlabs/property/string'

=begin
azure_sql_database { 'server_name':
  location  => 'West US',
  password  => 'ComplexPassword',
  firewalls => [{
    'name'             => 'rule-name'
    'start_ip_address' => '0.0.0.1',
    'end_ip_address'   => '0.0.0.5',
  }]
=end

Puppet::Type.newtype(:azure_sql_database) do
  @doc = 'Type representing a SQL database in Microsoft Azure.'
  ensurable

  newparam(:name, namevar: true, :parent => PuppetX::Property::String) do
    desc 'Name of the database.'
  end

  newproperty(:location, :parent => PuppetX::Property::String) do
    desc 'The location where the database will be created.'
  end

  newparam(:password, :parent => PuppetX::Property::String) do
    desc 'The password for the virtual machine.'
  end

  newproperty(:firewalls, :array_matching => :all) do
    desc 'A list of firewall rules controlling access to the database.'
    validate do |value|
      fail 'firewalls should be a Hash' unless value.is_a? Hash
      stringified_value = Hash.new
      value.each{|k,v| stringified_value[k.to_s] = v}
      required = ['name', 'start_ip_address', 'end_ip_address']
      missing = required - stringified_value.keys.map(&:to_s)
      unless missing.empty?
        fail "for firewalls you are missing the following keys: #{missing.join(',')}"
      end
      ['name', 'start_ip_address', 'end_ip_address'].each do |key|
        if stringified_value[key]
          fail "#{key} for firewalls should be a String" unless stringified_value[key].is_a? String
        end
      end
    end
  end
end
