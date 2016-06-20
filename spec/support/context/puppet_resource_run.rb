shared_context 'a puppet resource run' do
  before(:all) do
    @result = resource('azure_vm_classic', @name, beaker_opts)
  end

  it 'should not return an error' do
    expect(@result.stderr).not_to match(/\b/)
  end
end

shared_context 'a puppet ARM resource run' do
  before(:all) do
    @result = resource('azure_vm', @name, beaker_opts)
  end

  it 'should not return an error' do
    expect(@result.stderr).not_to match(/\b/)
  end
end
