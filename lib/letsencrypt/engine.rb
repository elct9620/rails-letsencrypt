module LetsEncrypt
  # :nodoc:
  class Engine < ::Rails::Engine
    isolate_namespace LetsEncrypt
    engine_name :letsencrypt

    config.generators.test_framework :rspec
  end
end
