require 'spec_helper_acceptance'

describe 'unified rake test' do
  before(:all) do
    @config = {
      name: @name,
      ensure: 'present',
      optional: {
        image: UBUNTU_IMAGE,
      },
    }
    @template = 'azure_vm_classic.pp.tmpl'
    @manifest = PuppetManifest.new(@template, @config)
  end

  it 'should be running this test' do
    expect(true).to be true
  end
end
