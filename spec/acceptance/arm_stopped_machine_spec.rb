require 'spec_helper_acceptance'

describe 'azure_vm when creating a stopped machine with minimal properties' do
  before(:all) do
    @name = 'spectestvm'
    @config = {
      name: @name,
      ensure: 'stopped',
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

  it 'should be in the correct state' do
    expect(@machine.status).to eq('Stopped')
  end

  context 'when looked for using puppet resource' do
    include_context 'a puppet resource run'
    puppet_resource_should_show('ensure', 'Stopped')
    puppet_resource_should_show('location', @config[:location])
    puppet_resource_should_show('image', @config[:image])
    puppet_resource_should_show('user', @config[:user])
    puppet_resource_should_show('size', @config[:size])
    puppet_resource_should_show('resource_group', @config[:resource_group])
  end

  context 'starting the machine' do
    before(:all) do
      new_config = @config.update({:ensure => 'stopped'})
      @manifest = PuppetManifest.new(@template, new_config)
      @result = @manifest.execute
      @stopped_machine = @client.get_vm(@name)
    end

    it_behaves_like 'an idempotent resource'

    it 'should be stopped' do
      expect(@stopped_machine.status).to eq('StoppedDeallocated')
    end

    it 'should run without errors' do
      expect(@result.exit_code).to eq 2
    end

    it 'should be in the correct state' do
      expect(@machine.status).to eq('Runnning')
    end

    context 'when looked for using puppet resource' do
      include_context 'a puppet resource run'
      puppet_resource_should_show('ensure', 'Started')
    end

    context 'restarting the machine' do
      before(:all) do
        new_config = @config.update({:ensure => 'running'})
        @manifest = PuppetManifest.new(@template, new_config)
        @result = @manifest.execute
        @started_machine = @client.get_vm(@name)
      end

      it_behaves_like 'an idempotent resource'

      it 'should not be stopped' do
        # Machines first enter an unknown state (RoleStateUnknown) before being
        # marked as ready (ReadyRole). This can take time so rather than always
        # wait for ready we're happy that we've changed the machine from stopped.
        expect(@started_machine.status).not_to eq('StoppedDeallocated')
      end

      it 'should run without errors' do
        expect(@result.exit_code).to eq 2
      end

      context 'when looked for using puppet resource' do
        include_context 'a puppet resource run'
        puppet_resource_should_show('ensure', 'Started')
      end
    end
  end

  after(:all) do
    it_behaves_like 'a removable ARM resource'
  end
end
