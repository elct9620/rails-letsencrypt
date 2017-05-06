# LetsEncrypt

Provide manageable Let's Encrypt Certificate for Rails.

## Installation

Puts this in your Gemfile:

```ruby
gem 'rails-letsencrypt'
```

Run install migrations
```bash
rake letsencrypt:install:migrations
rake db:migrate
```

Add `acme-challenge` mounts in `config/routes.rb`
```ruby
mount LetsEncrypt::Engine => '/.well-known'
```

## Usage

The SSL certificate setup is depend on web server, this gem can work with `ngx_mruby` or `kong`.

### ngx_mruby

The setup is following this [Article](http://hb.matsumoto-r.jp/entry/2017/03/23/173236)

Add `config/initializers/letsencrypt.rb` to add config to sync certificate.

```ruby
LetsEncrypt.config.redis_url = 'redis://localhost:6379/1'
LetsEncrypt.config.save_to_redis = true
```

Connect `Redis` when nginx worker start
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

### Kong

Not support now.

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
