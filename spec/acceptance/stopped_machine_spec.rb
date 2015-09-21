require 'spec_helper_acceptance'

describe 'azure_vm when creating a new machine in a stopped state' do
  include_context 'with certificate copied to system under test'

  before(:all) do
    @name = "CLOUD-#{SecureRandom.hex(8)}"

    @config = {
      name: @name,
      ensure: 'stopped',
      optional: {
        image: 'b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-14_04_2-LTS-amd64-server-20150706-en-us-30GB',
        location: CHEAPEST_AZURE_LOCATION,
        user: 'specuser',
        private_key_file: @remote_private_key_path,
      }
    }
    @manifest = PuppetManifest.new(@template, @config)
    @result = @manifest.execute
    @machine = @client.get_virtual_machine(@name).first
  end

  it_behaves_like 'an idempotent resource'

  include_context 'destroy left-over created resources after use'

  it 'should be stopped' do
    expect(@machine.status).to eq('StoppedDeallocated')
  end
end
