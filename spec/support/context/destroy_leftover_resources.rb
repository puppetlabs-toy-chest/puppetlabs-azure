shared_context 'destroy left-over created resources after use' do
  after(:all) do
    # Some tests remove the VM themselves. This check avoids a error message in that case
    if @client.get_virtual_machine(@machine.vm_name)
      @client.destroy_virtual_machine(@machine)
      (@machine.data_disks.map(&:name) + [ @machine.disk_name ]).each do |disk_name|
        @client.destroy_disk(disk_name)
      end
    end
  end
end
