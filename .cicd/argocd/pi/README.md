# Pi Kubernetes Deployment

This directory contains ArgoCD application manifests for deploying the djtip stack to the Pi Kubernetes cluster.

## Architecture

The Pi cluster runs:
- **Staging environment** (namespace: `staging`)
- **Production environment** (namespace: `production`)
- **Observability stack** (namespace: `observability`)
- **HAProxy Ingress Controller** (namespace: `haproxy-controller`)

## Domains

All services use the `*.k8s.pi.jennings.au` domain:

| Environment | URL |
|-------------|-----|
| **Staging** | https://djtip-staging.k8s.pi.jennings.au |
| **Production** | https://djtip.k8s.pi.jennings.au |
| **Grafana** | https://grafana.k8s.pi.jennings.au |

## Deployment

### Quick Deploy

```bash
# From the project root
./.cicd/argocd/pi/deploy.sh
```

### Manual Deploy

1. **Install ArgoCD** (if not already installed):
   ```bash
   ssh pi "kubectl create namespace argocd"
   ssh pi "kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
   ```

2. **Apply applications**:
   ```bash
   kubectl apply -f .cicd/argocd/pi/haproxy-ingress.yaml
   kubectl apply -f .cicd/argocd/pi/observability.yaml
   kubectl apply -f .cicd/argocd/pi/djtip-staging.yaml
   kubectl apply -f .cicd/argocd/pi/djtip-production.yaml
   ```

## Branch Strategy

| Environment | Branch | Auto-Sync |
|-------------|--------|-----------|
| **Staging** | `staging` | ✅ Yes |
| **Production** | `release` | ❌ Manual |

## Resource Scaling

Both staging and production use **2x the resources** of development:

| Resource | Staging/Production |
|----------|-------------------|
| Web Replicas | 4 |
| Worker Replicas | 2 |
| Web Memory | 512Mi-1Gi |
| Web CPU | 200m-1000m |
| Worker Memory | 512Mi-1Gi |
| Worker CPU | 200m-1000m |

## DNS Configuration

Configure your DNS to point these domains to your Pi's IP address:

```
djtip-staging.k8s.pi.jennings.au  A  <PI_IP_ADDRESS>
djtip.k8s.pi.jennings.au          A  <PI_IP_ADDRESS>
grafana.k8s.pi.jennings.au        A  <PI_IP_ADDRESS>
```

Or use a wildcard:
```
*.k8s.pi.jennings.au  A  <PI_IP_ADDRESS>
```

## Monitoring

### Check Application Status

```bash
ssh pi "kubectl get applications -n argocd"
```

### Check Pods

```bash
# Staging
ssh pi "kubectl get pods -n staging"

# Production
ssh pi "kubectl get pods -n production"

# Observability
ssh pi "kubectl get pods -n observability"
```

### ArgoCD UI

1. **Port-forward ArgoCD**:
   ```bash
   ssh -L 8080:localhost:8080 pi "kubectl port-forward svc/argocd-server -n argocd 8080:443"
   ```

2. **Get admin password**:
   ```bash
   ssh pi "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
   ```

3. **Access**: https://localhost:8080
   - Username: `admin`
   - Password: (from step 2)

## Syncing Applications

### Staging (Auto-sync enabled)
Automatically syncs when changes are pushed to the `staging` branch.

### Production (Manual sync required)

```bash
# Via kubectl
ssh pi "kubectl patch application djtip-production -n argocd --type merge -p '{\"operation\":{\"initiatedBy\":{\"username\":\"admin\"},\"sync\":{\"revision\":\"HEAD\"}}}'"

# Or via ArgoCD CLI (if installed)
argocd app sync djtip-production
```

## Secrets

Before deploying, ensure secrets are created in each namespace:

```bash
# Staging
ssh pi "kubectl create secret generic djtip-staging-secrets -n staging --from-literal=SECRET_KEY_BASE=<your-secret>"

# Production
ssh pi "kubectl create secret generic djtip-production-secrets -n production --from-literal=SECRET_KEY_BASE=<your-secret>"
```

## Troubleshooting

### Application OutOfSync

```bash
# Force refresh
ssh pi "kubectl patch application <app-name> -n argocd --type merge -p '{\"metadata\":{\"annotations\":{\"argocd.argoproj.io/refresh\":\"hard\"}}}'"
```

### Pods Not Starting

```bash
# Check events
ssh pi "kubectl get events -n <namespace> --sort-by='.lastTimestamp'"

# Check pod logs
ssh pi "kubectl logs -n <namespace> <pod-name>"
```

### Ingress Not Working

```bash
# Check ingress
ssh pi "kubectl get ingress -A"

# Check HAProxy pods
ssh pi "kubectl get pods -n haproxy-controller"
```
