# Deploy a three-node load-balanced webservice
azure_vm_classic { ['hanselmanfarm', 'hanselmanfarm-2', 'hanselmanfarm-3']:
  ensure           => present,
  image            => 'b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-14_04_3-LTS-amd64-server-20150908-en-us-30GB',
  location         => 'West US',
  user             => 'scott',
  password         => 'secretpw',
  # private_key_file => '/path/to/id_rsa',
  size             => 'Small',
  custom_data      => 'sudo apt-get update && sudo apt-get install apache2 libapache2-mod-php5 php5 -y && sudo sh -c "echo \'<?php echo gethostbyname(trim(\"`hostname`\")); ?><?php phpinfo(); ?>\' > /var/www/html/test.php"',
  cloud_service    => 'hanselmanfarmcs', # change this
  availability_set => 'hanselmanfarmas',
  endpoints        => [{
    name               => 'weblb',
    public_port        => 80,
    local_port         => 80,
    protocol           => 'TCP',
    load_balancer_name => 'HttpTrafficIn',
    load_balancer      => {
      port     => 80,
      protocol => 'http',
      interval => 5,
      path     => '/test.php',
    },
  }],
}
