# Deploy a three-node load-balanced webservice
# extension handlers only supported in azure_vm, not azure_vm_classic
azure_vm { 'puppethost':
  ensure           => present,
  image            => 'a699494373c04fc0bc8f2bb1389d6106__Windows-Server-2012-R2-20160126-en.us-127GB.vhd',
  location         => 'westus',
  user             => 'azureuser',
  password         => 'Puppet!!',
  resource_group   => 'puppethostrg',
  size             => 'Standard_A0',
}
  # custom_data      => 'sudo apt-get install apache2 libapache2-mod-php5 php5 -y && sudo sh -c "echo \'<?php echo gethostbyname(trim(\"`hostname`\")); ?><?php phpinfo(); ?>\' > /var/www/html/test.php"',
  # availability_set => 'puppetfarmas',
  # endpoints        => [{
  #   name               => 'weblb',
  #   public_port        => 80,
  #   local_port         => 80,
  #   protocol           => 'TCP',
  #   load_balancer_name => 'HttpTrafficIn',
  #   load_balancer      => {
  #     port     => 80,
  #     protocol => 'http',
  #     interval => 5,
  #     # path     => '/test.php',
  #   },
  # }],


# azure_vm { 'sample':
#   location                      => 'eastus',
#   image                         => 'canonical:ubuntuserver:14.04.2-LTS:latest',
#   resource_group                => 'testresacc01',
#   storage_account               => 'teststoracc01',
#   storage_account_type          => 'Standard_GRS',
#   os_disk_name                  => 'osdisk01',
#   os_disk_caching               => 'ReadWrite',
#   os_disk_create_option         => 'fromImage',
#   os_disk_vhd_container_name    => 'conttest1',
#   os_disk_vhd_name              => 'vhdtest1',
#   dns_domain_name               => 'mydomain01',
#   dns_servers                   => '10.1.1.1.1 10.1.2.4',
#   public_ip_allocation_method   => 'Dynamic',
#   public_ip_address_name        => 'ip_name_test01pubip',
#   virtual_network_name          => 'vnettest01',
#   virtual_network_address_space => '10.0.0.0/16',
#   subnet_name                   => 'subnet111',
#   subnet_address_prefix         => '10.0.2.0/24',
#   ip_configuration_name         => 'ip_config_test01',
#   private_ip_allocation_method  => 'Dynamic',
#   network_interface_name        => 'nicspec01',
# }
