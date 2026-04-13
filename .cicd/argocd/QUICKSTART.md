# ArgoCD Quick Start Guide

## 🚀 Access ArgoCD UI

```bash
# Easy way - use the helper script
./scripts/argocd-access.sh

# Manual way
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

**URL:** https://localhost:8080

**Credentials:**
- Username: `admin`
- Password: `X7Ff-siflLm4b7yo`

## 📦 Deploy DJ Tip Application

### Method 1: kubectl (Recommended)
```bash
kubectl apply -f .cicd/argocd/djtip-app.yaml
```

### Method 2: ArgoCD CLI
```bash
# Login first
argocd login localhost:8080 --username admin --password X7Ff-siflLm4b7yo --insecure

# Create app
argocd app create -f .cicd/argocd/djtip-app.yaml

# Or create directly
argocd app create djtip \
  --repo https://github.com/rob-j-au/djtip.git \
  --path .cicd/helm/djtip \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default \
  --sync-policy automated
```

### Method 3: ArgoCD UI
1. Login to UI
2. Click "+ NEW APP"
3. Fill in:
   - **App Name:** djtip
   - **Project:** default
   - **Sync Policy:** Automatic
   - **Repository URL:** https://github.com/rob-j-au/djtip.git
   - **Path:** .cicd/helm/djtip
   - **Cluster URL:** https://kubernetes.default.svc
   - **Namespace:** default
4. Click "CREATE"

## 🔍 Monitor Application

```bash
# View app status
argocd app get djtip

# View app in UI
open https://localhost:8080

# Watch pods
kubectl get pods -n default -w

# View logs
argocd app logs djtip -f
```

## 🔄 Common Operations

```bash
# Sync application
argocd app sync djtip

# Refresh app (check for changes)
argocd app get djtip --refresh

# View sync history
argocd app history djtip

# Rollback to previous version
argocd app rollback djtip <revision>

# Delete application
argocd app delete djtip
```

## ⚙️ Update Configuration

### Update Image Tag
```bash
# Edit values.yaml
vim .cicd/helm/djtip/values.yaml

# Commit and push
git add .cicd/helm/djtip/values.yaml
git commit -m "Update image tag"
git push

# ArgoCD will auto-sync (if enabled)
```

### Manual Parameter Override
```bash
argocd app set djtip --helm-set image.tag=v1.2.3
```

## 🛠️ Troubleshooting

```bash
# App stuck? Force sync
argocd app sync djtip --force

# Hard refresh (re-fetch from Git)
argocd app get djtip --hard-refresh

# View ArgoCD server logs
kubectl logs -n argocd deployment/argocd-server -f

# Check application events
kubectl get events -n argocd
```

## 📚 Documentation

- **Full Guide:** [docs/ARGO.md](../../docs/ARGO.md)
- **ArgoCD Docs:** https://argo-cd.readthedocs.io/
- **Helm Chart:** [.cicd/helm/djtip/](../helm/djtip/)

## 🔐 Security

### Change Admin Password
```bash
argocd account update-password
```

### Create Additional Users
Edit ArgoCD ConfigMap:
```bash
kubectl edit configmap argocd-cm -n argocd
```

## 🌍 Multiple Environments

Create separate app manifests:
```bash
# Development (auto-sync)
kubectl apply -f .cicd/argocd/djtip-app.yaml

# Production (manual sync)
kubectl apply -f .cicd/argocd/djtip-production.yaml
```

## ✅ Health Checks

```bash
# Check ArgoCD health
kubectl get pods -n argocd

# Check application health
argocd app get djtip | grep Health

# View application resources
argocd app resources djtip
```

## 🗑️ Cleanup

```bash
# Delete application (keeps ArgoCD)
argocd app delete djtip

# Uninstall ArgoCD completely
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl delete namespace argocd
```
