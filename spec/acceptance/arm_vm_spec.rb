require 'spec_helper_acceptance'

describe 'azure_vm when creating a machine with all available properties' do

  before(:all) do
    @config = {
      name: @name,
      ensure: 'present',
      image: 'canonical:ubuntuserver:14.04.2-LTS:latest',
      location: 'eastus',
      user: 'specuser',
      password: 'SpecPass123!@#$%',
      size: 'Standard_A0',
      name: 'spectestvm'

    }
    @template = 'azure_vm.pp.tmpl'
    @client = AzureARMHelper.new
    @manifest = PuppetManifest.new(@template, @config)
    @result = @manifest.execute
    @machine = @client.get_vm(@name).first
  end

  it 'should have the correct size' do
    expect(@machine.role_size).to eq(@config[:optional][:size])
  end


  context 'when looked for using puppet resource' do
    include_context 'a puppet resource run'
    puppet_resource_should_show('size')
    puppet_resource_should_show('location')
  end

  it_behaves_like 'a removable resource'
end
