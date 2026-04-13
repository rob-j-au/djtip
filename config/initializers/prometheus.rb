# frozen_string_literal: true

# Prometheus metrics configuration
# Provides NewRelic-style metrics collection

require 'prometheus/client'
require 'prometheus/client/formats/text'

# Initialize Prometheus registry
prometheus = Prometheus::Client.registry

# Custom application metrics
CUSTOM_METRICS = {
  # HTTP request metrics
  http_requests: prometheus.counter(
    :http_requests_total,
    docstring: 'Total HTTP requests',
    labels: %i[method path status]
  ),

  http_request_duration: prometheus.histogram(
    :http_request_duration_seconds,
    docstring: 'HTTP request duration in seconds',
    labels: %i[method path],
    buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10]
  ),

  # Database metrics
  db_query_duration: prometheus.histogram(
    :db_query_duration_seconds,
    docstring: 'Database query duration in seconds',
    labels: [:operation],
    buckets: [0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1]
  ),

  # Background job metrics
  sidekiq_jobs: prometheus.counter(
    :sidekiq_jobs_total,
    docstring: 'Total Sidekiq jobs processed',
    labels: %i[queue status]
  ),

  sidekiq_job_duration: prometheus.histogram(
    :sidekiq_job_duration_seconds,
    docstring: 'Sidekiq job duration in seconds',
    labels: %i[queue job_class],
    buckets: [0.1, 0.5, 1, 5, 10, 30, 60, 300]
  ),

  # Application-specific metrics
  tips_created: prometheus.counter(
    :tips_created_total,
    docstring: 'Total tips created'
  ),

  events_created: prometheus.counter(
    :events_created_total,
    docstring: 'Total events created'
  ),

  users_created: prometheus.counter(
    :users_created_total,
    docstring: 'Total users created'
  )
}.freeze

# Middleware to collect HTTP metrics
class PrometheusMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    start_time = Time.now

    status, headers, body = @app.call(env)

    duration = Time.now - start_time
    request = Rack::Request.new(env)

    # Skip metrics endpoint itself and assets
    unless request.path == '/metrics' || request.path.start_with?('/assets')
      # Record request count
      CUSTOM_METRICS[:http_requests].increment(
        labels: {
          method: request.request_method,
          path: normalize_path(request.path),
          status: status.to_s[0] # First digit of status code
        }
      )

      # Record request duration
      CUSTOM_METRICS[:http_request_duration].observe(
        duration,
        labels: {
          method: request.request_method,
          path: normalize_path(request.path)
        }
      )
    end

    [status, headers, body]
  rescue StandardError
    # Record error
    CUSTOM_METRICS[:http_requests].increment(
      labels: {
        method: request&.request_method || 'UNKNOWN',
        path: normalize_path(request&.path || '/unknown'),
        status: '5'
      }
    )
    raise
  end

  private

  def normalize_path(path)
    # Normalize paths to reduce cardinality
    # /users/123 -> /users/:id
    # /events/456/tips -> /events/:id/tips
    path.gsub(%r{/\d+}, '/:id')
        .gsub(%r{/[a-f0-9]{24}}, '/:id') # MongoDB ObjectIds
  end
end

# Add middleware to Rails
Rails.application.config.middleware.use PrometheusMiddleware

# Expose metrics endpoint
Rails.application.routes.prepend do
  get '/metrics' => proc { |_env|
    [
      200,
      { 'Content-Type' => Prometheus::Client::Formats::Text::CONTENT_TYPE },
      [Prometheus::Client::Formats::Text.marshal(Prometheus::Client.registry)]
    ]
  }
end

Rails.logger.info 'Prometheus metrics initialized at /metrics'
