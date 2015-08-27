require 'rake'

# We clear the Beaker rake tasks from spec_helper as they assume
# rspec-puppet and a certain filesystem layout
Rake::Task[:beaker_nodes].clear
Rake::Task[:beaker].clear

PE_RELEASES = {
  '3.8.1' => 'http://pe-releases.puppetlabs.lan/3.8.1/',
  '2015.2' => 'http://pe-releases.puppetlabs.lan/2015.2.0/',
}

desc "Run acceptance tests"
RSpec::Core::RakeTask.new(:acceptance) do |t|
  ENV['BEAKER_PE_DIR'] = ENV['BEAKER_PE_DIR'] || PE_RELEASES['2015.2']
  ENV['BEAKER_set'] = ENV['BEAKER_set'] || 'vagrant/ubuntu1404'
  t.pattern = 'spec/acceptance'
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
    ]
  }.each do |ns, configs|
    namespace ns.to_sym do
      configs.each do |config|
        PE_RELEASES.each do |version, pe_dir|
          desc "Run accpetance tests for #{config} on #{ns} with PE #{version}"
          RSpec::Core::RakeTask.new("#{config}_#{version}".to_sym) do |t|
            ENV['BEAKER_PE_DIR'] = pe_dir
            ENV['BEAKER_set'] = "#{ns}/#{config}"
            t.pattern = 'spec/acceptance'
          end
        end
      end
    end
  end
end


