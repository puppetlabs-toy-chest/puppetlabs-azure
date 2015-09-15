shared_context 'with known network' do
  before(:all) do
    @virtual_network_name = "CLOUD-VNET-ACCEPTANCE"
    @client.ensure_network(@virtual_network_name)
    @network = @client.get_virtual_network(@virtual_network_name)
  end
end
