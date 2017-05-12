# frozen_string_literal: true

# :nodoc:
module RailsVersionHelper
  def rails5?
    is_rails5 = Rails::VERSION::MAJOR == 5
    yield if block_given? && is_rails5
    is_rails5
  end

  def open(method, path, params)
    return send(method, path, params) unless rails5?
    send(method, path, params: params)
  end
end
