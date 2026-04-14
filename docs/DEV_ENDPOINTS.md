# Development Endpoints Reference

Complete reference of all service endpoints for local development and Kubernetes deployment.

## 📋 Table of Contents

- [Local Development](#local-development)
- [Kubernetes (Minikube)](#kubernetes-minikube)
- [Port Forwarding](#port-forwarding)
- [Service Discovery](#service-discovery)

---

## 🖥️ Local Development

### Rails Application

| Service | URL | Port | Description |
|---------|-----|------|-------------|
| **Web Application** | http://localhost:3000 | 3000 | Main Rails app |
| **Metrics** | http://localhost:3000/metrics | 3000 | Prometheus metrics endpoint |
| **Health Check** | http://localhost:3000/up | 3000 | Rails health check |

### Database & Cache

| Service | URL | Port | Description |
|---------|-----|------|-------------|
| **MongoDB** | mongodb://localhost:27017 | 27017 | MongoDB database |
| **MongoDB Database** | mongodb://localhost:27017/djtip_development | 27017 | Development database |
| **Redis** | redis://localhost:6379 | 6379 | Redis cache/sessions |

### Background Jobs

| Service | URL | Port | Description |
|---------|-----|------|-------------|
| **Sidekiq Web UI** | http://localhost:3000/sidekiq | 3000 | Sidekiq dashboard (if mounted) |

### Development Tools

| Service | URL | Port | Description |
|---------|-----|------|-------------|
| **Mailcatcher** | http://localhost:1080 | 1080 | Email testing (if installed) |
| **Letter Opener** | Opens in browser | - | Email preview in development |

---

## ☸️ Kubernetes (Minikube)

### Application Endpoints

| Service | URL | Port | Description |
|---------|-----|------|-------------|
| **DJ Tip App** | https://djtip.minikube.local | 443 | Main application (HTTPS) |
| **DJ Tip App (HTTP)** | http://djtip.minikube.local | 80 | Main application (HTTP redirect) |
| **Metrics** | https://djtip.minikube.local/metrics | 443 | Prometheus metrics |
| **Health Check** | https://djtip.minikube.local/up | 443 | Application health |

### Observability Stack

#### Grafana

| Service | URL | Port | Description |
|---------|-----|------|-------------|
| **Grafana UI** | https://grafana.minikube.local | 443 | Grafana dashboard (anonymous login) |
| **Grafana API** | https://grafana.minikube.local/api | 443 | Grafana API |
| **Grafana Health** | https://grafana.minikube.local/api/health | 443 | Health check |

**Default Access:**
- No login required (anonymous admin access enabled)
- Direct access to all dashboards and data sources

#### Prometheus

| Service | URL | Port | Description |
|---------|-----|------|-------------|
| **Prometheus UI** | http://mon-kube-prometheus-stack-prometheus.observability.svc.cluster.local:9090 | 9090 | Prometheus web UI |
| **Prometheus API** | http://mon-kube-prometheus-stack-prometheus.observability.svc.cluster.local:9090/api/v1 | 9090 | Prometheus API |
| **Prometheus Metrics** | http://mon-kube-prometheus-stack-prometheus.observability.svc.cluster.local:9090/metrics | 9090 | Prometheus self-metrics |

**Port Forward to Access:**
```bash
kubectl port-forward -n observability svc/mon-kube-prometheus-stack-prometheus 9090:9090
# Then access: http://localhost:9090
```

#### Loki

| Service | URL | Port | Description |
|---------|-----|------|-------------|
| **Loki API** | http://loki.observability.svc.cluster.local:3100 | 3100 | Loki log ingestion/query |
| **Loki Ready** | http://loki.observability.svc.cluster.local:3100/ready | 3100 | Readiness check |
| **Loki Metrics** | http://loki.observability.svc.cluster.local:3100/metrics | 3100 | Loki metrics |

**Port Forward to Access:**
```bash
kubectl port-forward -n observability svc/loki 3100:3100
# Then access: http://localhost:3100
```

#### Tempo

| Service | URL | Port | Description |
|---------|-----|------|-------------|
| **Tempo OTLP gRPC** | http://tempo.observability.svc.cluster.local:4317 | 4317 | OpenTelemetry gRPC receiver |
| **Tempo OTLP HTTP** | http://tempo.observability.svc.cluster.local:4318 | 4318 | OpenTelemetry HTTP receiver |
| **Tempo Query** | http://tempo.observability.svc.cluster.local:3100 | 3100 | Tempo query API |
| **Tempo Jaeger** | http://tempo.observability.svc.cluster.local:14268 | 14268 | Jaeger receiver |
| **Tempo Zipkin** | http://tempo.observability.svc.cluster.local:9411 | 9411 | Zipkin receiver |

**Port Forward to Access:**
```bash
kubectl port-forward -n observability svc/tempo 3100:3100
# Then access: http://localhost:3100
```

#### Alertmanager

| Service | URL | Port | Description |
|---------|-----|------|-------------|
| **Alertmanager UI** | http://mon-kube-prometheus-stack-alertmanager.observability.svc.cluster.local:9093 | 9093 | Alertmanager web UI |
| **Alertmanager API** | http://mon-kube-prometheus-stack-alertmanager.observability.svc.cluster.local:9093/api/v2 | 9093 | Alertmanager API |

**Port Forward to Access:**
```bash
kubectl port-forward -n observability svc/mon-kube-prometheus-stack-alertmanager 9093:9093
# Then access: http://localhost:9093
```

### ArgoCD

| Service | URL | Port | Description |
|---------|-----|------|-------------|
| **ArgoCD UI** | https://localhost:8080 | 8080 | ArgoCD dashboard (via port-forward) |
| **ArgoCD API** | https://localhost:8080/api | 8080 | ArgoCD API |
| **ArgoCD gRPC** | localhost:8080 | 8080 | ArgoCD CLI connection |

**Access:**
```bash
# Port forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Login
argocd login localhost:8080 --username admin --password <password>
```

### Internal Services (Cluster-Only)

#### Application Services

| Service | Internal URL | Port | Description |
|---------|--------------|------|-------------|
| **DJ Tip App** | http://djtip.default.svc.cluster.local | 80 | Application service |
| **MongoDB** | mongodb://djtip-mongodb.default.svc.cluster.local:27017 | 27017 | MongoDB service |
| **Redis Master** | redis://djtip-redis-master.default.svc.cluster.local:6379 | 6379 | Redis master |
| **Redis Replicas** | redis://djtip-redis-replicas.default.svc.cluster.local:6379 | 6379 | Redis read replicas |

#### Observability Services

| Service | Internal URL | Port | Description |
|---------|--------------|------|-------------|
| **Prometheus** | http://mon-kube-prometheus-stack-prometheus.observability.svc.cluster.local:9090 | 9090 | Prometheus |
| **Grafana** | http://grafana.observability.svc.cluster.local:80 | 80 | Grafana |
| **Loki** | http://loki.observability.svc.cluster.local:3100 | 3100 | Loki |
| **Tempo** | http://tempo.observability.svc.cluster.local:3100 | 3100 | Tempo query |
| **Tempo OTLP** | http://tempo.observability.svc.cluster.local:4318 | 4318 | Tempo OTLP HTTP |
| **Promtail** | http://promtail.observability.svc.cluster.local:3101 | 3101 | Promtail |

---

## 🔌 Port Forwarding

### Quick Port Forward Commands

#### Application
```bash
# DJ Tip App
kubectl port-forward -n default svc/djtip 3000:80
# Access: http://localhost:3000

# MongoDB
kubectl port-forward -n default svc/djtip-mongodb 27017:27017
# Access: mongodb://localhost:27017

# Redis
kubectl port-forward -n default svc/djtip-redis-master 6379:6379
# Access: redis://localhost:6379
```

#### Observability
```bash
# Grafana (alternative to ingress)
kubectl port-forward -n observability svc/grafana 3001:80
# Access: http://localhost:3001

# Prometheus
kubectl port-forward -n observability svc/mon-kube-prometheus-stack-prometheus 9090:9090
# Access: http://localhost:9090

# Loki
kubectl port-forward -n observability svc/loki 3100:3100
# Access: http://localhost:3100

# Tempo
kubectl port-forward -n observability svc/tempo 3100:3100 4318:4318
# Query: http://localhost:3100
# OTLP: http://localhost:4318

# Alertmanager
kubectl port-forward -n observability svc/mon-kube-prometheus-stack-alertmanager 9093:9093
# Access: http://localhost:9093
```

#### ArgoCD
```bash
# ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Access: https://localhost:8080
```

### Multi-Service Port Forward Script

Create a script to forward multiple services at once:

```bash
#!/bin/bash
# port-forward-all.sh

# Application
kubectl port-forward -n default svc/djtip 3000:80 &

# Observability
kubectl port-forward -n observability svc/grafana 3001:80 &
kubectl port-forward -n observability svc/mon-kube-prometheus-stack-prometheus 9090:9090 &
kubectl port-forward -n observability svc/loki 3100:3100 &
kubectl port-forward -n observability svc/tempo 3200:3100 &

# ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443 &

echo "Port forwarding started for all services"
echo "Press Ctrl+C to stop all port forwards"
wait
```

---

## 🔍 Service Discovery

### List All Services

```bash
# Application services
kubectl get svc -n default

# Observability services
kubectl get svc -n observability

# ArgoCD services
kubectl get svc -n argocd

# All services
kubectl get svc --all-namespaces
```

### Get Service Endpoints

```bash
# Get endpoints for a specific service
kubectl get endpoints -n default djtip
kubectl get endpoints -n observability grafana

# Describe service to see all details
kubectl describe svc -n default djtip
kubectl describe svc -n observability grafana
```

### DNS Names

All services are accessible via DNS within the cluster:

**Format:** `<service-name>.<namespace>.svc.cluster.local`

**Examples:**
- `djtip.default.svc.cluster.local`
- `grafana.observability.svc.cluster.local`
- `tempo.observability.svc.cluster.local`

**Short forms (within same namespace):**
- `djtip` (from default namespace)
- `grafana` (from observability namespace)

---

## 🌐 Ingress Endpoints

### Configured Ingresses

```bash
# List all ingresses
kubectl get ingress --all-namespaces

# DJ Tip App ingress
kubectl get ingress -n default djtip

# Grafana ingress
kubectl get ingress -n observability grafana
```

### Ingress Hosts

| Host | Service | Namespace | TLS |
|------|---------|-----------|-----|
| djtip.minikube.local | djtip | default | ✅ Yes |
| grafana.minikube.local | grafana | observability | ✅ Yes |

### Access Ingress Services

**Prerequisites:**
1. Minikube tunnel running: `minikube tunnel`
2. Hosts file configured:
   ```
   127.0.0.1 djtip.minikube.local
   127.0.0.1 grafana.minikube.local
   ```

**Access:**
- https://djtip.minikube.local
- https://grafana.minikube.local

---

## 📊 Monitoring Endpoints

### Application Metrics

```bash
# Prometheus metrics from Rails app
curl https://djtip.minikube.local/metrics

# Or via port-forward
kubectl port-forward -n default svc/djtip 3000:80
curl http://localhost:3000/metrics
```

### Health Checks

```bash
# Application health
curl https://djtip.minikube.local/up

# Grafana health
curl https://grafana.minikube.local/api/health

# Prometheus health
kubectl port-forward -n observability svc/mon-kube-prometheus-stack-prometheus 9090:9090
curl http://localhost:9090/-/healthy

# Loki health
kubectl port-forward -n observability svc/loki 3100:3100
curl http://localhost:3100/ready
```

---

## 🔐 Authentication

### Grafana
- **URL:** https://grafana.minikube.local
- **Username:** Not required (anonymous admin access)
- **Password:** Not required
- **Access:** Direct access, no login needed

### ArgoCD
- **URL:** https://localhost:8080 (via port-forward)
- **Username:** `admin`
- **Password:** Get from secret:
  ```bash
  kubectl -n argocd get secret argocd-initial-admin-secret \
    -o jsonpath="{.data.password}" | base64 -d
  ```

### Rails Application
- **Admin Email:** admin@djtip.com
- **Admin Password:** password123

---

## 🚀 Quick Access Guide

### Most Common Endpoints

**For Development:**
1. **Rails App:** http://localhost:3000
2. **Metrics:** http://localhost:3000/metrics
3. **MongoDB:** mongodb://localhost:27017/djtip_development

**For Kubernetes:**
1. **Rails App:** https://djtip.minikube.local
2. **Grafana:** https://grafana.minikube.local
3. **Prometheus:** Port-forward to localhost:9090
4. **ArgoCD:** Port-forward to localhost:8080

### Testing Connectivity

```bash
# Test Rails app
curl -I https://djtip.minikube.local

# Test Grafana
curl -I https://grafana.minikube.local

# Test Prometheus (via port-forward)
kubectl port-forward -n observability svc/mon-kube-prometheus-stack-prometheus 9090:9090 &
curl http://localhost:9090/-/healthy

# Test Tempo OTLP endpoint
kubectl port-forward -n observability svc/tempo 4318:4318 &
curl http://localhost:4318/v1/traces
```

---

## 📝 Notes

### Minikube Tunnel
Many services require the Minikube tunnel to be running:
```bash
minikube tunnel
```

Keep this running in a separate terminal for ingress access.

### Hosts File
Ensure your `/etc/hosts` file includes:
```
127.0.0.1 djtip.minikube.local
127.0.0.1 grafana.minikube.local
```

### TLS Certificates
TLS certificates are managed by:
- **Local:** mkcert (see `docs/HTTPS_DEV.md`)
- **Kubernetes:** Kubernetes secrets created from mkcert certificates

### Service Mesh
Currently not using a service mesh (Istio/Linkerd), all services use standard Kubernetes networking.

---

## 🔗 Related Documentation

- **[ArgoCD Setup](ARGO.md)** - Kubernetes deployment guide
- **[Docker Setup](DOCKER.md)** - Docker and Docker Compose
- **[HTTPS Development](HTTPS_DEV.md)** - Local HTTPS setup
- **[Observability Stack](OBSERVABILITY.md)** - Monitoring and tracing
- **[Instrumentation](INSTRUMENTATION.md)** - OpenTelemetry usage

---

**Last Updated:** April 14, 2026
