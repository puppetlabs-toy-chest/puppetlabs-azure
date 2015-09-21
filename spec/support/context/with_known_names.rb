shared_context 'with a known name and storage account name' do
  before(:all) do
    @name = "CLOUD-#{SecureRandom.hex(8)}"
    @storage_account_name = "cloud#{SecureRandom.hex(8)}"
  end
end
