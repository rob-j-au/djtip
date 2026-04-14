# Service Endpoints

Complete reference for all environments: Local, Development, Staging, and Production.

## Quick Reference

| Environment | Application | Grafana | Prometheus |
|-------------|-------------|---------|------------|
| **Local** | http://localhost:3000 | N/A | N/A |
| **Development** | https://app.dev.yourdomain.com | https://grafana.dev.yourdomain.com | Port-forward |
| **Staging** | https://app.staging.yourdomain.com | https://grafana.staging.yourdomain.com | Port-forward |
| **Production** | https://app.yourdomain.com | https://grafana.yourdomain.com | Port-forward |

---

## Local Development

### Rails Application

| Service | URL | Description |
|---------|-----|-------------|
| **Web App** | http://localhost:3000 | Main application |
| **Metrics** | http://localhost:3000/metrics | Prometheus metrics |
| **Health** | http://localhost:3000/up | Health check |

### Database & Cache

| Service | URL | Description |
|---------|-----|-------------|
| **MongoDB** | mongodb://localhost:27017/djtip_development | Database |
| **Redis** | redis://localhost:6379 | Cache/sessions |

---

## Kubernetes Environments

### Development (Minikube)

**Domain:** `*.dev.yourdomain.com`

| Service | URL | Description |
|---------|-----|-------------|
| **Application** | https://app.dev.yourdomain.com | Main app |
| **Grafana** | https://grafana.dev.yourdomain.com | Dashboards |
| **Metrics** | https://app.dev.yourdomain.com/metrics | Prometheus metrics |

**Configuration:**
- 2 web pods
- 1 worker pod
- Auto-sync enabled
- Wildcard TLS: `wildcard-dev-tls`

### Staging

**Domain:** `*.staging.yourdomain.com`

| Service | URL | Description |
|---------|-----|-------------|
| **Application** | https://app.staging.yourdomain.com | Main app |
| **Grafana** | https://grafana.staging.yourdomain.com | Dashboards |
| **Metrics** | https://app.staging.yourdomain.com/metrics | Prometheus metrics |

**Configuration:**
- 4 web pods
- 2 worker pods
- Persistence enabled
- Auto-sync enabled
| Wildcard TLS: `wildcard-staging-tls`

### Production

**Domain:** `*.yourdomain.com`

| Service | URL | Description |
|---------|-----|-------------|
| **Application** | https://app.yourdomain.com | Main app |
| **Grafana** | https://grafana.yourdomain.com | Dashboards |
| **Metrics** | https://app.yourdomain.com/metrics | Prometheus metrics |

**Configuration:**
- 4 web pods (autoscaling)
- 2 worker pods
- Persistence enabled
- Manual sync only
- Wildcard TLS: `wildcard-prod-tls`

---

## Observability Stack

### Grafana

**Access:** https://grafana.{env}.yourdomain.com

- Anonymous admin access enabled
- Pre-configured dashboards
- Data sources: Prometheus, Loki, Tempo

### Prometheus

**Internal:** `http://mon-kube-prometheus-stack-prometheus.observability:9090`

**Port-forward:**
```bash
kubectl port-forward -n observability svc/mon-kube-prometheus-stack-prometheus 9090:9090
# Access: http://localhost:9090
```

### Loki

**Internal:** `http://loki.observability:3100`

**Port-forward:**
```bash
kubectl port-forward -n observability svc/loki 3100:3100
# Access: http://localhost:3100
```

### Tempo

**Internal:** `http://tempo.observability:4318` (OTLP HTTP)

**Port-forward:**
```bash
kubectl port-forward -n observability svc/tempo 4318:4318
# Access: http://localhost:4318
```

---

## Internal Services

### Application (within cluster)

| Service | Internal URL | Port |
|---------|--------------|------|
| **Web** | http://app.{namespace}:80 | 80 |
| **MongoDB** | mongodb://app-mongodb.{namespace}:27017 | 27017 |
| **Redis** | redis://app-redis-master.{namespace}:6379 | 6379 |

### Observability (within cluster)

| Service | Internal URL | Port |
|---------|--------------|------|
| **Prometheus** | http://mon-kube-prometheus-stack-prometheus.observability:9090 | 9090 |
| **Grafana** | http://grafana.observability:80 | 80 |
| **Loki** | http://loki.observability:3100 | 3100 |
| **Tempo OTLP** | http://tempo.observability:4318 | 4318 |
| **Tempo Query** | http://tempo.observability:3100 | 3100 |

---

## ArgoCD

**Access via port-forward:**
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Access: https://localhost:8080
```

**Get admin password:**
```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

---

## Port Forwarding

### Quick Commands

```bash
# Application
kubectl port-forward -n default svc/app 3000:80

# Grafana
kubectl port-forward -n observability svc/grafana 3001:80

# Prometheus
kubectl port-forward -n observability svc/mon-kube-prometheus-stack-prometheus 9090:9090

# Loki
kubectl port-forward -n observability svc/loki 3100:3100

# Tempo
kubectl port-forward -n observability svc/tempo 4318:4318

# ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

---

## Health Checks

### Application

```bash
# Local
curl http://localhost:3000/up

# Kubernetes
curl https://app.dev.yourdomain.com/up
```

### Observability

```bash
# Grafana
curl https://grafana.dev.yourdomain.com/api/health

# Prometheus (via port-forward)
kubectl port-forward -n observability svc/mon-kube-prometheus-stack-prometheus 9090:9090
curl http://localhost:9090/-/healthy

# Loki (via port-forward)
kubectl port-forward -n observability svc/loki 3100:3100
curl http://localhost:3100/ready
```

---

## TLS Certificates

All Kubernetes environments use Let's Encrypt wildcard certificates via cert-manager:

- **Development**: `wildcard-dev-tls` → `*.dev.yourdomain.com`
- **Staging**: `wildcard-staging-tls` → `*.staging.yourdomain.com`
- **Production**: `wildcard-prod-tls` → `*.yourdomain.com`

**Verify certificates:**
```bash
kubectl get certificates -n cert-manager
kubectl get secrets -A | grep wildcard
```

---

## DNS Configuration

Managed by Terraform in `.terraform/cloudflare/`:

```
*.dev.yourdomain.com      → Minikube IP
*.staging.yourdomain.com  → Auto from base domain
*.yourdomain.com          → Auto from base domain
```

**Update DNS:**
```bash
cd .terraform/cloudflare
terraform apply
```

---

## Related Documentation

- [cert-manager Setup](CERT_MANAGER.md) - TLS certificates
- [ArgoCD Deployment](ARGO.md) - Kubernetes guide
- [Observability Stack](OBSERVABILITY.md) - Monitoring
- [Terraform DNS](.terraform/cloudflare/README.md) - DNS automation
