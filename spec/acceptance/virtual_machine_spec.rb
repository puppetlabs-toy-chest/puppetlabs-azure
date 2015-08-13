require 'spec_helper_acceptance'

describe 'azure_vm' do
  before(:all) do
    @client = AzureHelper.new
    @template = 'azure_vm.pp.tmpl'
  end

  def get_virtual_machine(name)
    vm = @client.get_virtual_machine(name)
    expect(vm).not_to be_nil
    vm.first
  end

  describe 'should be able to create a new machine' do
    before(:all) do
      @name = "CLOUD-#{SecureRandom.hex(8)}"
      insecure_private_key = File.join(Dir.getwd, 'spec', 'acceptance', 'fixtures', 'insecure_private_key.pem')

      config = {
        name: @name,
        ensure: 'present',
        optional: {
          image: 'b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-14_04_2-LTS-amd64-server-20150706-en-us-30GB',
          location: 'West US',
          user: 'foo',
          private_key_file: insecure_private_key,
        }
      }
      PuppetManifest.new(@template, config).apply
      @machine = get_virtual_machine(@name)
    end

    after(:all) do
      @client.destroy_virtual_machine(@machine)
    end

    it "that exists" do
      expect(@machine).not_to eq (nil)
    end
  end
end
