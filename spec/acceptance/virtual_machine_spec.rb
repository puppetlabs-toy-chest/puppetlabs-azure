require 'spec_helper_acceptance'

require 'net/ssh'
require 'ssh-exec'
require 'retries'

def run_command_over_ssh(command, auth_method)
  # We retry failed attempts as although the VM has booted it takes some
  # time to start and expose SSH. This mirrors the behaviour of a typical SSH client
  with_retries(:max_tries => 10,
               :base_sleep_seconds => 20,
               :max_sleep_seconds => 20,
               :rescue => [Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::ETIMEDOUT]) do
    Net::SSH.start(@ip,
                   @config[:optional][:user],
                   :password => @config[:optional][:password],
                   :keys => [@local_private_key_path],
                   :auth_methods => [auth_method],
                   :verbose => :info) do |ssh|
      SshExec.ssh_exec!(ssh, command)
    end
  end
end

describe 'azure_vm' do
  before(:all) do
    @client = AzureHelper.new
    @template = 'azure_vm.pp.tmpl'

    @local_private_key_path = File.join(Dir.getwd, 'spec', 'acceptance', 'fixtures', 'insecure_private_key.pem')
    @remote_private_key_path = '/tmp/id_rsa'

    # deploy the certificate to all the nodes, as the API requires local access to it.
    PuppetRunProxy.scp_to_ex(@local_private_key_path, @remote_private_key_path)
  end

  context 'when an error occurs' do
    before(:all) do
      @name = "CLOUD-#{SecureRandom.hex(8)}"
      config = {
        name: @name,
        ensure: 'present',
        optional: {
          image: 'INVALID_IMAGE_NAME',
        }
      }
      @result = PuppetManifest.new(@template, config).execute
    end

    it 'reports errors from the API' do
      expect(@result.output).to match /Failed to create virtual machine.*:.*The virtual machine image source is not valid\./
    end

    it 'reports the error in the exit code' do
      expect(@result.exit_code).to eq 4
    end
  end

  context 'when creating a new machine' do
    before(:all) do
      @name = "CLOUD-#{SecureRandom.hex(8)}"

      @config = {
        name: @name,
        ensure: 'present',
        optional: {
          image: 'b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-14_04_2-LTS-amd64-server-20150706-en-us-30GB',
          location: CHEAPEST_AZURE_LOCATION,
          user: 'foo',
          deployment: "CLOUD-DN-#{SecureRandom.hex(8)}",
          cloud_service: "CLOUD-CS-#{SecureRandom.hex(8)}",
          private_key_file: @remote_private_key_path,
        }
      }
      @manifest = PuppetManifest.new(@template, @config)
      @result = @manifest.execute
      @machine = @client.get_virtual_machine(@name).first
    end

    after(:all) do
      @client.destroy_virtual_machine(@machine)
    end

    it 'should run without errors' do
      expect(@result.exit_code).to eq 2
    end

    it 'should exist after the first run' do
      expect(@machine).not_to eq (nil)
    end

    it 'should have the correct deployment name' do
      expect(@machine.deployment_name).to eq(@config[:optional][:deployment])
    end

    it 'should have the correct cloud service name' do
      expect(@machine.cloud_service_name).to eq(@config[:optional][:cloud_service])
    end

    it 'should have the correct image' do
      expect(@machine.image).to eq(@config[:optional][:image])
    end

    it 'should be launched in the specified location' do
      expect(@client.get_cloud_service(@machine).location).to eq (@config[:optional][:location])
    end

    it 'should run a second time without changes' do
      second_result = @manifest.execute
      expect(second_result.exit_code).to eq 0
    end

    context 'when looked for using puppet resource' do
      before(:all) do
        @result = PuppetRunProxy.resource('azure_vm', {:name => @name})
      end

      it 'should not return an error' do
        expect(@result.stderr).not_to match(/\b/)
      end

      it 'should report the correct ensure value' do
        regex = /(ensure)(\s*)(=>)(\s*)('present')/
        expect(@result.stdout).to match(regex)
      end

      it 'should report the correct location value' do
        regex = /(location)(\s*)(=>)(\s*)('#{@config[:optional][:location]}')/
        expect(@result.stdout).to match(regex)
      end

      it 'should report the correct deployment name' do
        regex = /(deployment)(\s*)(=>)(\s*)('#{@config[:optional][:deployment]}')/
        expect(@result.stdout).to match(regex)
      end

      it 'should report the correct cloud service name' do
        regex = /(cloud_service)(\s*)(=>)(\s*)('#{@config[:optional][:cloud_service]}')/
        expect(@result.stdout).to match(regex)
      end

      it 'should report the correct image' do
        regex = /(image)(\s*)(=>)(\s*)('#{@config[:optional][:image]}')/
        expect(@result.stdout).to match(regex)
      end

      [
        'os_type',
        'ipaddress',
        'media_link',
      ].each do |read_only_property|
        it "#{read_only_property} is reported" do
          regex = /(#{read_only_property})(\s*)(=>)(\s*)/
          expect(@result.stdout).to match(regex)
        end
      end
    end
  end

  context 'when configuring a admin user on a linux guest with a private key' do
    before(:all) do
      @name = "CLOUD-#{SecureRandom.hex(8)}"
      @config = {
        :name     => @name,
        :ensure   => 'present',
        :optional => {
          :image        => 'b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-14_04_2-LTS-amd64-server-20150706-en-us-30GB',
          :location     => CHEAPEST_AZURE_LOCATION,
          :user         => 'specuser',
          :private_key_file => @remote_private_key_path,
        }
      }
      PuppetManifest.new(@template, @config).execute
      @machine = @client.get_virtual_machine(@name).first
      @ip = @machine.ipaddress
    end

    after(:all) do
      @client.destroy_virtual_machine(@machine)
    end

    it 'is accessible using the private key' do
      result = run_command_over_ssh('true', 'publickey')
      expect(result.exit_status).to eq 0
    end

    it 'is able to use sudo to root' do
      result = run_command_over_ssh('sudo true', 'publickey')
      expect(result.exit_status).to eq 0
    end
  end

  context 'when configuring a admin user on a linux guest with a password' do
    before(:all) do
      @name = "CLOUD-#{SecureRandom.hex(8)}"
      @config = {
        :name     => @name,
        :ensure   => 'present',
        :optional => {
          :image        => 'b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-14_04_2-LTS-amd64-server-20150706-en-us-30GB',
          :location     => CHEAPEST_AZURE_LOCATION,
          :user         => 'specuser',
          :password     => 'SpecPass123!@#$%',
        }
      }
      PuppetManifest.new(@template, @config).execute
      @machine = @client.get_virtual_machine(@name).first
      @ip = @machine.ipaddress
    end

    after(:all) do
      @client.destroy_virtual_machine(@machine)
    end

    it 'is accessible using the password' do
      result = run_command_over_ssh('true', 'password')
      expect(result.exit_status).to eq 0
    end
  end
end
