require 'spec_helper_acceptance'

describe 'azure_vm when creating a machine with all available properties' do
  before(:all) do
    @name = 'spectestvm'
    @config = {
      name: @name,
      ensure: 'present',
      optional: {
        image: 'xxx:xxx:xxx:xxx',
        location: 'eastus',
        user: 'specuser',
        password: 'SpecPass123!@#$%',
        size: 'Standard_A0',
        resource_group: 'puppettestresacc01',
        storage_account: 'puppetteststoracc01',
      },
    }
    @template = 'azure_vm.pp.tmpl'
    @client = AzureARMHelper.new
    @manifest = PuppetManifest.new(@template, @config)
    @result = @manifest.execute
    @machine = @client.get_vm(@name)
  end

  it 'should run with errors' do
    expect(@result.exit_code).to eq 4
  end

  it 'should not exist' do
    expect(@machine).to be_empty
  end

  it 'should return an exception' do
    expect(@result.stderr.include?('MsRestAzure::AzureOperationError')).to be true
  end
end
