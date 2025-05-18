LetsEncrypt.config do |config|
  # Using Let's Encrypt staging server or not
  # Default only `Rails.env.production? == true` will use Let's Encrypt production server.
  config.use_staging = true

  # Set the private key path
  # Default is locate at config/letsencrypt.key
  config.private_key_path = Rails.root.join('config', 'letsencrypt.key')

  # Use environment variable to set private key
  # If enable, the API Client will use `LETSENCRYPT_PRIVATE_KEY` as private key
  # Default is false
  config.use_env_key = false

  # Should sync certificate into redis
  # When using ngx_mruby to dynamic load certificate, this will be helpful
  # Default is false
  config.save_to_redis = false

  # The redis server url
  # Default is nil
  config.redis_url = 'redis://localhost:6379/1'

  # Enable it if you want to customize the model
  # Default is LetsEncrypt::Certificate
  # config.certificate_model = 'MyCertificate'

  # Configure the maximum attempts to re-check status when verifying or issuing
  # config.max_attempts = 30
end

