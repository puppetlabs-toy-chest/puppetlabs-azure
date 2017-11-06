require 'spec_helper_acceptance'

describe 'azure_network_security_group when creating a virtual network' do
  include_context 'with a known name and storage account name'
  include_context 'destroy left-over created ARM resources after use'

  before(:all) do
    @client = AzureARMHelper.new
    @name = @client.get_simple_name(@name)
    @config = {
      name: @name,
      ensure: 'present',
      location: CHEAPEST_ARM_LOCATION,
      resource_group: SPEC_RESOURCE_GROUP,
      optional: {
      },
      nonstring: {
        tags: {},
      },
    }
    @template = 'azure_network_security_group.pp.tmpl'
    @manifest = PuppetManifest.new(@template, @config)
    @result = @manifest.execute
    @nsg = @client.get_network_security_group(@name)
  end

  it_behaves_like 'an idempotent resource'

  it 'should have the correct name' do
    expect(@nsg.name).to eq(@name)
  end

  context 'when puppet resource is run' do
    include_context 'a puppet ARM resource run', 'azure_network_security_group'
    puppet_resource_should_show('ensure', 'present')
    puppet_resource_should_show('location', CHEAPEST_ARM_LOCATION)
    puppet_resource_should_show('resource_group', SPEC_RESOURCE_GROUP.downcase)
  end

  context 'when we try and destroy the network security group' do
    before(:all) do
      new_config = @config.update({:ensure => 'absent'})
      manifest = PuppetManifest.new(@template, new_config)
      @result = manifest.execute
      @nsg = @client.get_network_security_group(@name)
    end

    it 'should run without errors' do
      expect(@result.exit_code).to eq 2
    end

    it 'should be destroyed' do
      expect(@nsg).to be_nil
    end
  end
end
