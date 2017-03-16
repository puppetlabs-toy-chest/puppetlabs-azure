azure_resource_group { 'test-rg':
  ensure   => present,
  location => 'eastus',
}
# Example with a source
azure_resource_template { 'test-storage-account':
  ensure         => 'present',
  resource_group => 'test-rg',
  source         => 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-storage-account-create/azuredeploy.json',
  params         => {
    'storageAccountType' => 'Standard_GRS',
  },
}
# Example from https://github.com/Azure/azure-quickstart-templates/tree/master/101-loadbalancer-with-nat-rule
azure_resource_template { 'lb-test-template':
  ensure         => 'present',
  resource_group => 'test-rg',
  content        => file('loadbalancer.template'),
  params         => {
    'dnsNameforLBIP'      => 'stuffandthings02',
    'publicIPAddressType' => 'Dynamic',
    'addressPrefix'       => '10.0.0.0/16',
    'subnetPrefix'        => '10.0.0.0/24',
  },
}
