shared_context 'destroys created resources after use' do
  after(:all) do
    @client.destroy_virtual_machine(@machine)
  end
end
