shared_context 'with a known name and storage account name' do
  before(:all) do
    # Windows machines can't have names longer than 15 characters
    @name = "CLOUD-CON-#{SecureRandom.hex(4)}"
    @storage_account_name = "cloudcon#{SecureRandom.hex(8)}"
  end
end
