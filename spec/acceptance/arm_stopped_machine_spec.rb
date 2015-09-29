require 'spec_helper_acceptance'

describe 'azure_vm when creating a stopped machine with minimal properties' do
  include_context 'with a known name and storage account name'

  before(:all) do
    @config = {
      name: @name,
      ensure: 'stopped',
      optional: {
        image: 'canonical:ubuntuserver:14.04.2-LTS:latest',
        location: 'eastus',
        user: 'specuser',
        password: 'SpecPass123!@#$%',
        size: 'Standard_A0',
        resource_group: 'puppet-acceptance-tests',
        storage_account: @storage_account_name,
      },
    }
    @template = 'azure_vm.pp.tmpl'
    @client = AzureARMHelper.new
    @manifest = PuppetManifest.new(@template, @config)
    @result = @manifest.execute
    @machine = @client.get_vm(@name)
  end

  it_behaves_like 'an idempotent resource'
  #it_behaves_like 'a removable ARM resource'

  it 'should run without errors' do
    expect(@result.exit_code).to eq 2
  end

  it 'should exist' do
    expect(@machine.name).to eq(@name)
  end

  it 'should have the correct size' do
    expect(@machine.properties.hardware_profile.vm_size).to eq(@config[:optional][:size])
  end

  it 'should be stopped' do
    expect(@client.vm_stopped(@name)).to be true
  end


  context 'when looked for using puppet resource' do
    include_context 'a puppet ARM resource run'
    puppet_resource_should_show('ensure', 'stopped')
  end

  context 'starting the machine' do
    before(:all) do
      new_config = @config.update({:ensure => 'running'})
      @manifest = PuppetManifest.new(@template, new_config)
      @result = @manifest.execute
      @stopped_machine = @client.get_vm(@name).first
    end

    it_behaves_like 'an idempotent resource'

    it 'should run without errors' do
      expect(@result.exit_code).to eq 2
    end

    it 'should be started' do
      expect(@client.vm_running(@name)).to be true
    end

    context 'when looked for using puppet resource' do
      include_context 'a puppet ARM resource run'
      puppet_resource_should_show('ensure', 'running')
    end
  end
end
