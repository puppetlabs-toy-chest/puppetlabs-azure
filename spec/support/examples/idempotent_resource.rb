shared_examples 'an idempotent resource' do
  it 'should run without errors' do
    expect(@result.exit_code).to eq 2
  end

  it 'should exist after the first run' do
    expect(@machine).not_to eq (nil)
  end

  it 'should run a second time without changes' do
    second_result = @manifest.execute
    expect(second_result.exit_code).to eq 0
  end
end
