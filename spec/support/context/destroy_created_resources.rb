shared_context 'destroys created resources after use' do
  after(:all) do
    @client.destroy_virtual_machine(@machine)
    @client.destroy_storage_account(@storage_account_name) if @client.get_storage_account(@storage_account_name)
  end
end
