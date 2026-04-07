# frozen_string_literal: true

# spec/swagger_helper.rb

require 'rails_helper'

RSpec.configure do |config|
  config.openapi_root = Rails.root.join('swagger').to_s

  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'AUROSPACE Orders API',
        version: 'v1',
        description: 'Payment workflow API for AUROSPACE Orders Demo',
      },
      servers: [
        { url: '/' },
      ],
    },
  }

  config.openapi_strict_schema_validation = true
end
