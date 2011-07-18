require "rubygems"
require "rspec"
require "rspec/mocks"
require "mocha"
require File.dirname(__FILE__) + "/../jgrep.rb"

RSpec.configure do |config|
    config.mock_with :mocha
end

