require 'spec_helper'

provider_class = Puppet::Type.type(:azure_vm).provider(:azure_sdk)

describe provider_class do

  let(:resource) {
    Puppet::Type.type(:azure_vm).new(
      name: 'name',
    )
  }

  let(:provider) { resource.provider }

  it 'should be an instance of the correct provider' do
    expect(provider).to be_an_instance_of Puppet::Type::Azure_vm::ProviderAzure_sdk
  end

  [:vm_manager, :list_vms, :read_only, :machine_to_hash, :prefetch].each do |method|
    it "should respond to the class method #{method}" do
      expect(provider_class).to respond_to(method)
    end
  end

  [:exists?, :create, :destroy].each do |method|
    it "should respond to the instance method #{method}" do
      expect(provider_class.new).to respond_to(method)
    end
  end

  it 'should have a prefetch which triggers a call to instances' do
    expect(provider_class).to receive(:instances).and_return([])
    provider_class.prefetch({})
  end

end
