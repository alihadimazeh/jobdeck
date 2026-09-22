ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

module ActionDispatch
  # Every controller now requires authentication (app/controllers/concerns/authentication.rb).
  # These pre-existing scaffold tests exercise the resource controllers directly, not the
  # sign-in flow itself, so sign in as the fixture user before each one.
  class IntegrationTest
    setup do
      post session_url, params: { email: users(:one).email, password: "password123" }
    end
  end
end
