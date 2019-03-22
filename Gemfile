source ENV['GEM_SOURCE'] || "https://rubygems.org"

gem 'azure', '~> 0.7.0'

gem 'azure_mgmt_compute', '~> 0.14.0'
gem 'azure_mgmt_network', '~> 0.14.0'
gem 'azure_mgmt_resources', '~> 0.14.0'
gem 'azure_mgmt_storage', '~> 0.14.0'
gem 'facets'

gem 'hocon'
gem 'retries'

group :test do
  gem 'facter', '>= 2.0'
  gem 'metadata-json-lint'
  gem 'puppet', ENV['PUPPET_GEM_VERSION'] || '~> 4'
  gem 'puppetlabs_spec_helper'  
  # json_pure 2.0.2 added a requirement on ruby >= 2. We pin to json_pure 2.0.1
  # if using ruby 1.x
  gem 'json_pure', '<=2.0.1', :require => false if RUBY_VERSION =~ /^1\./
  gem 'listen', '~> 3.0.0'
  gem 'parallel_tests', '< 2.10.0' if RUBY_VERSION < '2.0.0'
  gem 'public_suffix', '~> 1.4.0' #used for azure, 1.5.0 dropped ruby 1.9
  gem 'rake'
  gem 'rspec-puppet', :git => 'https://github.com/rodjek/rspec-puppet.git'
  gem 'rspec_junit_formatter'
  gem 'rubocop', '~> 0.49.0'
  gem 'rubocop-rspec'
  gem 'semantic_puppet'
  gem 'simplecov', '>= 0.11.0'
  gem 'simplecov-console'
end

group :development do
  gem 'guard-rake'
  gem 'pry-byebug'
  gem 'puppet-blacksmith'
  # required by puppet-blacksmith
  gem 'rest-client', '~> 1.8.0' # for ruby 1.9 compatibility
end

group :acceptance do
  gem 'beaker', ENV['BEAKER_VERSION'] || '~> 2.0'
  gem 'beaker-puppet_install_helper', :require => false
  gem 'beaker-rspec'
  gem 'beaker-testmode_switcher'
  gem 'master_manipulator', '~> 1.0'
  gem 'mustache'
  gem 'ssh-exec'
  gem 'winrm', '~> 1.3'
end
