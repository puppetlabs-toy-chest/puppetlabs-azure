require 'spec_helper_acceptance'

describe 'azure_vm when creating a stopped machine with minimal properties' do
  before(:all) do
    @name = 'stoptestvm'
    @config = {
      name: @name,
      ensure: 'stopped',
      optional: {
        image: 'canonical:ubuntuserver:14.04.2-LTS:latest',
        location: 'eastus',
        user: 'specuser',
        password: 'SpecPass123!@#$%',
        size: 'Standard_A0',
        resource_group: 'puppettestresacc02',
        storage_account: 'puppettestresacc02',
      },
    }
    @template = 'azure_vm.pp.tmpl'
    @client = AzureARMHelper.new
    @manifest = PuppetManifest.new(@template, @config)
    @result = @manifest.execute
    @machine = @client.get_vm(@name).first
  end

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
    state = @client.vm_stopped(@name)
    expect(state).to be true
  end

  it_behaves_like 'an idempotent resource'

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
      state = @client.vm_running(@name)
      expect(state).to be true
    end

    context 'when looked for using puppet resource' do
      include_context 'a puppet ARM resource run'
      puppet_resource_should_show('ensure', 'running')
    end

    context 'restarting the machine' do
      before(:all) do
        new_config = @config.update({:ensure => 'running'})
        @manifest = PuppetManifest.new(@template, new_config)
        @result = @manifest.execute
        @started_machine = @client.get_vm(@name).first
      end

      it_behaves_like 'an idempotent resource'

      it 'should be started' do
        state = @client.vm_running(@name)
        expect(state).to be true
      end

      it 'should run without errors' do
        expect(@result.exit_code).to eq 2
      end

      context 'when looked for using puppet resource' do
        include_context 'a puppet ARM resource run'
        puppet_resource_should_show('ensure', 'running')
      end
    end
  end

  after(:all) do
    it_behaves_like 'a removable ARM resource'
  end
end
