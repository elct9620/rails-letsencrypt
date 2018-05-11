# frozen_string_literal: true

$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "letsencrypt/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "rails-letsencrypt"
  s.version     = LetsEncrypt::VERSION
  s.authors     = ["蒼時弦也"]
  s.email       = ["elct9620@frost.tw"]
  s.homepage    = "https://github.com/elct9620/rails-letsencrypt"
  s.summary     = "The Let's Encrypt certificate manager for rails"
  s.description = "The Let's Encrypt certificate manager for rails"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  s.require_paths = ["lib"]

  s.add_dependency "rails", ">= 4.1"
  s.add_dependency "acme-client", "~> 2.0.1"
  s.add_dependency "redis"

  s.add_development_dependency "appraisal"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "coveralls"
  s.add_development_dependency "codeclimate-test-reporter"
end
