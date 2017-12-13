require 'spec_helper_acceptance'

describe 'azure_vm when creating a machine with all available properties' do
  include_context 'with certificate copied to system under test for ARM'
  include_context 'with a known name and storage account name'
  include_context 'destroy left-over created ARM resources after use'

  before(:all) do
    @custom_data_file = '/tmp/needle'
    @extension_file = is_windows? ? '/cygdrive/c/extenionz.txt' : '/tmp/extensionz'

    @tag_seed = SecureRandom.hex(4)
    @resource_group_name = "ccresgroup#{@tag_seed}"
    @vnet_name = "ccvnet#{@tag_seed}"
    @subnet_name = "ccsubnet#{@tag_seed}"
    @vm_name = @name

    @config = {
      name: @vm_name,
      ensure: 'present',
      optional: {
        image: UBUNTU_IMAGE_ID,
        location: CHEAPEST_ARM_LOCATION,
        user: 'specuser',
        size: 'Standard_DS3_v2',
        resource_group: @resource_group_name,
        password: 'SpecPass123!@#$%',
        storage_account: @storage_account_name,
        storage_account_type: 'Standard_GRS',
        os_disk_name: 'osdisk01',
        os_disk_caching: 'ReadWrite',
        os_disk_create_option: 'FromImage',
        os_disk_vhd_container_name: 'conttest1',
        os_disk_vhd_name: 'osvhdtest1',
        dns_domain_name: "cloudspecdomain#{@tag_seed}",
        dns_servers: '8.8.8.8 8.8.4.4',
        public_ip_allocation_method: 'Dynamic',
        public_ip_address_name: "pubip_#{@tag_seed}",
        virtual_network_name: @vnet_name,
        custom_data: "touch #{@custom_data_file}",
        subnet_name: @subnet_name,
        subnet_address_prefix: '10.0.2.0/24',
        ip_configuration_name: "ip_config_#{@tag_seed}",
        private_ip_allocation_method: 'Dynamic',
        network_interface_name: "nicspec_#{@tag_seed}",
      },
      nonstring: {
        tags: {'mytag1' => 'tag1', 'mytag2' => 'tag2', 'tag_seed' => @tag_seed},
        extensions: {
          'CustomScriptForLinux' => {
            'auto_upgrade_minor_version' => true,
            'publisher'                  => 'Microsoft.Azure.Extensions',
            'type'                       => 'CustomScript',
            'type_handler_version'       => '2.0',
            'settings'                   => {
              'fileUris' => [],
              'commandToExecute' => "touch #{@extension_file}",
            }
          },
        },
      },
    }
    @config = {
      name: @name,
      ensure: 'present',
      optional: {
        image: UBUNTU_IMAGE_ID,
        location: CHEAPEST_ARM_LOCATION,
        user: 'specuser',
        size: 'Standard_DS3_v2',
        resource_group: @resource_group_name,
        password: 'SpecPass123!@#$%',
        storage_account: @storage_account_name,
        storage_account_type: 'Standard_GRS',
        os_disk_name: 'osdisk01',
        os_disk_caching: 'ReadWrite',
        os_disk_create_option: 'FromImage',
        os_disk_vhd_container_name: 'conttest1',
        os_disk_vhd_name: 'osvhdtest1',
        dns_domain_name: "cloudspecdomain#{@tag_seed}",
        dns_servers: '8.8.8.8 8.8.4.4',
        public_ip_allocation_method: 'Dynamic',
        public_ip_address_name: "pubip_#{@tag_seed}",
        virtual_network_name: @vnet_name,
        custom_data: "touch #{@custom_data_file}",
        subnet_name: @subnet_name,
        ip_configuration_name: "ip_config_#{@tag_seed}",
        private_ip_allocation_method: 'Dynamic',
        network_interface_name: "nicspec_#{@tag_seed}",
      }
    } if is_windows?

    @config_storage = {
      name: @storage_account_name,
      ensure: 'present',
      optional: {
        location: CHEAPEST_ARM_LOCATION,
        resource_group: @resource_group_name,
        sku_name: 'Standard_GRS',
        account_kind: 'Storage',
      },
    }

    @config_resg = {
      ensure: 'present',
      name: @resource_group_name,
      location: CHEAPEST_ARM_LOCATION
    }

    @config_vnet = {
      name: @vnet_name,
      ensure: 'present',
      location: CHEAPEST_ARM_LOCATION,
      resource_group: @resource_group_name,
      nonstring: {
        address_prefixes: ["10.0.2.0/24"],
        dns_servers: ["8.8.8.8","8.8.4.4"],
      }
    }

    @config_subnet = {
      name: @subnet_name,
      ensure: 'present',
      resource_group: @resource_group_name,
      virtual_network: @vnet_name,
      optional: {
        address_prefix: "10.0.2.0/24"
      }
    }
  end


  context 'when we create a resource group' do
    before(:all) do
      @temp = 'azure_resource_group.pp.tmpl'
      @client = AzureARMHelper.new
      @manifest = PuppetManifest.new(@temp, @config_resg)
      puts "Manifest #{@manifest.render}"
      @result = @manifest.execute
      @resource_group = @client.get_resource_group(@resource_group_name)
      @machine = @resource_group
      @name = @resource_group.name
    end

    it 'should run without errors' do
      expect(@result.exit_code).to eq 2
    end

    it_behaves_like 'an idempotent resource'

    it 'should exist' do
      expect(@resource_group).not_to be_nil
      expect(@resource_group.name). to eq(@resource_group_name)
    end
  end


  context 'when we create a storage account' do
    before(:all) do
      @temp = 'azure_storage_account.pp.tmpl'
      @client = AzureARMHelper.new
      @manifest = PuppetManifest.new(@temp, @config_storage)
      puts "Manifest #{@manifest.render}"
      @result = @manifest.execute
      @storage_account = @client.get_storage_account(@storage_account_name)
      @machine = @storage_account
      @name = @storage_account.name
      
    end

    it 'should run without errors' do
      expect(@result.exit_code).to eq 2
    end

    it_behaves_like 'an idempotent resource'
    
    it 'should exist' do
      expect(@storage_account).not_to be_nil
      expect(@storage_account.name). to eq(@storage_account_name)
    end
  end


  context 'when we create a vnet' do
    before(:all) do
      @temp = 'azure_vnet.pp.tmpl'
      @client = AzureARMHelper.new
      @manifest = PuppetManifest.new(@temp, @config_vnet)
      puts "Manifest #{@manifest.render}"
      @result = @manifest.execute
      @vnet = @client.get_virtual_network(@resource_group_name, @vnet_name)
      @machine = @vnet
      @name = @vnet.name
    end

    it 'should run without errors' do
      expect(@result.exit_code).to eq 2
    end

    it_behaves_like 'an idempotent resource'
    

    it 'should exist' do
      expect(@vnet).not_to be_nil
      expect(@vnet.name). to eq(@vnet_name)
    end
  end

  context 'when we create a subnet' do
    before(:all) do
      @temp = 'azure_subnet.pp.tmpl'
      @client = AzureARMHelper.new
      @manifest = PuppetManifest.new(@temp, @config_subnet)
      @result = @manifest.execute
      @subnet = @client.get_subnet(@resource_group_name, @vnet_name, @subnet_name)
      @machine = @subnet
      @name = @subnet.name
    end

    it 'should run without errors' do
      expect(@result.exit_code).to eq 2
    end

    it_behaves_like 'an idempotent resource'
    
    it 'should exist' do
      expect(@subnet).not_to be_nil
      expect(@subnet.name). to eq(@subnet_name)
    end
  end

  context 'when we create a vm' do
    before(:all) do
    @template = 'azure_vm.pp.tmpl'
    @client = AzureARMHelper.new
    @manifest = PuppetManifest.new(@template, @config)
    @result = @manifest.execute
    @machine = @client.get_vm(@vm_name)
    @name = @machine.name
    end

    it 'should run without errors' do
      expect(@result.exit_code).to eq 2
    end

    it_behaves_like 'an idempotent resource'

    it 'should have the correct name' do
      expect(@machine.name).to eq(@vm_name)
    end

    it 'should have the correct size' do
      expect(@machine.hardware_profile.vm_size).to eq(@config[:optional][:size])
    end

    it 'should be running' do
      expect(@client.vm_running?(@machine)).to be true
    end
    context 'when puppet resource is run' do
      include_context 'a puppet ARM resource run'
      puppet_resource_should_show('ensure', 'running')
      puppet_resource_should_show('location', CHEAPEST_ARM_LOCATION)
      puppet_resource_should_show('user')
      puppet_resource_should_show('size')
      puppet_resource_should_show('resource_group')
    end
  end

  context 'when we try and destroy the VM' do
    before(:all) do
      @template = 'azure_vm.pp.tmpl'
      config = @config.update({:ensure => 'absent'})
      manifest = PuppetManifest.new(@template, config)
      @client = AzureARMHelper.new
      @result = manifest.execute
      @machine = @client.get_vm(@vm_name)
    end

    it 'should run without errors' do
      expect(@result.exit_code).to eq 2
    end

    it 'should be destroyed' do
      expect(@machine).to be_nil
    end
  end

  context 'when we create a vm that has no public ip type method and generated vnet and subnet' do
    before(:all) do
      @config = {
        name: @vm_name,
        ensure: 'present',
        optional: {
          image: UBUNTU_IMAGE_ID,
          location: CHEAPEST_ARM_LOCATION,
          user: 'specuser',
          size: 'Standard_A0',
          resource_group: @resource_group_name,
          password: 'SpecPass123!@#$%',
          public_ip_allocation_method: 'None'
        }
      }

      @template = 'azure_vm.pp.tmpl'
      @client = AzureARMHelper.new
      @manifest = PuppetManifest.new(@template, @config)
      @result = @manifest.execute
      @machine = @client.get_vm(@vm_name)
    end

    it_behaves_like 'an idempotent resource'
    

    it 'should run without errors' do
      expect(@result.exit_code).to eq 2
    end

    it 'should have the correct name' do
      expect(@machine.name).to eq(@vm_name)
    end

    it 'should have the correct size' do
      expect(@machine.hardware_profile.vm_size).to eq(@config[:optional][:size])
    end
  end

  context 'when we try and destroy the VM' do
    before(:all) do
      @template = 'azure_vm.pp.tmpl'
      config = @config.update({:ensure => 'absent'})
      manifest = PuppetManifest.new(@template, config)
      @client = AzureARMHelper.new
      @result = manifest.execute
      @machine = @client.get_vm(@vm_name)
    end

    it 'should run without errors' do
      expect(@result.exit_code).to eq 2
    end

    it 'should be destroyed' do
      expect(@machine).to be_nil
    end
  end

  context 'when we try and destroy the resource group and network resources' do
    before(:all) do
      @client = AzureARMHelper.new
      
      # config = @config_subnet.update({:ensure => 'absent'})
      # @temp = 'azure_subnet.pp.tmpl'
      # @manifest = PuppetManifest.new(@temp, config)
      # @result = @manifest.execute
      # @subnet = @client.get_subnet(@resource_group_name, @vnet_name, @subnet_name)

      # config = @config_vnet.update({:ensure => 'absent'})
      # @temp = 'azure_vnet.pp.tmpl'
      # @manifest = PuppetManifest.new(@temp, config)
      # @result = @manifest.execute

      # config = @config_storage.update({:ensure => 'absent'})
      # @template = 'azure_storage_account.pp.tmpl'
      # @manifest = PuppetManifest.new(@template, config)
      # @result = @manifest.execute
      # @storage_account = @client.get_storage_account(@storage_account_name)

      config = @config_resg.update({:ensure => 'absent'})
      @temp = 'azure_resource_group.pp.tmpl'
      @manifest = PuppetManifest.new(@temp, config)
      @result = @manifest.execute
      @resource_group = @client.get_resource_group(@resource_group_name)
    end

    it 'should run without errors' do
      expect(@result.exit_code).to eq 2
    end

    it 'should have removed the storage account' do
      expect(@storage_account).to be_nil
    end

    it 'should have removed the resource group' do
      expect(@resource_group).to be_nil
    end
  end
end
