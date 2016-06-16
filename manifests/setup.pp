# Internal class to install Azure Module package dependancies
class azure::setup (
  $gempackages,
  $nokogirideps,
  $manage_azure_conf,
  $subscription_id,
  $tenant_id,
  $client_id,
  $client_secret,
  $management_certificate,
) {

  if $nokogirideps {
    $nokogiridepspackages = suffix(prefix(keys($nokogirideps),'Package['),']')
  }

  case $::osfamily {
    'windows': {
      $azureconf = "${::common_appdata}\\PuppetLabs\\puppet\\etc\\azure.conf"
      create_resources('package',$gempackages)
    }
    'RedHat', 'Debian': {
      $azureconf = '/etc/puppetlabs/puppet/azure.conf'
      create_resources('package',$nokogirideps)
      create_resources('package',$gempackages, {'require' => $nokogiridepspackages})
    }
    default: { fail('This module only supports Windows, RedHat, and Debian based systems') }
  }

  if $manage_azure_conf {
    if $subscription_id == undef {
      fail('If manage_azure_conf is true, then subscription_id must be defined')
    }
    if ($management_certificate == undef) and (($tenant_id == undef) or ($client_id == undef) or ($client_secret == undef)) {
      fail('If manage_azure_conf is true, then management_certificate or tenant_id, client_id, and client_secret must be defined')
    }
    file { $azureconf:
      ensure  => file,
      content => template('azure/azure.conf.erb'),
    }
  }
}
