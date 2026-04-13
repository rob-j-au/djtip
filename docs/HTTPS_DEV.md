# HTTPS Setup for Local Development

This guide explains how to set up HTTPS/TLS for local Minikube development using mkcert.

## Overview

The application uses **mkcert** to generate locally-trusted SSL certificates for development. This provides:

- ✅ Trusted HTTPS certificates (no browser warnings)
- ✅ HTTP/2 support
- ✅ Production-like environment
- ✅ Automatic browser trust
- ✅ Valid for 2+ years

## Prerequisites

- Minikube running
- kubectl configured
- Homebrew (macOS)

## Initial Setup

### 1. Install mkcert

```bash
brew install mkcert
```

### 2. Install the local Certificate Authority (CA)

This creates a local CA and installs it in your system's trust store:

```bash
mkcert -install
```

**What this does:**
- Creates a local CA certificate
- Installs it in macOS Keychain
- Automatically trusted by Chrome, Safari, and other browsers
- ⚠️ Firefox requires additional setup (see below)

### 3. Generate Certificate for djtip.minikube.local

```bash
cd /path/to/djtip
mkcert djtip.minikube.local
```

**Output:**
- `djtip.minikube.local.pem` - Certificate
- `djtip.minikube.local-key.pem` - Private key

**Certificate details:**
- Valid for: 2+ years
- Trusted by: System trust store
- Domains: djtip.minikube.local

### 4. Create Kubernetes TLS Secret

```bash
kubectl create secret tls djtip-tls \
  --cert=djtip.minikube.local.pem \
  --key=djtip.minikube.local-key.pem \
  -n default
```

### 5. Verify the Secret

```bash
kubectl get secret djtip-tls -n default
kubectl describe secret djtip-tls -n default
```

## Helm Chart Configuration

The TLS configuration is in `.cicd/helm/djtip/values.yaml`:

```yaml
ingress:
  enabled: true
  className: "haproxy"
  annotations:
    ingress.class: haproxy
  hosts:
    - host: djtip.minikube.local
      paths:
        - path: /
          pathType: ImplementationSpecific
  tls:
    - secretName: djtip-tls        # References the Kubernetes secret
      hosts:
        - djtip.minikube.local     # Domain covered by the certificate
```

## How It Works

### SSL Termination Flow

```
Browser (HTTPS)
    ↓
https://djtip.minikube.local:443
    ↓
HAProxy Ingress Controller
    ├─ Reads certificate from djtip-tls secret
    ├─ Terminates SSL/TLS
    ├─ Validates certificate
    └─ Decrypts traffic
        ↓
http://djtip-service:3000 (plain HTTP)
    ↓
Rails Application (receives plain HTTP)
```

### Key Points

1. **HAProxy handles SSL** - The ingress controller terminates TLS
2. **Backend uses HTTP** - Rails app doesn't need SSL configuration
3. **Automatic reload** - HAProxy detects secret changes automatically
4. **HTTP/2 enabled** - Automatically available with HTTPS

## Accessing the Application

### HTTPS (Recommended)
```bash
curl https://djtip.minikube.local
```

Or open in browser: **https://djtip.minikube.local**

### HTTP (Redirects to HTTPS)
```bash
curl http://djtip.minikube.local
```

## Verification

### 1. Check Ingress Configuration

```bash
kubectl get ingress djtip -n default
```

Expected output:
```
NAME    CLASS     HOSTS                  ADDRESS     PORTS     AGE
djtip   haproxy   djtip.minikube.local   127.0.0.1   80, 443   1h
```

Note the **80, 443** ports indicating both HTTP and HTTPS are configured.

### 2. Test HTTPS Connection

```bash
curl -I https://djtip.minikube.local
```

Expected response:
```
HTTP/2 200
x-frame-options: SAMEORIGIN
...
```

Note **HTTP/2** which confirms TLS is working.

### 3. Verify Certificate in Browser

1. Open https://djtip.minikube.local in Chrome/Safari
2. Click the padlock icon
3. View certificate details
4. Should show:
   - ✅ Issued by: mkcert [your-username]
   - ✅ Valid until: [2+ years from creation]
   - ✅ Trusted

