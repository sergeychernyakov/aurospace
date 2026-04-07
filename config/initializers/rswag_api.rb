# frozen_string_literal: true

# config/initializers/rswag_api.rb

Rswag::Api.configure do |config|
  config.openapi_root = Rails.root.join('swagger').to_s
end
