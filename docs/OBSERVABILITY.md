# Observability Stack Documentation

Complete observability setup with Prometheus, Grafana, Loki, and Tempo for metrics, logs, and distributed tracing.

## Overview

The observability stack provides:

- **📊 Metrics** - Prometheus + Grafana
- **📝 Logs** - Loki + Promtail  
- **🔍 Traces** - Tempo (OpenTelemetry compatible)
- **🚨 Alerts** - Alertmanager
- **📈 Dashboards** - Pre-configured Grafana

## Components

### Prometheus Stack (kube-prometheus-stack)

**What it includes:**
- **Prometheus** - Metrics collection and storage
- **Grafana** - Visualization and dashboards
- **Alertmanager** - Alert routing and management
- **Node Exporter** - Node-level metrics
- **Kube State Metrics** - Kubernetes object metrics
- **Prometheus Operator** - Manages Prometheus instances

**Metrics collected:**
- CPU, memory, disk, network usage
- Kubernetes pod/deployment/service metrics
- Application custom metrics (via ServiceMonitor)
- Node-level system metrics

### Loki

**Log aggregation system** - Like Prometheus, but for logs

**Features:**
- Automatic log collection from all pods
- Label-based log querying
- Integration with Grafana
- Low resource usage (indexes labels, not content)

### Promtail

**Log shipping agent** - Runs on every node

**What it does:**
- Discovers all pods automatically
- Reads container logs
- Adds Kubernetes labels
- Ships logs to Loki

### Tempo

**Distributed tracing** - OpenTelemetry compatible

**Protocols supported:**
- OpenTelemetry (OTLP) - gRPC (4317) and HTTP (4318)
- Jaeger - gRPC (14250) and HTTP (14268)
- Zipkin - HTTP (9411)

**Use cases:**
- Request tracing across microservices
- Performance bottleneck identification
- Dependency mapping
- Error tracking

## Access URLs

### Grafana
- **HTTPS**: https://grafana.minikube.local
- **HTTP**: http://grafana.minikube.local
- **Login**: Anonymous (Admin role) - No password required!

### Prometheus
```bash
# Port-forward to access Prometheus UI
kubectl port-forward -n observability svc/mon-kube-prometheus-stack-prometheus 9090:9090
```
Then: http://localhost:9090

### Alertmanager
```bash
# Port-forward to access Alertmanager UI
kubectl port-forward -n observability svc/mon-kube-prometheus-stack-alertmanager 9093:9093
```
Then: http://localhost:9093

## Grafana Configuration

### Pre-configured Datasources

Grafana comes with three datasources automatically configured:

1. **Prometheus** (default)
   - URL: `http://mon-kube-prometheus-stack-prometheus:9090`
   - Type: Metrics
   - Use for: System metrics, application metrics

2. **Loki**
   - URL: `http://loki:3100`
   - Type: Logs
   - Use for: Pod logs, application logs

3. **Tempo**
   - URL: `http://tempo:3100`
   - Type: Traces
   - Use for: Distributed tracing, request flows

### Anonymous Access

Grafana is configured with anonymous authentication:
- **Enabled**: Yes
- **Role**: Admin (full access)
- **No login required** - Just open the URL!

⚠️ **Security Note**: This is for local development only. In production, disable anonymous auth and use proper authentication.

## Using the Observability Stack

### Viewing Logs in Grafana

1. Open https://grafana.minikube.local
2. Click **Explore** (compass icon)
3. Select **Loki** datasource
4. Use LogQL queries:

```logql
# All logs from djtip pods
{app="djtip"}

# Logs from specific namespace
{namespace="default"}

# Filter by log level
{app="djtip"} |= "ERROR"

# Last 5 minutes of logs
{app="djtip"} [5m]

# Logs containing specific text
{app="djtip"} |~ "database.*error"
```

### Viewing Metrics in Grafana

1. Open https://grafana.minikube.local
2. Go to **Dashboards**
3. Pre-installed dashboards:
   - **Kubernetes / Compute Resources / Cluster**
   - **Kubernetes / Compute Resources / Namespace (Pods)**
   - **Kubernetes / Compute Resources / Pod**
   - **Node Exporter / Nodes**

Or create custom dashboards with PromQL:

```promql
# CPU usage by pod
rate(container_cpu_usage_seconds_total{namespace="default"}[5m])

# Memory usage by pod
container_memory_usage_bytes{namespace="default"}

# HTTP request rate
rate(http_requests_total[5m])

# Pod restart count
kube_pod_container_status_restarts_total
```

### Viewing Traces in Grafana

