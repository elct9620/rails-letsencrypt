# frozen_string_literal: true

Rails.application.routes.draw do
  mount LetsEncrypt::Engine => '/.well-known'
end
