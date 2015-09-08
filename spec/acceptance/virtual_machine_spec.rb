require 'spec_helper_acceptance'

require 'net/ssh'
require 'ssh-exec'
require 'retries'

def expect_failed_apply(config)
  result = PuppetManifest.new(@template, config).execute
  expect(result.exit_code).not_to eq 0
end

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

def puppet_resource_should_show(property_name, value=nil)
  it "should report the correct #{property_name} value" do
    # this overloading allows for passing either a key or a key and value
    # and naively picks the key from @config if it exists. This is because
    # @config is only available in the context of a test, and not in the context
    # of describe or context
    real_value = @config[:optional][property_name.to_sym] || value
    regex = if real_value.nil?
              /(#{property_name})(\s*)(=>)(\s*)/
            else
              /(#{property_name})(\s*)(=>)(\s*)('#{real_value}'|#{real_value})/
            end
    expect(@result.stdout).to match(regex)
  end
end

shared_context 'a puppet resource run' do
  before(:all) do
    @result = PuppetRunProxy.resource('azure_vm', {:name => @name})
  end

  it 'should not return an error' do
    expect(@result.stderr).not_to match(/\b/)
  end
end

shared_context 'destroys created resources after use' do
  after(:all) do
    @client.destroy_virtual_machine(@machine)
  end
end

RSpec.shared_examples 'an idempotent resource' do
  it 'should run without errors' do
    expect(@result.exit_code).to eq 2
  end

  it 'should exist after the first run' do
    expect(@machine).not_to eq (nil)
  end

  it 'should run a second time without changes' do
    second_result = @manifest.execute
    expect(second_result.exit_code).to eq 0
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

  context 'when providing an invalid image' do
    before(:all) do
      @name = "CLOUD-#{SecureRandom.hex(8)}"
      config = {
        name: @name,
        ensure: 'present',
        optional: {
          location: CHEAPEST_AZURE_LOCATION,
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

  context 'when creating a new machine with the minimum properties' do
    before(:all) do
      @name = "CLOUD-#{SecureRandom.hex(8)}"

      @config = {
        name: @name,
        ensure: 'present',
        optional: {
          image: 'b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-14_04_2-LTS-amd64-server-20150706-en-us-30GB',
          location: CHEAPEST_AZURE_LOCATION,
          user: 'specuser',
          private_key_file: @remote_private_key_path,
        }
      }
      @manifest = PuppetManifest.new(@template, @config)
      @result = @manifest.execute
      @machine = @client.get_virtual_machine(@name).first
      @ip = @machine.ipaddress
    end

    it_behaves_like 'an idempotent resource'

    include_context 'destroys created resources after use'

    it 'should have the correct image' do
      expect(@machine.image).to eq(@config[:optional][:image])
    end

    it 'should have the default size' do
      expect(@machine.role_size).to eq('Small')
    end

    it 'should be launched in the specified location' do
      expect(@client.get_cloud_service(@machine).location).to eq (@config[:optional][:location])
    end

    it 'is accessible using the private key' do
      result = run_command_over_ssh('true', 'publickey')
      expect(result.exit_status).to eq 0
    end

    it 'is able to use sudo to root' do
      result = run_command_over_ssh('sudo true', 'publickey')
      expect(result.exit_status).to eq 0
    end

    context 'stopping the machine' do
      before(:all) do
        new_config = @config.update({:ensure => 'stopped'})
        @manifest = PuppetManifest.new(@template, new_config)
        @result = @manifest.execute
        @stopped_machine = @client.get_virtual_machine(@name).first
      end

      it_behaves_like 'an idempotent resource'

      it 'should be stopped' do
        expect(@stopped_machine.status).to eq('StoppedDeallocated')
      end

      context 'restarting the machine' do
        before(:all) do
          new_config = @config.update({:ensure => 'running'})
          @manifest = PuppetManifest.new(@template, new_config)
          @result = @manifest.execute
          @started_machine = @client.get_virtual_machine(@name).first
        end

        it_behaves_like 'an idempotent resource'

        it 'should not be stopped' do
          # Machines first enter an unknown state (RoleStateUnknown) before being
          # marked as ready (ReadyRole). This can take time so rather than always
          # wait for ready we're happy that we've changed the machine from stopped.
          expect(@started_machine.status).not_to eq('StoppedDeallocated')
        end
      end
    end

    context 'when looked for using puppet resource' do
      include_context 'a puppet resource run'
      puppet_resource_should_show('ensure', 'running')
      puppet_resource_should_show('location')
      puppet_resource_should_show('size', 'Small')
      puppet_resource_should_show('image')
      puppet_resource_should_show('os_type')
      puppet_resource_should_show('ipaddress')
      puppet_resource_should_show('media_link')
    end
  end

  context 'when creating a new machine in a stopped state' do
    before(:all) do
      @name = "CLOUD-#{SecureRandom.hex(8)}"

      @config = {
        name: @name,
        ensure: 'stopped',
        optional: {
          image: 'b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-14_04_2-LTS-amd64-server-20150706-en-us-30GB',
          location: CHEAPEST_AZURE_LOCATION,
          user: 'specuser',
          private_key_file: @remote_private_key_path,
        }
      }
      @manifest = PuppetManifest.new(@template, @config)
      @result = @manifest.execute
      @machine = @client.get_virtual_machine(@name).first
    end

    it_behaves_like 'an idempotent resource'

    include_context 'destroys created resources after use'

    it 'should be stopped' do
      expect(@machine.status).to eq('StoppedDeallocated')
    end
  end

  context 'when creating a machine with all available properties' do
    before(:all) do
      @name = "CLOUD-#{SecureRandom.hex(8)}"

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
        }
      }
      @manifest = PuppetManifest.new(@template, @config)
      @result = @manifest.execute
      @machine = @client.get_virtual_machine(@name).first
      @ip = @machine.ipaddress
    end

    it_behaves_like 'an idempotent resource'

    include_context 'destroys created resources after use'

    it 'should have the correct size' do
      expect(@machine.role_size).to eq(@config[:optional][:size])
    end

    it 'should have the correct deployment name' do
      expect(@machine.deployment_name).to eq(@config[:optional][:deployment])
    end

    it 'should have the correct cloud service name' do
      expect(@machine.cloud_service_name).to eq(@config[:optional][:cloud_service])
    end

    it 'is accessible using the password' do
      result = run_command_over_ssh('true', 'password')
      expect(result.exit_status).to eq 0
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
  end
end
