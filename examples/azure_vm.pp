azure_vm { 'sample':
  ensure          => stopped,
  location        => 'eastus',
  image           => 'canonical:ubuntuserver:14.04.2-LTS:latest',
  user            => 'azureuser',
  password        => 'Password',
  size            => 'Standard_A0',
  resource_group  => 'testresacc01',
  storage_account => 'mystorageaccount',
}
