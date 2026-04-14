# Complete Setup Guide: Terraform + cert-manager DNS-01

This guide walks through the complete setup from scratch to get wildcard TLS certificates working with cert-manager and Cloudflare DNS-01.

## Prerequisites

- ✅ Cloudflare account with your domain
- ✅ Kubernetes cluster (Minikube or Pi)
- ✅ kubectl configured
- ✅ Helm installed
- ✅ Terraform installed (`brew install terraform`)
- ✅ ArgoCD installed in cluster

## Overview

```
Step 1: Terraform → Create DNS records in Cloudflare
Step 2: cert-manager → Install cert-manager in Kubernetes
Step 3: Cloudflare Secret → Store API token in Kubernetes
Step 4: ClusterIssuer → Create Cloudflare DNS-01 issuer
Step 5: Certificates → Create wildcard certificates
Step 6: Helm Values → Update ingress to use certificates
Step 7: Deploy Apps → ArgoCD syncs everything
```

---

## Step 1: Apply Terraform (Create DNS Records)

### 1.1 Navigate to Terraform directory

```bash
cd .terraform/cloudflare
```

### 1.2 Create terraform.tfvars

```bash
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

**Edit with your values:**
```hcl
cloudflare_api_token = "your-cloudflare-api-token-here"
domain               = "djtip.jennings.au"  # Your actual domain
dev_ip              = "192.168.49.2"        # minikube ip
```

### 1.3 Initialize Terraform

```bash
terraform init
```

### 1.4 Preview changes

```bash
terraform plan
```

You should see:
```
Plan: 3 to add, 0 to change, 0 to destroy.

Changes:
  + cloudflare_record.dev_wildcard
  + cloudflare_record.staging_wildcard
  + cloudflare_record.prod_wildcard
```

### 1.5 Apply Terraform

```bash
terraform apply
```

Type `yes` when prompted.

### 1.6 Verify DNS records created

```bash
# Check Terraform outputs
terraform output

# Test DNS resolution
dig djtip.dev.djtip.jennings.au
dig djtip.staging.djtip.jennings.au
dig djtip.djtip.jennings.au
```

**Expected:** All should resolve to the correct IPs.

---

## Step 2: Install cert-manager

### 2.1 Deploy cert-manager via ArgoCD

```bash
cd /Users/robert/dev/djtip

# For Minikube
kubectl apply -f .cicd/argocd/cert-manager-app.yaml

# For Pi
kubectl apply -f .cicd/argocd/pi/cert-manager.yaml
```

### 2.2 Wait for cert-manager to be ready

```bash
kubectl get pods -n cert-manager -w
```

Wait until all pods are Running:
```
NAME                                       READY   STATUS    RESTARTS   AGE
cert-manager-xxxxxxxxx-xxxxx               1/1     Running   0          1m
cert-manager-cainjector-xxxxxxxxx-xxxxx    1/1     Running   0          1m
cert-manager-webhook-xxxxxxxxx-xxxxx       1/1     Running   0          1m
```

Press `Ctrl+C` to exit watch.

---

## Step 3: Create Cloudflare API Token Secret

### 3.1 Store your Cloudflare API token in Kubernetes

```bash
export CLOUDFLARE_API_TOKEN="your-cloudflare-api-token-here"

kubectl create secret generic cloudflare-api-token \
  --from-literal=api-token=$CLOUDFLARE_API_TOKEN \
  -n cert-manager
```

### 3.2 Verify secret created

```bash
kubectl get secret cloudflare-api-token -n cert-manager
```

---

## Step 4: Create Cloudflare ClusterIssuer

### 4.1 Create the ClusterIssuer manifest

Create `.cicd/helm/cert-manager/templates/clusterissuer-cloudflare.yaml`:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-cloudflare
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: robert@jennings.au  # Your email
    privateKeySecretRef:
      name: letsencrypt-cloudflare
    solvers:
    - dns01:
        cloudflare:
          email: robert@jennings.au  # Your Cloudflare email
          apiTokenSecretRef:
            name: cloudflare-api-token
            key: api-token
```

