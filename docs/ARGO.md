# ArgoCD Setup and Usage Guide

This guide covers the installation, configuration, and usage of ArgoCD for continuous deployment of the DJ Tip application on Minikube.

## Table of Contents

- [Installation](#installation)
- [Accessing ArgoCD UI](#accessing-argocd-ui)
- [Initial Setup](#initial-setup)
- [Deploying DJ Tip Application](#deploying-dj-tip-application)
- [Common Operations](#common-operations)
- [Troubleshooting](#troubleshooting)

---

## Installation

### Prerequisites

- Minikube running
- kubectl configured
- ArgoCD CLI installed (optional but recommended)

### Install ArgoCD on Minikube

1. **Create ArgoCD namespace:**

```bash
kubectl create namespace argocd
```

2. **Install ArgoCD:**

```bash
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

3. **Wait for pods to be ready:**

```bash
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
```

4. **Verify installation:**

```bash
kubectl get pods -n argocd
```

All pods should be in `Running` state.

---

## Accessing ArgoCD UI

### Method 1: Port Forwarding (Recommended for Local)

1. **Start port forwarding:**

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

2. **Access the UI:**

- Open browser: <https://localhost:8080>
- Accept the self-signed certificate warning

### Method 2: Minikube Service

```bash
minikube service argocd-server -n argocd
```

### Method 3: NodePort (Alternative)

Patch the service to use NodePort:

```bash
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'
minikube service argocd-server -n argocd --url
```

---

## Initial Setup

### Get Initial Admin Password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### Login Credentials

- **Username:** `admin`
- **Password:** Use the password from the command above

### Change Admin Password (Recommended)

Via UI:

1. Login to ArgoCD UI
2. Go to User Info (top right)
3. Click "Update Password"

Via CLI:

```bash
# Get password
PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

# Login
argocd login localhost:8080 --username admin --password "$PASSWORD" --insecure

# Change password
argocd account update-password
```

### Install ArgoCD CLI (if not installed)

**macOS:**

```bash
brew install argocd
```

**Linux:**

```bash
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x /usr/local/bin/argocd
```

---

## Deploying DJ Tip Application

### Option 1: Using ArgoCD UI

1. **Login to ArgoCD UI**

2. **Click "New App"** and configure:
   - **Application Name:** `djtip`
   - **Project:** `default`
   - **Sync Policy:** `Automatic` (or Manual)
   - **Repository URL:** Your Git repository URL
   - **Revision:** `main` (or your branch)
   - **Path:** `.cicd/helm/djtip`
   - **Cluster:** `https://kubernetes.default.svc` (in-cluster)
   - **Namespace:** `default` (or create a new namespace)

3. **Click "Create"**

4. **Sync the application** (if manual sync)

### Option 2: Using ArgoCD CLI

```bash
# Login to ArgoCD
argocd login localhost:8080 --username admin --insecure

# Create application
argocd app create djtip \
  --repo https://github.com/rob-j-au/djtip.git \
  --path .cicd/helm/djtip \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default \
  --sync-policy automated \
  --auto-prune \
  --self-heal
```

### Option 3: Using Kubernetes Manifest

Create `argocd-app.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: djtip
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/rob-j-au/djtip.git
    targetRevision: main
    path: .cicd/helm/djtip
    helm:
      valueFiles:
        - values.yaml
      parameters:
        - name: image.tag
          value: "latest"
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

Apply it:

```bash
kubectl apply -f argocd-app.yaml
```

---

## Common Operations

### View Application Status

**CLI:**

```bash
argocd app get djtip
```

**kubectl:**

```bash
kubectl get application djtip -n argocd
```

### Sync Application

**CLI:**

```bash
argocd app sync djtip
```

**UI:**

- Click on the application
- Click "Sync" button

### View Application Logs

```bash
argocd app logs djtip
```

### Delete Application

**CLI:**

```bash
argocd app delete djtip
```

**UI:**

- Click on the application
- Click "Delete" button

### Rollback to Previous Version

**CLI:**

```bash
# List history
argocd app history djtip

# Rollback to specific revision
argocd app rollback djtip <revision-number>
```

### Update Helm Values

Edit your `values.yaml` in the repository and commit:

```bash
# Edit .cicd/helm/djtip/values.yaml
git add .cicd/helm/djtip/values.yaml
git commit -m "Update helm values"
git push
```

ArgoCD will automatically detect and sync (if auto-sync is enabled).

### Manual Parameter Override

```bash
argocd app set djtip \
  --helm-set image.tag=v1.2.3 \
  --helm-set replicaCount=3
```

---

## ArgoCD Configuration

### Enable Auto-Sync

```bash
argocd app set djtip --sync-policy automated
```

### Enable Auto-Prune (Delete removed resources)

```bash
argocd app set djtip --auto-prune
```

### Enable Self-Heal (Auto-sync on drift)

```bash
argocd app set djtip --self-heal
```

### Disable Auto-Sync

```bash
argocd app set djtip --sync-policy none
```

---

## Working with Multiple Environments

### Create Environment-Specific Values

```
.cicd/helm/djtip/
├── values.yaml              # Default values
├── values-dev.yaml          # Development overrides
├── values-staging.yaml      # Staging overrides
└── values-production.yaml   # Production overrides
```

### Deploy to Different Environments

**Development:**

```bash
argocd app create djtip-dev \
  --repo https://github.com/rob-j-au/djtip.git \
  --path .cicd/helm/djtip \
  --dest-namespace dev \
  --helm-set-file values=.cicd/helm/djtip/values-dev.yaml
```

**Production:**

```bash
argocd app create djtip-prod \
  --repo https://github.com/rob-j-au/djtip.git \
  --path .cicd/helm/djtip \
  --dest-namespace production \
  --helm-set-file values=.cicd/helm/djtip/values-production.yaml
```

---

## Monitoring and Observability

### View Application Health

```bash
argocd app get djtip --show-operation
```

### View Resource Status

```bash
argocd app resources djtip
```

### View Application Events

```bash
kubectl get events -n argocd --field-selector involvedObject.name=djtip
```

### View Sync History

```bash
argocd app history djtip
```

---

## Troubleshooting

### Application Stuck in "Progressing"

```bash
# Check application details
argocd app get djtip

# Check pod status
kubectl get pods -n default

# Check pod logs
kubectl logs -n default <pod-name>
```

### Sync Fails with "Out of Sync"

```bash
# Force sync
argocd app sync djtip --force

# Hard refresh (re-fetch from Git)
argocd app get djtip --hard-refresh
```

### Can't Access ArgoCD UI

```bash
# Check if port-forward is running
ps aux | grep port-forward

# Restart port-forward
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

### Reset Admin Password

```bash
# Delete the secret (it will be regenerated)
kubectl -n argocd delete secret argocd-initial-admin-secret

# Restart argocd-server
kubectl -n argocd rollout restart deployment argocd-server

# Get new password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### Application Not Syncing Automatically

```bash
# Check sync policy
argocd app get djtip | grep "Sync Policy"

# Enable auto-sync
argocd app set djtip --sync-policy automated --self-heal --auto-prune
```

### View ArgoCD Server Logs

```bash
kubectl logs -n argocd deployment/argocd-server -f
```

### View Application Controller Logs

```bash
kubectl logs -n argocd statefulset/argocd-application-controller -f
```

---

## Uninstalling ArgoCD

### Delete All Applications First

```bash
argocd app delete djtip
```

### Uninstall ArgoCD

```bash
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl delete namespace argocd
```

---

## Best Practices

1. **Use Git as Single Source of Truth**
   - All configuration changes should go through Git
   - Avoid manual kubectl changes

2. **Enable Auto-Sync for Non-Production**
   - Development/Staging: Auto-sync enabled
   - Production: Manual sync for control

3. **Use Helm Value Files**
   - Separate values files per environment
   - Keep secrets in Kubernetes secrets, not in Git

4. **Monitor Sync Status**
   - Set up notifications (Slack, email)
   - Regular health checks

5. **Use Projects for Multi-Tenancy**
   - Separate projects for different teams/apps
   - Apply RBAC policies

6. **Tag Docker Images Properly**
   - Use semantic versioning
   - Avoid `latest` in production

---

## Useful Links

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [ArgoCD GitHub](https://github.com/argoproj/argo-cd)
- [Helm Chart Best Practices](https://helm.sh/docs/chart_best_practices/)
- [GitOps Principles](https://www.gitops.tech/)

---

## Quick Reference

### Common Commands

```bash
# Login
argocd login localhost:8080 --username admin --insecure

# List apps
argocd app list

# Get app details
argocd app get djtip

# Sync app
argocd app sync djtip

# View logs
argocd app logs djtip

# Delete app
argocd app delete djtip

# Port forward
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

### Current Installation Details

- **Namespace:** `argocd`
- **UI URL:** <https://localhost:8080> (with port-forward)
- **Username:** `admin`
- **Password:** Get from secret: `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`
- **Cluster:** Minikube (local)
