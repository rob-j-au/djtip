# Kargo Setup for djtip

[Kargo](https://kargo.io) is a progressive delivery tool that works alongside
ArgoCD to manage multi-stage promotion pipelines. It automates the promotion of
artifacts (Git commits, container images) through environments like
development → staging → production.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Kargo Control Plane                          │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │                      djtip Project                            │   │
│  │                                                               │   │
│  │  ┌───────────┐     ┌───────────┐     ┌───────────┐           │   │
│  │  │  Warehouse │────▶│   Stage   │────▶│   Stage   │────▶ ...  │   │
│  │  │   djtip    │     │    dev    │     │  staging  │           │   │
│  │  └───────────┘     └───────────┘     └───────────┘           │   │
│  │                          │                    │                │   │
│  │                          ▼                    ▼                │   │
│  │                  ┌──────────────┐    ┌──────────────┐          │   │
│  │                  │  ArgoCD App  │    │  ArgoCD App  │          │   │
│  │                  │  djtip-dev   │    │ djtip-staging│          │   │
│  │                  └──────────────┘    └──────────────┘          │   │
│  └──────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

## Promotion Pipeline

| Stage | Source | Auto-Promotion | Soak Time | ArgoCD App |
|-------|--------|---------------|-----------|------------|
| **dev** | Warehouse (main branch) | ✅ Yes | — | `djtip-development` |
| **staging** | dev stage | ✅ Yes | 5 minutes | `djtip-staging` |
| **production** | staging stage | ❌ Manual | 30 minutes | `djtip-production` |

### How it Works

1. A developer pushes a commit to the `main` branch
2. **Kargo Warehouse** detects the new commit and creates **Freight**
3. **Kargo Stage `dev`** auto-promotes the Freight (via `ProjectConfig` policy)
4. The `argocd-update` promotion step updates the `djtip-development` ArgoCD Application's `targetRevision` to the commit SHA
5. ArgoCD syncs the application, deploying the new commit to the `default` namespace
6. After 5 minutes of soak time in `dev`, **Stage `staging`** auto-promotes
7. The `argocd-update` step updates the `djtip-staging` ArgoCD Application
8. After 30 minutes of soak time in `staging`, **Stage `production`** is available for manual promotion
9. A human approves the promotion to production via the Kargo UI or CLI

## Installation

### Prerequisites

- ArgoCD installed and running (namespace: `argocd`)
- `kubectl` configured for the target cluster

### Minikube (Local Development)

```bash
# Deploy Kargo via ArgoCD
kubectl apply -f .cicd/argocd/kargo-app.yaml

# Wait for Kargo to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=kargo -n kargo --timeout=300s

# Access Kargo UI
kubectl port-forward svc/kargo-api -n kargo 31081:8080
```

Open http://localhost:31081 and login with:
- **Username:** `admin`
- **Password:** `admin`

### Pi Kubernetes Cluster

```bash
# Deploy Kargo via ArgoCD
kubectl apply -f .cicd/argocd/pi/kargo.yaml

# Or use the deploy script
./.cicd/argocd/pi/deploy.sh
```

### ArgoCD Application Deployment Order

For the Kargo promotion pipeline to work correctly, deploy in this order:

1. **ArgoCD** (already installed)
2. **Kargo** - `kubectl apply -f .cicd/argocd/kargo-app.yaml`
3. **djtip applications** - Update ArgoCD Applications with `kargo.akuity.io/authorized-stage` annotations

## Usage

### Kargo Dashboard

Access the Kargo UI to view and manage promotions:

```bash
# Minikube
kubectl port-forward svc/kargo-api -n kargo 31081:8080
# Open http://localhost:31081

# Pi (via SSH tunnel)
ssh -L 31081:localhost:31081 pi "kubectl port-forward svc/kargo-api -n kargo 31081:8080"
```

### Kargo CLI

```bash
# Download the CLI
# macOS
curl -LO https://github.com/akuity/kargo/releases/latest/download/kargo-darwin-arm64
chmod +x kargo-darwin-arm64
sudo mv kargo-darwin-arm64 /usr/local/bin/kargo

# Login
kargo login localhost:31081 --admin

# View projects
kargo get projects

# View stages
kargo get stages --project djtip

# View freight
kargo get freight --project djtip

# Manually promote to production
kargo promote --project djtip --stage production --freight <freight-id>
```

## Files

| File | Description |
|------|-------------|
| [`.cicd/helm/kargo/Chart.yaml`](Chart.yaml) | Kargo Helm chart wrapping the upstream OCI chart |
| [`.cicd/helm/kargo/values.yaml`](values.yaml) | Kargo values with extraObjects (Warehouse, Stages, Project) |
| [`.cicd/argocd/kargo-app.yaml`](../../argocd/kargo-app.yaml) | ArgoCD Application for Kargo (Minikube) |
| [`.cicd/argocd/pi/kargo.yaml`](../../argocd/pi/kargo.yaml) | ArgoCD Application for Kargo (Pi) |

## Troubleshooting

### Kargo Pods Not Starting

```bash
kubectl get pods -n kargo
kubectl describe pod -n kargo <pod-name>
kubectl logs -n kargo <pod-name>
```

### Warehouse Not Discovering Commits

```bash
kubectl get warehouses -n kargo-djtip
kubectl describe warehouse -n kargo-djtip djtip
```

### Stage Not Promoting

```bash
kubectl get stages -n kargo-djtip
kubectl describe stage -n kargo-djtip <stage-name>
kubectl get promotions -n kargo-djtip
```

### ArgoCD Application Not Authorized

Ensure the ArgoCD Application has the annotation:
```yaml
metadata:
  annotations:
    kargo.akuity.io/authorized-stage: djtip:<stage-name>
```

## References

- [Kargo Documentation](https://docs.kargo.io)
- [Kargo GitHub](https://github.com/akuity/kargo)
- [ArgoCD Integration](https://docs.kargo.io/user-guide/reference-docs/promotion-steps/argocd-update)