require 'spec_helper'

type_class = Puppet::Type.type(:azure_vm)

describe type_class do
  let :params do
    [
      :name,
      :image,
      :user,
      :password,
      :private_key_file,
    ]
  end

  let :properties do
    [
      :ensure,
      :location,
      :storage_account,
      :winrm_transport,
      :winrm_https_port,
      :winrm_http_port,
      :cloud_service,
      :deployment,
      :ssh_port,
      :vm_size,
      :affinity_group,
      :virtual_network,
      :subnet,
      :availability_set,
      :reserved_ip,
      :disks,
      :endpoints,
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
    expect do
      type_class.new({})
    end.to raise_error(Puppet::Error, 'Title or name must be provided')
  end

  [
    'name',
    'image',
    'user',
    'password',
    'private_key_file',
    'location',
    'storage_account',
    'winrm_transport',
    'cloud_service',
    'deployment',
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
      expect do
        config = {name: 'sample'}
        config[property] = 0
        type_class.new(config)
      end.to raise_error(Puppet::Error, /#{property} should be greater than 0/)
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

  context 'with a password and a private key file' do
    let :config do
      {
        ensure: :present,
        name: 'image-test',
        password: 'no-a-real-password',
        private_key_file: '/not/a/real/private.key',
      }
    end

    it 'should be invalid' do
      expect { type_class.new(config) }.to raise_error(Puppet::Error, /You can only provide either a password or a private_key_file for an Azure VM/)
    end
  end

  context 'with a image specified' do
    let :config do
      {
        ensure: :present,
        name: 'image-test',
        location: 'West US',
        image: 'image-name',
      }
    end

    it 'should be valid' do
      expect { type_class.new(config) }.to_not raise_error
    end

    it "should require image to have a value" do
      expect do
        config[:image] = ''
        type_class.new(config)
      end.to raise_error(Puppet::Error, /the image name must not be empty/)
    end
  end

  context 'with a location' do
    let :config do
      {
        ensure: :present,
        name: 'disk-test',
        location: 'West US',
      }
    end

    it 'should be valid' do
      expect { type_class.new(config) }.to_not raise_error
    end
  end

  context 'with a blank location' do
    let :config do
      {
        ensure: :present,
        name: 'disk-test',
        location: '',
      }
    end

    it 'should be invalid' do
      expect { type_class.new(config) }.to raise_error(Puppet::Error)
    end
  end

  context 'with no location' do
    let :config do
      {
        ensure: :present,
        name: 'disk-test',
      }
    end

    it 'should be invalid' do
      expect { type_class.new(config) }.to raise_error(Puppet::Error)
    end
  end

  context 'with a disk specified' do
    let :config do
      {
        ensure: :present,
        name: 'disk-test',
        location: 'West US',
        disks: {
          label: 'disk-label',
          size: 100,
          import: false,
          name: 'disk-name',
        }
      }
    end

    it 'should be valid' do
      expect { type_class.new(config) }.to_not raise_error
    end

    [:label, :size].each do |key|
      it "should require disk to have a #{key} key" do
        expect do
          config[:disks].delete(key)
          type_class.new(config)
        end.to raise_error(Puppet::Error, /for disks you are missing the following keys: #{key}/)
      end
    end

    it "should require disk size to be an integer" do
      expect do
        config[:disks][:size] = 'invalid'
        type_class.new(config)
      end.to raise_error(Puppet::Error, /size for disks should be an Integer/)
    end

    it 'should require disk import to be true or false if set' do
      expect do
        config[:disks][:import] = 'invalid'
        type_class.new(config)
      end.to raise_error(Puppet::Error, /import for disks must be true or false/)
    end

    [true, false].each do |bool|
      it "should allow import to be #{bool}" do
        expect do
          config[:disks][:import] = bool
          type_class.new(config)
        end.to_not raise_error
      end
    end

    it 'when import is true should require name to be specified for disk' do
      expect do
        config[:disks][:import] = true
        config[:disks].delete(:name)
        type_class.new(config)
      end.to raise_error(Puppet::Error, /if import is true a name must be provided for disks/)
    end
  end

  context 'with an endpoint specified' do
    let :config do
      {
        ensure: :present,
        name: 'endpoint-test',
        location: 'West US',
        endpoints: {
          name: 'ep-1',
          public_port: 996,
          local_port: 998,
          protocol: 'TCP',
        }
      }
    end

    it 'should be valid' do
      expect { type_class.new(config) }.to_not raise_error
    end

    [:name, :public_port, :local_port, :protocol].each do |key|
      it "should require endpoint to have a #{key} key" do
        expect do
          config[:endpoints].delete(key)
          type_class.new(config)
        end.to raise_error(Puppet::Error, /for endpoints you are missing the following keys: #{key}/)
      end
    end

    [:local_port, :public_port].each do |port|
      it "should require endpoint #{port} to be an integer" do
        expect do
          config[:endpoints][port] = 'invalid'
          type_class.new(config)
        end.to raise_error(Puppet::Error, /#{port} for endpoints should be an Integer/)
      end
    end
  end
end
