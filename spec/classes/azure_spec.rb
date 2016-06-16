require 'spec_helper'

describe 'azure dependencies setup' do
  context 'RedHat setup' do
    let(:facts) {{ :osfamily => 'RedHat' }}

    it { is_expected.to compile.with_all_deps }
    it 'contains retries package' do 
      is_expected.to contain_package('retries').with(
        ensure: 'installed',
        provider: 'puppet_gem'
      )
    end
    it 'contains azure package' do
      is_expected.to contain_package('azure').with(
        ensure: '~>0.7.0',
        provider: 'puppet_gem'
      )
    end
    it 'contains azure_mgmt_compute package' do
      is_expected.to contain_package('azure_mgmt_compute').with(
        ensure: '~>0.3.0',
        provider: 'puppet_gem'
      )
    end
    it 'contains azure_mgmt_storage package' do
      is_expected.to contain_package('azure_mgmt_storage').with(
        ensure: '~>0.3.0',
        provider: 'puppet_gem'
      )
    end
    it 'contains azure_mgmt_resources package' do
      is_expected.to contain_package('azure_mgmt_resources').with(
        ensure: '~>0.3.0',
        provider: 'puppet_gem'
      )
    end
    it 'contains azure_mgmt_network package' do
      is_expected.to contain_package('azure_mgmt_network').with(
        ensure: '~>0.3.0',
        provider: 'puppet_gem'
      )
    end
    it 'contains hocon package' do
      is_expected.to contain_package('hocon').with(
        ensure: '~>1.1.2',
        provider: 'puppet_gem'
      )
    end

    ['gcc', 'ruby-devel', 'zlib-devel', 'rpm-build', 'gcc-c++'].each do |x|
      it { is_expected.to contain_package(x) }
    end

    context 'parameters' do
      let(:params) do
        {
          :subscription_id => 'fake',
          :tenant_id => 'fake',
          :client_id => 'fake',
          :client_secret => 'fake'
        }
      end
      it { is_expected.to compile.with_all_deps }
      it { should contain_file('/etc/puppetlabs/puppet/azure.conf') }
    end
  end

  context 'Debian setup' do
    let(:facts) {{ :osfamily => 'Debian' }}

    it { is_expected.to compile.with_all_deps }
    it 'contains retries package' do 
      is_expected.to contain_package('retries').with(
        ensure: 'installed',
        provider: 'puppet_gem'
      )
    end
    it 'contains azure package' do
      is_expected.to contain_package('azure').with(
        ensure: '~>0.7.0',
        provider: 'puppet_gem'
      )
    end
    it 'contains azure_mgmt_compute package' do
      is_expected.to contain_package('azure_mgmt_compute').with(
        ensure: '~>0.3.0',
        provider: 'puppet_gem'
      )
    end
    it 'contains azure_mgmt_storage package' do
      is_expected.to contain_package('azure_mgmt_storage').with(
        ensure: '~>0.3.0',
        provider: 'puppet_gem'
      )
    end
    it 'contains azure_mgmt_resources package' do
      is_expected.to contain_package('azure_mgmt_resources').with(
        ensure: '~>0.3.0',
        provider: 'puppet_gem'
      )
    end
    it 'contains azure_mgmt_network package' do
      is_expected.to contain_package('azure_mgmt_network').with(
        ensure: '~>0.3.0',
        provider: 'puppet_gem'
      )
    end
    it 'contains hocon package' do
      is_expected.to contain_package('hocon').with(
        ensure: '~>1.1.2',
        provider: 'puppet_gem'
      )
    end
    ['build-essential', 'patch', 'ruby-dev', 'zlib1g-dev', 'liblzma-dev'].each do |x|
      it { is_expected.to contain_package(x) } 
    end

    context 'parameters' do
      let(:params) do
        {
          :subscription_id => 'fake',
          :tenant_id => 'fake',
          :client_id => 'fake',
          :client_secret => 'fake'
        }
      end
      it { is_expected.to compile.with_all_deps }
      it { should contain_file('/etc/puppetlabs/puppet/azure.conf') }
    end
  end


  context 'windows setup' do
    let(:facts) do
      {
        :osfamily => 'windows',
        :common_appdata => 'C:\ProgramData'
      }
    end

# Commented out due to error with path validation
#    it { is_expected.to compile.with_all_deps }
    it 'contains retries package' do 
      is_expected.to contain_package('retries').with(
        ensure: 'installed',
        provider: 'puppet_gem'
      )
    end
    it 'contains azure package' do
      is_expected.to contain_package('azure').with(
        ensure: '~>0.7.0',
        provider: 'puppet_gem'
      )
    end
    it 'contains azure_mgmt_compute package' do
      is_expected.to contain_package('azure_mgmt_compute').with(
        ensure: '~>0.3.0',
        provider: 'puppet_gem'
      )
    end
    it 'contains azure_mgmt_storage package' do
      is_expected.to contain_package('azure_mgmt_storage').with(
        ensure: '~>0.3.0',
        provider: 'puppet_gem'
      )
    end
    it 'contains azure_mgmt_resources package' do
      is_expected.to contain_package('azure_mgmt_resources').with(
        ensure: '~>0.3.0',
        provider: 'puppet_gem'
      )
    end
    it 'contains azure_mgmt_network package' do
      is_expected.to contain_package('azure_mgmt_network').with(
        ensure: '~>0.3.0',
        provider: 'puppet_gem'
      )
    end
    it 'contains hocon package' do
      is_expected.to contain_package('hocon').with(
        ensure: '~>1.1.2',
        provider: 'puppet_gem'
      )
    end

    context 'parameters' do
      let(:params) do
        {
          :subscription_id => 'fake',
          :tenant_id => 'fake',
          :client_id => 'fake',
          :client_secret => 'fake'
        }
      end
      it { should contain_file('C:\ProgramData\PuppetLabs\puppet\etc\azure.conf') }
    end
  end

  context 'Solaris setup' do
    let(:facts) {{ :osfamily => 'Solaris' }}
    it { expect { catalogue}.to raise_error }
  end
end 
