source ENV['GEM_SOURCE'] || "https://rubygems.org"

gem 'azure', '~> 0.7.0'
gem 'hocon'

group :test do
  gem 'rake'
  gem 'puppet', ENV['PUPPET_GEM_VERSION'] || '~> 3.8.0'
  gem 'facter', '>= 2.0'
  gem 'rspec-puppet', :git => 'https://github.com/rodjek/rspec-puppet.git'
  gem 'puppetlabs_spec_helper'
  gem 'metadata-json-lint'
  gem 'rubocop', '0.33.0', require: false
  gem 'simplecov'
  gem 'simplecov-console'
  gem 'parallel_tests'
end

group :development do
  gem 'pry'
  gem 'puppet-blacksmith'
  gem 'guard-rake'
  gem 'pry-rescue'
  gem 'pry-stack_explorer'
end

group :acceptance do
  gem 'mustache'
  gem 'ssh-exec'
  gem 'retries'
  gem "beaker-puppet_install_helper", :require => false
  gem 'beaker', '~> 2.0'
  gem 'master_manipulator', '~> 1.0'
  gem 'beaker-rspec'
end
