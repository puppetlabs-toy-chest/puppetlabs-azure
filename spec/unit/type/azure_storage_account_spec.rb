require 'spec_helper'

describe 'azure_storage_account', :type => :type do
  let(:type_class) { Puppet::Type.type(:azure_storage_account) }

  let :params do
    [
      :name,
    ]
  end

  let :properties do
    [
      :ensure,
      :account_type,
      :sku_name,
      :account_kind,
      :access_tier,
      :https_traffic_only,
      :location,
      :tags,
      :resource_group,
    ]
  end

  let :default_config do
    {
      name: 'testsa',
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
    'sku_name',
    'account_kind',
    'resource_group',
  ].each do |property|
    it "should require #{property} to be a string" do
      expect(type_class).to require_string_for(property)
    end
  end

  context 'with a minimal set of properties' do
    let :config do
      default_config
    end

    let :storage_account do
      type_class.new(config)
    end

    it 'should be valid' do
      expect { storage_account }.to_not raise_error
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
          expect { storage_account }.to raise_error(Puppet::Error, /You must provide a #{key}/)
        end
      end
      it "should not fail with ensure => absent" do
        config.delete(key)
        config[:ensure] = :absent
        expect { storage_account }.to_not raise_error
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

    context 'with account_type instead of sku_name' do
      let :config do
        result = default_config
        result.delete(:sku_name)
        result[:account_type] = 'Standard_GRS'
        result
      end

      it 'should be invalid' do
        expect { type_class.new(config) }.to_not raise_error
      end
    end

    context 'with non-alpha characters in the name' do
      let :config do
        result = default_config
        result[:name] = 'Junk! Entry%'
        result
      end

      it 'should be invalid' do
        expect { type_class.new(config) }.to raise_error(Puppet::ResourceError, /name can contain only alphanumeric characters/)
      end
    end

    it "should default ensure to present" do
      expect(storage_account[:ensure]).to eq(:present)
    end

    it "should default account_kind to Storage" do
      expect(storage_account[:account_kind]).to eq(:Storage)
    end

    it "should default https_traffic_only to false" do
      expect(storage_account[:https_traffic_only]).to be_falsey
    end
  end
end
