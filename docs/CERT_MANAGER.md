# cert-manager with Wildcard Certificates

Automated TLS certificates using cert-manager and Cloudflare DNS-01 challenges.

## Quick Start

```bash
# 1. Setup DNS with Terraform
cd .terraform/cloudflare && terraform init && terraform apply

# 2. Setup cert-manager
export CLOUDFLARE_API_TOKEN="your-token"
cd ../.. && ./scripts/setup-cert-manager-wildcard.sh

# Done! Certificates ready in 2 minutes ✅
```

---

## Overview

**One unified approach for all environments:**

| Environment | Wildcard Domain | IP Source | Certificate |
|-------------|-----------------|-----------|-------------|
| Development | `*.dev.yourdomain.com` | Minikube | Let's Encrypt |
| Staging | `*.staging.yourdomain.com` | Auto from base domain | Let's Encrypt |
| Production | `*.yourdomain.com` | Auto from base domain | Let's Encrypt |

---

## Complete Setup

### 1. Create DNS Records (Terraform)

```bash
cd .terraform/cloudflare
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Add your token and domain
terraform init
terraform apply
```

**Creates:**
- `*.dev.yourdomain.com` → Minikube IP
- `*.staging.yourdomain.com` → Auto from yourdomain.com
- `*.yourdomain.com` → Auto from yourdomain.com

### 2. Install cert-manager

```bash
kubectl apply -f .cicd/argocd/cert-manager-app.yaml
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=cert-manager -n cert-manager --timeout=300s
```

### 3. Create Cloudflare Secret

```bash
export CLOUDFLARE_API_TOKEN="your-token"
kubectl create secret generic cloudflare-api-token \
  --from-literal=api-token=$CLOUDFLARE_API_TOKEN \
  -n cert-manager
```

### 4. Create ClusterIssuer

Create `.cicd/helm/cert-manager/templates/clusterissuer-cloudflare.yaml`:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-cloudflare
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-cloudflare
    solvers:
    - dns01:
        cloudflare:
          email: your-cloudflare-email@example.com
          apiTokenSecretRef:
            name: cloudflare-api-token
            key: api-token
```

Apply:
```bash
kubectl apply -f .cicd/helm/cert-manager/templates/clusterissuer-cloudflare.yaml
```

### 5. Install Reflector

```bash
helm repo add emberstack https://emberstack.github.io/helm-charts
helm install reflector emberstack/reflector -n cert-manager
```

### 6. Create Wildcard Certificates

Create `.cicd/helm/cert-manager/templates/certificate-wildcards.yaml`:

```yaml
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: wildcard-dev
  namespace: cert-manager
spec:
  secretName: wildcard-dev-tls
  issuerRef:
    name: letsencrypt-cloudflare
    kind: ClusterIssuer
  dnsNames:
    - "*.dev.yourdomain.com"
    - "dev.yourdomain.com"
  secretTemplate:
    annotations:
      reflector.v1.k8s.emberstack.com/reflection-allowed: "true"
      reflector.v1.k8s.emberstack.com/reflection-auto-enabled: "true"
      reflector.v1.k8s.emberstack.com/reflection-auto-namespaces: "default,observability"
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: wildcard-staging
  namespace: cert-manager
spec:
  secretName: wildcard-staging-tls
  issuerRef:
    name: letsencrypt-cloudflare
    kind: ClusterIssuer
  dnsNames:
    - "*.staging.yourdomain.com"
    - "staging.yourdomain.com"
  secretTemplate:
    annotations:
      reflector.v1.k8s.emberstack.com/reflection-allowed: "true"
      reflector.v1.k8s.emberstack.com/reflection-auto-enabled: "true"
      reflector.v1.k8s.emberstack.com/reflection-auto-namespaces: "staging,observability"
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: wildcard-prod
  namespace: cert-manager
spec:
  secretName: wildcard-prod-tls
  issuerRef:
    name: letsencrypt-cloudflare
    kind: ClusterIssuer
  dnsNames:
    - "*.yourdomain.com"
    - "yourdomain.com"
  secretTemplate:
    annotations:
      reflector.v1.k8s.emberstack.com/reflection-allowed: "true"
      reflector.v1.k8s.emberstack.com/reflection-auto-enabled: "true"
      reflector.v1.k8s.emberstack.com/reflection-auto-namespaces: "production,observability"
```

Apply and monitor:
```bash
kubectl apply -f .cicd/helm/cert-manager/templates/certificate-wildcards.yaml
kubectl get certificates -n cert-manager -w  # Wait for READY=True
```

### 7. Update Helm Values

**Development** (`.cicd/helm/djtip/values-development.yaml`):
```yaml
ingress:
  enabled: true
  className: "haproxy"
  hosts:
    - host: app.dev.yourdomain.com
      paths:
        - path: /
          pathType: ImplementationSpecific
  tls:
    - secretName: wildcard-dev-tls
      hosts:
        - app.dev.yourdomain.com
```

**Staging** (`.cicd/helm/djtip/values-staging.yaml`):
```yaml
ingress:
  tls:
    - secretName: wildcard-staging-tls
      hosts:
        - app.staging.yourdomain.com
```

**Production** (`.cicd/helm/djtip/values-production.yaml`):
```yaml
ingress:
  tls:
    - secretName: wildcard-prod-tls
      hosts:
        - app.yourdomain.com
```

Commit:
```bash
git add .cicd/helm/
git commit -m "Update ingress to use wildcard TLS"
git push
```

### 8. Deploy Applications

ArgoCD auto-syncs or manually:
```bash
kubectl apply -f .cicd/argocd/djtip-development.yaml
```

### 9. Verify

```bash
kubectl get certificates -n cert-manager
kubectl get secrets -A | grep wildcard
curl -I https://app.dev.yourdomain.com
```

---

## Troubleshooting

### Certificate Not Issuing

```bash
kubectl describe certificate wildcard-dev -n cert-manager
kubectl logs -n cert-manager deployment/cert-manager --tail=100
kubectl get challenge -n cert-manager
```

**Common issues:**
- Invalid API token
- DNS not resolving
- Cloudflare proxy enabled (must be OFF)

### Secret Not in Namespace

```bash
kubectl get pods -n cert-manager | grep reflector
kubectl get certificate wildcard-dev -n cert-manager -o yaml | grep reflection
```

---

## Benefits

✅ One wildcard cert per environment
✅ Automatic renewal (30 days before expiry)
✅ Works with private IPs (DNS-01)
✅ Reflector auto-copies secrets
✅ Terraform manages DNS
✅ Auto-sync with DDNS

---

## Resources

- [Terraform Configuration](.terraform/cloudflare/README.md)
- [cert-manager Docs](https://cert-manager.io/docs/)
- [Cloudflare API Tokens](https://developers.cloudflare.com/fundamentals/api/get-started/create-token/)
