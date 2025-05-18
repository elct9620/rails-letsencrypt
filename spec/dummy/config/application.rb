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
    when 8
      config.load_defaults 8.0
    when 7
      config.load_defaults 7.2
    end

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
  end
end
