# frozen_string_literal: true

# OpenTelemetry configuration for distributed tracing
# This provides NewRelic-style APM capabilities using open-source tools

require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'
require 'opentelemetry/instrumentation/all'

# Configure OTLP endpoint
otlp_endpoint = ENV.fetch('OTEL_EXPORTER_OTLP_ENDPOINT') do
  if Rails.env.production?
    'http://observability-tempo.observability.svc.cluster.local:4318'
  else
    'http://localhost:4318' # For local development
  end
end

# Set environment variables for OpenTelemetry SDK
ENV['OTEL_SERVICE_NAME'] ||= 'djtip'
ENV['OTEL_EXPORTER_OTLP_ENDPOINT'] ||= otlp_endpoint
ENV['OTEL_TRACES_EXPORTER'] ||= 'otlp'
ENV['OTEL_EXPORTER_OTLP_PROTOCOL'] ||= 'http/protobuf'

# Configure OpenTelemetry SDK
OpenTelemetry::SDK.configure(&:use_all)

Rails.logger.info "OpenTelemetry initialized: service=djtip, endpoint=#{otlp_endpoint}"

# Add custom instrumentation helpers
module OpenTelemetryHelpers
  # Create a custom span for any block of code
  # Usage: trace_span('database.query') { User.find(id) }
  def trace_span(name, attributes = {})
    tracer = OpenTelemetry.tracer_provider.tracer('djtip', '1.0.0')
    tracer.in_span(name, attributes: attributes) do |span|
      result = yield
      span.set_attribute('result.success', true)
      result
    rescue StandardError => e
      span.set_attribute('result.success', false)
      span.set_attribute('error.type', e.class.name)
      span.set_attribute('error.message', e.message)
      span.status = OpenTelemetry::Trace::Status.error(e.message)
      raise
    end
  end

  # Add custom attributes to current span
  # Usage: add_trace_attributes('user.id' => current_user.id)
  def add_trace_attributes(attributes)
    span = OpenTelemetry::Trace.current_span
    attributes.each { |k, v| span.set_attribute(k.to_s, v) }
  end
end

# Include helpers in controllers and models
ActiveSupport.on_load(:action_controller) do
  include OpenTelemetryHelpers
end

ActiveSupport.on_load(:active_record) do
  include OpenTelemetryHelpers
end
