# frozen_string_literal: true

require 'rails/version'

require_relative 'boot'

require 'rails/all'

Bundler.require(*Rails.groups)
require 'rails-letsencrypt'

module Dummy
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    case Rails::VERSION::MAJOR
    when 6
      config.load_defaults 6.0
    when 5
      config.load_defaults 5.1
      config.active_record.sqlite3.represent_boolean_as_integer = true
    end

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
  end
end
