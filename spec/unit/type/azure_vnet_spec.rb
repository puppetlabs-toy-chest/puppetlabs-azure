require 'spec_helper'

describe 'azure_vnet', :type => :type do
  let(:type_class) { Puppet::Type.type(:azure_vnet) }

  let :params do
    [
      :name,
      :provider,
    ]
  end

  let :properties do
    [
      :ensure,
      :location,
      :resource_group,
      :etag,
      :address_prefixes,
      :dns_servers,
      :subnets,
    ]
  end

  let :default_config do
    {
      name: 'testvnet',
      location: 'eastus',
      resource_group: 'testresourcegrp',
    }
  end

  it 'should have expected properties' do
    expect(type_class.properties.map(&:name)).to include(*properties)
  end

  it 'should have expected parameters' do
    expect(type_class.parameters).to include(*params)
  end

  it 'should not have unexpected properties' do
    expect(properties).to include(*type_class.properties.map(&:name))
  end

  it 'should not have unexpected parameters' do
    expect(params + [:provider]).to include(*type_class.parameters)
  end


  [
    'location',
    'resource_group',
  ].each do |property|
    it "should require #{property} to be a string" do
      expect(type_class).to require_string_for(property)
    end
  end

  # verify Arrays
  [
    'address_prefixes',
    'dns_servers',
  ].each do |property|
    it "should require #{property} to be an Array" do
      config = default_config
      config[property] = 2
      expect do
        type_class.new(config)
      end.to raise_error(Puppet::Error, /#{property} must be an Array/)
    end
  end

  #  Arrays
  [
    'etag',
    'subnets',
  ].each do |property|
    it "should prevent setting #{property}" do
      config = default_config
      config[property] = 'junk'
      expect do
        type_class.new(config)
      end.to raise_error(Puppet::Error, /#{property} is a read-only property/)
    end
  end

  context 'with a minimal set of properties' do
    let :config do
      default_config
    end

    let :vnet do
      type_class.new(config)
    end

    it 'should be valid' do
      expect { vnet }.to_not raise_error
    end

    [
      :location,
      :resource_group,
    ].each do |key|
      context "when missing the #{key} property" do
        it "should fail with ensure => present" do
          config.delete(key)
          config[:ensure] = :present
          p config
          expect { vnet }.to raise_error(Puppet::Error, /You must provide a #{key}/)
        end
      end
      it "should not fail with ensure => absent" do
        config.delete(key)
        config[:ensure] = :absent
        expect { vnet }.to_not raise_error
      end
    end

    context 'with a blank location' do
      let :config do
        result = default_config
        result[:location] = ''
        result
      end

      it 'should be invalid' do
        expect { type_class.new(config) }.to raise_error(Puppet::ResourceError, /the location must not be empty/)
      end
    end

    context 'with a name greater than 64 characters' do
      let :config do
        result = default_config
        result[:name] = SecureRandom.hex(33)
        result
      end

      it 'should be invalid' do
        expect { type_class.new(config) }.to raise_error(Puppet::Error, /the name must be between 1 and 64 characters long/)
      end
    end

    context 'with a resource group greater than 64 characters' do
      let :config do
        result = default_config
        result[:resource_group] = SecureRandom.hex(33)
        result
      end

      it 'should be invalid' do
        expect { type_class.new(config) }.to raise_error(Puppet::Error, /the resource group must be less that 65 characters/)
      end
    end

    context 'with no location' do
      let :config do
        result = default_config
        result[:location] = ''
        result
      end

      it 'should be invalid' do
        expect { type_class.new(config) }.to raise_error(Puppet::ResourceError, /the location must not be empty/)
      end
    end

    {
      :ensure => :present,
      :dns_servers => [],
      :address_prefixes => ['10.0.0.0/16'],
    }.each do |property, value|
      it "should default #{property} to #{value}" do
        expect(vnet[property]).to eq(value)
      end
    end
  end
end
