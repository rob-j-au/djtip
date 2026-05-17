# Vultr Kubernetes Deployment Guide

## Overview

The djtip staging application is deployed on a Vultr VPS running Kubernetes (K3s) with Traefik as the ingress controller.

## Infrastructure

### Cluster Details

- **Provider**: Vultr VPS
- **Kubernetes**: K3s (lightweight Kubernetes)
- **Ingress Controller**: Traefik
- **Certificate Manager**: cert-manager with Let's Encrypt
- **GitOps**: ArgoCD

### Access

```bash
# SSH into Vultr VPS
ssh vultr

# Check cluster status
kubectl get nodes
kubectl get pods -A
```

## Deployed Applications

### Staging Environment

- **Namespace**: `staging`
- **URL**: https://app.staging.djtip.jennings.au
- **IP Address**: 45.32.242.189

#### Components

```bash
# Check all resources in staging namespace
kubectl get all -n staging

# Expected resources:
# - djtip-staging (web application)
# - djtip-staging-worker (Sidekiq background jobs)
# - djtip-staging-mongodb (database)
# - djtip-staging-redis (cache/sessions)
```

## Traefik Ingress Controller

### Overview

Traefik replaced HAProxy as the ingress controller for better Kubernetes integration and automatic service discovery.

### Configuration

The Traefik ingress is configured in the Helm chart at `.cicd/helm/djtip/values-staging.yaml`:

```yaml
ingress:
  enabled: true
  className: "traefik"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod-dns01"
    traefik.ingress.kubernetes.io/router.tls: "true"
  hosts:
    - host: app.staging.djtip.jennings.au
      paths:
        - path: /
          pathType: ImplementationSpecific
  tls:
    - secretName: djtip-staging-tls
      hosts:
        - app.staging.djtip.jennings.au
```

### Traefik Service

```bash
# Check Traefik service
kubectl get svc -n kube-system traefik

# Expected output:
# NAME      TYPE       CLUSTER-IP    EXTERNAL-IP   PORT(S)
# traefik   NodePort   10.43.6.196   <none>        80:30080/TCP,443:30443/TCP
```

### Ingress Status

```bash
# Check ingress resources
kubectl get ingress -A

# Check specific staging ingress
kubectl get ingress djtip-staging -n staging -o yaml
```

## ArgoCD GitOps

### Overview

ArgoCD automatically deploys and syncs the application from the GitHub repository.

### Application Status

```bash
# Check ArgoCD applications
kubectl get application -n argocd

# Get detailed status
kubectl get application djtip-staging -n argocd -o yaml
```

### Source Repository

- **Repository**: https://github.com/rob-j-au/djtip.git
- **Branch**: main
- **Path**: `.cicd/helm/djtip`
- **Values File**: `values-staging.yaml`

### Manual Sync

```bash
# Trigger manual sync (if needed)
kubectl patch application djtip-staging -n argocd \
  --type merge \
  -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}'
```

## TLS Certificates

### cert-manager

TLS certificates are automatically managed by cert-manager using Let's Encrypt DNS-01 challenge.

```bash
# Check certificates
kubectl get certificate -n staging

# Check certificate details
kubectl describe certificate djtip-staging-tls -n staging

# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager
```

### Certificate Issuer

- **Issuer**: `letsencrypt-prod-dns01`
- **Challenge Type**: DNS-01
- **Secret Name**: `djtip-staging-tls`

## Deployment Process

### Automatic Deployment

1. Push code to `main` branch on GitHub
2. ArgoCD detects changes (polls every 3 minutes)
3. ArgoCD syncs Helm chart with new values
4. Kubernetes applies changes
5. Traefik automatically routes traffic to new pods

### Manual Deployment

```bash
# Update Helm values locally
vim .cicd/helm/djtip/values-staging.yaml

# Commit and push
git add .cicd/helm/djtip/values-staging.yaml
git commit -m "Update staging configuration"
git push origin main

# ArgoCD will auto-sync within 3 minutes
# Or trigger manual sync via ArgoCD UI/CLI
```

## Monitoring & Debugging

### Check Application Logs

```bash
# Web application logs
kubectl logs -n staging -l app.kubernetes.io/name=djtip -f

# Worker logs
kubectl logs -n staging -l app.kubernetes.io/component=worker -f

# MongoDB logs
kubectl logs -n staging -l app.kubernetes.io/name=mongodb -f

# Redis logs
kubectl logs -n staging -l app.kubernetes.io/name=redis -f
```

### Check Application Status

```bash
# Get all pods in staging
kubectl get pods -n staging

# Describe a specific pod
kubectl describe pod <pod-name> -n staging

# Get pod resource usage
kubectl top pods -n staging
```

### Check Ingress Routing

```bash
# Test DNS resolution
dig app.staging.djtip.jennings.au

# Test HTTP endpoint
curl -I https://app.staging.djtip.jennings.au

# Check Traefik routes
kubectl get ingressroute -A
```

### Common Issues

#### Pod Not Starting

```bash
# Check pod events
kubectl describe pod <pod-name> -n staging

# Check pod logs
kubectl logs <pod-name> -n staging

# Common causes:
# - Image pull errors
# - Resource limits (OOMKilled)
# - Missing environment variables
# - Database connection issues
```

