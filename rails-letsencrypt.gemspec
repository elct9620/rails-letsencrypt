# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)

# Maintain your gem's version:
require 'letsencrypt/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'rails-letsencrypt'
  s.version     = LetsEncrypt::VERSION
  s.authors     = ['蒼時弦也']
  s.email       = ['elct9620@frost.tw']
  s.homepage    = 'https://github.com/elct9620/rails-letsencrypt'
  s.summary     = "The Let's Encrypt certificate manager for rails"
  s.description = "The Let's Encrypt certificate manager for rails"
  s.license     = 'MIT'

  s.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']
  s.require_paths = ['lib']

  s.required_ruby_version = '>= 3.2.0'
  s.add_dependency 'acme-client', '~> 2.0.0'
  s.add_dependency 'actionmailer', '>= 6.1'
  s.add_dependency 'actionpack', '>= 6.1'
  s.add_dependency 'actionview', '>= 6.1'
  s.add_dependency 'activemodel', '>= 6.1'
  s.add_dependency 'activerecord', '>= 6.1'
  s.add_dependency 'activesupport', '>= 6.1'
  s.add_dependency 'railties', '>= 6.1'
  s.add_dependency 'redis'
  s.metadata['rubygems_mfa_required'] = 'true'
end
