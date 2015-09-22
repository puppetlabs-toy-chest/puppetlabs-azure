require 'spec_helper_acceptance'

describe 'azure_vm when creating a new Windows machine' do
  include_context 'with certificate copied to system under test'
  include_context 'with a known name and storage account name'

  before(:all) do
    # Windows machines can't have names longer than 15 characters
    @name = "CLOUD-#{SecureRandom.hex(4)}"

    @config = {
      name: @name,
      ensure: 'present',
      optional: {
        image: WINDOWS_IMAGE,
        location: CHEAPEST_AZURE_LOCATION,
        user: 'specuser',
        password: 'SpecPass123!@#$%',
        winrm_https_port: 5986,
        storage_account: @storage_account_name, # required in order to tidy up created storage group
      }
    }
    @manifest = PuppetManifest.new(@template, @config)
    @result = @manifest.execute
    @machine = @client.get_virtual_machine(@name).first
    @ip = @machine.ipaddress
  end

  it_behaves_like 'an idempotent resource'

  include_context 'destroy left-over created resources after use'

  it 'should have the correct image' do
    expect(@machine.image).to eq(@config[:optional][:image])
  end

  it 'should be accessible via WinRM with the provided details' do
    pending 'the Azure firewall is not by default open to WinRM, pending work in CLOUD-429'
    run_command_over_winrm('ipconfig /all', @config[:optional][:winrm_https_port]) do |stdout, stderr|
      expect(stderr).to be_empty?
    end
  end

  context 'when looked for using puppet resource' do
    include_context 'a puppet resource run'
    puppet_resource_should_show('os_type', 'Windows')
  end
end
