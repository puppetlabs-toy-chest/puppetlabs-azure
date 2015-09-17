shared_context 'a puppet resource run' do
  before(:all) do
    @result = PuppetRunProxy.resource('azure_vm_classic', {:name => @name})
  end

  it 'should not return an error' do
    expect(@result.stderr).not_to match(/\b/)
  end
end
