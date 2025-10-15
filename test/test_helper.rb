ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require 'mocha/minitest'

class ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods

  # Disable parallel tests to avoid factory sequence collisions
  # parallelize(workers: :number_of_processors)
  # fixtures :all
end

class ActionDispatch::IntegrationTest
  def login_as(account)
    ApplicationController.any_instance.stubs(:current_account).returns(account)
  end
end
