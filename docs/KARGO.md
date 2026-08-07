# Kargo - Progressive Delivery for djtip

Kargo is a progressive delivery tool built by Akuity (the creators of Argo) that
sits alongside ArgoCD to manage **multi-stage promotion pipelines**. It automates
the movement of application changes (Git commits, container images) through
environments such as development → staging → production, with configurable soak
times, verification, and manual approval gates.

## Why Kargo?

The current ArgoCD setup uses **branch-based** deployment:
- `main` branch → development
- `staging` branch → staging
- `release` branch → production

Kargo adds a **promotion-based** model on top of this:
- A single **Warehouse** watches the Git repository
- **Stages** define promotion paths between environments
- Freight (a specific commit) is promoted through stages with soak times
- Each stage's promotion updates the corresponding ArgoCD Application's `targetRevision`

## Architecture

```
                 ┌───────────────────────────────────────────────┐
                 │            Kargo (namespace: kargo)            │
                 │                                                │
                 │  ┌────────────────────────────────────────┐    │
                 │  │  Project: djtip (ns: djtip)      │    │
                 │  │                                        │    │
                 │  │  ┌──────────┐     ┌───────────┐        │    │
   git push ────────▶│ Warehouse │────▶│ Stage dev │───────┐ │    │
   (main branch) │  │  djtip    │auto │ (auto)    │ 5m soak│ │    │
                 │  └──────────┘     └───────────┘        │ │    │
                 │                           │             ▼ │    │
                 │                           ▼        ┌───────────┐
                 │                    ┌───────────┐   │  Stage    │
                 │                    │  Stage    │──▶│ production│
                 │                    │ staging   │   │ (manual)  │
                 │                    └───────────┘   └───────────┘
                 │                           │              │
                 └───────────────────────────┼──────────────┼──────┘
                                             │              │
                     argocd-update step      ▼              ▼
                 ┌────────────────────┐  ┌────────────┐  ┌────────────┐
                 │ ArgoCD Application │  │ ArgoCD App │  │ ArgoCD App │
                 │ djtip-development  │  │ djtip-stage│  │ djtip-prod │
                 └────────────────────┘  └────────────┘  └────────────┘
```

## Promotion Pipeline

| Stage | Source | Auto-Promotion | Soak Time | ArgoCD Application | Namespace |
|-------|--------|---------------|-----------|-------------------|-----------|
| **dev** | Warehouse (main) | ✅ Yes | — | `djtip-development` | `default` |
| **staging** | Stage `dev` | ✅ Yes | 5 minutes | `djtip-staging` | `staging` |
| **production** | Stage `staging` | ❌ Manual | 30 minutes | `djtip-production` | `production` |

## How a Promotion Works

1. A commit is pushed to `main` on `https://github.com/rob-j-au/djtip.git`
2. Kargo **Warehouse `djtip`** polls the repo (every 5m) and creates a **Freight** object
3. `ProjectConfig` policy allows **auto-promotion** to `dev`
4. Kargo runs the `argocd-update` promotion step, which sets `targetRevision` on
   the `djtip-development` ArgoCD Application to the promoted commit SHA
5. ArgoCD syncs the application (deployment to the `default` namespace)
6. After the Freight has "soaked" in `dev` for 5 minutes, it becomes available to
   `staging`, which auto-promotes (updating `djtip-staging`)
7. After 30 minutes in `staging`, the Freight becomes available to `production`
8. **A human must approve** the production promotion via the Kargo UI or CLI

## Installation

### Prerequisites

- ArgoCD running in the `argocd` namespace
- Helm CLI (for local chart validation)
- `kubectl` access to the target cluster

### Minikube

```bash
# 1. Deploy Kargo via ArgoCD
kubectl apply -f .cicd/argocd/kargo-app.yaml

# 2. Wait for the Kargo API
kubectl wait --for=condition=available --timeout=300s deployment -l app.kubernetes.io/name=kargo-api -n kargo

# 3. Verify Kargo resources were created
kubectl get projects -n kargo
kubectl get warehouses,stages -n djtip

# 4. Access the UI
kubectl port-forward svc/kargo-api -n kargo 31081:8080
# → http://localhost:31081  (admin / admin)
```

### Pi Cluster

```bash
kubectl apply -f .cicd/argocd/pi/kargo.yaml
# Or: ./.cicd/argocd/pi/deploy.sh

# UI via SSH tunnel
ssh -L 31081:localhost:31081 pi "kubectl port-forward svc/kargo-api -n kargo 31081:8080"
```

## Kargo CLI

```bash
# Install (macOS ARM)
curl -LO https://github.com/akuity/kargo/releases/latest/download/kargo-darwin-arm64
chmod +x kargo-darwin-arm64 && sudo mv kargo-darwin-arm64 /usr/local/bin/kargo

# Login
kargo login localhost:31081 --admin

# Common commands
kargo get projects
kargo get warehouses --project djtip
kargo get stages --project djtip
kargo get freight --project djtip
kargo get promotions --project djtip

# Manual promotion to production
kargo promote --project djtip --stage production --freight <freight-id>
```

## Configuration Files

| File | Purpose |
|------|---------|
| [`.cicd/helm/kargo/Chart.yaml`](../.cicd/helm/kargo/Chart.yaml) | Wraps upstream `ghcr.io/akuity/kargo-charts/kargo` chart |
| [`.cicd/helm/kargo/values.yaml`](../.cicd/helm/kargo/values.yaml) | Kargo config + `extraObjects` (Project, ProjectConfig, Warehouse, Stages) |
| [`.cicd/argocd/kargo-app.yaml`](../.cicd/argocd/kargo-app.yaml) | ArgoCD Application → deploys Kargo (Minikube) |
| [`.cicd/argocd/pi/kargo.yaml`](../.cicd/argocd/pi/kargo.yaml) | ArgoCD Application → deploys Kargo (Pi) |
| [`docs/KARGO.md`](KARGO.md) | This document |

## Authorizing ArgoCD Applications

Each ArgoCD Application that Kargo will update **must** carry the annotation:

```yaml
metadata:
  annotations:
    kargo.akuity.io/authorized-stage: djtip:<stage-name>
```

Applied to:
- `djtip-development` → `djtip:dev`
- `djtip-staging` → `djtip:staging`
- `djtip-production` → `djtip:production`

## Troubleshooting

| Symptom | Command |
|---------|---------|
| Kargo pods crash-looping | `kubectl get pods -n kargo && kubectl logs -n kargo deploy/kargo-controller` |
| Warehouse not finding commits | `kubectl describe warehouse -n djtip djtip` |
| Stage stuck `NotVerified` | `kubectl describe stage -n djtip <stage>` |
| Promotion failed | `kubectl get promotions -n djtip && kubectl describe promotion -n djtip <name>` |
| ArgoCD app "unauthorized" | Verify `kargo.akuity.io/authorized-stage` annotation is present |

## References

- [Kargo Docs](https://docs.kargo.io)
- [argocd-update step reference](https://docs.kargo.io/user-guide/reference-docs/promotion-steps/argocd-update)
- [Kargo GitHub](https://github.com/akuity/kargo)