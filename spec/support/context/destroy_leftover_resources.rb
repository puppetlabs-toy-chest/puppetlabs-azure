shared_context 'destroy left-over created resources after use' do
  after(:all) do
    # Some tests remove the VM themselves. This check avoids a error message in that case
    unless @client.get_virtual_machine(@machine.vm_name).empty?
      @client.destroy_virtual_machine(@machine)
      (@machine.data_disks.map { |h| h[:name] } + [ @machine.disk_name ]).each do |disk_name|
        @client.destroy_disk(disk_name)
      end
    end
    while @client.get_cloud_service(@machine) do
      puts "The cloud service #{@machine.cloud_service_name} has not been deleted yet. Sleeping for 10 seconds..."
      sleep 10
    end
    @client.destroy_storage_account(@storage_account_name) if @client.get_storage_account(@storage_account_name)
    while @client.get_storage_account(@storage_account_name) do
      puts "The storage account #{@storage_account_name} has not been deleted yet. Sleeping for 10 seconds..."
      sleep 10
    end
  end
end

shared_context 'destroy left-over created ARM resources after use' do
  after(:all) do
    # Some tests remove the VM themselves. This check avoids a error message in that case
    if @client
      if @machine
        @client.destroy_vm(@machine) unless @client.get_vm(@machine).nil?
      end
      @client.destroy_resource_group(
        @config[:optional][:resource_group]
      ) if @client.get_resource_group(@config[:optional][:resource_group])
      @client.destroy_storage_account(
        @config[:optional][:resource_group],
        @config[:optional][:storage_account]
      ) if @client.get_storage_account(@config[:optional][:storage_account])
    end
  end
end
