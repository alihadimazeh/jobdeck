require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Jobdeck
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # The business's day, not UTC: "Today", follow-ups due/overdue, and every "N days late /
    # over / overdue" count come from Date.current, which follows this zone. Under UTC they all
    # rolled over to tomorrow at 8pm Eastern. One zone for now; per-business zones come with
    # multi-tenancy. The DB keeps storing UTC (Active Record's default), so this only changes
    # how times are read and how "today" is decided.
    config.time_zone = "Eastern Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
