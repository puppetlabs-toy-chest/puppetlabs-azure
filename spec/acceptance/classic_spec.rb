require 'spec_helper_acceptance'

describe 'azure_vm_classic when creating a new machine with the minimum properties' do
  include_context 'with certificate copied to system under test'
  include_context 'with a known name and storage account name'
  include_context 'with temporary affinity group'

  before(:all) do
    @config = {
      name: @name,
      ensure: 'present',
      optional: {
        image: WINDOWS_IMAGE,
        location: CHEAPEST_AZURE_LOCATION,
        user: 'specuser',
        password: 'SpecPass123!@#$%',
        storage_account: @storage_account_name, # required in order to tidy up created storage groups
        affinity_group: @affinity_group_name, # tested here to avoid clash with virtual_network
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

  it 'should have the default size' do
    expect(@machine.role_size).to eq('Small')
  end

  it 'should be launched in the specified location' do
    cloud_service = @client.get_cloud_service(@machine)
    location = cloud_service.location || cloud_service.extended_properties["ResourceLocation"]
    expect(location).to eq(@config[:optional][:location])
  end

  it 'should be in the correct affinity group' do
    affinity_group = @client.get_affinity_group(@affinity_group_name)
    associated_services = affinity_group.hosted_services.map { |service| service[:service_name] }
    expect(associated_services).to include(@machine.cloud_service_name)
  end

  # this primarily tests that the image we use for testing does not add its own data disks,
  # which could confuse the other tests for data_disk_size_gb
  describe 'the image' do
    it 'has no data disk' do
      expect(@machine.data_disks).to be_empty
    end
  end
  it_behaves_like 'a removable resource'
end
