# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LetsEncrypt::VerificationsController, type: :controller do
  routes { LetsEncrypt::Engine.routes }
end