## Troubleshooting

### Browser Shows "Not Secure"

**Cause:** mkcert CA not installed in system trust store

**Solution:**
```bash
mkcert -install
# Restart browser
```

### Certificate Expired

**Cause:** Certificate is older than 2 years

**Solution:** Regenerate certificate:
```bash
# Generate new certificate
mkcert djtip.minikube.local

# Update Kubernetes secret
kubectl delete secret djtip-tls -n default
kubectl create secret tls djtip-tls \
  --cert=djtip.minikube.local.pem \
  --key=djtip.minikube.local-key.pem \
  -n default

# HAProxy will automatically reload
```

### Firefox Shows Warning

**Cause:** Firefox uses its own certificate store

**Solution:**
```bash
# Install certutil
brew install nss

# Reinstall mkcert CA
mkcert -install

# Restart Firefox
```

### HTTPS Not Working After ArgoCD Sync

**Cause:** Secret not recreated after namespace deletion

**Solution:**
```bash
# Recreate the secret
kubectl create secret tls djtip-tls \
  --cert=djtip.minikube.local.pem \
  --key=djtip.minikube.local-key.pem \
  -n default
```

### HAProxy Not Using Certificate

**Check ingress configuration:**
```bash
kubectl describe ingress djtip -n default
```

Look for:
```
TLS:
  djtip-tls terminates djtip.minikube.local
```

**Check HAProxy logs:**
```bash
kubectl logs -n haproxy-controller -l app.kubernetes.io/name=kubernetes-ingress
```

## Firefox Setup (Optional)

Firefox doesn't use the system certificate store by default.

### Option 1: Install certutil (Recommended)
```bash
brew install nss
mkcert -install
```

### Option 2: Manual Import
1. Export the CA certificate:
   ```bash
   mkcert -CAROOT
   # Note the path shown
   ```
2. In Firefox:
   - Settings → Privacy & Security → Certificates → View Certificates
   - Authorities → Import
   - Select `rootCA.pem` from the mkcert CA root path
   - Trust for websites

## Certificate Renewal

mkcert certificates are valid for 2+ years. To renew:

```bash
# Generate new certificate (overwrites old files)
mkcert djtip.minikube.local

# Update Kubernetes secret
kubectl create secret tls djtip-tls \
  --cert=djtip.minikube.local.pem \
  --key=djtip.minikube.local-key.pem \
  -n default \
  --dry-run=client -o yaml | kubectl apply -f -
```

HAProxy will automatically detect the change and reload.

## Production Considerations

This setup is **for local development only**. For production:

1. **Use cert-manager** with Let's Encrypt
2. **Update Helm values** to use cert-manager annotations:
   ```yaml
   annotations:
     cert-manager.io/cluster-issuer: "letsencrypt-prod"
   ```
3. **Use real domain** (not .local)
4. **Remove mkcert secret** from production namespace

## Security Notes

- ⚠️ **Never commit** the `.pem` files to git (they're in `.gitignore`)
- ⚠️ **Local CA only** - mkcert CA is only for your machine
- ⚠️ **Not for production** - Use Let's Encrypt for production
- ✅ **Safe for development** - Certificates only trusted on your machine

## Additional Resources

- [mkcert GitHub](https://github.com/FiloSottile/mkcert)
- [HAProxy Ingress TLS](https://www.haproxy.com/documentation/kubernetes/latest/)
- [Kubernetes TLS Secrets](https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets)
- [cert-manager for Production](https://cert-manager.io/)

## Quick Reference

```bash
# Check certificate expiry
openssl x509 -in djtip.minikube.local.pem -noout -dates

# View certificate details
openssl x509 -in djtip.minikube.local.pem -noout -text

# Test HTTPS
curl -v https://djtip.minikube.local

# Check ingress TLS
kubectl get ingress djtip -n default -o yaml | grep -A5 tls

# View secret
kubectl get secret djtip-tls -n default -o yaml
```
