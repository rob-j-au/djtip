# Local TLS Setup for Minikube

This guide explains how to set up TLS certificates for local development domains (*.minikube.local) that are not publicly accessible.

## Problem

Let's Encrypt requires domains to be publicly accessible for HTTP-01 challenges. Since `*.minikube.local` domains only resolve locally, Let's Encrypt cannot verify ownership and issue certificates.

## Solutions

### Option 1: Self-Signed Certificates with mkcert (Recommended for Development)

**mkcert** creates locally-trusted development certificates that work in your browser without warnings.

#### 1. Install mkcert

**macOS:**
```bash
brew install mkcert
brew install nss  # For Firefox support
```

**Linux:**
```bash
# Debian/Ubuntu
sudo apt install libnss3-tools
wget https://github.com/FiloSottile/mkcert/releases/download/v1.4.4/mkcert-v1.4.4-linux-amd64
chmod +x mkcert-v1.4.4-linux-amd64
sudo mv mkcert-v1.4.4-linux-amd64 /usr/local/bin/mkcert
```

#### 2. Install Local CA

```bash
# Install the local CA in the system trust store
mkcert -install
```

This creates a local Certificate Authority (CA) that your browser will trust.

#### 3. Generate Certificates for Minikube Domains

```bash
# Create certificates directory
mkdir -p certs

# Generate wildcard certificate for all minikube.local domains
mkcert -cert-file certs/minikube-local.crt \
       -key-file certs/minikube-local.key \
       "*.minikube.local" \
       "minikube.local"

# Or generate specific certificates
mkcert -cert-file certs/djtip.crt \
       -key-file certs/djtip.key \
       "djtip.minikube.local" \
       "djtip-staging.minikube.local" \
       "grafana.minikube.local"
```

#### 4. Create Kubernetes Secrets

```bash
# Development
kubectl create secret tls djtip-tls \
  --cert=certs/minikube-local.crt \
  --key=certs/minikube-local.key \
  -n default

# Staging
kubectl create secret tls djtip-staging-tls \
  --cert=certs/minikube-local.crt \
  --key=certs/minikube-local.key \
  -n staging

# Production (local)
kubectl create secret tls djtip-production-tls \
  --cert=certs/minikube-local.crt \
  --key=certs/minikube-local.key \
  -n production

# Grafana
kubectl create secret tls grafana-tls \
  --cert=certs/minikube-local.crt \
  --key=certs/minikube-local.key \
  -n observability
```

#### 5. Update Ingress to NOT Use cert-manager

For local development, remove the cert-manager annotation from your values files:

**values-development.yaml:**
```yaml
ingress:
  enabled: true
  className: "haproxy"
  annotations:
    ingress.class: haproxy
    # cert-manager.io/cluster-issuer: "letsencrypt-staging"  # Comment out for local
  hosts:
    - host: djtip.minikube.local
      paths:
        - path: /
          pathType: ImplementationSpecific
  tls:
    - secretName: djtip-tls
      hosts:
        - djtip.minikube.local
```

#### 6. Verify

```bash
# Check secrets
kubectl get secrets -n default | grep tls

# Access your application
open https://djtip.minikube.local
```

You should see a valid certificate with no browser warnings! 🎉

---

### Option 2: Self-Signed Certificates with OpenSSL

If you can't use mkcert, you can create self-signed certificates with OpenSSL (browsers will show warnings).

#### 1. Create Certificate Authority

```bash
# Generate CA private key
openssl genrsa -out ca.key 2048

# Generate CA certificate
openssl req -x509 -new -nodes -key ca.key -sha256 -days 1825 -out ca.crt \
  -subj "/C=AU/ST=NSW/L=Sydney/O=Dev/CN=Minikube Local CA"
```

#### 2. Create Certificate for Minikube Domains

```bash
# Create private key
openssl genrsa -out minikube-local.key 2048

# Create certificate signing request
openssl req -new -key minikube-local.key -out minikube-local.csr \
  -subj "/C=AU/ST=NSW/L=Sydney/O=Dev/CN=*.minikube.local"

# Create config file for SAN (Subject Alternative Names)
cat > minikube-local.ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = *.minikube.local
DNS.2 = minikube.local
DNS.3 = djtip.minikube.local
DNS.4 = djtip-staging.minikube.local
DNS.5 = grafana.minikube.local
EOF

# Sign the certificate
openssl x509 -req -in minikube-local.csr -CA ca.crt -CAkey ca.key \
  -CAcreateserial -out minikube-local.crt -days 825 -sha256 \
  -extfile minikube-local.ext
```

#### 3. Trust the CA Certificate

**macOS:**
```bash
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain ca.crt
```

**Linux:**
```bash
sudo cp ca.crt /usr/local/share/ca-certificates/minikube-local-ca.crt
sudo update-ca-certificates
```

#### 4. Create Kubernetes Secrets

Same as Option 1, step 4.

---

### Option 3: DNS-01 Challenge with cert-manager (Advanced)

If you control a public domain, you can use DNS-01 challenges with cert-manager.

#### 1. Create DNS Records

Add DNS records pointing to your Minikube IP:
```
djtip.yourdomain.com         A    192.168.49.2
djtip-staging.yourdomain.com A    192.168.49.2
grafana.yourdomain.com       A    192.168.49.2
```

