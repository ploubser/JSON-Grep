require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

desc "Run rubycop style checks"
task :rubocop do
  sh("rubocop -f progress -f offenses lib spec bin")
end

task :default => [:rubocop, :spec]
