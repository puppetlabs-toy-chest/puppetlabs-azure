require 'spec_helper'

type_class = Puppet::Type.type(:azure_virtual_network)

describe type_class do

  let :params do
    [
      :name,
    ]
  end

  let :properties do
    [
      :ensure,
      :address_space,
      :subnets,
      :dns_servers,
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
    'address_space',
  ].each do |property|
    it "should require #{property} to be a string" do
      expect(type_class).to require_string_for(property)
    end
  end

  [
    'dns_servers',
    'subnets',
  ].each do |param|
    it "should require #{param} to be a hash" do
      expect(type_class).to require_hash_for(param)
    end
  end

  [
  ].each do |property|
    it "should require #{property} to be read only" do
      expect(type_class).to be_read_only(property)
    end
  end

  context 'with basic properties' do
    before :each do
      @config = {
        ensure: :present,
        name: 'network-test',
        address_space: [
          '172.16.0.0/12',
          '10.0.0.0/8',
          '192.168.0.0/24',
        ],
        dns_servers: [{
          name: 'dns-1',
          ip_address: '1.2.3.4',
        },{
          name: 'dns-2',
          ip_address: '8.7.6.5',
        }],
        subnets: [{
          name: 'subnet-1',
          ip_address: '172.16.0.0',
          cidr: 12,
        },{
          name: 'subnet-2',
          ip_address: '10.0.0.0',
          cidr: 8,
        }],
      }
    end

    it 'should be valid' do
      expect { type_class.new(@config) }.to_not raise_error
    end

  end

  context 'with a subnet specified' do
    before :each do
      @config = {
        ensure: :present,
        name: 'network-test',
        subnets: {
          name: 'subnet-1',
          ip_address: '172.16.0.0',
          cidr: 12,
        },
      }
    end

    it 'should be valid' do
      expect { type_class.new(@config) }.to_not raise_error
    end

    [:name, :ip_address, :cidr].each do |key|
      it "should require subnets to have a #{key} key" do
        expect {
          config = Marshal.load(Marshal.dump(@config))
          config[:subnets].delete(key)
          type_class.new(config)
        }.to raise_error(Puppet::Error, /for subnets you are missing the following keys: #{key}/)
      end
    end

    it "should require subnet cidr to be an integer" do
      expect {
        config = Marshal.load(Marshal.dump(@config))
        config[:subnets][:cidr] = 'invalid'
        type_class.new(config)
      }.to raise_error(Puppet::Error, /cidr for subnets should be an Integer/)
    end

  end

  context 'with a dns_server specified' do
    before :each do
      @config = {
        ensure: :present,
        name: 'network-test',
        dns_servers: {
          name: 'dns-1',
          ip_address: '1.2.3.4',
        }
      }
    end

    it 'should be valid' do
      expect { type_class.new(@config) }.to_not raise_error
    end

    [:name, :ip_address].each do |key|
      it "should require dns_servers to have a #{key} key" do
        expect {
          config = Marshal.load(Marshal.dump(@config))
          config[:dns_servers].delete(key)
          type_class.new(config)
        }.to raise_error(Puppet::Error, /for dns_servers you are missing the following keys: #{key}/)
      end
    end

  end


end
