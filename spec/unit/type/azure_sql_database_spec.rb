require 'spec_helper'

type_class = Puppet::Type.type(:azure_sql_database)

describe type_class do

  let :params do
    [
      :name,
      :password,
    ]
  end

  let :properties do
    [
      :ensure,
      :location,
      :firewalls,
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
    'password',
    'location',
  ].each do |property|
    it "should require #{property} to be a string" do
      expect(type_class).to require_string_for(property)
    end
  end

  [
    'firewalls',
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
        name: 'database-test',
        password: 'complexPassword',
        location: 'West US',
      }
    end

    it 'should be valid' do
      expect { type_class.new(@config) }.to_not raise_error
    end

  end

context 'with a firewall rule specified' do
    before :each do
      @config = {
        ensure: :present,
        name: 'database-test',
        password: 'complexPassword',
        location: 'West US',
        firewalls: {
          name: 'rule',
          start_ip_address: '0.0.0.1',
          end_ip_address: '0.0.0.5',
        }
      }
    end

    it 'should be valid' do
      expect { type_class.new(@config) }.to_not raise_error
    end

    [:name, :start_ip_address, :end_ip_address].each do |key|
      it "should require firewalls to have a #{key} key" do
        expect {
          config = Marshal.load(Marshal.dump(@config))
          config[:firewalls].delete(key)
          type_class.new(config)
        }.to raise_error(Puppet::Error, /for firewalls you are missing the following keys: #{key}/)
      end
    end

  end

end
