require 'spec_helper'

type_class = Puppet::Type.type(:azure_vm)

describe type_class do

  let :params do
    [
      :name,
      :password,
      :private_key_file,
    ]
  end

  let :properties do
    [
      :endpoints,
      :disks,
      :reserved_ip,
      :availability_set,
      :subnet,
      :virtual_network,
      :affinity_group,
      :vm_size,
      :ssh_port,
      :tcp_endpoints,
      :deployment,
      :cloud_service,
      :winrm_http_port,
      :winrm_https_port,
      :winrm_transport,
      :storage_account,
      :location,
      :image,
      :user,
      :ensure,
    ]
  end

  let :read_only_properties do
    []
  end

  it 'should have expected properties' do
    all_properties = properties + read_only_properties
    all_properties.each do |property|
      expect(type_class.properties.map(&:name)).to be_include(property)
    end
  end

  it 'should have expected parameters' do
    params.each do |param|
      expect(type_class.parameters).to be_include(param)
    end
  end

  it 'should require a name' do
    expect {
      type_class.new({})
    }.to raise_error(Puppet::Error, 'Title or name must be provided')
  end

  [
    'name',
    'user',
    'image',
    'password',
    'location',
    'storage_account',
    'winrm_transport',
    'cloud_service',
    'deployment',
    'tcp_endpoints',
    'vm_size',
    'affinity_group',
    'virtual_network',
    'subnet',
    'availability_set',
    'reserved_ip',
  ].each do |property|
    it "should require #{property} to be a string" do
      expect(type_class).to require_string_for(property)
    end
  end

  [
    'winrm_https_port',
    'winrm_http_port',
    'ssh_port',
  ].each do |property|
    it "should require #{property} to be a number" do
      expect(type_class).to require_integer_for(property)
    end

    it "should require #{property} to be greater than 0" do
      expect {
        config = {name: 'sample'}
        config[property] = 0
        type_class.new(config)
      }.to raise_error(Puppet::Error, /#{property} should be greater than 0/)
    end
  end

  [
    'disks',
    'endpoints',
  ].each do |param|
    it "should require #{param}' to be a hash" do
      expect(type_class).to require_hash_for(param)
    end
  end

  [
  ].each do |property|
    it "should require #{property} to be read only" do
      expect(type_class).to be_read_only(property)
    end
  end

  context 'with a disk specified' do
    before :each do
      @config = {
        ensure: :present,
        name: 'disk-test',
        disks: {
          label: 'disk-label',
          size: 100,
          import: false,
          name: 'disk-name',
        }
     }
    end

    it 'should be valid' do
      expect { type_class.new(@config) }.to_not raise_error
    end

    [:label, :size].each do |key|
      it "should require disk to have a #{key} key" do
        expect {
          config = Marshal.load(Marshal.dump(@config))
          config[:disks].delete(key)
          type_class.new(config)
        }.to raise_error(Puppet::Error, /for disks you are missing the following keys: #{key}/)
      end
    end

    it "should require disk size to be an integer" do
      expect {
        config = Marshal.load(Marshal.dump(@config))
        config[:disks][:size] = 'invalid'
        type_class.new(config)
      }.to raise_error(Puppet::Error, /size for disks should be an Integer/)
    end

    it 'should require disk import to be true or false if set' do
      expect {
        config = Marshal.load(Marshal.dump(@config))
        config[:disks][:import] = 'invalid'
        type_class.new(config)
      }.to raise_error(Puppet::Error, /import for disks must be true or false/)
    end

    [true, false].each do |bool|
      it "should allow import to be #{bool}" do
        expect {
          config = Marshal.load(Marshal.dump(@config))
          config[:disks][:import] = bool
          type_class.new(config)
        }.to_not raise_error
      end
    end

    it 'when import is true should require name to be specified for disk' do
      expect {
        config = Marshal.load(Marshal.dump(@config))
        config[:disks][:import] = true
        config[:disks].delete(:name)
        type_class.new(config)
      }.to raise_error(Puppet::Error, /if import is true a name must be provided for disks/)
    end

  end

  context 'with an endpoint specified' do
    before :each do
      @config = {
        ensure: :present,
        name: 'endpoint-test',
        endpoints: {
          name: 'ep-1',
          public_port: 996,
          local_port: 998,
          protocol: 'TCP',
        }
     }
    end

    it 'should be valid' do
      expect { type_class.new(@config) }.to_not raise_error
    end

    [:name, :public_port, :local_port, :protocol].each do |key|
      it "should require disk to have a #{key} key" do
        expect {
          config = Marshal.load(Marshal.dump(@config))
          config[:endpoints].delete(key)
          type_class.new(config)
        }.to raise_error(Puppet::Error, /for endpoints you are missing the following keys: #{key}/)
      end
    end

    [:local_port, :public_port].each do |port|
      it "should require endpoint #{port} to be an integer" do
        expect {
          config = Marshal.load(Marshal.dump(@config))
          config[:endpoints][port] = 'invalid'
          type_class.new(config)
        }.to raise_error(Puppet::Error, /#{port} for endpoints should be an Integer/)
      end
    end

  end

end
