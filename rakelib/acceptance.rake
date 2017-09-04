require 'rake'
require 'parallel_tests'

# We clear the Beaker rake tasks from spec_helper as they assume
# rspec-puppet and a certain filesystem layout
Rake::Task[:beaker_nodes].clear
Rake::Task[:beaker].clear

module ParallelTests
  module Tasks
    def self.parse_args(args)
      args = [args[:count], args[:options]]

      # count given or empty ?
      # parallel:spec[2,options]
      # parallel:spec[,options]
      count = args.shift if args.first.to_s =~ /^\d*$/
      num_processes = count.to_i unless count.to_s.empty?
      options = args.shift

      [num_processes, options.to_s]
    end
  end
end

namespace :parallel do
  desc "Run acceptance in parallel with parallel:acceptance[num_cpus]"
  task :acceptance, [:count, :options] do |t, args|
    ENV['BEAKER_TESTMODE'] = 'local'
    count, options = ParallelTests::Tasks.parse_args(args)
    executable = 'parallel_test'
    command = "#{executable} spec --type rspec " \
      "-n #{count} "                 \
      "--pattern 'spec/acceptance' " \
      "--test-options '#{options}'"
    abort unless system(command)
  end
end

PE_RELEASES = {
  '2016.2' => 'http://pm.puppetlabs.com/puppet-enterprise/2016.4.6/',
  '2017.2' => 'http://pm.puppetlabs.com/puppet-enterprise/2017.2.2/'
}.freeze

desc "Run acceptance tests"
RSpec::Core::RakeTask.new(:acceptance => [:spec_prep, :envs]) do |t|
  t.pattern = 'spec/acceptance'
end

fast_tests = [
  'spec/*/all_properties_spec.rb',
  'spec/*/arm_vm_spec.rb',
  'spec/*/config_validation_spec.rb'
]

arm_tests = [
  'spec/*/arm_vm_datadisks_spec.rb',
  'spec/*/arm_vm_plan_spec.rb',
  'spec/*/arm_vm_no_publicip_spec.rb',
  'spec/*/arm_vm_minimal_spec.rb'
]

classic_resources = [
  'spec/*/storage_account_spec.rb',
  'spec/*/resource_group_spec.rb',
  'spec/*/resource_template_spec.rb',
]

classic_operations = [
  'spec/*/minimal_properties_spec.rb',
  'spec/*/stopped_machine_spec.rb',
  'spec/*/invalid_image_spec.rb'
]

classic_extensions = [
  'spec/*/multi_role_service_spec.rb',
  'spec/*/endpoints_spec.rb'
]

classic_windows = [
  'spec/*/windows_machine_spec.rb'
]

mandatory_envs = [
  'AZURE_MANAGEMENT_CERTIFICATE',
  'AZURE_CLIENT_ID',
  'AZURE_CLIENT_SECRET',
  'AZURE_SUBSCRIPTION_ID',
  'AZURE_TENANT_ID'
]

task :envs do
  ENV['BEAKER_debug'] = true if ENV['BEAKER_DEBUG']
  ENV['BEAKER_TESTMODE'] = 'agent'
  ENV['BEAKER_set'] = ENV['BEAKER_set'] || 'pooler/centos7m_windows2012r2a'
  ENV['PUPPET_INSTALL_VERSION'] = ENV['PUPPET_INSTALL_VERSION'] || '2017.1'
  ENV['BEAKER_PE_DIR'] = ENV['BEAKER_PE_DIR'] || PE_RELEASES[ENV['PUPPET_INSTALL_VERSION']]
  ENV['PUPPET_INSTALL_TYPE'] = "pe"
  ENV['BEAKER_PE_VER'] = ENV['BEAKER_PE_VER'] || `curl http://getpe.delivery.puppetlabs.net/latest/#{ENV['PUPPET_INSTALL_VERSION']}`
  for env in mandatory_envs
    fail "#{env} must be set" unless ENV[env]
  end 
end

desc "Run fast acceptance tests"
RSpec::Core::RakeTask.new(:fast => [:spec_prep, :envs]) do |t|
  t.pattern = fast_tests
end

desc "Run arm_only acceptance tests"
RSpec::Core::RakeTask.new(:arm_only => [:spec_prep, :envs]) do |t|
  t.pattern = arm_tests
end

desc "Run asm_resources acceptance tests"
RSpec::Core::RakeTask.new(:asm_resources => [:spec_prep, :envs]) do |t|
  t.pattern = classic_resources
end

desc "Run asm_operations acceptance tests"
RSpec::Core::RakeTask.new(:asm_operations => [:spec_prep, :envs]) do |t|
  t.pattern = classic_operations
end

desc "Run asm_extensions acceptance tests"
RSpec::Core::RakeTask.new(:asm_extensions => [:spec_prep, :envs]) do |t|
  t.pattern = classic_extensions
end

desc "Run asm_windows acceptance tests"
RSpec::Core::RakeTask.new(:asm_windows => [:spec_prep, :envs]) do |t|
  t.pattern = classic_windows
end

namespace :acceptance do
  {
    :vagrant => [
      'ubuntu1404',
      'centos7',
      'centos6',
      'ubuntu1404m_debian7a',
      'ubuntu1404m_ubuntu1404a',
      'centos7m_centos7a',
      'centos6m_centos6a',
    ],
    :pooler => [
      'ubuntu1404',
      'centos7',
      'centos6',
      'ubuntu1404m_debian7a',
      'ubuntu1404m_ubuntu1404a',
      'centos7m_centos7a',
      'centos6m_centos6a',
      'rhel7',
      'rhel7m_scientific7a',
      'centos7m_windows2012a',
      'centos7m_windows2012r2a',
    ]
  }.each do |ns, configs|
    namespace ns.to_sym do
      configs.each do |config|
        PE_RELEASES.each do |version, pe_dir|
          desc "Run acceptance tests for #{config} on #{ns} with PE #{version}"
          RSpec::Core::RakeTask.new("#{config}_#{version}".to_sym => [:spec_prep, :envs]) do |t|
            ENV['BEAKER_PE_DIR'] = pe_dir
            ENV['BEAKER_keyfile'] = '~/.ssh/id_rsa-acceptance' if ns == :pooler
            ENV['BEAKER_debug'] = true if ENV['BEAKER_DEBUG']
            ENV['BEAKER_set'] = "#{ns}/#{config}"
            t.pattern = 'spec/acceptance'
          end
        end
      end
    end
  end
end
