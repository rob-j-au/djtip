# ArgoCD Application Manifests

This directory contains ArgoCD Application manifests for deploying the djtip application across multiple environments.

## Files

### Minikube (Local Development)
- `djtip-development.yaml` - Development environment (default namespace, main branch)
- `djtip-staging.yaml` - Staging environment (staging namespace, staging branch)
- `djtip-production.yaml` - Production environment (production namespace, release branch)
- `observability-app.yaml` - Observability stack (Grafana, Prometheus, Loki, Tempo)
- `haproxy-ingress-app.yaml` - HAProxy Ingress Controller
- `cert-manager-app.yaml` - cert-manager for automated TLS certificates

### Pi Kubernetes Cluster
- `pi/` - Separate manifests for Pi deployment (staging and production only)

## Quick Start

### 1. Install ArgoCD (if not already installed)

See [docs/ARGO.md](../../docs/ARGO.md) for detailed installation instructions.

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### 2. Access ArgoCD UI

```bash
# Use the helper script
./scripts/argocd-access.sh

# Or manually
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Open https://localhost:8080

### 3. Deploy Infrastructure

**Deploy in this order:**

```bash
# 1. HAProxy Ingress Controller
kubectl apply -f .cicd/argocd/haproxy-ingress-app.yaml

# 2. cert-manager (for automated TLS)
kubectl apply -f .cicd/argocd/cert-manager-app.yaml

# 3. Observability Stack
kubectl apply -f .cicd/argocd/observability-app.yaml

# 4. Development Application
kubectl apply -f .cicd/argocd/djtip-development.yaml
```

**Optional: Deploy Staging/Production**
```bash
kubectl apply -f .cicd/argocd/djtip-staging.yaml
kubectl apply -f .cicd/argocd/djtip-production.yaml
```

### 4. Monitor Deployment

**Check all applications:**
```bash
kubectl get applications -n argocd
```

**Check pods by namespace:**
```bash
kubectl get pods -n default              # Development
kubectl get pods -n staging              # Staging
kubectl get pods -n production           # Production
kubectl get pods -n observability        # Monitoring
kubectl get pods -n haproxy-controller   # Ingress
kubectl get pods -n cert-manager         # TLS
```

**Check certificates:**
```bash
kubectl get clusterissuers
kubectl get certificates -A
```

## Configuration

### Update Git Repository URL

Edit `djtip-app.yaml` and update the `repoURL`:

```yaml
source:
  repoURL: https://github.com/YOUR-USERNAME/djtip.git
```

### Change Target Namespace

Edit `djtip-app.yaml`:

```yaml
destination:
  namespace: production  # Change from 'default'
```

### Override Helm Values

Add parameters to `djtip-app.yaml`:

```yaml
source:
  helm:
    parameters:
      - name: image.tag
        value: "v1.2.3"
      - name: replicaCount
        value: "3"
```

### Disable Auto-Sync

Comment out the `automated` section in `djtip-app.yaml`:

```yaml
syncPolicy:
  # automated:
  #   prune: true
  #   selfHeal: true
```

## Sync Policies

### Automated Sync (Current)
- **Prune:** Enabled - Deletes resources removed from Git
- **Self-Heal:** Enabled - Reverts manual changes to match Git
- **Retry:** 5 attempts with exponential backoff

### Manual Sync
To switch to manual sync, comment out the `automated` section.

## Environment Configuration

### Development (Minikube)
- **Namespace**: `default`
- **Branch**: `main`
- **Values**: `values-development.yaml`
- **Auto-sync**: ✅ Enabled
- **Resources**: 2 web pods, 1 worker
- **Ingress**: `djtip.minikube.local`
- **TLS**: Let's Encrypt Staging

### Staging (Minikube)
- **Namespace**: `staging`
- **Branch**: `staging`
- **Values**: `values-staging.yaml`
- **Auto-sync**: ✅ Enabled
- **Resources**: 4 web pods, 2 workers (2x dev)
- **Ingress**: `djtip-staging.minikube.local`
- **TLS**: Let's Encrypt Staging
- **Persistence**: Enabled (MongoDB 8Gi, Redis 4Gi)

### Production (Minikube)
- **Namespace**: `production`
- **Branch**: `release`
- **Values**: `values-production.yaml`
- **Auto-sync**: ❌ Manual only
- **Resources**: 4 web pods, 2 workers (2x dev)
- **Ingress**: `djtip.production.local`
- **TLS**: Let's Encrypt Production
- **Persistence**: Enabled (MongoDB 20Gi, Redis 10Gi)
- **Autoscaling**: Enabled (4-20 replicas)
- **Auth**: MongoDB & Redis authentication enabled

### Pi Cluster (Staging & Production)
- **Ingress**: `*.k8s.pi.jennings.au`
- **TLS**: Let's Encrypt Production
- See `pi/README.md` for details

## Troubleshooting

### Application Not Syncing

```bash
# Check application status
argocd app get djtip

