# Load the main files
require_relative '../module/skeleton_app'
require_relative '../app'

# Load Factories
require_relative './factories.rb'

# Dependencies
require 'minitest/autorun'
require 'minitest/reporters'
require 'rack/test'
require 'bundler/setup'
require 'rubygems'
require 'mongoid'
require 'mocha/setup'
require 'faker'

Bundler.require(:default)

#Minitest reporter
reporter_options = { color: true }
Minitest::Reporters.use! [Minitest::Reporters::DefaultReporter.new(reporter_options)]

# Include Factory Girl in MiniTest
class MiniTest::Unit::TestCase
  include FactoryGirl::Syntax::Methods
end

class MiniTest::Spec
  include FactoryGirl::Syntax::Methods
end

Faker::Config.locale = 'en-US'
