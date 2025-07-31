# Cloudflare Tunnel for Homelab

This directory contains the Kubernetes manifests for deploying Cloudflare Tunnel (cloudflared) to expose homelab services securely without opening ports or needing public IPs.

## Prerequisites

1. A Cloudflare account with a domain
2. Cloudflare Tunnel credentials

## Setup Instructions

### 1. Create a Cloudflare Tunnel

```bash
# Install cloudflared locally
brew install cloudflare/cloudflare/cloudflared

# Login to Cloudflare
cloudflared tunnel login

# Create a tunnel
cloudflared tunnel create homelab-tunnel

# This will create a credentials file at ~/.cloudflared/<TUNNEL_ID>.json
```

### 2. Configure the Tunnel

#### Option A: Manual Secret (Quick Start)

1. Copy the contents of `~/.cloudflared/<TUNNEL_ID>.json`
2. Edit `secret.yaml` and replace the placeholder with your actual credentials
3. Apply the manifests

#### Option B: Using External Secrets (Recommended)

1. Store the credentials in 1Password
2. Create an ExternalSecret to pull the credentials:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: cloudflared-credentials
  namespace: cloudflare
spec:
  secretStoreRef:
    name: onepassword-store
    kind: SecretStore
  target:
    name: cloudflared-credentials
  data:
  - secretKey: credentials.json
    remoteRef:
      key: cloudflare-tunnel-credentials
      property: credentials.json
```

### 3. Configure DNS

In Cloudflare Dashboard:

1. Go to your domain's DNS settings
2. Add CNAME records for each service:
   - `argocd.home.techdufus.com` → `<TUNNEL_ID>.cfargotunnel.com`
   - `n8n.home.techdufus.com` → `<TUNNEL_ID>.cfargotunnel.com`
   - etc.

### 4. Deploy to Kubernetes

```bash
# If not using ArgoCD, apply directly:
kubectl apply -k kubernetes/apps/core/cloudflared/
```

## Configuration

Edit `configmap.yaml` to add or modify service routes. Each ingress rule maps a hostname to a Kubernetes service.

### Example Service Route

```yaml
- hostname: myapp.home.techdufus.com
  service: http://myapp-service.myapp-namespace.svc.cluster.local:8080
  originRequest:
    noTLSVerify: true
    httpHostHeader: myapp.home.techdufus.com
```

## Monitoring

The cloudflared deployment exposes metrics on port 2000:

```bash
# Port forward to view metrics
kubectl port-forward -n cloudflare deployment/cloudflared 2000:2000

# View metrics
curl http://localhost:2000/metrics
```

## Troubleshooting

### View Logs

```bash
kubectl logs -n cloudflare deployment/cloudflared
```

### Test Connectivity

```bash
# From inside the cluster
kubectl run test --rm -it --image=curlimages/curl -- sh
curl https://argocd-server.argocd.svc.cluster.local:443
```

### Common Issues

1. **503 Service Unavailable**: Check that the service name and port in the ingress rules are correct
2. **SSL/TLS Errors**: Ensure `noTLSVerify: true` is set for HTTPS services without valid certificates
3. **Tunnel Not Connecting**: Verify credentials.json is correctly formatted and the tunnel exists in Cloudflare

## Security Considerations

- The tunnel authenticates using the credentials.json file - keep this secure
- All traffic is encrypted from your cluster to Cloudflare's edge
- No inbound ports need to be opened on your network
- Consider using Cloudflare Access for additional authentication