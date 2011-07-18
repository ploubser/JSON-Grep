specdir = File.join([File.dirname(__FILE__), "spec"])

require "#{specdir}/spec_helper.rb"
require "rake"
require "rspec/core/rake_task"

desc "Run JGrep tests"
RSpec::Core::RakeTask.new(:test) do |t|
    t.pattern = "spec/unit/*_spec.rb"
    t.rspec_opts = "--format s --color --backtrace"
end

task :default => :test
