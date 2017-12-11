require 'rake'
PE_RELEASES = {
  '2017.2' => 'http://neptune.puppetlabs.lan/2017.2/ci-ready/',
  '2017.3' => 'http://neptune.puppetlabs.lan/2017.3/ci-ready/'
}.freeze

fast_tests = [
  'spec/*/arm_vm_spec.rb'
]

acceptance_tests = [
  'spec/*/arm_vm_minimal_spec.rb',
  'spec/*/all_properties_spec.rb'
]

arm_tests = [
  'spec/*/arm_vm_datadisks_spec.rb',
  'spec/*/arm_vm_managed_disk_spec.rb',
  'spec/*/arm_vm_security_group_spec.rb',
  'spec/*/arm_vm_minimal_spec.rb'
]

classic_extensions = [
  'spec/*/resource_template_spec.rb',
  'spec/*/multi_role_service_spec.rb',
  'spec/*/endpoints_spec.rb'
]

classic_windows = [
  'spec/*/windows_machine_spec.rb'
]

task :envs do
  ENV['BEAKER_debug'] = true if ENV['BEAKER_DEBUG']
  ENV['BEAKER_TESTMODE'] = ENV['BEAKER_TESTMODE'] || 'local'
  ENV['BEAKER_set'] = ENV['BEAKER_set'] || 'pooler/centos7'
  ENV['PUPPET_INSTALL_VERSION'] = ENV['PUPPET_INSTALL_VERSION'] || '2017.2'
  ENV['BEAKER_PE_DIR'] = ENV['BEAKER_PE_DIR'] || PE_RELEASES[ENV['PUPPET_INSTALL_VERSION']]
  ENV['PUPPET_INSTALL_TYPE'] = "pe"
  # ENV['BEAKER_PE_VER'] = ENV['BEAKER_PE_VER'] || `curl http://getpe.delivery.puppetlabs.net/latest/#{ENV['PUPPET_INSTALL_VERSION']}`
end

desc "Run fast acceptance tests"
RSpec::Core::RakeTask.new(:fast => [:spec_prep, :envs]) do |t|
  t.pattern = fast_tests
end

desc "Run acceptance tests"
RSpec::Core::RakeTask.new(:acceptance => [:spec_prep, :envs]) do |t|
  t.pattern = acceptance_tests
end

desc "Run ARM acceptance tests"
RSpec::Core::RakeTask.new(:arm_only => [:spec_prep, :envs]) do |t|
  t.pattern = arm_tests
end

desc "Run ASM acceptance tests"
RSpec::Core::RakeTask.new(:asm_extensions => [:spec_prep, :envs]) do |t|
  t.pattern = classic_extensions
end

desc "Run ASM windows acceptance tests"
RSpec::Core::RakeTask.new(:asm_windows => [:spec_prep, :envs]) do |t|
  t.pattern = classic_windows
end

