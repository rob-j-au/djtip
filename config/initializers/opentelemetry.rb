# OpenTelemetry configuration for distributed tracing
# This provides NewRelic-style APM capabilities using open-source tools

require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'
require 'opentelemetry/instrumentation/all'

OpenTelemetry::SDK.configure do |c|
  # Service name - appears in Grafana/Tempo
  c.service_name = ENV.fetch('OTEL_SERVICE_NAME', 'djtip')
  c.service_version = '1.0.0'
  
  # Resource attributes - additional metadata (must be strings, integers, floats, or booleans)
  c.resource = OpenTelemetry::SDK::Resources::Resource.create(
    'deployment.environment' => Rails.env.to_s,
    'service.namespace' => 'djtip',
    'service.instance.id' => Socket.gethostname.to_s
  )
  
  # Auto-instrument everything (like NewRelic)
  c.use_all({
    'OpenTelemetry::Instrumentation::ActionPack' => { enabled: true },
    'OpenTelemetry::Instrumentation::ActionView' => { enabled: true },
    'OpenTelemetry::Instrumentation::ActiveJob' => { enabled: true },
    'OpenTelemetry::Instrumentation::ActiveSupport' => { enabled: true },
    'OpenTelemetry::Instrumentation::Faraday' => { enabled: true },
    'OpenTelemetry::Instrumentation::HttpClient' => { enabled: true },
    'OpenTelemetry::Instrumentation::Net::HTTP' => { enabled: true },
    'OpenTelemetry::Instrumentation::Rack' => { enabled: true },
    'OpenTelemetry::Instrumentation::Rails' => { enabled: true },
    'OpenTelemetry::Instrumentation::Redis' => { enabled: true },
    'OpenTelemetry::Instrumentation::Sidekiq' => { enabled: true },
  })
  
  # Configure OTLP exporter to send traces to Tempo
  otlp_endpoint = ENV.fetch('OTEL_EXPORTER_OTLP_ENDPOINT') do
    if Rails.env.production?
      'http://observability-tempo.observability.svc.cluster.local:4318'
    else
      'http://localhost:4318'  # For local development
    end
  end
  
  c.add_span_processor(
    OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
      OpenTelemetry::Exporter::OTLP::Exporter.new(
        endpoint: "#{otlp_endpoint}/v1/traces",
        headers: {},
        compression: 'gzip'
      )
    )
  )
  
  # Sampling is controlled via OTEL_TRACE_SAMPLE_RATE environment variable
  # Set in deployment.yaml: OTEL_TRACE_SAMPLE_RATE=1.0 for 100% sampling
  
  Rails.logger.info "OpenTelemetry initialized: service=#{c.service_name}, endpoint=#{otlp_endpoint}"
end

# Add custom instrumentation helpers
module OpenTelemetryHelpers
  # Create a custom span for any block of code
  # Usage: trace_span('database.query') { User.find(id) }
  def trace_span(name, attributes = {})
    tracer = OpenTelemetry.tracer_provider.tracer('djtip', '1.0.0')
    tracer.in_span(name, attributes: attributes) do |span|
      begin
        result = yield
        span.set_attribute('result.success', true)
        result
      rescue => e
        span.set_attribute('result.success', false)
        span.set_attribute('error.type', e.class.name)
        span.set_attribute('error.message', e.message)
        span.status = OpenTelemetry::Trace::Status.error(e.message)
        raise
      end
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
