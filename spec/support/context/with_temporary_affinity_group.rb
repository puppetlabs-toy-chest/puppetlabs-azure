shared_context 'with temporary affinity group' do
  before(:all) do
    @affinity_group_name = "CLOUD-AG-#{SecureRandom.hex(8)}"
    @client.create_affinity_group(@affinity_group_name)
  end
  after(:all) do
    # TODO this will currently fail due to the storage account on being
    # deleted at the moment
    @client.destroy_affinity_group(@affinity_group_name)
  end
end
