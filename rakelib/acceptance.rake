require 'rake/task_arguments'
require 'rake/tasklib'
require 'rake'

# We clear the Beaker rake tasks from spec_helper as they assume
# rspec-puppet and a certain filesystem layout
Rake::Task[:beaker_nodes].clear
Rake::Task[:beaker].clear

module Beaker
  module Tasks
    class RakeTask < ::Rake::TaskLib
      include ::Rake::DSL if defined?(::Rake::DSL)

      [
        :name,
        :keyfile,
        :config,
        :debug,
        :tests,
        :pe_dir,
      ].each do |sym|
        attr_accessor(sym.to_sym)
      end

      def initialize(name, *args, &task_block)
        @name = name
        define(args, &task_block)
      end

      private
      def run_task(verbose)
        ENV['BEAKER_PE_DIR'] = pe_dir
        system(beaker_command)
      end

      def define(args, &task_block)
        task name, *args do |_, task_args|
          RakeFileUtils.__send__(:verbose, verbose) do
            task_block.call(*[self, task_args].slice(0, task_block.arity)) if task_block
            run_task verbose
          end
        end
      end

      def beaker_command
        cmd_parts = []
        cmd_parts << "beaker"
        cmd_parts << "--debug" if @debug
        cmd_parts << "--config #{@config}"
        cmd_parts << "--keyfile #{@keyfile}" if @keyfile
        cmd_parts << "--test #{@tests}"
        cmd_parts << "--pre-suite integration/pre-suite"
        cmd_parts << "--load-path integration/lib"
        cmd_parts << "--timeout 360"
        cmd_parts.flatten.join(" ")
      end
    end
  end
end

PE_RELEASES = {
  '3.8.1' => 'http://pe-releases.puppetlabs.lan/3.8.1/',
  '2015.2' => 'http://enterprise.delivery.puppetlabs.net/2015.2/preview/',
}

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
          ENV['BEAKER_PE_DIR'] = pe_dir
          ENV['BEAKER_set'] = "acceptance/nodesets/#{ns}/#{config}.yml"
          desc "Run accpetance tests for #{config} on #{ns} with PE #{version}"
          RSpec::Core::RakeTask.new("#{config}_#{version}".to_sym) do |t|
            t.pattern = 'spec/acceptance'
          end
        end
      end
    end
  end
end

desc "Run acceptance tests"
RSpec::Core::RakeTask.new(:acceptance) do |t|
  ENV['BEAKER_PE_DIR'] = ENV['BEAKER_PE_DIR'] || PE_RELEASES['2015.2']
  ENV['BEAKER_set'] = ENV['BEAKER_set'] || 'acceptance/nodesets/vagrant/ubuntu1404.yml'
  t.pattern = 'spec/acceptance'
end