# Force sync
argocd app sync djtip --force

# Hard refresh
argocd app get djtip --hard-refresh
```

### View Application Logs

```bash
argocd app logs djtip
```

### Delete and Recreate

```bash
kubectl delete -f .cicd/argocd/djtip-app.yaml
kubectl apply -f .cicd/argocd/djtip-app.yaml
```

## Infrastructure Components

### HAProxy Ingress Controller
- **Release name**: `haproxy`
- **Pods**: `haproxy-ingress` (2 replicas)
- **Service**: NodePort (30080/http, 30443/https)
- **Chart**: `.cicd/helm/haproxy-ingress`

### cert-manager
- **Namespace**: `cert-manager`
- **ClusterIssuers**: `letsencrypt-staging`, `letsencrypt-prod`
- **Auto-renewal**: 30 days before expiry
- **Challenge**: HTTP-01 via HAProxy
- **Chart**: `.cicd/helm/cert-manager`

### Observability Stack
- **Release name**: `obs`
- **Components**: Grafana, Prometheus, Loki, Tempo, Alertmanager
- **Ingress**: `grafana.minikube.local`
- **Chart**: `.cicd/helm/observability`

## Helm Values Structure

### Base Values (`values.yaml`)
- Default configuration for all environments
- Environment variables in `env:` section
- Resource requests and limits
- MongoDB and Redis configuration

### Environment Overrides
- `values-development.yaml` - Minimal overrides (just ingress)
- `values-staging.yaml` - 2x resources, persistence enabled
- `values-production.yaml` - 2x resources, autoscaling, auth enabled

### Parameterized Environment Variables
All environment variables are now configurable via Helm values:
```yaml
env:
  railsEnv: "production"
  logLevel: "info"
  otelServiceName: "djtip"
  # ... etc
```

## Best Practices

1. **Branch Strategy**
   - Development: `main` branch
   - Staging: `staging` branch
   - Production: `release` branch

2. **Manual Sync for Production**
   - Production has auto-sync disabled
   - Always review changes before syncing
   - Use ArgoCD UI or CLI to sync manually

3. **TLS Certificates**
   - Development/Staging: Use `letsencrypt-staging` (unlimited rate limits)
   - Production: Use `letsencrypt-prod` (50 certs/week limit)
   - Certificates auto-renew 30 days before expiry

4. **Resource Scaling**
   - Staging/Production: 2x development resources
   - Production: Autoscaling enabled (4-20 replicas)
   - Adjust based on actual load

5. **Secrets Management**
   - Create secrets before deploying apps
   - Use different secrets per environment
   - Never commit secrets to Git

## Secrets Required

### Development
```bash
kubectl create secret generic djtip-development-secrets -n default \
  --from-literal=SECRET_KEY_BASE=$(openssl rand -hex 64)
```

### Staging
```bash
kubectl create secret generic djtip-staging-secrets -n staging \
  --from-literal=SECRET_KEY_BASE=$(openssl rand -hex 64)
```

### Production
```bash
kubectl create secret generic djtip-production-secrets -n production \
  --from-literal=SECRET_KEY_BASE=$(openssl rand -hex 64)
```

## Access URLs

### Minikube
- **Development**: https://djtip.minikube.local
- **Staging**: https://djtip-staging.minikube.local
- **Production**: https://djtip.production.local
- **Grafana**: https://grafana.minikube.local

### Pi Cluster
- **Staging**: https://djtip-staging.k8s.pi.jennings.au
- **Production**: https://djtip.k8s.pi.jennings.au
- **Grafana**: https://grafana.k8s.pi.jennings.au

## Additional Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Full Setup Guide](../../docs/ARGO.md)
- [Helm Charts](../helm/)
- [cert-manager Setup](../helm/cert-manager/README.md)
- [Pi Deployment](pi/README.md)
