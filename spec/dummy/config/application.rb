# frozen_string_literal: true

require 'rails/version'

if Rails::VERSION::MAJOR == 5
  require_relative 'boot'

  require 'rails/all'

  Bundler.require(*Rails.groups)
  require 'rails-letsencrypt'

  module Dummy
    class Application < Rails::Application
      config.load_defaults 5.1
    end
  end

else
  require File.expand_path('../boot', __FILE__)

  # Pick the frameworks you want:
  require 'active_record/railtie'
  require 'action_controller/railtie'
  require 'action_mailer/railtie'
  require 'action_view/railtie'
  require 'sprockets/railtie'

  Bundler.require(*Rails.groups)
  require 'rails-letsencrypt'

  module Dummy
    class Application < Rails::Application
      config.active_record.raise_in_transactional_callbacks = true
    end
  end
end
