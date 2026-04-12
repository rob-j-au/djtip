# ArgoCD Application Manifests

This directory contains ArgoCD Application manifests for deploying the DJ Tip application.

## Files

- `djtip-app.yaml` - Main application manifest for deploying DJ Tip to Kubernetes

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

### 3. Deploy DJ Tip Application

**Option A: Using kubectl**
```bash
kubectl apply -f .cicd/argocd/djtip-app.yaml
```

**Option B: Using ArgoCD CLI**
```bash
argocd app create -f .cicd/argocd/djtip-app.yaml
```

**Option C: Using ArgoCD UI**
1. Login to ArgoCD UI
2. Click "New App"
3. Click "Edit as YAML"
4. Paste contents of `djtip-app.yaml`
5. Click "Create"

### 4. Monitor Deployment

**UI:**
- Open ArgoCD UI
- Click on the `djtip` application

**CLI:**
```bash
argocd app get djtip
argocd app sync djtip  # Force sync if needed
```

**kubectl:**
```bash
kubectl get application djtip -n argocd
kubectl get pods -n default
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

## Multiple Environments

Create separate manifests for each environment:

```
.cicd/argocd/
├── djtip-app.yaml           # Development
├── djtip-staging.yaml       # Staging
└── djtip-production.yaml    # Production
```

Example for production:

```yaml
metadata:
  name: djtip-production
spec:
  source:
    targetRevision: release  # Use release branch
    helm:
      valueFiles:
        - values-production.yaml
  destination:
    namespace: production
  syncPolicy:
    automated: null  # Manual sync for production
```

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

## Best Practices

1. **Use Git Tags for Production**
   - Development: `targetRevision: main`
   - Production: `targetRevision: v1.2.3`

2. **Manual Sync for Production**
   - Disable auto-sync for production environments
   - Review changes before syncing

3. **Separate Namespaces**
   - Development: `default` or `dev`
   - Staging: `staging`
   - Production: `production`

4. **Monitor Sync Status**
   - Set up notifications (Slack, email)
   - Regular health checks

## Additional Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Full Setup Guide](../../docs/ARGO.md)
- [Helm Chart](../helm/djtip/)
