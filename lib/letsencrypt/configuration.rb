module LetsEncrypt
  # :nodoc:
  class Configuration
    include ActiveSupport::Configurable

    config_accessor :private_key_path
    config_accessor :use_env_key do
      false
    end

    config_accessor :save_to_redis
    config_accessor :redis_url

    def use_redis?
      save_to_redis == true
    end
  end
end
