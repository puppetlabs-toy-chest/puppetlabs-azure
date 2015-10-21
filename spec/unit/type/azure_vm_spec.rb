require 'spec_helper'

describe 'azure_vm', :type => :type do
  let(:type_class) { Puppet::Type.type(:azure_vm) }

  let :params do
    [
      :user,
      :password,
      :name,
    ]
  end

  let :properties do
    [
      :ensure,
      :location,
      :image,
      :size,
    ]
  end

  let :read_only_properties do
    [
      :ipaddress,
      :hostname,
    ]
  end

  it 'should have expected properties' do
    expect(type_class.properties.map(&:name)).to include(*(properties + read_only_properties))
  end

  it 'should have expected parameters' do
    expect(type_class.parameters).to include(*params)
  end

  it 'should not have unexpected properties' do
    expect(properties + read_only_properties).to include(*type_class.properties.map(&:name))
  end

  it 'should not have unexpected parameters' do
    expect(params + [:provider]).to include(*type_class.parameters)
  end

  [
    'location',
    'image',
    'user',
    'password',
    'size',
  ].each do |property|
    it "should require #{property} to be a string" do
      expect(type_class).to require_string_for(property)
    end
  end

  [
    :ipaddress,
    :hostname,
  ].each do |property|
    it "should require #{property} to be read only" do
      expect(type_class).to be_read_only(property)
    end
  end

  it 'should default ensure to present' do
    machine = type_class.new(
      name: 'testvm',
      size: 'Standard_A0',
      location: 'eastus',
      user: 'specuser',
      password: 'Pa55wd!'
    )
    expect(machine[:ensure]).to eq(:present)
  end

  context 'with a minimal set of properties' do
    let :config do
      {
        ensure: :present,
        name: 'image-test',
        location: 'eastus',
        size: 'Standard_A0',
        image: 'image-name',
        user: 'specuser',
        password: 'Pa55wd!'
      }
    end

    let :machine do
      type_class.new(config)
    end

    it 'should be valid' do
      expect { machine }.not_to raise_error
    end

    it 'should alias running to present for ensure values' do
      expect(machine.property(:ensure).insync?(:running)).to be true
    end

    context 'when out of sync' do
      it 'should report actual state if desired state is present, as present is overloaded' do
        expect(machine.property(:ensure).change_to_s(:running, :present)).to eq(:running)
      end

      it 'if current and desired are the same then should report value' do
        expect(machine.property(:ensure).change_to_s(:stopped, :stopped)).to eq(:stopped)
      end

      it 'if current and desired are different should report change' do
        expect(machine.property(:ensure).change_to_s(:stopped, :running)).to eq('changed stopped to running')
      end
    end

    [
      :location,
    ].each do |key|
      context "when missing the #{key} property" do
        it "should fail" do
          config.delete(key)
          expect { machine }.to raise_error(Puppet::Error, /You must provide a #{key}/)
        end
      end
    end
  end

  context 'with ensure set to stopped' do
    let :config do
      {
        ensure: :stopped,
        name: 'testvm',
        location: 'eastus',
        size: 'Standard_A0',
        user: 'specuser',
        password: 'Pa55wd!'
      }
    end

    it 'should acknowledge stopped machines to be present' do
      expect(type_class.new(config).property(:ensure).insync?(:stopped)).to be true
    end
  end


  context 'with a image specified' do
    let :config do
      {
        ensure: :present,
        name: 'testvm',
        location: 'eastus',
        size: 'Standard_A0',
        user: 'specuser',
        password: 'Pa55wd!'
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
        name: 'loc-test',
        location: 'eastus',
        size: 'Standard_A0',
        user: 'specuser',
        password: 'Pa55wd!'
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
        name: 'blank-loc-test',
        location: '',
        size: 'Standard_A0',
        user: 'specuser',
        password: 'Pa55wd!'
      }
    end

    it 'should be invalid' do
      expect { type_class.new(config) }.to raise_error(Puppet::Error, /the location must not be empty/)
    end
  end

  context 'with no location' do
    let :config do
      {
        ensure: :present,
        name: 'inv-loc-test',
        size: 'Standard_A0',
        user: 'specuser',
        password: 'Pa55wd!'
      }
    end

    it 'should be invalid' do
      expect { type_class.new(config) }.to raise_error(Puppet::Error, /You must provide a location/)
    end
  end

  context 'with no size' do
    let :config do
      {
        ensure: :present,
        name: 'nosize-test',
        location: 'eastus',
        user: 'specuser',
        password: 'Pa55wd!'
      }
    end

    it 'should be invalid' do
      expect { type_class.new(config) }.to raise_error(Puppet::Error, /You must provide a size/)
    end
  end

  context 'with a blank size' do
    let :config do
      {
        ensure: :present,
        name: 'size-test',
        location: 'eastus',
        size: '',
        user: 'specuser',
        password: 'Pa55wd!'
      }
    end

    it 'should be invalid' do
      expect { type_class.new(config) }.to raise_error(Puppet::Error, /the size must not be empty/)
    end
  end

  context 'with no password' do
    let :config do
      {
        ensure: :present,
        name: 'disk-test',
        location: 'eastus',
        size: 'Standard_A0',
        user: 'specuser',
      }
    end

    it 'should be invalid' do
      expect { type_class.new(config) }.to raise_error(Puppet::Error, /You must provide a password for an Azure VM/)
    end
  end

  context 'with a blank password' do
    let :config do
      {
        ensure: :present,
        name: 'disk-test',
        location: 'eastus',
        size: 'Standard_A0',
        user: 'specuser',
        password: '',
      }
    end

    it 'should be invalid' do
      expect { type_class.new(config) }.to raise_error(Puppet::Error, /The VM password may not be blank/)
    end
  end
end