### 4.2 Apply the ClusterIssuer

```bash
kubectl apply -f .cicd/helm/cert-manager/templates/clusterissuer-cloudflare.yaml
```

### 4.3 Verify ClusterIssuer is ready

```bash
kubectl get clusterissuer letsencrypt-cloudflare
```

Expected:
```
NAME                      READY   AGE
letsencrypt-cloudflare    True    10s
```

---

## Step 5: Install Reflector (for secret copying)

### 5.1 Install Reflector via Helm

```bash
helm repo add emberstack https://emberstack.github.io/helm-charts
helm repo update
helm install reflector emberstack/reflector -n cert-manager
```

### 5.2 Verify Reflector is running

```bash
kubectl get pods -n cert-manager | grep reflector
```

---

## Step 6: Create Wildcard Certificates

### 6.1 Create the Certificate manifests

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

**Important:** Replace `djtip.jennings.au` with your actual domain!

### 6.2 Apply the Certificate manifests

```bash
kubectl apply -f .cicd/helm/cert-manager/templates/certificate-wildcards.yaml
```

### 6.3 Monitor certificate issuance

```bash
kubectl get certificates -n cert-manager -w
```

Wait for all certificates to show `READY = True`:
```
NAME                    READY   SECRET               AGE
wildcard-dev-djtip      True    wildcard-dev-tls     2m
wildcard-staging-djtip  True    wildcard-staging-tls 2m
wildcard-prod-djtip     True    wildcard-prod-tls    2m
```

This takes 1-2 minutes. Press `Ctrl+C` when done.

### 6.4 Verify secrets were created and reflected

```bash
# Check secrets in cert-manager namespace
kubectl get secrets -n cert-manager | grep wildcard

# Check secrets were copied to app namespaces
kubectl get secrets wildcard-dev-tls -n default
kubectl get secrets wildcard-staging-tls -n staging
kubectl get secrets wildcard-prod-tls -n production
```

---

## Step 7: Update Helm Values to Use Certificates

### 7.1 Update values-development.yaml

Edit `.cicd/helm/djtip/values-development.yaml`:

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

### 7.2 Update values-staging.yaml

Edit `.cicd/helm/djtip/values-staging.yaml`:

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

### 7.3 Update values-production.yaml

Edit `.cicd/helm/djtip/values-production.yaml`:

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

### 7.4 Update observability values

Edit `.cicd/helm/observability/values.yaml`:

```yaml
kube-prometheus-stack:
  grafana:
    ingress:
      enabled: true
      ingressClassName: haproxy
      hosts:
        - grafana.dev.djtip.jennings.au
      tls:
        - secretName: wildcard-dev-tls
          hosts:
            - grafana.dev.djtip.jennings.au
```

### 7.5 Commit the changes

```bash
git add .cicd/helm/
git commit -m "Update ingress to use wildcard TLS certificates"
git push origin main
```

---

## Step 8: Deploy/Sync Applications

### 8.1 ArgoCD will auto-sync (if enabled)

If auto-sync is enabled, ArgoCD will detect the changes and sync automatically.

### 8.2 Or manually sync via ArgoCD UI

1. Open ArgoCD UI: `kubectl port-forward svc/argocd-server -n argocd 8080:443`
2. Navigate to https://localhost:8080
3. Click on each application
4. Click "Sync"

### 8.3 Or manually sync via CLI

```bash
# Sync development
kubectl apply -f .cicd/argocd/djtip-development.yaml

# Sync staging
kubectl apply -f .cicd/argocd/djtip-staging.yaml

# Sync production
kubectl apply -f .cicd/argocd/djtip-production.yaml

# Sync observability
kubectl apply -f .cicd/argocd/observability-app.yaml
```

---

## Step 9: Verify Everything Works

### 9.1 Check ingresses are using certificates

```bash
kubectl get ingress -A
kubectl describe ingress djtip-development -n default
```

