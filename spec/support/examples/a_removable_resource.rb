shared_examples 'a removable resource' do
  describe 'setting ensure => absent' do
    before(:all) do
      @disk_names = @machine.data_disks.map { |h| h[:name] }
      @disk_names << @machine.disk_name
      @config = {
        name: @name,
        ensure: 'absent',
        optional: {
          location: @config[:optional][:location],
          deployment: @config[:optional][:deployment],
          cloud_service: @config[:optional][:cloud_service],
          purge_disk_on_delete: true,
        }
      }
      @manifest = <<PP
azure_vm {
  '#{@name}':
    ensure    => absent,
    location  => '#{@config[:optional][:location]}',
    deployment => '#{@config[:optional][:deployment]}',
    cloud_service => '#{@config[:optional][:cloud_service]}',
    purge_disk_on_delete => #{@config[:optional][:purge_disk_on_delete]},
}
PP
      @result = PuppetRunProxy.execute(@manifest)
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
