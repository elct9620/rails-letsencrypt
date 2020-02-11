Rails.application.routes.draw do
  mount LetsEncrypt::Engine => '/.well-known'
end
