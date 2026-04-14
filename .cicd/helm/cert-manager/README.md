# cert-manager with Let's Encrypt

Automated TLS certificate management using cert-manager and Let's Encrypt.

## Features

- **Automatic certificate issuance** from Let's Encrypt
- **Automatic renewal** (30 days before expiry)
- **HTTP-01 challenge** via HAProxy ingress
- **Staging and production** issuers
- **Unified configuration** across all environments

## ClusterIssuers

### letsencrypt-staging
- **Purpose**: Development and testing
- **Server**: Let's Encrypt staging API
- **Rate limits**: Very high (for testing)
- **Certificates**: Not trusted by browsers (test only)
- **Use for**: Development, staging environments

### letsencrypt-prod
- **Purpose**: Production
- **Server**: Let's Encrypt production API
- **Rate limits**: 50 certificates per domain per week
- **Certificates**: Trusted by all browsers
- **Use for**: Production environment only

## Configuration

### Email Address

Update the email in `values.yaml`:
```yaml
letsencrypt:
  email: "your-email@example.com"
```

This email receives:
- Certificate expiry notifications
- Let's Encrypt important notices
- Rate limit warnings

## Usage

### Automatic Certificate Management

Certificates are automatically issued when you create an Ingress with the cert-manager annotation:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-staging"  # or letsencrypt-prod
spec:
  tls:
    - hosts:
        - example.com
      secretName: example-tls  # cert-manager will create this
```

### Environment-Specific Configuration

**Development:**
```yaml
annotations:
  cert-manager.io/cluster-issuer: "letsencrypt-staging"
```

**Staging:**
```yaml
annotations:
  cert-manager.io/cluster-issuer: "letsencrypt-staging"
```

**Production:**
```yaml
annotations:
  cert-manager.io/cluster-issuer: "letsencrypt-prod"
```

## Deployment

### Minikube

```bash
kubectl apply -f .cicd/argocd/cert-manager-app.yaml
```

### Pi

```bash
kubectl apply -f .cicd/argocd/pi/cert-manager.yaml
```

## Verification

### Check cert-manager pods

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

### Check ClusterIssuers

```bash
kubectl get clusterissuers
```

Expected output:
```
NAME                   READY   AGE
letsencrypt-prod       True    1m
letsencrypt-staging    True    1m
```

### Check Certificate

```bash
kubectl get certificate -n <namespace>
kubectl describe certificate <cert-name> -n <namespace>
```

### Check Certificate Secret

```bash
kubectl get secret <tls-secret-name> -n <namespace>
```

## Troubleshooting

### Certificate not issuing

1. **Check Certificate status:**
   ```bash
   kubectl describe certificate <name> -n <namespace>
   ```

2. **Check CertificateRequest:**
   ```bash
   kubectl get certificaterequest -n <namespace>
   kubectl describe certificaterequest <name> -n <namespace>
   ```

3. **Check Order:**
   ```bash
   kubectl get order -n <namespace>
   kubectl describe order <name> -n <namespace>
   ```

4. **Check Challenge:**
   ```bash
   kubectl get challenge -n <namespace>
   kubectl describe challenge <name> -n <namespace>
   ```

### Common Issues

**HTTP-01 challenge failing:**
- Ensure ingress is accessible from the internet
- Check HAProxy ingress is working
- Verify DNS points to your cluster
- Check firewall allows HTTP (port 80)

**Rate limit exceeded:**
- Use staging issuer for testing
- Production has 50 certs/week limit
- Wait for rate limit to reset
- Consider using DNS-01 challenge for high volume

**Certificate shows as not ready:**
- Wait 1-2 minutes for issuance
- Check cert-manager logs: `kubectl logs -n cert-manager deployment/cert-manager`
- Verify ClusterIssuer is ready

## Migration from Manual Certificates

1. **Deploy cert-manager** (via ArgoCD)
2. **Verify ClusterIssuers** are ready
3. **Update ingress annotations** to use cert-manager
4. **Delete old manual secrets** (optional, after verification)
5. **Cert-manager creates new secrets** automatically

## Best Practices

1. **Always test with staging** before using production
2. **Monitor certificate expiry** (cert-manager auto-renews at 30 days)
3. **Use production issuer** only for production domains
4. **Keep email updated** for important notifications
5. **Check logs regularly** for any issues

## Certificate Lifecycle

1. **Ingress created** with cert-manager annotation
2. **Certificate resource** created automatically
3. **CertificateRequest** submitted to Let's Encrypt
4. **HTTP-01 challenge** completed via ingress
5. **Certificate issued** and stored in secret
6. **Auto-renewal** starts 30 days before expiry
7. **Ingress uses** the certificate from secret

## Resources

- [cert-manager documentation](https://cert-manager.io/docs/)
- [Let's Encrypt documentation](https://letsencrypt.org/docs/)
- [Rate limits](https://letsencrypt.org/docs/rate-limits/)
