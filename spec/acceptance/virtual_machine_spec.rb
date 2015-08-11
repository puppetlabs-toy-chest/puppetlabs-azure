require 'spec_helper_acceptance'

describe 'azure_vm' do
  def get_virtual_machine(name)
    azureHelper = AzureHelper.new
    vm = azureHelper.get_virtual_machine(name)
    expect(vm).not_to be_nil
    vm.first
  end

  describe 'should create a new instance' do
    it "Initial stub test" do
      expect(get_virtual_machine('fauximage')).not_to eq (nil)
    end
  end
end
