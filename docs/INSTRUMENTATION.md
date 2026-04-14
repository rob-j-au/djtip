# Application Instrumentation Guide

Complete guide for OpenTelemetry tracing and Prometheus metrics in the djtip Rails application.

## Overview

The djtip application is fully instrumented with:

- **📊 Prometheus Metrics** - Request rates, durations, errors, custom business metrics
- **🔍 OpenTelemetry Traces** - Distributed tracing across all requests (NewRelic-style APM)
- **📝 Automatic Instrumentation** - Rails, Sidekiq, Redis, HTTP clients all auto-instrumented

## What Gets Automatically Traced

### HTTP Requests
Every HTTP request is automatically traced with:
- Request method and path
- Response status code
- Duration
- Query parameters
- Headers (sanitized)
- User agent

### Database Queries
All MongoDB queries are traced with:
- Query type (find, insert, update, delete)
- Collection name
- Query duration
- Document count

### Background Jobs
All Sidekiq jobs are traced with:
- Job class name
- Queue name
- Arguments (sanitized)
- Duration
- Success/failure status

### External HTTP Calls
All outbound HTTP requests are traced:
- Target URL
- HTTP method
- Response status
- Duration

### Redis Operations
All Redis commands are traced:
- Command name
- Key (sanitized)
- Duration

## Viewing Traces in Grafana

### 1. Access Grafana
Open https://grafana.minikube.local (no login required)

### 2. Go to Explore
Click the **Explore** icon (compass) in the left sidebar

### 3. Select Tempo Datasource
Choose **Tempo** from the datasource dropdown

### 4. Search for Traces

**By Service:**
```
Service: djtip
```

**By Duration:**
```
Min Duration: 100ms
Max Duration: 5s
```

**By Status:**
```
Status: error
```

**By Span Name:**
```
Span Name: GET /events
```

### 5. Analyze Trace
Click on any trace to see:
- **Waterfall view** - Timeline of all spans
- **Span details** - Attributes, events, errors
- **Service map** - Dependencies between services
- **Logs** - Associated log lines (if correlated)

## Custom Instrumentation

### Adding Custom Spans

Wrap any code block with a custom span:

```ruby
class EventsController < ApplicationController
  def create
    trace_span('events.create', 'user.id' => current_user.id) do
      @event = Event.new(event_params)
      
      trace_span('events.geocode') do
        @event.geocode_location
      end
      
      if @event.save
        add_trace_attributes(
          'event.id' => @event.id.to_s,
          'event.name' => @event.name
        )
        redirect_to @event
      else
        render :new
      end
    end
  end
end
```

### Adding Custom Attributes

Add metadata to the current span:

```ruby
def show
  @event = Event.find(params[:id])
  
  add_trace_attributes(
    'event.id' => @event.id.to_s,
    'event.attendees' => @event.attendees.count,
    'event.tips_total' => @event.tips.sum(:amount)
  )
  
  render :show
end
```

### Tracking Errors

Errors are automatically captured, but you can add context:

```ruby
begin
  process_payment(tip)
rescue PaymentError => e
  add_trace_attributes(
    'error.type' => 'payment_failed',
    'error.payment_gateway' => 'stripe',
    'error.amount' => tip.amount
  )
  raise
end
```

## Prometheus Metrics

### Available Metrics

#### HTTP Metrics

**Request Count:**
```promql
http_requests_total{method="GET", path="/events", status="2"}
```

**Request Duration (95th percentile):**
```promql
histogram_quantile(0.95, 
  rate(http_request_duration_seconds_bucket[5m])
)
```

**Error Rate:**
```promql
rate(http_requests_total{status="5"}[5m])
```

#### Database Metrics

**Query Duration:**
```promql
db_query_duration_seconds{operation="find"}
```

**Slow Queries (>100ms):**
```promql
db_query_duration_seconds > 0.1
```

#### Background Job Metrics

**Job Count:**
```promql
sidekiq_jobs_total{queue="default", status="success"}
```

**Job Duration:**
```promql
sidekiq_job_duration_seconds{job_class="TipNotificationJob"}
```

#### Business Metrics

**Tips Created:**
```promql
rate(tips_created_total[1h])
```

**Events Created:**
```promql
rate(events_created_total[1h])
```

**Users Created:**
```promql
rate(users_created_total[1h])
```

### Adding Custom Metrics

#### Counter (for events that happen)

