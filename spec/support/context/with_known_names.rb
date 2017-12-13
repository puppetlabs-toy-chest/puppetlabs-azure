shared_context 'with a known name and storage account name' do
  before(:all) do
    # Windows machines can't have names longer than 15 characters
    @tag_seed = SecureRandom.hex(4)
    @name = "CLOUD-CON-#{@tag_seed}"
    @storage_account_name = "cloudcon#{@tag_seed}"
  end
end
