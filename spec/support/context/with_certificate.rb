shared_context 'with certificate copied to system under test' do
  before(:all) do
    @client = AzureHelper.new
    @template = 'azure_vm_classic.pp.tmpl'

    @local_private_key_path = File.join(Dir.getwd, 'spec', 'acceptance', 'fixtures', 'insecure_private_key.pem')
    @remote_private_key_path = '/tmp/id_rsa'

    # deploy the certificate to all the nodes, as the API requires local access to it.
    PuppetRunProxy.scp_to_ex(@local_private_key_path, @remote_private_key_path)
  end
end
