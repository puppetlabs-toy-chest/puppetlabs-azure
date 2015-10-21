require 'spec_helper'

provider_class = Puppet::Type.type(:azure_vm).provider(:azure_arm)

describe provider_class do
  let(:resource) do
    Puppet::Type.type(:azure_vm).new(
      name: 'spectestvm',
      location: 'eastus',
      size: 'Standard_A0',
      password: 'Pa55wd!',
      user: 'specuser',
    )
  end

  let(:provider) { resource.provider }

  it 'should be an instance of the correct provider' do
    expect(provider).to be_an_instance_of Puppet::Type::Azure_vm::ProviderAzure_arm
  end

  [:compute_client, :get_all_vms, :read_only].each do |method|
    it "should respond to the class method #{method}" do
      expect(provider_class).to respond_to(method)
    end
  end

  [:exists?, :create, :destroy, :running?, :stopped?, :start, :stop].each do |method|
    it "should respond to the instance method #{method}" do
      expect(provider_class.new).to respond_to(method)
    end
  end
end
