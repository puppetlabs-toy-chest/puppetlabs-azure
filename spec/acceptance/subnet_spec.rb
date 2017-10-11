require 'spec_helper_acceptance'

describe 'azure_subnet when creating a subnet' do
  include_context 'with a known name and storage account name'
  include_context 'destroy left-over created ARM resources after use'

  before(:all) do
    @client = AzureARMHelper.new

    # first build the vnet
    @vnet_name = @client.get_simple_name(@name)
    @vnet_config = {
      name: @vnet_name,
      ensure: 'present',
      location: cheapest_arm_location,
      resource_group: spec_resource_group,
      optional: {
      },
      nonstring: {
        address_prefixes: ['172.16.0.0/12'],
        dns_servers: ['8.8.8.8'],
      },
    }
    @vnet_template = 'azure_vnet.pp.tmpl'
    @vnet_manifest = puppetmanifest.new(@vnet_template, @vnet_config)
    @vnet_result = @vnet_manifest.execute

    # now build the subnet
    @subnet_name = @client.get_simple_name(@name)
    @config = {
      name: @subnet_name,
      ensure: 'present',
      virtual_network: @vnet_name,
      resource_group: spec_resource_group,
      optional: {
        address_prefix: ['172.16.1.0/24'],
      },
    }
    @template = 'azure_subnet.pp.tmpl'
    @manifest = puppetmanifest.new(@template, @config)
    @result = @manifest.execute
    @subnet = @client.get_subnet(@subnet_name)
  end

  it_behaves_like 'an idempotent resource'

  it 'should have the correct name' do
    expect(@subnet.name).to eq(@subnet_name)
  end

  context 'when puppet resource is run' do
    include_context 'a puppet arm resource run', 'azure_subnet'
    puppet_resource_should_show('ensure', 'present')
    puppet_resource_should_show('resource_group', spec_resource_group.downcase)
    puppet_resource_should_show('virtual_network', @vnet_name)
  end

  context 'when we try and destroy the subnet' do
    before(:all) do
      new_config = @config.update({:ensure => 'absent'})
      manifest = PuppetManifest.new(@template, new_config)
      @result = manifest.execute
      @subnet = @client.get_subnet(@subnet)
    end

    it 'should run without errors' do
      expect(@result.exit_code).to eq 2
    end

    it 'should be destroyed' do
      expect(@subnet).to be_nil
    end
  end
end
