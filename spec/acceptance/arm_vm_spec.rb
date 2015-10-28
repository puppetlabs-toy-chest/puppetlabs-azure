require 'spec_helper_acceptance'

require 'pry'

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

  after(:all) do
    @config[:ensure] = 'absent'
    @manifest = PuppetManifest.new(@template, @config)
    @result = @manifest.execute
    expect(@result.exit_code).to eq 2
    @machine = @client.get_vm(@name)
    expect(@machine).to be_nil

    @client.destroy_resource_group(@config[:optional][:resource_group]) if @client.get_resource_group(@config[:optional][:resource_group])
    expect(@client.get_resource_group(@config[:optional][:resource_group])).to be_nil
    @client.destroy_storage_account(@config[:optional][:storage_account], @config[:optional][:resource_group]) if @client.get_storage_account(@config[:optional][:storage_account])
    expect(@client.get_storage_account(@config[:optional][:storage_account])).to be_nil
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
end
