require "rubygems"
require "rspec"
require "rspec/mocks"
require "mocha"
require "jgrep"

RSpec.configure do |config|
  config.mock_with :mocha
end
