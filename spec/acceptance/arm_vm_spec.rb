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
        storage_account_type: 'Standard_GRS',
        os_disk_name: 'myosdisk01',
        os_disk_caching: 'ReadWrite',
        os_disk_create_option: 'fromImage',
        os_disk_vhd_container_name: 'conttest1',
        os_disk_vhd_name: 'vhdtest1',
        dns_domain_name: 'mydomain01',
        dns_servers: '10.1.1.1 10.1.2.4',
        public_ip_allocation_method: 'Dynamic',
        public_ip_address_name: 'ip_name_test01pubip',
        virtual_network_name: 'vnettest01',
        virtual_network_address_space: '10.0.0.0/16',
        subnet_name: 'subnet111',
        subnet_address_prefix: '10.0.2.0/24',
        ip_configuration_name: 'ip_config_test01',
        private_ipallocation_method: 'Dynamic',
        network_interface_name: 'nicspec01',
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
    puppet_resource_should_show('location', @config[:location])
    puppet_resource_should_show('image', @config[:image])
    puppet_resource_should_show('user', @config[:user])
    puppet_resource_should_show('size', @config[:size])
    puppet_resource_should_show('resource_group', @config[:resource_group])
  end

  it 'it should destroy the vm' do
    before(:all) do
      it 'should be running' do
        @running_machine = @client.get_vm(@name)
        expect(@running_machine).to be('Running')
      end

      new_config = @config.update({:ensure => 'absent'})
      @manifest = PuppetManifest.new(@template, new_config)
      @result = @manifest.execute
      @machine = @client.get_vm(@name)
    end

    it_behaves_like 'an idempotent resource'

    it 'should run without errors' do
      expect(@result.exit_code).to eq 2
    end

    it 'should be destroyed' do
      expect(@machine).to be_empty
    end
  end

  after(:all) do
    it_behaves_like 'a removable ARM resource'
  end
end
