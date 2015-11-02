require 'spec_helper_acceptance'

describe 'azure_vm when creating a machine with all available properties' do
  before(:all) do
    @name = 'spectestvm'
    @config = {
      name: @name,
      ensure: 'present',
      optional: {
        image: 'canonical:ubuntuserver:14.04.2-LTS:latest',
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

  it_behaves_like 'an idempotent resource'

  it 'should run without errors' do
    expect(@result.exit_code).to eq 2
  end

  it 'should exist' do
    expect(@machine.name).to eq(@name)
  end

  it 'should have the correct size' do
    expect(@machine.properties.hardware_profile.vm_size).to eq(@config[:optional][:size])
  end

  it 'should stop on command' do
    result = @client.stop_vm(@config[:optional][:resource_group], @name)
    contains_succeeded = result.include? 'Succeeded'
    expect(contains_succeeded).to be true
  end

  it 'should start on command' do
    result = @client.start_vm(@config[:optional][:resource_group], @name)
    contains_succeeded = result.include? 'Succeeded'
    expect(contains_succeeded).to be true
  end

  it_behaves_like 'a removable resource'
end
