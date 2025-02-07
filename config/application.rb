# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module DulArclight
  # Defines various application-wide settings and options
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    # NOTE: In DUL app, we need to ignore traject here, else our local configs
    # at lib/traject will cause eager loading to fail.
    config.autoload_lib(ignore: %w[assets tasks traject])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.action_mailer.default_options = {
      from: format('dul-arclight@%s', ENV.fetch('APPLICATION_HOSTNAME', 'localhost')),
      reply_to: 'no-reply@duke.edu'
    }
    config.action_mailer.default_url_options = {
      host: ENV.fetch('APPLICATION_HOSTNAME', 'localhost')
    }

    logger           = ActiveSupport::Logger.new($stdout)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end
end
