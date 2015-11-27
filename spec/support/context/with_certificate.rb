require 'spec_helper_acceptance'

shared_context 'with certificate copied to system under test' do
  before(:all) do
    @client = AzureHelper.new
    @template = 'azure_vm_classic.pp.tmpl'

    @local_private_key_path = File.join(Dir.getwd, 'spec', 'acceptance', 'fixtures', 'insecure_private_key.pem')

    if ! @remote_private_key_path
      @remote_private_key_path = if ENV['PUPPET_AZURE_BEAKER_MODE'] !~ /^local$/ && default['platform'] =~ /^windows/
                                  'c:\\cygwin64\\tmp\\id_rsa'
                                 else
                                   '/tmp/id_rsa'
                                 end
    end
    # deploy the certificate to all the nodes, as the API requires local access to it.
    PuppetRunProxy.scp_to_ex(@local_private_key_path, @remote_private_key_path)
  end
end