Look for the TLS section showing the wildcard secret.

### 9.2 Test HTTPS access

```bash
# Development
curl -k https://djtip.dev.djtip.jennings.au

# Staging
curl -k https://djtip.staging.djtip.jennings.au

# Production
curl -k https://djtip.djtip.jennings.au

# Grafana
curl -k https://grafana.dev.djtip.jennings.au
```

### 9.3 Check certificate details

```bash
# View certificate
kubectl get secret wildcard-dev-tls -n default -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -text -noout

# Check expiry
kubectl get secret wildcard-dev-tls -n default -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -noout -dates
```

---

## Automation Script

Or use the provided automation script:

```bash
# Set your Cloudflare API token
export CLOUDFLARE_API_TOKEN="your-token-here"

# Run the complete setup
./scripts/setup-cert-manager-wildcard.sh
```

---

## Troubleshooting

### Certificate not issuing

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

### Secret not appearing in namespace

```bash
# Check Reflector is running
kubectl get pods -n cert-manager | grep reflector

# Check certificate has reflection annotations
kubectl get certificate wildcard-dev-djtip -n cert-manager -o yaml | grep reflection

# Check namespace exists
kubectl get namespace default staging production observability
```

### DNS not resolving

```bash
# Check Terraform created the records
cd .terraform/cloudflare
terraform show

# Check DNS resolution
dig djtip.dev.djtip.jennings.au

# Check Cloudflare dashboard
# Verify records exist and proxy is OFF (grey cloud)
```

---

## Summary Checklist

- [ ] Terraform applied (DNS records created)
- [ ] cert-manager installed and running
- [ ] Cloudflare API token secret created
- [ ] ClusterIssuer created and ready
- [ ] Reflector installed
- [ ] Wildcard certificates created and ready
- [ ] Secrets reflected to all namespaces
- [ ] Helm values updated with TLS configuration
- [ ] Applications deployed/synced
- [ ] HTTPS access working
- [ ] Certificates valid and trusted

---

## Next Steps

- **Monitor certificate renewal**: cert-manager auto-renews 30 days before expiry
- **Update DNS when IP changes**: Run `terraform apply` to sync wildcards
- **Add more services**: They'll automatically use the wildcard certificates
- **Set up monitoring**: Alert on certificate expiry (though auto-renewal should handle it)

---

## Complete Command Sequence

For reference, here's the complete sequence:

```bash
# 1. Terraform
cd .terraform/cloudflare
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform apply

# 2. cert-manager
cd /Users/robert/dev/djtip
kubectl apply -f .cicd/argocd/cert-manager-app.yaml
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=cert-manager -n cert-manager --timeout=300s

# 3. Cloudflare secret
export CLOUDFLARE_API_TOKEN="your-token"
kubectl create secret generic cloudflare-api-token \
  --from-literal=api-token=$CLOUDFLARE_API_TOKEN \
  -n cert-manager

# 4. ClusterIssuer
kubectl apply -f .cicd/helm/cert-manager/templates/clusterissuer-cloudflare.yaml

# 5. Reflector
helm repo add emberstack https://emberstack.github.io/helm-charts
helm repo update
helm install reflector emberstack/reflector -n cert-manager

# 6. Certificates
kubectl apply -f .cicd/helm/cert-manager/templates/certificate-wildcards.yaml
kubectl wait --for=condition=ready certificate --all -n cert-manager --timeout=300s

# 7. Update Helm values (edit files)
# 8. Commit and push
git add .cicd/helm/
git commit -m "Update ingress to use wildcard TLS"
git push origin main

# 9. Sync applications (ArgoCD auto-syncs or manual)
kubectl apply -f .cicd/argocd/djtip-development.yaml

# 10. Verify
kubectl get certificates -n cert-manager
kubectl get secrets -A | grep wildcard
curl -k https://djtip.dev.djtip.jennings.au
```

**Done! You now have automated wildcard TLS certificates with cert-manager and Cloudflare DNS-01! 🎉**
