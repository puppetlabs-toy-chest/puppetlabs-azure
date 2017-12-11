require 'spec_helper'

describe 'azure_network_security_group', :type => :type do
  let(:type_class) { Puppet::Type.type(:azure_network_security_group) }

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
      :guid,
      :default_security_rules,
      :security_rules,
      :network_interfaces,
      :subnets,
      :tags,
    ]
  end

  let :default_config do
    {
      name: 'testnsg',
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

  # Related resource arrays
  [
    'etag',
    'default_security_rules',
    'security_rules',
    'network_interfaces',
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

    let :nsg do
      type_class.new(config)
    end

    it 'should be valid' do
      expect { nsg }.to_not raise_error
    end

    [
      :name,
      :location,
      :resource_group,
    ].each do |property|
      context "with a #{property} greater than 64 characters" do
        it 'should be invalid' do
          config[:ensure] = :present
          config[property] = SecureRandom.hex(33)
          expect { type_class.new(config) }.to raise_error(Puppet::Error, /the #{property} must be between 1 and 64 characters long/)
        end
      end
    end

    [
      :location,
      :resource_group,
    ].each do |property|
      it "should require #{property} to be a string" do
        expect(type_class).to require_string_for(property)
      end
      context "when missing the #{property} property" do
        it "should fail with ensure => present" do
          config.delete(property)
          config[:ensure] = :present
          expect { nsg }.to raise_error(Puppet::Error, /You must provide a #{property}/)
        end
      end
      it "should not fail with ensure => absent" do
        config.delete(property)
        config[:ensure] = :absent
        expect { nsg }.to_not raise_error
      end
      context "with a blank #{property}" do
        it 'should be invalid' do
          config[:ensure] = :present
          config[property] = ''
          expect { type_class.new(config) }.to raise_error(Puppet::ResourceError, /the #{property} must not be empty/)
        end
      end
    end
  end
end
