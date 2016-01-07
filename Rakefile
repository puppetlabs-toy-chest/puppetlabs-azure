require 'rubygems'
require 'bundler/setup'

require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet-lint/tasks/puppet-lint'
require 'puppet-syntax/tasks/puppet-syntax'
require 'rubocop/rake_task'

require_relative 'rakelib/common_tasks'
require_relative 'rakelib/puppet_acceptance_task'
require_relative 'rakelib/dsl_extention'

require_relative 'lib/env_var_checker'
require_relative 'lib/color_text'

# This gem isn't always present, for instance
# on Travis with --without development
begin
  require 'puppet_blacksmith/rake_tasks'
rescue LoadError # rubocop:disable Lint/HandleExceptions
end

# This gem isn't always present, for instance
# on Travis with --without acceptance
begin
require 'master_manipulator'
rescue LoadError # rubocop:disable Lint/HandleExceptions
end

RuboCop::RakeTask.new

exclude_paths = [
  "pkg/**/*",
  "vendor/**/*",
  "spec/**/*",
]

Rake::Task[:lint].clear

PuppetLint.configuration.relative = true
PuppetLint.configuration.disable_80chars
PuppetLint.configuration.disable_class_inherits_from_params_class
PuppetLint.configuration.fail_on_warnings = true
PuppetLint::RakeTask.new :lint do |config|
  config.ignore_paths = exclude_paths
end

PuppetSyntax.exclude_paths = exclude_paths

# Use our own metadata task so we can ignore the non-SPDX PE licence
Rake::Task[:metadata].clear
desc "Check metadata is valid JSON"
task :metadata do
  sh "bundle exec metadata-json-lint metadata.json --no-strict-license"
end

desc 'Run syntax, lint, and spec tests.'
task :test => [
  :metadata,
  :syntax,
  :lint,
  :rubocop,
  :spec,
]

desc 'Acceptance test for the Azure project'
acceptance_task do |t|
  puts green_text('Acceptance test task invoked')
  # Setup rake env variables
  t.track_env_var('AZURE_TENANT_ID', 'The tenant id is available on the URI when you access the portal or in powershell')
  t.track_env_var('AZURE_CLIENT_ID', 'Available manage.windowsazure.com -> Active Directory -> Default Directory -> Applications Tab')
  t.track_env_var('AZURE_CLIENT_SECRET', 'Available manage.windowsazure.com -> Active Directory -> Default Directory -> Applications Tab')
  t.track_env_var('AZURE_SUBSCRIPTION_ID', 'Available manage.windowsazure.com -> Settings')
  t.track_env_var('AZURE_MANAGEMENT_CERTIFICATE', 'To create : https://azure.microsoft.com/en-gb/documentation/articles/cloud-services-configure-ssl-certificate/')

  # Set the framework
  t.test_framework('beaker-rspec')
end
