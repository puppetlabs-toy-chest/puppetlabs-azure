# Install Azure Module package dependancies
class azure (
  $gempackages = $azure::params::gempackages,
  $nokogirideps = $azure::params::nokogirideps,
  $manage_azure_conf = false,
  $subscription_id = undef,
  $tenant_id = undef,
  $client_id = undef,
  $client_secret = undef,
  $management_certificate = undef,
) inherits azure::params {

  include stdlib
  class { 'azure::setup':
    gempackages            => $gempackages,
    nokogirideps           => $nokogirideps,
    manage_azure_conf      => $manage_azure_conf,
    subscription_id        => $subscription_id,
    tenant_id              => $tenant_id,
    client_id              => $client_id,
    client_secret          => $client_secret,
    management_certificate => $management_certificate,
    stage                  => setup,
  }
}
