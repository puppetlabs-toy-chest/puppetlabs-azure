require_relative '../lib/env_var_checker'

module Rake
  class PuppetAcceptanceTask < Task

    include EnvVar

    def initialize(task_name=:acceptance, app)
      super
      @configuration = true
    end

    def test_framework(framework)
      # required as the default acceptance task will attempt
      # to kick off all spec tests and now allow us the chance
      # to execute a dependent task based on the framework
      Rake::Task[:acceptance].clear
      case framework.downcase
        when 'beaker'
          Rake::Task[:beaker].invoke
        when 'beaker-rspec'
          Rake::Task[:beaker_rspec].invoke
      end
    end
  end
end
