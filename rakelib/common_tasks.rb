require_relative '../lib/color_text'
require_relative 'puppet_acceptance_task'
require_relative 'beaker_tasks'

require 'rake/task_arguments'
require 'rake/tasklib'
require 'rake'

include ColorText

# The lauching of pooler master/agent config is not part of the rototiller remit.
# There is a new gem being released for this "test mode switcher"
ENV['PUPPET_AZURE_BEAKER_MODE'] = 'local' # Demo only.

# Demo only
# Normally we would work through a config loop. See the cloud modules.
ns = 'pooler'
config = 'pooler/centos7m_centos7a'
version = ''
test_file = 'spec/acceptance/test.rb'
## End Demo Config

Rake::TaskManager.record_task_metadata = true

task :parse_env do |t|
  # This task is used by other tasks
  include EnvVar
  t.check_env_vars
end

task :beaker_task do |t|
end

Beaker::Tasks::RakeTask.new(:beaker_test => :parse_env) do |task, args|
  puts green_text('test framework => ') << bold(green_text('BEAKER'))

  task.config = "spec/acceptance/nodesets/#{ns}/#{config}.yml"
  task.pe_dir = ENV['BEAKER_PE_DIR'] || pe_dir
  task.keyfile = '~/.ssh/id_rsa-acceptance' if ns == :pooler
  task.debug = true if ENV['BEAKER_DEBUG']
  task.tests = ENV['TESTS'] || 'integration/tests'
end

RSpec::Core::RakeTask.new(:beaker_rspec => :parse_env) do |t|
  puts green_text('test framework => ') << bold(green_text('RSPEC'))

  ENV['BEAKER_PE_DIR'] = ENV['BEAKER_PE_DIR'] || PE_RELEASES['2015.2']
  ENV['BEAKER_set'] = ENV['BEAKER_set'] || 'vagrant/ubuntu1404'

  t.pattern = test_file
end
