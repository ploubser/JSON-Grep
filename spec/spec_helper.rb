require "rubygems"
require "rspec"
require "rspec/mocks"
require "mocha"
require File.dirname(__FILE__) + "/../lib/jgrep"

RSpec.configure do |config|
  config.mock_with :mocha
end
