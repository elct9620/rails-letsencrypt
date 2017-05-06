module LetsEncrypt
  # :nodoc:
  class Configuration
    include ActiveSupport::Configurable

    config_accessor :private_key_path
    config_accessor :use_env_key do
      false
    end
  end
end
