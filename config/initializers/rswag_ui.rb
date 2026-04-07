# frozen_string_literal: true

# config/initializers/rswag_ui.rb

Rswag::Ui.configure do |config|
  config.openapi_endpoint '/api-docs/v1/swagger.yaml', 'AUROSPACE Orders API V1'
end
