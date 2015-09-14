require 'spec_helper_acceptance'

describe 'azure_vm when creating a machine with all available properties' do
  include_context 'with certificate copied to system under test'
  include_context 'with a known name and storage account name'

  before(:all) do
    @custom_data_file = '/tmp/needle'

    @config = {
      name: @name,
      ensure: 'present',
      optional: {
        image: 'b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-14_04_2-LTS-amd64-server-20150706-en-us-30GB',
        location: CHEAPEST_AZURE_LOCATION,
        user: 'specuser',
        password: 'SpecPass123!@#$%',
        size: 'Medium',
        deployment: "CLOUD-DN-#{SecureRandom.hex(8)}",
        cloud_service: "CLOUD-CS-#{SecureRandom.hex(8)}",
        data_disk_size_gb: 53,
        purge_disk_on_delete: true,
        custom_data: "touch #{@custom_data_file}",
        storage_account: @storage_account_name,
      }
    }
    @manifest = <<PP #PuppetManifest.new(@template, @config)
azure_vm {
'#{@name}':
  ensure    => present,
  image     => '#{@config[:optional][:image]}',
  location  => '#{@config[:optional][:location]}',
  user      => '#{@config[:optional][:user]}',
  password  => '#{@config[:optional][:password]}',
  size      => '#{@config[:optional][:size]}',
  deployment           => '#{@config[:optional][:deployment]}',
  cloud_service        => '#{@config[:optional][:cloud_service]}',
  data_disk_size_gb    => #{@config[:optional][:data_disk_size_gb]},
  purge_disk_on_delete => #{@config[:optional][:purge_disk_on_delete]},
  custom_data          => #{@config[:optional][:custom_data]},
  storage_account      => '#{@config[:optional][:storage_account]}',
}
PP
    @result = PuppetRunProxy.execute(@manifest)
    @machine = @client.get_virtual_machine(@name).first
    @ip = @machine.ipaddress
  end

  it_behaves_like 'an idempotent resource'

  include_context 'destroy left-over created resources after use'

  it 'should have the correct size' do
    expect(@machine.role_size).to eq(@config[:optional][:size])
  end

  it 'should have the correct deployment name' do
    expect(@machine.deployment_name).to eq(@config[:optional][:deployment])
  end

  it 'should have the correct cloud service name' do
    expect(@machine.cloud_service_name).to eq(@config[:optional][:cloud_service])
  end

  describe 'the data disk' do
    it 'should be attached' do
      expect(@machine.data_disks.count).to eq 1
    end

    it 'should have the correct size' do
      expect(@machine.data_disks.first[:size_in_gb].to_i).to eq @config[:optional][:data_disk_size_gb]
    end
  end

  it 'is accessible using the password' do
    result = run_command_over_ssh('true', 'password')
    expect(result.exit_status).to eq 0
  end

  pending 'should be able to grow the disk on the fly'

  it 'should have run the custom data script' do
    # It's possible to get an SSH connection before cloud-init kicks in and sets the file.
    # so we retry this a few times
    5.times do
      @result = run_command_over_ssh("test -f #{@custom_data_file}", 'password', @config[:optional][:ssh_port])
      break if @result.exit_status == 0
      sleep 10
    end
    expect(@result.exit_status).to eq 0
  end

  it 'should be in the correct storage account' do
    storage_account = @client.get_storage_account(@config[:optional][:storage_account])
    expect(storage_account.label).to eq(@config[:optional][:cloud_service])
  end

  context 'which has read-only properties' do
    read_only = [
      :location,
      :deployment,
      :cloud_service,
      :size,
      :image,
    ]

    read_only.each do |new_config_value|
      it "should prevent change to read-only property #{new_config_value}" do
        config_clone = Marshal.load(Marshal.dump(@config))
        config_clone[:optional][new_config_value.to_sym] = 'foo'
        expect_failed_apply(config_clone)
      end
    end
  end

  context 'when looked for using puppet resource' do
    include_context 'a puppet resource run'
    puppet_resource_should_show('size')
    puppet_resource_should_show('deployment')
    puppet_resource_should_show('cloud_service')
  end

  it_behaves_like 'a removable resource'
end
