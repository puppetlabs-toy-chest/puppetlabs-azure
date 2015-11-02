require 'spec_helper_acceptance'

describe 'azure_vm when creating a machine with minimal properties' do
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

  context 'when looked for using puppet resource' do
    include_context 'a puppet resource run'
    puppet_resource_should_show('location')
    puppet_resource_should_show('image')
    puppet_resource_should_show('user')
    puppet_resource_should_show('size')
    puppet_resource_should_show('resource_group')
  end

  it 'it should stop the vm' do
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
          resource_group: 'puppettestresacc01',
          storage_account: 'puppetteststoracc01',
        },
      }
      @manifest = PuppetManifest.new(@template, @config)
      @result = @manifest.execute
      @machine = @client.get_virtual_machine(@name).first
    end

    it_behaves_like 'an idempotent resource'

    it 'should be stopped' do
      expect(@machine.status).to eq('StoppedDeallocated')
    end
  end

  it 'it should start the vm' do
    before(:all) do
      @config = {
        name: @name,
        ensure: 'start',
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
      @manifest = PuppetManifest.new(@template, @config)
      @result = @manifest.execute
      @machine = @client.get_virtual_machine(@name).first
    end

    it_behaves_like 'an idempotent resource'

    it 'should be stopped' do
      expect(@machine.status).to eq('Started')
    end
  end

  it 'it should destroy the vm' do
    before(:all) do
      @config = {
        name: @name,
        ensure: 'absent',
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
      @manifest = PuppetManifest.new(@template, @config)
      @result = @manifest.execute
      @machine = @client.get_virtual_machine(@name).first
    end

    it_behaves_like 'an idempotent resource'

    it 'should not exist' do
      expect(@machine).to be_empty
    end
  end

  after(:all) do
    it_behaves_like 'a removable ARM resource'
  end
end
