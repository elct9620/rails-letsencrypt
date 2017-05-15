# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/migration'
require 'rails/generators/active_record'

module LetsEncrypt
  module Generators
    # :nodoc:
    class RegisterGenerator < ::Rails::Generators::Base
      def register
        say 'Starting register Let\'s Encrypt account', :green

        setup_environment
        generate_key
        register_email
      rescue Acme::Client::Error => e
        say(e.message, :red)
      end

      private

      def setup_environment
        production = yes?('Do you want to use in production environment? [y/N]:')
        LetsEncrypt.config.use_staging = !production
      end

      def generate_key
        # rubocop:disable Metrics/LineLength
        key_path = ask("Where you to save private key [#{LetsEncrypt.private_key_path}]:", path: true)
        # rubocop:enable Metrics/LineLength
        key_path = LetsEncrypt.private_key_path if key_path.blank?

        return unless file_collision(key_path)
        FileUtils.rm(key_path) if File.exist?(key_path)
        LetsEncrypt.config.use_env_key = false
        LetsEncrypt.config.private_key_path = key_path

        LetsEncrypt.load_private_key

        # rubocop:disable Metrics/LineLength
        say "Your privated key is saved in #{key_path}, make sure setup configure for your rails.", :yellow
        # rubocop:enable Metrics/LineLength
      end

      def register_email
        email = ask('What email you want to register:')
        return say('Email is inavlid!', :red) if email.blank?
        LetsEncrypt.register(email)
        say 'Register successed, don\'t forget backup your private key', :green
      end
    end
  end
end
