require 'spec_helper_acceptance'


describe 'azure class' do
  azurepackages = ['retries', 'azure', 'azure_mgmt_compute', 'azure_mgmt_storage','azure_mgmt_resources', 'azure_mgmt_network', 'hocon']

  it 'installs packages' do
    apply_manifest(%{
      class { 'azure': }
    }, :catch_failures => true)
  end

  Array(azurepackages).each do |package|
    describe package(package) do
      it { should be_installed }
    end
  end
end
