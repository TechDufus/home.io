# Cloudflare Tunnel Setup for Homelab

This directory contains the Kubernetes manifests for running Cloudflare Tunnel (cloudflared) to securely expose your homelab services to the internet with GitHub authentication.

## Architecture

The tunnel routes all traffic for `lab.techdufus.com` to your Gateway, which handles path-based routing:
- `/argocd` → ArgoCD UI
- `/traefik` → Traefik Dashboard  
- Additional paths can be added in the HTTPRoute

## Manual Setup Required (One-time)

### 1. Create Cloudflare Tunnel

1. Go to [Cloudflare Zero Trust Dashboard](https://one.dash.cloudflare.com)
2. Navigate to **Access** → **Tunnels**
3. Click **Create a tunnel**
4. Choose **Cloudflared** tunnel type
5. Name it `homelab-tunnel`
6. Save the tunnel token/credentials JSON
7. **IMPORTANT**: Store credentials in 1Password as "Cloudflare Tunnel - Homelab"

### 2. Configure GitHub Authentication

1. In Zero Trust Dashboard, go to **Settings** → **Authentication**
2. Add **GitHub** as an identity provider
3. Create a GitHub OAuth App:
   - Go to GitHub Settings → Developer settings → OAuth Apps
   - Application name: `Homelab Access`
   - Homepage URL: `https://lab.techdufus.com`
   - Authorization callback URL: `https://<your-team>.cloudflareaccess.com/cdn-cgi/access/callback`
4. Copy Client ID and Secret to Cloudflare

### 3. Create Access Application

1. Go to **Access** → **Applications**
2. Click **Add an application**
3. Select **Self-hosted**
4. Configure:
   - Name: `Homelab Services`
   - Domain: `lab.techdufus.com`
   - Path: Leave blank (protects all paths)
5. Configure policies:
   - Name: `GitHub Users`
   - Action: Allow
   - Include: GitHub identity provider
   - Selector: Email → Matches → Your email(s)

### 4. Configure DNS

1. In Cloudflare DNS, ensure `lab.techdufus.com` exists
2. It will be automatically configured as a CNAME to your tunnel when the tunnel connects

## Deployment

### Prerequisites

Ensure the tunnel credentials are in 1Password:
```bash
# Test that credentials exist
op item get "Cloudflare Tunnel - Homelab" --vault Personal
```

### Deploy via ArgoCD

1. Apply the ArgoCD application:
```bash
kubectl apply -f kubernetes/argocd/apps/cloudflared.yaml
```

2. Sync the application in ArgoCD UI or CLI:
```bash
argocd app sync cloudflared
```

### Manual Deployment (if needed)

1. Create the secret from 1Password:
```bash
# This is handled by setup-secrets.sh script
./kubernetes/bootstrap/setup-secrets.sh
```

2. Apply manifests:
```bash
kubectl apply -f kubernetes/argocd/manifests/cloudflared/
```

## Adding New Services

To expose a new service through the tunnel:

1. Edit `httproute.yaml` to add the new path:
```yaml
- matches:
    - path:
        type: PathPrefix
        value: /newservice
  filters:
    - type: URLRewrite
      urlRewrite:
        path:
          type: ReplacePrefixMatch
          replacePrefixMatch: /
  backendRefs:
    - name: service-name
      namespace: service-namespace
      port: 80
```

2. Optionally add a direct subdomain in `configmap.yaml`:
```yaml
- hostname: newservice.lab.techdufus.com
  service: http://service-name.namespace.svc.cluster.local:port
```

3. Commit and push - ArgoCD will sync automatically

## Troubleshooting

### Check Tunnel Status
```bash
# Check if pods are running
kubectl get pods -n cloudflare

# Check logs
kubectl logs -n cloudflare deployment/cloudflared

# Check tunnel status in Cloudflare dashboard
# Go to Zero Trust → Access → Tunnels
```

### Common Issues

1. **Authentication loops**: Ensure cookies are enabled and domain is correct
2. **404 errors**: Check HTTPRoute configuration and service endpoints
3. **Tunnel offline**: Verify credentials secret exists and is valid
4. **Path issues**: Some apps don't work well with path prefixes, consider subdomains

### Application-Specific Configuration

#### ArgoCD
ArgoCD needs special configuration for path-based access:
- Set `server.basehref: "/argocd"` in ConfigMap
- Set `server.rootpath: "/argocd"`
- Enable `server.insecure: "true"` (TLS handled by Cloudflare)

#### Traefik
The dashboard works best at root but can be configured with:
- Path rewrite from `/traefik` to `/dashboard`
- Or use subdomain `traefik.lab.techdufus.com`

## Security Notes

- All access requires GitHub authentication
- Tunnel credentials should never be committed to git
- Use 1Password for all secret management
- Regular review Access policies for authorized users
- Consider IP restrictions for additional security

## Monitoring

View tunnel metrics:
```bash
# Port-forward to metrics endpoint
kubectl port-forward -n cloudflare deployment/cloudflared 2000:2000

# Access metrics at http://localhost:2000/metrics
```

## Links

- [Cloudflare Zero Trust Dashboard](https://one.dash.cloudflare.com)
- [Cloudflare Tunnel Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps)
- [Gateway API Documentation](https://gateway-api.sigs.k8s.io)