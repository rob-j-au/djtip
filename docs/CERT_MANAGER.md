# cert-manager Setup with Wildcard Certificates

Unified cert-manager setup using wildcard certificates and DNS-01 challenges for all environments.

## Overview

This setup uses **one approach for all environments**:
- **Development**: `*.dev.djtip.jennings.au` → Local Minikube IP
- **Staging**: `*.staging.djtip.jennings.au` → Pi cluster IP
- **Production**: `*.djtip.jennings.au` → Pi cluster IP

All certificates are issued by Let's Encrypt using Cloudflare DNS-01 challenges.

## Architecture

```
Environment    Wildcard Domain                  IP Address        Certificate
-----------    -------------------------------- ----------------- -----------
Development    *.dev.djtip.jennings.au         192.168.49.2      Let's Encrypt
Staging        *.staging.djtip.jennings.au     <pi-ip>           Let's Encrypt
Production     *.djtip.jennings.au             <pi-ip>           Let's Encrypt
```

**Services use consistent naming:**
- Development: `djtip.dev.djtip.jennings.au`, `grafana.dev.djtip.jennings.au`
- Staging: `djtip.staging.djtip.jennings.au`, `grafana.staging.djtip.jennings.au`
- Production: `djtip.djtip.jennings.au`, `grafana.djtip.jennings.au`

---

## Prerequisites

1. **Cloudflare account** with `djtip.jennings.au` domain
2. **Cloudflare API token** with DNS edit permissions
3. **cert-manager** installed in your cluster

---

## Step 1: Cloudflare DNS Setup

### Create DNS Records

**In Cloudflare Dashboard:**

```
Type: A
Name: *.dev.djtip
Content: 192.168.49.2  (your Minikube IP)
Proxy: OFF (DNS only - grey cloud)
TTL: Auto

Type: A
Name: *.staging.djtip
Content: <your-pi-ip>
Proxy: OFF (DNS only - grey cloud)
TTL: Auto

Type: A
Name: *.djtip
Content: <your-pi-ip>
Proxy: OFF (DNS only - grey cloud)
TTL: Auto
```

**⚠️ IMPORTANT:** Proxy status must be **OFF** (grey cloud, not orange)

### Create Cloudflare API Token