1. Open https://grafana.minikube.local
2. Click **Explore**
3. Select **Tempo** datasource
4. Search by:
   - Trace ID
   - Service name
   - Duration
   - Tags

## Instrumenting Your Application

### Adding Metrics to Rails App

Install the `prometheus-client` gem:

```ruby
# Gemfile
gem 'prometheus-client'
```

Add metrics endpoint:

```ruby
# config/routes.rb
require 'prometheus/middleware/collector'
require 'prometheus/middleware/exporter'

Rails.application.routes.draw do
  mount Prometheus::Middleware::Exporter, at: '/metrics'
end
```

Add middleware:

```ruby
# config/application.rb
config.middleware.use Prometheus::Middleware::Collector
```

The ServiceMonitor in `.cicd/helm/djtip/templates/servicemonitor.yaml` will automatically scrape `/metrics`.

### Adding Distributed Tracing

Install OpenTelemetry:

```ruby
# Gemfile
gem 'opentelemetry-sdk'
gem 'opentelemetry-exporter-otlp'
gem 'opentelemetry-instrumentation-rails'
gem 'opentelemetry-instrumentation-active_record'
```

Configure:

```ruby
# config/initializers/opentelemetry.rb
require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'
require 'opentelemetry/instrumentation/rails'

OpenTelemetry::SDK.configure do |c|
  c.service_name = 'djtip'
  c.use 'OpenTelemetry::Instrumentation::Rails'
  c.use 'OpenTelemetry::Instrumentation::ActiveRecord'
  
  # Send traces to Tempo
  c.add_span_processor(
    OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
      OpenTelemetry::Exporter::OTLP::Exporter.new(
        endpoint: ENV.fetch('OTEL_EXPORTER_OTLP_ENDPOINT', 'http://tempo:4318')
      )
    )
  )
end
```

Add environment variable to deployment:

```yaml
# .cicd/helm/djtip/templates/deployment.yaml
env:
  - name: OTEL_EXPORTER_OTLP_ENDPOINT
    value: http://tempo.observability.svc.cluster.local:4318
```

## Querying Logs with LogQL

### Basic Queries

```logql
# All logs from a specific app
{app="djtip"}

# Logs from multiple apps
{app=~"djtip|redis|mongodb"}

# Logs NOT from specific app
{app!="kube-proxy"}

# Logs from specific namespace
{namespace="default"}
```

### Filtering

```logql
# Contains text
{app="djtip"} |= "error"

# Doesn't contain text
{app="djtip"} != "debug"

# Regex match
{app="djtip"} |~ "error|ERROR|Error"

# Regex not match
{app="djtip"} !~ "debug|DEBUG"
```

### Aggregations

```logql
# Count logs per second
rate({app="djtip"}[1m])

# Count by log level
sum by (level) (rate({app="djtip"}[5m]))

# Top 10 pods by log volume
topk(10, sum by (pod) (rate({namespace="default"}[5m])))
```

## Querying Metrics with PromQL

### Resource Usage

```promql
# CPU usage by pod
sum(rate(container_cpu_usage_seconds_total{namespace="default"}[5m])) by (pod)

# Memory usage by pod
sum(container_memory_usage_bytes{namespace="default"}) by (pod)

# Network received by pod
sum(rate(container_network_receive_bytes_total{namespace="default"}[5m])) by (pod)
```

### Application Metrics

```promql
# HTTP request rate
rate(http_requests_total[5m])

# HTTP error rate
rate(http_requests_total{status=~"5.."}[5m])

# 95th percentile response time
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Request rate by endpoint
sum(rate(http_requests_total[5m])) by (endpoint)
```

### Kubernetes Metrics

```promql
# Pod restart count
kube_pod_container_status_restarts_total

# Pods not ready
kube_pod_status_ready{condition="false"}

# Deployment replicas
kube_deployment_status_replicas

# Node CPU usage
100 - (avg by (node) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

## Alerting

### Creating Alerts

Alerts are defined in PrometheusRule CRDs:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: djtip-alerts
  namespace: observability
spec:
  groups:
    - name: djtip
      interval: 30s
      rules:
        - alert: HighErrorRate
          expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
          for: 5m
          labels:
            severity: warning
          annotations:
            summary: "High error rate detected"
            description: "Error rate is {{ $value }} requests/sec"
        
        - alert: PodDown
          expr: kube_pod_status_phase{pod=~"djtip.*",phase!="Running"} > 0
          for: 5m
          labels:
            severity: critical
          annotations:
            summary: "Pod {{ $labels.pod }} is down"
```

### Alert Routing

Configure Alertmanager in `values.yaml`:

```yaml
alertmanager:
  config:
    route:
      group_by: ['alertname', 'cluster']
      receiver: 'slack'
    receivers:
      - name: 'slack'
        slack_configs:
          - api_url: 'YOUR_SLACK_WEBHOOK_URL'
            channel: '#alerts'
```

## Resource Usage

Current observability stack resource usage:

| Component | CPU Request | Memory Request | CPU Limit | Memory Limit |
|-----------|-------------|----------------|-----------|--------------|
| Prometheus | 200m | 512Mi | 1000m | 2Gi |
| Grafana | 100m | 256Mi | 500m | 512Mi |
| Loki | 100m | 256Mi | 500m | 512Mi |
| Tempo | 100m | 256Mi | 500m | 512Mi |
| Alertmanager | 50m | 128Mi | 200m | 256Mi |
| **Total** | **~600m** | **~1.5Gi** | **~3Gi** | **~4Gi** |

Plus per-node:
- Node Exporter: ~50m CPU, ~50Mi memory
- Promtail: ~100m CPU, ~128Mi memory

## Troubleshooting

### Grafana Not Accessible

```bash
# Check pod status
kubectl get pods -n observability -l app.kubernetes.io/name=grafana

# Check logs
kubectl logs -n observability -l app.kubernetes.io/name=grafana

# Check ingress
kubectl get ingress -n observability
```

### No Logs in Loki

```bash
# Check Promtail is running
kubectl get pods -n observability -l app.kubernetes.io/name=promtail

# Check Promtail logs
kubectl logs -n observability -l app.kubernetes.io/name=promtail

# Test Loki directly
kubectl port-forward -n observability svc/loki 3100:3100
curl http://localhost:3100/ready
```

### Prometheus Not Scraping Metrics

```bash
# Check ServiceMonitor
kubectl get servicemonitor -n default

# Check Prometheus targets
kubectl port-forward -n observability svc/mon-kube-prometheus-stack-prometheus 9090:9090
# Open http://localhost:9090/targets
```

### High Resource Usage

```bash
# Check resource usage
kubectl top pods -n observability

# Reduce retention (in values.yaml)
prometheus:
  prometheusSpec:
    retention: 3d  # Reduce from 7d

# Disable components you don't need
loki:
  enabled: false
tempo:
  enabled: false
```

## Best Practices

### For Development

1. ✅ Use anonymous Grafana auth
2. ✅ Disable persistence (faster startup)
3. ✅ Reduce retention periods
4. ✅ Use single-binary mode for Loki
5. ✅ Limit resource requests

### For Production

1. ✅ Enable authentication (disable anonymous)
2. ✅ Enable persistence for all components
3. ✅ Increase retention (30d+ for metrics)
4. ✅ Use distributed mode for Loki
5. ✅ Set up alerting to Slack/PagerDuty
6. ✅ Enable TLS for all components
7. ✅ Use remote storage (S3, GCS) for long-term retention
8. ✅ Set up backup for Grafana dashboards

## Comparison with NewRelic

| Feature | NewRelic | This Stack | Notes |
|---------|----------|------------|-------|
| **Metrics** | ✅ APM | ✅ Prometheus | Similar capabilities |
| **Logs** | ✅ Log Management | ✅ Loki | Similar query language |
| **Traces** | ✅ Distributed Tracing | ✅ Tempo | OpenTelemetry compatible |
| **Dashboards** | ✅ Built-in | ✅ Grafana | More customizable |
| **Alerts** | ✅ Alerting | ✅ Alertmanager | Similar features |
| **Cost** | 💰 Paid | ✅ Free/Open Source | Major advantage |
| **Setup** | ✅ SaaS | ⚠️ Self-hosted | Requires maintenance |
| **Data Retention** | 💰 Limited | ✅ Unlimited | You control storage |

## Additional Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Loki Documentation](https://grafana.com/docs/loki/)
- [Tempo Documentation](https://grafana.com/docs/tempo/)
- [OpenTelemetry Documentation](https://opentelemetry.io/docs/)
- [LogQL Cheat Sheet](https://grafana.com/docs/loki/latest/logql/)
- [PromQL Cheat Sheet](https://promlabs.com/promql-cheat-sheet/)

## Quick Commands

```bash
# View all observability pods
kubectl get pods -n observability

# Access Grafana
open https://grafana.minikube.local

# Port-forward Prometheus
kubectl port-forward -n observability svc/mon-kube-prometheus-stack-prometheus 9090:9090

# View Loki logs
kubectl logs -n observability -l app.kubernetes.io/name=loki -f

# Check metrics endpoint
kubectl port-forward -n default svc/djtip 3000:3000
curl http://localhost:3000/metrics

# Restart observability stack
kubectl delete pods -n observability --all
```