```ruby
# In model or controller
TIPS_METRIC = Prometheus::Client.registry.counter(
  :tips_by_amount,
  docstring: 'Tips grouped by amount range',
  labels: [:amount_range]
)

def create
  @tip = Tip.new(tip_params)
  if @tip.save
    # Increment counter
    range = case @tip.amount
            when 0..10 then 'small'
            when 10..50 then 'medium'
            else 'large'
            end
    TIPS_METRIC.increment(labels: { amount_range: range })
  end
end
```

#### Gauge (for current values)

```ruby
ACTIVE_EVENTS = Prometheus::Client.registry.gauge(
  :active_events_count,
  docstring: 'Number of currently active events'
)

# Update periodically (e.g., in a background job)
ACTIVE_EVENTS.set(Event.active.count)
```

#### Histogram (for distributions)

```ruby
IMAGE_UPLOAD_SIZE = Prometheus::Client.registry.histogram(
  :image_upload_size_bytes,
  docstring: 'Size of uploaded images',
  buckets: [1024, 10240, 102400, 1024000, 10240000]
)

def upload_image
  IMAGE_UPLOAD_SIZE.observe(params[:image].size)
  # ... upload logic
end
```

## Accessing Metrics Endpoint

The `/metrics` endpoint exposes all Prometheus metrics:

```bash
# In Kubernetes
kubectl port-forward -n default svc/djtip 3000:3000
curl http://localhost:3000/metrics

# Locally
curl http://localhost:3000/metrics
```

Output example:
```
# HELP http_requests_total Total HTTP requests
# TYPE http_requests_total counter
http_requests_total{method="GET",path="/events",status="2"} 1234.0

# HELP http_request_duration_seconds HTTP request duration in seconds
# TYPE http_request_duration_seconds histogram
http_request_duration_seconds_bucket{method="GET",path="/events",le="0.005"} 100.0
http_request_duration_seconds_bucket{method="GET",path="/events",le="0.01"} 250.0
...
```

## Grafana Dashboards

### Creating a Custom Dashboard

1. Open Grafana: https://grafana.minikube.local
2. Click **+** → **Dashboard**
3. Click **Add visualization**
4. Select **Prometheus** datasource
5. Add queries:

**Request Rate:**
```promql
sum(rate(http_requests_total[5m])) by (path)
```

**Error Rate:**
```promql
sum(rate(http_requests_total{status="5"}[5m])) / 
sum(rate(http_requests_total[5m]))
```

**Response Time (p95):**
```promql
histogram_quantile(0.95, 
  sum(rate(http_request_duration_seconds_bucket[5m])) by (le, path)
)
```

### Importing Pre-built Dashboards

Grafana has community dashboards for Rails:

1. Go to **Dashboards** → **Import**
2. Enter dashboard ID: `315` (Rails Overview)
3. Select **Prometheus** datasource
4. Click **Import**

## Correlating Logs and Traces

### Adding Trace ID to Logs

```ruby
class ApplicationController < ActionController::Base
  before_action :add_trace_id_to_logs
  
  private
  
  def add_trace_id_to_logs
    trace_id = OpenTelemetry::Trace.current_span.context.hex_trace_id
    Rails.logger.tagged(trace_id) do
      yield if block_given?
    end
  end
end
```

Now logs will include trace IDs:
```
[a1b2c3d4e5f6] Started GET "/events" for 127.0.0.1
[a1b2c3d4e5f6] Processing by EventsController#index
```

### Viewing Logs from Traces

In Grafana Explore:
1. Select a trace
2. Click **Logs** tab
3. See all logs with matching trace ID

## Performance Optimization

### Identifying Slow Requests

**In Grafana (Tempo):**
1. Go to Explore → Tempo
2. Set **Min Duration: 1s**
3. View slowest requests
4. Analyze span waterfall to find bottlenecks

**In Grafana (Prometheus):**
```promql
# Requests slower than 1 second
http_request_duration_seconds > 1
```

### Identifying N+1 Queries

Look for traces with many database spans:

1. Find slow request in Tempo
2. Count database query spans
3. If >10 queries for a single request → likely N+1

**Fix with eager loading:**
```ruby
# Before (N+1)
@events = Event.all
@events.each { |e| e.tips.count }

# After (optimized)
@events = Event.includes(:tips)
@events.each { |e| e.tips.count }
```

### Monitoring Background Jobs

**Failed jobs:**
```promql
sidekiq_jobs_total{status="failed"}
```

**Slow jobs:**
```promql
sidekiq_job_duration_seconds > 30
```

