# Observability Stack Naming Convention

## Overview

This document explains the naming convention used for the observability stack components in the `observability` namespace.

## Naming Strategy

We use simplified names to make `kubectl` output more readable and service discovery more intuitive. The naming follows these principles:

1. **Remove redundant prefixes** - No "observability-" prefix since resources are already in the `observability` namespace
2. **Use shortest meaningful names** - Direct component names where possible
3. **Accept chart limitations** - Some components retain minimal prefixes due to Helm chart constraints

## Current Naming

### Clean Names (No Prefixes)

These services and pods use direct component names:

| Component | Service Name | Pod Name Pattern | Purpose |
|-----------|--------------|------------------|---------|
| Grafana | `grafana` | `grafana-*` | Visualization & dashboards |
| Loki | `loki` | `loki-*` | Log aggregation |
| Tempo | `tempo` | `tempo-*` | Distributed tracing |
| Promtail | N/A | `promtail-*` | Log shipping (DaemonSet) |
| Prometheus Operator | `prometheus-operator` | `prometheus-operator-*` | Manages Prometheus CRDs |

### Minimal Prefixes (mon-)

These components retain the "mon-" prefix due to kube-prometheus-stack chart design:

| Component | Service Name | Pod Name Pattern | Purpose |
|-----------|--------------|------------------|---------|
| Prometheus | `mon-kube-prometheus-stack-prometheus` | `prometheus-mon-kube-prometheus-stack-prometheus-*` | Metrics collection |
| Alertmanager | `mon-kube-prometheus-stack-alertmanager` | `alertmanager-mon-kube-prometheus-stack-alertmanager-*` | Alert management |
| Kube State Metrics | `mon-kube-state-metrics` | `mon-kube-state-metrics-*` | K8s object metrics |
| Node Exporter | `mon-prometheus-node-exporter` | `mon-prometheus-node-exporter-*` | Node metrics |

## Why "mon-" Prefix?

The kube-prometheus-stack Helm chart uses the **release name** as a prefix for certain components. This is hardcoded in the chart and cannot be fully overridden with `fullnameOverride`.

We chose "mon" (short for "monitoring") as the release name because:
- ✅ Short and meaningful
- ✅ Easier to type than "observability"
- ✅ Still descriptive
- ✅ Better than single-letter names

### Alternative Options Considered

1. **Single letter** (e.g., "o" or "m") - Too cryptic
2. **Empty string** - Not supported by Helm
3. **Fork the chart** - High maintenance burden
4. **Use "observability"** - Results in very long names like `observability-kube-prometheus-stack-prometheus`

## Service Discovery

### From djtip Application (default namespace)

```yaml
# Grafana
http://grafana.observability.svc.cluster.local:80

# Loki
http://loki.observability.svc.cluster.local:3100

# Tempo (OpenTelemetry)
http://tempo.observability.svc.cluster.local:4318

# Prometheus
http://mon-kube-prometheus-stack-prometheus.observability.svc.cluster.local:9090
```

### Within observability Namespace

Services can be accessed by short name:

```yaml
# Grafana datasources
http://loki:3100
http://tempo:3100

# Promtail client
http://loki:3100/loki/api/v1/push
```

## Helm Release Information

```bash
# Release name: mon
# Namespace: observability
# Chart: .cicd/helm/observability

# View release
helm list -n observability

# Upgrade
helm upgrade mon .cicd/helm/observability -n observability
```

## kubectl Examples

### List All Pods

```bash
kubectl get pods -n observability
```

Output shows clean names:
```
NAME                                    READY   STATUS
grafana-*                               3/3     Running
loki-0                                  2/2     Running
tempo-0                                 1/1     Running
promtail-*                              1/1     Running
prometheus-operator-*                   1/1     Running
mon-kube-state-metrics-*                1/1     Running
mon-prometheus-node-exporter-*          1/1     Running
```

### Access Logs

```bash
# Clean names - easy to remember
kubectl logs -n observability grafana-*
kubectl logs -n observability loki-0
kubectl logs -n observability tempo-0

# With prefix - still reasonable
kubectl logs -n observability prometheus-operator-*
```

### Port Forward

```bash
# Grafana
kubectl port-forward -n observability svc/grafana 3000:80

# Prometheus
kubectl port-forward -n observability svc/mon-kube-prometheus-stack-prometheus 9090:9090

# Tempo
kubectl port-forward -n observability svc/tempo 3200:3200
```

## Configuration Files

The naming is configured in:

- **Helm values**: `.cicd/helm/observability/values.yaml`
  - Uses `fullnameOverride` for Grafana, Loki, Tempo, Promtail
  - Release name "mon" provides prefix for kube-prometheus-stack components

- **djtip ConfigMap**: `.cicd/helm/djtip/templates/configmap-environment.yaml`
  - `OTEL_EXPORTER_OTLP_ENDPOINT: "http://tempo.observability.svc.cluster.local:4318"`

## Benefits

### Before Simplification
```
observability-grafana-6c8c445584-trb9s
observability-loki-0
observability-tempo-0
prometheus-observability-kube-prometh-prometheus-0
alertmanager-observability-kube-prometh-alertmanager-0
observability-kube-state-metrics-7d4b5dd676-wlw7j
observability-prometheus-node-exporter-fbf8v
```

### After Simplification
```
grafana-69bb9d9949-6wq2n
loki-0
tempo-0
prometheus-mon-kube-prometheus-stack-prometheus-0
alertmanager-mon-kube-prometheus-stack-alertmanager-0
mon-kube-state-metrics-58df9fd9d6-rnh6r
mon-prometheus-node-exporter-xk6x7
```

### Improvements
- ✅ Removed redundant "observability-" prefix (already in namespace)
- ✅ Shortened "observability-kube-prometh-" to "mon-"
- ✅ Clean service names for most-used services (Grafana, Loki, Tempo)
- ✅ Easier to read `kubectl get pods` output
- ✅ Simpler service discovery URLs

## Future Considerations

If the kube-prometheus-stack chart adds better support for `fullnameOverride` in future versions, we can:

1. Remove the "mon-" prefix entirely
2. Update the Helm release to use a different name
3. Keep the current naming for consistency

For now, this naming scheme provides the best balance of:
- **Readability** - Easy to identify components
- **Maintainability** - Uses standard Helm charts
- **Practicality** - Works with chart limitations