#### 2. Configure DNS-01 ClusterIssuer

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-dns
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-dns
    solvers:
    - dns01:
        cloudflare:  # Or your DNS provider
          email: your-email@example.com
          apiTokenSecretRef:
            name: cloudflare-api-token
            key: api-token
```

#### 3. Update Ingress

```yaml
annotations:
  cert-manager.io/cluster-issuer: "letsencrypt-dns"
```

---

## Recommended Approach by Environment

| Environment | Domain | Recommended Solution |
|-------------|--------|---------------------|
| **Local Development** | *.minikube.local | **mkcert** (Option 1) |
| **Staging (Public)** | *.k8s.pi.jennings.au | cert-manager HTTP-01 |
| **Production (Public)** | yourdomain.com | cert-manager HTTP-01 |

## Troubleshooting

### Certificate Not Trusted

**mkcert:**
```bash
# Reinstall CA
mkcert -uninstall
mkcert -install

# Regenerate certificates
mkcert -cert-file certs/minikube-local.crt \
       -key-file certs/minikube-local.key \
       "*.minikube.local"
```

**OpenSSL:**
- Ensure CA certificate is installed in system trust store
- Restart browser after installing CA

### Ingress Not Using Certificate

```bash
# Check secret exists
kubectl get secret djtip-tls -n default

# Check ingress configuration
kubectl describe ingress djtip-development -n default

# Check HAProxy logs
kubectl logs -n haproxy-controller -l app.kubernetes.io/name=haproxy-ingress
```

### Certificate Expired

**mkcert certificates are valid for 825 days (2+ years)**

```bash
# Check expiry
openssl x509 -in certs/minikube-local.crt -noout -dates

# Regenerate if needed
mkcert -cert-file certs/minikube-local.crt \
       -key-file certs/minikube-local.key \
       "*.minikube.local"

# Update secret
kubectl delete secret djtip-tls -n default
kubectl create secret tls djtip-tls \
  --cert=certs/minikube-local.crt \
  --key=certs/minikube-local.key \
  -n default
```

## Automation Script

Create a helper script to automate certificate creation:

```bash
#!/bin/bash
# scripts/setup-local-tls.sh

set -e

echo "🔐 Setting up local TLS certificates for Minikube..."

# Check if mkcert is installed
if ! command -v mkcert &> /dev/null; then
    echo "❌ mkcert not found. Please install it first:"
    echo "   brew install mkcert (macOS)"
    exit 1
fi

# Install local CA
echo "📜 Installing local CA..."
mkcert -install

# Create certs directory
mkdir -p certs

# Generate wildcard certificate
echo "🔑 Generating wildcard certificate for *.minikube.local..."
mkcert -cert-file certs/minikube-local.crt \
       -key-file certs/minikube-local.key \
       "*.minikube.local" \
       "minikube.local"

# Create secrets in all namespaces
echo "🔒 Creating Kubernetes secrets..."

# Development
kubectl create secret tls djtip-tls \
  --cert=certs/minikube-local.crt \
  --key=certs/minikube-local.key \
  -n default \
  --dry-run=client -o yaml | kubectl apply -f -

# Staging
kubectl create namespace staging --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret tls djtip-staging-tls \
  --cert=certs/minikube-local.crt \
  --key=certs/minikube-local.key \
  -n staging \
  --dry-run=client -o yaml | kubectl apply -f -

# Production
kubectl create namespace production --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret tls djtip-production-tls \
  --cert=certs/minikube-local.crt \
  --key=certs/minikube-local.key \
  -n production \
  --dry-run=client -o yaml | kubectl apply -f -

# Observability
kubectl create namespace observability --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret tls grafana-tls \
  --cert=certs/minikube-local.crt \
  --key=certs/minikube-local.key \
  -n observability \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✅ Local TLS setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Update your values files to remove cert-manager annotations"
echo "2. Deploy your applications"
echo "3. Access https://djtip.minikube.local"
echo ""
echo "🔍 Verify certificates:"
echo "   kubectl get secrets -A | grep tls"
```

Make it executable:
```bash
chmod +x scripts/setup-local-tls.sh
./scripts/setup-local-tls.sh
```

## Best Practices

1. **Use mkcert for local development** - It's the easiest and most reliable
2. **Don't commit certificates to Git** - Add `certs/` to `.gitignore`
3. **Use cert-manager for public domains** - Let's Encrypt for staging/production
4. **Separate certificates per environment** - Different secrets for dev/staging/prod
5. **Document the setup** - Team members need to run mkcert -install

## Security Notes

- ⚠️ **mkcert CA is only for local development** - Never use in production
- ⚠️ **Keep CA private key secure** - It can sign certificates for any domain
- ⚠️ **Self-signed certs show warnings** - Only mkcert-generated certs are trusted
- ✅ **Use Let's Encrypt for production** - Free, trusted, automated

## Additional Resources

- [mkcert GitHub](https://github.com/FiloSottile/mkcert)
- [cert-manager Documentation](https://cert-manager.io/docs/)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)
- [OpenSSL Certificate Guide](https://www.openssl.org/docs/)
