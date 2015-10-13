require_relative 'puppet_acceptance_task'


module Rake
  module DSL
    def acceptance_task(*args, &block)
      Rake::PuppetAcceptanceTask.define_task :acceptance, &block
      description = "Tests in the 'Acceptance' tier"
      unless Rake::PuppetAcceptanceTask[:acceptance].comment
        Rake::PuppetAcceptanceTask[:acceptance].add_description(description)
      end
    end
  end
end
