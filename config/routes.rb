LetsEncrypt::Engine.routes.draw do
  get '/acme-challenge/:verification_path', to: 'verifications#show'
end
