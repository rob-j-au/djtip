# frozen_string_literal: true

Rswag::Api.configure do |c|
  # Specify a root path where OpenAPI JSON/YAML specs are located
  c.openapi_root = Rails.root.join('config/openapi').to_s
end