1. Go to: https://dash.cloudflare.com/profile/api-tokens
2. Click **Create Token**
3. Use **Edit zone DNS** template
4. Permissions: `Zone → DNS → Edit`
5. Zone Resources: `Include → Specific zone → djtip.jennings.au`
6. Click **Continue to summary** → **Create Token**
7. **Copy the token** (you won't see it again)

---

## Step 2: Install cert-manager

cert-manager is already configured in `.cicd/helm/cert-manager/`.

### Deploy cert-manager

**Minikube:**
```bash
kubectl apply -f .cicd/argocd/cert-manager-app.yaml
```

**Pi:**
```bash
kubectl apply -f .cicd/argocd/pi/cert-manager.yaml
```

### Verify Installation

```bash
kubectl get pods -n cert-manager
```

Expected output:
```
NAME                                       READY   STATUS    RESTARTS   AGE
cert-manager-xxxxxxxxx-xxxxx               1/1     Running   0          1m
cert-manager-cainjector-xxxxxxxxx-xxxxx    1/1     Running   0          1m
cert-manager-webhook-xxxxxxxxx-xxxxx       1/1     Running   0          1m
```

---

## Step 3: Configure Cloudflare DNS-01

### Create Cloudflare API Token Secret

```bash
# Set your token
export CLOUDFLARE_API_TOKEN="your-token-here"

# Create secret in cert-manager namespace
kubectl create secret generic cloudflare-api-token \
  --from-literal=api-token=$CLOUDFLARE_API_TOKEN \
  -n cert-manager
```

### Create DNS-01 ClusterIssuer

Create `.cicd/helm/cert-manager/templates/clusterissuer-cloudflare.yaml`:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-cloudflare
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: robert@jennings.au
    privateKeySecretRef:
      name: letsencrypt-cloudflare
    solvers:
    - dns01:
        cloudflare:
          email: robert@jennings.au
          apiTokenSecretRef:
            name: cloudflare-api-token
            key: api-token
```

Apply it:
```bash
kubectl apply -f .cicd/helm/cert-manager/templates/clusterissuer-cloudflare.yaml
```

Verify:
```bash
kubectl get clusterissuer letsencrypt-cloudflare
```

---

## Step 4: Create Wildcard Certificates

### Install Reflector (to copy certs to all namespaces)

```bash
helm repo add emberstack https://emberstack.github.io/helm-charts
helm repo update
helm install reflector emberstack/reflector -n cert-manager
```

### Create Wildcard Certificates

Create `.cicd/helm/cert-manager/templates/certificate-wildcards.yaml`:

```yaml
---
# Development wildcard
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: wildcard-dev-djtip
  namespace: cert-manager
spec:
  secretName: wildcard-dev-tls
  issuerRef:
    name: letsencrypt-cloudflare
    kind: ClusterIssuer
  dnsNames:
    - "*.dev.djtip.jennings.au"
    - "dev.djtip.jennings.au"
  secretTemplate:
    annotations:
      reflector.v1.k8s.emberstack.com/reflection-allowed: "true"
      reflector.v1.k8s.emberstack.com/reflection-auto-enabled: "true"
      reflector.v1.k8s.emberstack.com/reflection-auto-namespaces: "default,observability"

---
# Staging wildcard
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: wildcard-staging-djtip
  namespace: cert-manager
spec:
  secretName: wildcard-staging-tls
  issuerRef:
    name: letsencrypt-cloudflare
    kind: ClusterIssuer
  dnsNames:
    - "*.staging.djtip.jennings.au"
    - "staging.djtip.jennings.au"
  secretTemplate:
    annotations:
      reflector.v1.k8s.emberstack.com/reflection-allowed: "true"
      reflector.v1.k8s.emberstack.com/reflection-auto-enabled: "true"
      reflector.v1.k8s.emberstack.com/reflection-auto-namespaces: "staging,observability"

---
# Production wildcard
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: wildcard-prod-djtip
  namespace: cert-manager
spec:
  secretName: wildcard-prod-tls
  issuerRef:
    name: letsencrypt-cloudflare
    kind: ClusterIssuer
  dnsNames:
    - "*.djtip.jennings.au"
    - "djtip.jennings.au"
  secretTemplate:
    annotations:
      reflector.v1.k8s.emberstack.com/reflection-allowed: "true"
      reflector.v1.k8s.emberstack.com/reflection-auto-enabled: "true"
      reflector.v1.k8s.emberstack.com/reflection-auto-namespaces: "production,observability"
```

Apply:
```bash
kubectl apply -f .cicd/helm/cert-manager/templates/certificate-wildcards.yaml
```

### Monitor Certificate Issuance

```bash
# Watch certificates
kubectl get certificates -n cert-manager -w

# Check certificate details
kubectl describe certificate wildcard-dev-djtip -n cert-manager

# Check if secrets are created
kubectl get secrets -A | grep wildcard
```

Certificate issuance takes 1-2 minutes. You should see:
```
NAME                    READY   SECRET               AGE
wildcard-dev-djtip      True    wildcard-dev-tls     2m
wildcard-staging-djtip  True    wildcard-staging-tls 2m
wildcard-prod-djtip     True    wildcard-prod-tls    2m
```

---

## Step 5: Update Helm Values

### Development (values-development.yaml)

```yaml
ingress:
  enabled: true
  className: "haproxy"
  hosts:
    - host: djtip.dev.djtip.jennings.au
      paths:
        - path: /
          pathType: ImplementationSpecific
  tls:
    - secretName: wildcard-dev-tls
      hosts:
        - djtip.dev.djtip.jennings.au
```

### Staging (values-staging.yaml)

```yaml
ingress:
  enabled: true
  className: "haproxy"
  hosts:
    - host: djtip.staging.djtip.jennings.au
      paths:
        - path: /
          pathType: ImplementationSpecific
  tls:
    - secretName: wildcard-staging-tls
      hosts:
        - djtip.staging.djtip.jennings.au
```

### Production (values-production.yaml)

```yaml
ingress:
  enabled: true
  className: "haproxy"
  hosts:
    - host: djtip.djtip.jennings.au
      paths:
        - path: /
          pathType: ImplementationSpecific
  tls:
    - secretName: wildcard-prod-tls
      hosts:
        - djtip.djtip.jennings.au
```

### Observability (values.yaml)

```yaml
kube-prometheus-stack:
  grafana:
    ingress:
      enabled: true
      ingressClassName: haproxy
      hosts:
        - grafana.dev.djtip.jennings.au        # Development
        # - grafana.staging.djtip.jennings.au  # Staging
        # - grafana.djtip.jennings.au          # Production
      tls:
        - secretName: wildcard-dev-tls         # Match environment
          hosts:
            - grafana.dev.djtip.jennings.au
```

---

## Step 6: Deploy Applications

### Minikube (Development)

```bash
# Deploy applications
kubectl apply -f .cicd/argocd/djtip-development.yaml
kubectl apply -f .cicd/argocd/observability-app.yaml

# Wait for sync
kubectl get applications -n argocd -w
```

### Pi (Staging & Production)

```bash
# Deploy applications
kubectl apply -f .cicd/argocd/pi/djtip-staging.yaml
kubectl apply -f .cicd/argocd/pi/djtip-production.yaml
kubectl apply -f .cicd/argocd/pi/observability.yaml
```

---

## Step 7: Verify

### Check Certificates

```bash
# All certificates
kubectl get certificates -A

# Certificate details
kubectl describe certificate wildcard-dev-djtip -n cert-manager

# Secrets in namespaces
kubectl get secrets wildcard-dev-tls -n default
kubectl get secrets wildcard-dev-tls -n observability
```

### Check Ingresses

```bash
# All ingresses
kubectl get ingress -A

# Ingress details
kubectl describe ingress djtip-development -n default
```

### Test Access

**Development:**
```bash
open https://djtip.dev.djtip.jennings.au
open https://grafana.dev.djtip.jennings.au
```

**Staging:**
```bash
open https://djtip.staging.djtip.jennings.au
open https://grafana.staging.djtip.jennings.au
```

**Production:**
```bash
open https://djtip.djtip.jennings.au
open https://grafana.djtip.jennings.au
```

You should see:
- ✅ Valid certificate (no browser warnings)
- ✅ Issued by Let's Encrypt
- ✅ Covers wildcard domain

---

## Automation Script

Create `scripts/setup-cert-manager-wildcard.sh`:

```bash
#!/bin/bash
set -e

echo "🔐 Setting up cert-manager with Cloudflare DNS-01 wildcards"

# Check for Cloudflare API token
if [ -z "$CLOUDFLARE_API_TOKEN" ]; then
  echo "❌ Please set CLOUDFLARE_API_TOKEN environment variable"
  echo ""
  echo "Get it from: https://dash.cloudflare.com/profile/api-tokens"
  echo "Permissions needed: Zone → DNS → Edit"
  echo ""
  echo "Then run:"
  echo "  export CLOUDFLARE_API_TOKEN='your-token-here'"
  echo "  $0"
  exit 1
fi

# Create Cloudflare secret
echo "🔑 Creating Cloudflare API token secret..."
kubectl create secret generic cloudflare-api-token \
  --from-literal=api-token=$CLOUDFLARE_API_TOKEN \
  -n cert-manager \
  --dry-run=client -o yaml | kubectl apply -f -

# Install Reflector
echo "🔄 Installing Reflector..."
helm repo add emberstack https://emberstack.github.io/helm-charts 2>/dev/null || true
helm repo update
helm upgrade --install reflector emberstack/reflector -n cert-manager

# Apply ClusterIssuer
echo "🌐 Creating Cloudflare ClusterIssuer..."
kubectl apply -f .cicd/helm/cert-manager/templates/clusterissuer-cloudflare.yaml

# Apply wildcard certificates
echo "📜 Creating wildcard certificates..."
kubectl apply -f .cicd/helm/cert-manager/templates/certificate-wildcards.yaml

echo ""
echo "✅ Setup complete!"
echo ""
echo "📋 Certificates will be issued in 1-2 minutes"
echo ""
echo "🔍 Monitor progress:"
echo "  kubectl get certificates -n cert-manager -w"
echo ""
echo "🌐 Your domains:"
echo "  Development:  https://djtip.dev.djtip.jennings.au"
echo "  Staging:      https://djtip.staging.djtip.jennings.au"
echo "  Production:   https://djtip.djtip.jennings.au"
echo ""
echo "  Grafana Dev:  https://grafana.dev.djtip.jennings.au"
echo "  Grafana Stg:  https://grafana.staging.djtip.jennings.au"
echo "  Grafana Prod: https://grafana.djtip.jennings.au"
```

Make it executable:
```bash
chmod +x scripts/setup-cert-manager-wildcard.sh
```

Run it:
```bash
export CLOUDFLARE_API_TOKEN="your-token-here"
./scripts/setup-cert-manager-wildcard.sh
```

---

## Troubleshooting

### Certificate Not Issuing

```bash
# Check certificate status
kubectl describe certificate wildcard-dev-djtip -n cert-manager

# Check certificate request
kubectl get certificaterequest -n cert-manager
kubectl describe certificaterequest <name> -n cert-manager

# Check order
kubectl get order -n cert-manager
kubectl describe order <name> -n cert-manager

# Check challenge
kubectl get challenge -n cert-manager
kubectl describe challenge <name> -n cert-manager

# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager --tail=100
```

### Common Issues

**1. Challenge failing:**
- Verify Cloudflare API token has DNS edit permissions
- Check token is not expired
- Verify domain is in Cloudflare

**2. Secret not appearing in namespace:**
- Check Reflector is installed: `kubectl get pods -n cert-manager | grep reflector`
- Check certificate has reflection annotations
- Check namespace exists

**3. Ingress not using certificate:**
- Verify secret name matches in ingress
- Check secret exists in correct namespace
- Restart ingress controller: `kubectl rollout restart deployment haproxy-ingress -n haproxy-controller`

**4. DNS not resolving:**
- Verify DNS records in Cloudflare
- Check Proxy status is OFF (grey cloud)
- Test DNS: `dig djtip.dev.djtip.jennings.au`

---

## Benefits of This Approach

✅ **One approach for all environments** - Same configuration style everywhere
✅ **Wildcard certificates** - One cert covers all subdomains
✅ **Real Let's Encrypt certs** - Trusted by all browsers
✅ **Works with private IPs** - DNS-01 doesn't need HTTP access
✅ **Automatic renewal** - cert-manager handles it (30 days before expiry)
✅ **Consistent naming** - `service.env.djtip.jennings.au` pattern
✅ **Simple ingress config** - Just specify host and secret name
✅ **Team-friendly** - Everyone gets trusted certificates

---

## Domain Structure

```
djtip.jennings.au
├── *.dev.djtip.jennings.au          (Development - Minikube)
│   ├── djtip.dev.djtip.jennings.au
│   └── grafana.dev.djtip.jennings.au
│
├── *.staging.djtip.jennings.au      (Staging - Pi)
│   ├── djtip.staging.djtip.jennings.au
│   └── grafana.staging.djtip.jennings.au
│
└── *.djtip.jennings.au              (Production - Pi)
    ├── djtip.djtip.jennings.au
    └── grafana.djtip.jennings.au
```

---

## Certificate Lifecycle

1. **Certificate created** - cert-manager detects Certificate resource
2. **DNS-01 challenge initiated** - cert-manager creates TXT record via Cloudflare API
3. **Let's Encrypt verifies** - Checks TXT record exists
4. **Certificate issued** - Stored in secret
5. **Reflector copies** - Secret copied to all specified namespaces
6. **Ingress uses cert** - HAProxy serves HTTPS with certificate
7. **Auto-renewal** - cert-manager renews 30 days before expiry

---

## Security Notes

- 🔒 **Cloudflare API token** - Store securely, limit permissions to DNS only
- 🔒 **Let's Encrypt rate limits** - 50 certificates per domain per week
- 🔒 **Private keys** - Stored in Kubernetes secrets, encrypted at rest
- 🔒 **Certificate transparency** - All Let's Encrypt certs are logged publicly
- ✅ **Production-grade** - Same setup used by major companies

---

## Additional Resources

- [cert-manager Documentation](https://cert-manager.io/docs/)
- [Cloudflare API Tokens](https://developers.cloudflare.com/fundamentals/api/get-started/create-token/)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)
- [DNS-01 Challenge](https://letsencrypt.org/docs/challenge-types/#dns-01-challenge)
- [Reflector Documentation](https://github.com/emberstack/kubernetes-reflector)
