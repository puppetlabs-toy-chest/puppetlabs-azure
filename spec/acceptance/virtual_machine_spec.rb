require 'spec_helper_acceptance'

describe 'azure_vm' do
  before(:all) do
    @client = AzureHelper.new
    @template = 'azure_vm.pp.tmpl'
  end

  context 'when creating a new machine' do
    before(:all) do
      @name = "CLOUD-#{SecureRandom.hex(8)}"
      # deploy the certificate to all the nodes, as the API requires local access to it.
      PuppetRunProxy.scp_to_ex(File.join(Dir.getwd, 'spec', 'acceptance', 'fixtures', 'insecure_private_key.pem'), '/tmp/id_rsa')

      config = {
        name: @name,
        ensure: 'present',
        optional: {
          image: 'b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-14_04_2-LTS-amd64-server-20150706-en-us-30GB',
          location: CHEAPEST_AZURE_LOCATION,
          user: 'foo',
          private_key_file: '/tmp/id_rsa',
        }
      }
      @manifest = PuppetManifest.new(@template, config)
      @result = @manifest.apply
      @machine = @client.get_virtual_machine(@name).first
    end

    after(:all) do
      @client.destroy_virtual_machine(@machine)
    end

    it 'should run without errors' do
      expect(@result.exit_code).to eq 2
    end

    it 'should exist after the first run' do
      # TODO: actually go back to the API to check for that
      expect(@machine).not_to eq (nil)
    end

    it 'should run a second time without changes' do
      second_result = @manifest.apply
      expect(second_result.exit_code).to eq 0
    end
  end
end
