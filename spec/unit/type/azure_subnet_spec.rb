require 'spec_helper'

describe 'azure_subnet', :type => :type do
  let(:type_class) { Puppet::Type.type(:azure_subnet) }

  let :params do
    [
      :name,
    ]
  end

  let :properties do
    [
      :ensure,
      :resource_group,
      :virtual_network,
      :address_prefix,
      :network_security_group,
      :route_table,
    ]
  end

  let :default_config do
    {
      name: 'testsa',
      resource_group: 'testresourcegrp',
      virtual_network: 'testnet',
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
    :resource_group,
    :virtual_network,
    :address_prefix,
    :network_security_group,
    :route_table,
  ].each do |property|
    it "should require #{property} to be a string" do
      expect(type_class).to require_string_for(property)
    end
  end

  it "should require address_prefix to be an IPv4 subnet" do
    config = default_config
    config[:address_prefix] = '192.168.5.2'
    expect do
      type_class.new(config)
    end.to raise_error(Puppet::Error, /address_prefix must be an IP v4 subnet/)
  end

  context 'with a minimal set of properties' do
    let :config do
      default_config
    end

    let :subnet do
      type_class.new(config)
    end

    it 'should be valid' do
      expect { subnet }.to_not raise_error
    end

    [
      :virtual_network,
      :resource_group,
    ].each do |key|
      context "when missing the #{key} property" do
        it "should fail with ensure => present" do
          config.delete(key)
          config[:ensure] = :present
          expect { subnet }.to raise_error(Puppet::Error, /You must provide a #{key}/)
        end
      end
      it "should not fail with ensure => absent" do
        config.delete(key)
        config[:ensure] = :absent
        expect { subnet }.to_not raise_error
      end
      context 'with a {key} greater than 64 characters' do
        it "should fail with complaint" do
          config[key] = SecureRandom.hex(33)
          expect { subnet }.to raise_error(Puppet::Error, /#{key} must be less that 65 characters in length/)
        end
      end
    end

    context 'with a blank virtual_network' do
      let :config do
        result = default_config
        result[:virtual_network] = ''
        result
      end

      it 'should be invalid' do
        expect { type_class.new(config) }.to raise_error(Puppet::ResourceError, /the virtual_network must not be empty/)
      end
    end


    it "should default ensure to present" do
      expect(subnet[:ensure]).to eq(:present)
    end
  end
end
