source ENV['GEM_SOURCE'] || "https://rubygems.org"

gem 'azure', '~> 0.7.0'

gem 'azure_mgmt_storage', '~> 0.3.0'
gem 'azure_mgmt_compute', '~> 0.3.0'
gem 'azure_mgmt_resources', '~> 0.3.0'
gem 'azure_mgmt_network', '~> 0.3.0'

gem 'hocon'
gem 'retries'

group :test do
  gem 'rake'
  gem 'puppet', ENV['PUPPET_GEM_VERSION'] || '~> 4'
  gem 'facter', '>= 2.0'
  gem 'rspec-puppet', :git => 'https://github.com/rodjek/rspec-puppet.git'
  gem 'puppetlabs_spec_helper', '< 1.0'
  gem 'metadata-json-lint'
  gem 'rubocop'
  gem 'simplecov', '>= 0.11.0'
  gem 'simplecov-console'
  gem 'parallel_tests'
  gem 'listen', '~> 3.0.0'
end

group :development do
  gem 'pry'
  gem 'puppet-blacksmith'
  gem 'guard-rake'
  gem 'pry-rescue'
  gem 'pry-stack_explorer'
end

group :acceptance do
  gem 'winrm', '~> 1.3'
  gem 'mustache'
  gem 'ssh-exec'
  gem "beaker-puppet_install_helper", :require => false
  gem "beaker-testmode_switcher"
  gem 'beaker', ENV['BEAKER_VERSION'] || '~> 2.0'
  gem 'master_manipulator', '~> 1.0'
  gem 'beaker-rspec'
end
