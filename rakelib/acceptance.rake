require 'rake/task_arguments'
require 'rake/tasklib'
require 'rake'

task :default => [:test]

task :test do
  puts "GH:: in :test"
end

task :rspec do
  puts "GH:: HA this is the rspec task"
end