#### Certificate Issues

```bash
# Check certificate status
kubectl get certificate -n staging

# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager

# Check certificate request
kubectl get certificaterequest -n staging

# Common causes:
# - DNS propagation delay
# - Rate limiting from Let's Encrypt
# - Incorrect DNS credentials
```

#### Ingress Not Working

```bash
# Check ingress status
kubectl get ingress djtip-staging -n staging

# Check Traefik logs
kubectl logs -n kube-system -l app.kubernetes.io/name=traefik

# Check service endpoints
kubectl get endpoints -n staging

# Common causes:
# - Service selector mismatch
# - Pod not ready
# - Traefik configuration error
```

## Resource Management

### Current Resource Allocation

#### Web Application
- **Requests**: 200Mi memory, 100m CPU
- **Limits**: 384Mi memory, 500m CPU
- **Replicas**: 1

#### Worker
- **Requests**: 150Mi memory, 100m CPU
- **Limits**: 256Mi memory, 500m CPU
- **Replicas**: 1

#### MongoDB
- **Requests**: 256Mi memory, 100m CPU
- **Limits**: 512Mi memory, 500m CPU
- **Storage**: 8Gi

#### Redis
- **Requests**: 64Mi memory, 50m CPU
- **Limits**: 128Mi memory, 200m CPU
- **Storage**: 4Gi

### Scaling

```bash
# Scale web application
kubectl scale deployment djtip-staging -n staging --replicas=2

# Scale worker
kubectl scale deployment djtip-staging-worker -n staging --replicas=2

# Note: ArgoCD will revert manual scaling on next sync
# Update values-staging.yaml for permanent changes
```

## Backup & Recovery

### Database Backup

```bash
# Create MongoDB backup
kubectl exec -n staging djtip-staging-mongodb-<pod-id> -- \
  mongodump --out=/tmp/backup

# Copy backup locally
kubectl cp staging/djtip-staging-mongodb-<pod-id>:/tmp/backup ./backup
```

### Restore Database

```bash
# Copy backup to pod
kubectl cp ./backup staging/djtip-staging-mongodb-<pod-id>:/tmp/backup

# Restore MongoDB
kubectl exec -n staging djtip-staging-mongodb-<pod-id> -- \
  mongorestore /tmp/backup
```

## Security

### Network Policies

Network policies are configured to restrict traffic between pods:

```bash
# Check network policies
kubectl get networkpolicy -n staging

# MongoDB network policy - only allows traffic from app pods
# Redis network policy - only allows traffic from app pods
```

### Pod Security

```bash
# Check pod security policies
kubectl get podsecuritypolicy

# Check service accounts
kubectl get serviceaccount -n staging
```

## Maintenance

### Update Application

1. Build new Docker image
2. Push to Docker Hub: `robj/djtip:latest`
3. Restart deployment: `kubectl rollout restart deployment djtip-staging -n staging`

### Update Kubernetes Resources

1. Modify Helm values in `.cicd/helm/djtip/values-staging.yaml`
2. Commit and push to GitHub
3. ArgoCD auto-syncs changes

### Cluster Maintenance

```bash
# Check node status
kubectl get nodes

# Drain node for maintenance
kubectl drain <node-name> --ignore-daemonsets

# Uncordon node after maintenance
kubectl uncordon <node-name>
```

## Differences from HAProxy Setup

### Key Changes

1. **Ingress Controller**: Traefik (was HAProxy)
   - Better Kubernetes integration
   - Automatic service discovery
   - Built-in Let's Encrypt support
   - Dynamic configuration

2. **Annotations**: Traefik-specific
   - `traefik.ingress.kubernetes.io/router.tls: "true"`
   - Removed HAProxy-specific annotations

3. **Service Type**: NodePort (Traefik default)
   - Ports: 80:30080, 443:30443
   - External access via node IP

4. **Configuration**: Simplified
   - Less manual configuration needed
   - Automatic TLS termination
   - Better integration with cert-manager

### Migration Notes

- HAProxy ingress controller has been completely removed
- All ingress resources updated to use `ingressClassName: traefik`
- No changes required to application code
- DNS and TLS certificates remain the same

## Useful Commands

```bash
# Quick status check
kubectl get all -n staging

# Watch pod status
kubectl get pods -n staging -w

# Get all ingress resources
kubectl get ingress -A

# Check ArgoCD sync status
kubectl get application -n argocd

# View application in browser
open https://app.staging.djtip.jennings.au

# SSH to VPS
ssh vultr

# Check Traefik dashboard (if enabled)
kubectl port-forward -n kube-system $(kubectl get pods -n kube-system -l app.kubernetes.io/name=traefik -o name) 9000:9000
open http://localhost:9000/dashboard/
```

## References

- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [cert-manager Documentation](https://cert-manager.io/docs/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [K3s Documentation](https://docs.k3s.io/)
- [Helm Documentation](https://helm.sh/docs/)

## Support

For issues or questions:
1. Check application logs: `kubectl logs -n staging -l app.kubernetes.io/name=djtip`
2. Check ArgoCD status: `kubectl get application djtip-staging -n argocd`
3. Check ingress status: `kubectl get ingress -n staging`
4. Review this documentation
5. Check GitHub repository for recent changes
