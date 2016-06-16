# Parameters
class azure::params {
  $gempackages = {
    'retries' => {
      'ensure' => 'installed',
      'provider' => 'puppet_gem',
    },
    'azure' => {
      'ensure' => '~>0.7.0',
      'provider' => 'puppet_gem',
    },
    'azure_mgmt_compute' => {
      'ensure' => '~>0.3.0',
      'provider' => 'puppet_gem',
    },
    'azure_mgmt_storage' => {
      'ensure' => '~>0.3.0',
      'provider' => 'puppet_gem',
    },
    'azure_mgmt_resources' => {
      'ensure' => '~>0.3.0',
      'provider' => 'puppet_gem',
    },
    'azure_mgmt_network' => {
      'ensure' => '~>0.3.0',
      'provider' => 'puppet_gem',
    },
    'hocon' => {
      'ensure' => '~>1.1.2',
      'provider' => 'puppet_gem',
    },
  }
  case $::osfamily {
    'RedHat': {
      $nokogirideps = {
        'gcc' => {},
        'ruby-devel' => {},
        'zlib-devel' => {},
        'rpm-build' => {},
        'gcc-c++' => {},
      }
    }
    'Debian': {
      $nokogirideps = {
        'build-essential' => {},
        'patch' => {},
        'ruby-dev' => {},
        'zlib1g-dev' => {},
        'liblzma-dev' => {},
      }
    }
    default: {
      $nokogirideps = false
    }
  }
}
