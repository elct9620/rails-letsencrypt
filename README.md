Rails LetsEncrypt
===

[![Gem Version](https://badge.fury.io/rb/rails-letsencrypt.svg)](https://badge.fury.io/rb/rails-letsencrypt)
[![Code Climate](https://codeclimate.com/github/elct9620/rails-letsencrypt/badges/gpa.svg)](https://codeclimate.com/github/elct9620/rails-letsencrypt)
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/elct9620/rails-letsencrypt)

Provide manageable Let's Encrypt Certificate for Rails.

## Requirement

* Rails 7.2+
* Ruby 3.2+

## Installation

Puts this in your Gemfile:

```ruby
gem 'rails-letsencrypt'
```

Run install migrations

```bash
rails generate lets_encrypt:install
rake db:migrate
```

Setup private key for Let's Encrypt API, and create an account at letsencrypt.org associated with that key

```bash
rails generate lets_encrypt:register
```


Add `acme-challenge` mounts in `config/routes.rb`
```ruby
mount LetsEncrypt::Engine => '/.well-known'
```

### Configuration

Add a file to `config/initializers/letsencrypt.rb` and put below config you need.

```ruby
LetsEncrypt.config do |config|
  # Configure the ACME server
  # Default is Let's Encrypt production server
  # config.acme_server = 'https://acme-v02.api.letsencrypt.org/directory'

  # Using Let's Encrypt staging server or not
  # Default only `Rails.env.production? == true` will use Let's Encrypt production server.
  # config.use_staging = true

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
```

> [!WARNING]
> **Depcrecation Notice**
> The `use_staging` will be removed in the future, and the `acme_server` will be used to determine the server.

## Usage

The SSL certificate setup depends on the web server, this gem can work with `ngx_mruby` or `kong`.

### Service

#### Renew Service

```ruby
certificate = LetsEncrypt::Certificate.find_by(domain: 'example.com')

service = LetsEncrypt::RenewService.new
service.execute(certificate)
```

#### Verify Service

```ruby
certificate = LetsEncrypt::Certificate.find_by(domain: 'example.com')

order = LetsEncrypt.client.new_order(identifiers: [certificate.domain])

service = LetsEncrypt::VerifyService.new
service.execute(certificate, order)
```

#### Issue Service

```ruby
certificate = LetsEncrypt::Certificate.find_by(domain: 'example.com')

order = LetsEncrypt.client.new_order(identifiers: [certificate.domain])

service = LetsEncrypt::IssueService.new
service.execute(certificate, order)
```

### Certificate Model

#### Create

Add a new domain into the database.

```ruby
cert = LetsEncrypt::Certificate.create(domain: 'example.com')
cert.get # alias  `verify && issue`
```

> [!WARNING]
> **Depcrecation Notice**
> The `get` will be replaced by `RenewService` in the future.

#### Verify

Makes a request to Let's Encrypt and verify domain

```ruby
cert = LetsEncrypt::Certificate.find_by(domain: 'example.com')
cert.verify
```

> [!WARNING]
> **Depcrecation Notice**
> The `verify` will be replaced by `VerifyService` in the future.

#### Issue

Ask Let's Encrypt to issue a new certificate.

```ruby
cert = LetsEncrypt::Certificate.find_by(domain: 'example.com')
cert.issue
```

> [!WARNING]
> **Depcrecation Notice**
> The `issue` will be replaced by `IssueService` in the future.

#### Renew

```ruby
cert = LetsEncrypt::Certificate.find_by(domain: 'example.com')
cert.renew
```

> [!WARNING]
> **Depcrecation Notice**
> The `renew` will be replaced by `RenewService` in the future.

#### Status

Check a certificate is verified and issued.

```ruby
cert = LetsEncrypt::Certificate.find_by(domain: 'example.com')
cert.active? # => true
```

Check a certificate is expired.

```ruby
cert = LetsEncrypt::Certificate.find_by(domain: 'example.com')
cert.expired? # => false
```

### Tasks

To renew a certificate, you can run `renew` task to renew coming expires certificates.

```bash
rake letsencrypt:renew
```

### Jobs

If you are using Sidekiq or others, you can enqueue renew task daily.

```ruby
LetsEncrypt::RenewCertificatesJob.perform_later
```

### Subscribe

When the certificate is trying to issue a new one, you can subscribe it for logging or error handling.

```ruby
ActiveSupport::Notifications.subscribe('letsencrypt.issue') do |name, start, finish, id, payload|
  Rails.logger.info("Certificate for #{payload[:domain]} is issued")
end
```

### ngx_mruby

The setup is following this [Article](http://hb.matsumoto-r.jp/entry/2017/03/23/173236)

Add `config/initializers/letsencrypt.rb` to add config to sync certificate.

```ruby
LetsEncrypt.config do |config|
  config.redis_url = 'redis://localhost:6379/1'
  config.save_to_redis = true
end
```

Connect `Redis` when Nginx worker start
```
http {
  # ...
  mruby_init_worker_code '
    userdata = Userdata.new
    userdata.redis = Redis.new "127.0.0.1", 6379
    # If your redis database is not 0, please select a correct one
    userdata.redis.select 1
  ';
}
```

Setup SSL using mruby
```
server {
  listen 443 ssl;
  server_name _;

  ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
  ssl_ciphers HIGH:!aNULL:!MD5;
  ssl_certificate certs/dummy.crt;
  ssl_certificate_key certs/dummy.key;

  mruby_ssl_handshake_handler_code '
    ssl = Nginx::SSL.new
    domain = ssl.servername

    redis = Userdata.new.redis
    unless redis["#{domain}.crt"].nil? and redis["#{domain}.key"].nil?
      ssl.certificate_data = redis["#{domain}.crt"]
      ssl.certificate_key_data = redis["#{domain}.key"]
    end
  ';
}
```

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
