shared_examples 'a removable resource' do
  describe 'setting ensure => absent' do
    before(:all) do
      @disk_names = @machine.data_disks.map { |h| h[:name] }
      @disk_names << @machine.disk_name
      old_config = @config
      @config = {
        name: @name,
        ensure: 'absent',
        optional: {
          location: old_config[:optional][:location],
          deployment: old_config[:optional][:deployment],
          cloud_service: old_config[:optional][:cloud_service],
          purge_disk_on_delete: true,
        }
      }

      @manifest = PuppetManifest.new(@template, @config)
      @result = @manifest.execute
    end

    # note that @machine is still set to the "original" azure instance, making the "should exist" test here useless
    it_behaves_like 'an idempotent resource'

    it 'has removed the VM' do
      expect(@client.get_virtual_machine(@name)).to be_empty
    end

    it 'cleans up the disks' do
      remaining_disks = @disk_names.map { |name| @client.get_disk(name) }.compact
      expect(remaining_disks).to be_empty
    end
  end
end

shared_examples 'a removable ARM resource' do
  describe 'setting ensure => absent' do
    before(:all) do
      old_config = @config
      @config = {
        name: @name,
        ensure: 'absent',
        optional: {
          resource_group: old_config[:optional][:resource_group],
          storage_account: old_config[:optional][:storage_account],
        }
      }

      @manifest = PuppetManifest.new(@template, @config)
      @result = @manifest.execute
    end

    # note that @machine is still set to the "original" azure instance, making the "should exist" test here useless
    it_behaves_like 'an idempotent resource'

    it 'has removed the VM' do
      expect(@client.get_vm(@name)).to be_empty
    end

    it 'cleans up the resource group' do
      @client.destroy_resource_group(@config[:optional][:resource_group])
      expect(@client.get_resource_group(@config[:optional][:resource_group])).to be_nil
    end

    it 'cleans up the storage account' do
      @client.destroy_storage_account(@config[:optional][:storage_account], @config[:optional][:resource_group])
      expect(@client.get_storage_account(@config[:optional][:storage_account])).to be_nil
    end
  end
end