**Queue depth:**
```promql
sidekiq_queue_depth{queue="default"}
```

## Alerting

### Creating Alerts

Create a PrometheusRule for alerts:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: djtip-alerts
  namespace: observability
spec:
  groups:
    - name: djtip-performance
      interval: 30s
      rules:
        - alert: HighErrorRate
          expr: |
            sum(rate(http_requests_total{status="5"}[5m])) /
            sum(rate(http_requests_total[5m])) > 0.05
          for: 5m
          labels:
            severity: warning
          annotations:
            summary: "High error rate in djtip"
            description: "Error rate is {{ $value | humanizePercentage }}"
        
        - alert: SlowRequests
          expr: |
            histogram_quantile(0.95,
              rate(http_request_duration_seconds_bucket[5m])
            ) > 2
          for: 10m
          labels:
            severity: warning
          annotations:
            summary: "Slow requests detected"
            description: "95th percentile is {{ $value }}s"
```

## Sampling Configuration

### Production Sampling

To reduce overhead in production, adjust sampling:

```yaml
# .cicd/helm/djtip/templates/deployment.yaml
- name: OTEL_TRACE_SAMPLE_RATE
  value: "0.1"  # Sample 10% of requests
```

### Smart Sampling

Sample all errors, but only some successful requests:

```ruby
# config/initializers/opentelemetry.rb
class SmartSampler < OpenTelemetry::SDK::Trace::Samplers::Sampler
  def should_sample?(trace_id:, parent_context:, links:, name:, kind:, attributes:)
    # Always sample errors
    if attributes['http.status_code'].to_i >= 500
      return OpenTelemetry::SDK::Trace::Samplers::Decision::RECORD_AND_SAMPLE
    end
    
    # Sample 10% of successful requests
    if trace_id.to_i % 10 == 0
      return OpenTelemetry::SDK::Trace::Samplers::Decision::RECORD_AND_SAMPLE
    end
    
    OpenTelemetry::SDK::Trace::Samplers::Decision::DROP
  end
end

c.sampler = SmartSampler.new
```

## Troubleshooting

### No Traces Appearing

**Check OTLP endpoint:**
```bash
kubectl logs -n default -l app.kubernetes.io/name=djtip | grep OpenTelemetry
```

**Test connectivity:**
```bash
kubectl exec -n default deployment/djtip -- curl -v http://tempo.observability.svc.cluster.local:4318/v1/traces
```

### No Metrics at /metrics

**Check Prometheus initialization:**
```bash
kubectl logs -n default -l app.kubernetes.io/name=djtip | grep Prometheus
```

**Test endpoint:**
```bash
kubectl port-forward -n default svc/djtip 3000:3000
curl http://localhost:3000/metrics
```

### High Memory Usage

OpenTelemetry can use memory. Reduce sampling:

```yaml
- name: OTEL_TRACE_SAMPLE_RATE
  value: "0.01"  # 1% sampling
```

Or disable specific instrumentations:

```ruby
c.use_all({
  'OpenTelemetry::Instrumentation::ActionView' => { enabled: false },  # Disable view tracing
})
```

## Best Practices

### 1. Use Semantic Attributes

Follow OpenTelemetry semantic conventions:

```ruby
add_trace_attributes(
  'http.method' => 'GET',
  'http.url' => request.url,
  'http.status_code' => response.status,
  'user.id' => current_user&.id,
  'user.email' => current_user&.email
)
```

### 2. Don't Trace Everything

Skip tracing for:
- Health checks
- Metrics endpoints
- Static assets

```ruby
# Already handled in prometheus.rb middleware
unless request.path == '/metrics' || request.path.start_with?('/assets')
  # ... trace
end
```

### 3. Sanitize Sensitive Data

Never include passwords, tokens, or PII in traces:

```ruby
# BAD
add_trace_attributes('user.password' => params[:password])

# GOOD
add_trace_attributes('user.id' => current_user.id)
```

### 4. Use Consistent Naming

Follow naming conventions:
- `http.*` for HTTP attributes
- `db.*` for database attributes
- `user.*` for user attributes
- `event.*` for business domain attributes

## Resources

- [OpenTelemetry Ruby Docs](https://opentelemetry.io/docs/instrumentation/ruby/)
- [Prometheus Client Ruby](https://github.com/prometheus/client_ruby)
- [Grafana Tempo Docs](https://grafana.com/docs/tempo/)
- [Semantic Conventions](https://opentelemetry.io/docs/specs/semconv/)
