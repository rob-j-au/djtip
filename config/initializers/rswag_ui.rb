# frozen_string_literal: true

Rswag::Ui.configure do |c|
  # List of OpenAPI specs to display in the Swagger UI
  c.openapi_endpoint '/api-docs/v1/openapi.json', 'DJTip API v1'
end