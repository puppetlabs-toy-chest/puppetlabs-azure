require 'spec_helper_acceptance'

describe 'azure_vm' do
  before(:all) do
    @client = AzureHelper.new
    @template = 'azure_vm.pp.tmpl'
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
      @result = PuppetManifest.new(@template, config).apply
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
      # deploy the certificate to all the nodes, as the API requires local access to it.
      PuppetRunProxy.scp_to_ex(File.join(Dir.getwd, 'spec', 'acceptance', 'fixtures', 'insecure_private_key.pem'), '/tmp/id_rsa')

      config = {
        name: @name,
        ensure: 'present',
        optional: {
          image: 'b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-14_04_2-LTS-amd64-server-20150706-en-us-30GB',
          location: CHEAPEST_AZURE_LOCATION,
          user: 'foo',
          private_key_file: '/tmp/id_rsa',
        }
      }
      @manifest = PuppetManifest.new(@template, config)
      @result = @manifest.apply
      @machine = @client.get_virtual_machine(@name).first
    end

    after(:all) do
      @client.destroy_virtual_machine(@machine)
    end

    it 'should run without errors' do
      expect(@result.exit_code).to eq 2
    end

    it 'should exist after the first run' do
      # TODO: actually go back to the API to check for that
      expect(@machine).not_to eq (nil)
    end

    it 'should run a second time without changes' do
      second_result = @manifest.apply
      expect(second_result.exit_code).to eq 0
    end
  end

  context 'when configuring a admin user on a linux guest' do
    # default initialisation; creating a VM
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
          :private_key_file => '/tmp/id_rsa'
        }
      }
      PuppetManifest.new(@template, @config).apply
      @machine = @client.get_virtual_machine(@name).first
      @ip = @machine.ipaddress
    end

    # init helper scripts on default node
    before (:all) do
      # Thanks to André Frimberger from http://andre.frimberger.de/index.php/linux/reading-ssh-password-from-stdin-the-openssh-5-6p1-compatible-way/ for a example implementation of this.
      PuppetRunProxy.create_remote_file_ex('/tmp/ssh_passer.sh', '#!/bin/sh\\necho $SSH_PASS\\n', {mode: '0755'})
    end

    after(:all) do
      @client.destroy_virtual_machine(@machine)
    end

    it 'is accessible using the password' do
      result = PuppetRunProxy.shell_ex "SSH_ASKPASS=/tmp/ssh_passer.sh SSH_PASS='SpecPass123!@#$%' DISPLAY=:0 setsid ssh -aknTvx -i /dev/null -l specuser -o 'CheckHostIP no' -o 'StrictHostKeyChecking no' #{@ip} true"
      expect(result.exit_code).to eq 0
    end

    it 'is accessible using the private key' do
      result = PuppetRunProxy.shell_ex "setsid ssh -aknTvx -i /tmp/id_rsa -l specuser -o 'CheckHostIP no' -o 'StrictHostKeyChecking no' #{@ip} true"
      expect(result.exit_code).to eq 0
    end

    it 'is able to use sudo to root' do
      result = PuppetRunProxy.shell_ex "setsid ssh -aknTvx -i /tmp/id_rsa -l specuser -o 'CheckHostIP no' -o 'StrictHostKeyChecking no' #{@ip} sudo true"
      expect(result.exit_code).to eq 0
    end
  end
end
