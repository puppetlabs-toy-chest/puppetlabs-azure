require 'spec_helper_acceptance'

describe 'azure_vm_classic when creating a multirole services' do
  include_context 'with certificate copied to system under test'
  include_context 'with a known name and storage account name'
  include_context 'with known network'

  before(:all) do
    @second_name = @name[0..-2] + "2nd"
    @third_name = @name[0..-2] + "3rd"

    @config = {
      name: @name,
      ensure: 'present',
      optional: {
        image: UBUNTU_IMAGE,
        location: 'East US',
        user: 'specuser',
        password: '11TestManner!',
        size: 'Medium',
        storage_account: @storage_account_name, # required in order to tidy up created storage groups
        virtual_network: @virtual_network_name,
        cloud_service: SPEC_CLOUD_SERVICE,
        purge_disk_on_delete: true,
        subnet: @network.subnets.first[:name],
      },
      endpoints: [{
        name: 'ssh',
        local_port: 22,
        public_port: 2201,
        protocol: 'TCP',
        direct_server_return: false,
      }],
    }

    @config_first_machine = Hash[@config]

    @client = AzureHelper.new
    @manifest = PuppetManifest.new(@template, @config_first_machine)
    @result = @manifest.execute
    @machine = @client.get_virtual_machine(@name).first
    @ip = @machine.ipaddress if @machine

    @config_second_machine = Hash[@config_first_machine]
    @config_second_machine[:name] = @second_name
    @config_second_machine[:endpoints][0][:public_port] = 2202

    @second_manifest = PuppetManifest.new(@template, @config_second_machine)
    @second_result = @second_manifest.execute
    @second_machine = @client.get_virtual_machine(@second_name).first
    @second_ip = @second_machine.ipaddress if @second_machine
  end

  it_behaves_like 'an idempotent resource'

  describe 'the first machine' do
    it 'is accessible on its own port' do
      result = run_command_over_ssh(@ip, "true", 'password', 2201)
      expect(result.exit_status).to eq 0
    end
  end

  describe 'the second machine' do
    it 'is accessible on its own port' do
      result = run_command_over_ssh(@second_ip, "true", 'password', 2202)
      expect(result.exit_status).to eq 0
    end
  end

  context 'when adding another machine to the cloud service' do
    before(:all) do
      @config_third_machine = Hash[@config_first_machine]
      @config_third_machine[:name] = @third_name
      @config_third_machine[:endpoints][0][:public_port] = 2203
      @manifest = PuppetManifest.new(@template, @config_third_machine)
      @result = @manifest.execute

      @machine = @client.get_virtual_machine(@name).first
      @second_machine = @client.get_virtual_machine(@second_name).first
      @third_machine = @client.get_virtual_machine(@third_name).first

      @ip = @machine.ipaddress if @machine
      @second_ip = @second_machine.ipaddress if @second_machine
      @third_ip = @third_machine.ipaddress if @third_machine
    end

    it_behaves_like 'an idempotent resource'

    describe 'the first machine' do
      it 'is accessible on its own port' do
        result = run_command_over_ssh(@ip, "true", 'password', 2201)
        expect(result.exit_status).to eq 0
      end
    end

    describe 'the second machine' do
      it 'is accessible on its own port' do
        result = run_command_over_ssh(@second_ip, "true", 'password', 2202)
        expect(result.exit_status).to eq 0
      end
    end
    describe 'the third machine' do
      it 'is accessible on its own port' do
        result = run_command_over_ssh(@third_ip, "true", 'password', 2203)
        expect(result.exit_status).to eq 0
      end
    end
  end

  describe 'removing a single machine' do
    before(:all) do
      @manifest = <<CONFIG
      azure_vm_classic {
        "#{@second_name}":
          ensure        => 'absent',
          location      => "#{CHEAPEST_CLASSIC_LOCATION}",
          cloud_service => "#{SPEC_CLOUD_SERVICE}",
          purge_disk_on_delete => true,
      }
CONFIG

      @result = @manifest.execute_manifest(@manifest, beaker_opts)

      @machine = @client.get_virtual_machine(@name).first
      @second_machine = @client.get_virtual_machine(@second_name).first
      @third_machine = @client.get_virtual_machine(@third_name).first
      @ip = @machine.ipaddress if @machine
      @third_ip = @third_machine.ipaddress if @third_machine
    end

    it 'runs successfully' do
      expect(@result.exit_code).to eq 2
    end

    it 'removes the machine' do
      expect(@second_machine).to be_nil
    end

    describe 'the first machine' do
      it 'is still accessible on its own port' do
        result = run_command_over_ssh(@ip, "true", 'password', 2201)
        expect(result.exit_status).to eq 0
      end
    end

    describe 'the third machine' do
      it 'is still accessible on its own port' do
        result = run_command_over_ssh(@third_ip, "true", 'password', 2203)
        expect(result.exit_status).to eq 0
      end
    end
  end
  describe 'shall clean up Azure resources' do
    before(:all) do
      @machine = @client.get_virtual_machine(@name).first
      @second_machine = @client.get_virtual_machine(@second_name).first
      @third_machine = @client.get_virtual_machine(@third_name).first
      @client.destroy_virtual_machine(@machine) if @machine
      @client.destroy_virtual_machine(@second_machine) if @second_machine
      @client.destroy_virtual_machine(@third_machine) if @third_machine

      @client.destroy_storage_account(@storage_account_name)
    end

    it 'runs successfully' do
      expect(@result.exit_code).to eq 2
    end

    it 'removes all machines' do
      expect(@client.get_virtual_machine(@name).first).to be_nil
      expect(@client.get_virtual_machine(@second_name).first).to be_nil
      expect(@client.get_virtual_machine(@third_name).first).to be_nil
    end

    it 'removes the storage account' do
      expect(@client.get_storage_account(@storage_account_name)).to be_nil
    end
  end
end
