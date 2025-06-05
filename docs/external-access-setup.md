# External Access Setup Guide

This guide walks you through setting up secure external access to your home lab services using Cloudflare Tunnel with automatic SSL certificate management.

## Architecture Overview

### Domain Strategy
- **Internal**: `*.home.io` for local network access
- **External**: `*.lab.techdufus.com` for internet access via Cloudflare Tunnel
- **Benefits**: Clear separation, organized namespace, no DNS conflicts, easy security management

### How It Works
1. **Cloudflare Tunnel** creates a secure connection from your cluster to Cloudflare's network
2. **No exposed ports** - Your home IP remains private
3. **Automatic SSL** - Cloudflare handles certificate management
4. **DDoS protection** - Built-in via Cloudflare's network

## Prerequisites

1. **Cloudflare Account** with `techdufus.com` domain
2. **Kubernetes cluster** with ingress-nginx deployed
3. **ArgoCD** installed and configured

## Step 1: Cloudflare Zero Trust Setup

### 1.1 Create a Tunnel

1. Go to [Cloudflare Zero Trust Dashboard](https://one.dash.cloudflare.com/)
2. Navigate to **Access** → **Tunnels**
3. Click **Create a tunnel**
4. Choose **Cloudflared** connector
5. Name your tunnel: `techdufus-home-lab`
6. Copy the tunnel token (you'll need this later)

### 1.2 Configure DNS Records

In your Cloudflare DNS settings for `techdufus.com`, the tunnel will automatically create CNAME records for:
- `argocd.lab.techdufus.com`
- `ha.lab.techdufus.com`
- Add more as needed

## Step 2: Deploy Cloudflare Tunnel to Kubernetes

### 2.1 Create Tunnel Secret

```bash
# Base64 encode your tunnel token
echo -n "your-tunnel-token-here" | base64

# Update the secret file
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: cloudflare-tunnel-token
  namespace: cloudflare-tunnel
type: Opaque
data:
  token: "<your-base64-encoded-token>"
EOF
```

### 2.2 Deploy via ArgoCD

The Cloudflare tunnel is configured as an ArgoCD application and will deploy automatically once you:

1. Update the tunnel token in `kubernetes/infrastructure/cloudflare-tunnel/secret.yaml`
2. Commit and push to your repository
3. ArgoCD will sync and deploy the tunnel

## Step 3: Configure DNS in Cloudflare

### 3.1 Update DNS Settings

For each service you want to expose externally:

1. Go to **DNS** in your Cloudflare dashboard
2. Add CNAME records pointing to your tunnel:
   - `argocd.lab.techdufus.com` → `<tunnel-id>.cfargotunnel.com`
   - `ha.lab.techdufus.com` → `<tunnel-id>.cfargotunnel.com`

### 3.2 SSL/TLS Configuration

1. Go to **SSL/TLS** → **Overview**
2. Set encryption mode to **Full (strict)**
3. Enable **Always Use HTTPS**
4. Enable **HSTS** for additional security

## Step 4: Update Service Configurations

### 4.1 ArgoCD External Access

The ArgoCD ingress is configured for both internal and external access:

```yaml
# Internal: https://argocd.home.io
# External: https://argocd.techdufus.com (via tunnel)
```

### 4.2 Home Assistant External Access

Deploy Home Assistant with dual-domain support:

```bash
kubectl apply -f kubernetes/apps/external/home-assistant-ingress.yaml
```

## Step 5: Security Configuration

### 5.1 Cloudflare Security Settings

1. **Access Policies** (Optional but recommended):
   - Go to **Access** → **Applications**
   - Create policies for sensitive services
   - Add authentication requirements

2. **WAF Rules**:
   - Go to **Security** → **WAF**
   - Enable bot protection
   - Set up rate limiting

### 5.2 Service-Level Security

For ArgoCD, update the server configuration:

```yaml
# Add to argocd-server-config
data:
  url: "https://argocd.lab.techdufus.com"
  oidc.config: |
    # Configure SSO if desired
```

## Step 6: Testing and Validation

### 6.1 Test Internal Access

```bash
# Test internal DNS resolution
nslookup argocd.home.io
curl -k https://argocd.home.io
```

### 6.2 Test External Access

```bash
# Test external access
curl https://argocd.lab.techdufus.com
curl https://ha.lab.techdufus.com
```

### 6.3 Verify SSL Certificates

1. Check that certificates are issued by Cloudflare
2. Verify HTTPS redirects work
3. Test from external networks

## Migration Strategy

### Phase 1: Setup (No Service Disruption)
1. Deploy Cloudflare tunnel infrastructure
2. Configure external ingresses alongside existing ones
3. Test external access while keeping internal access intact

### Phase 2: DNS Update (Minimal Disruption)
1. Update internal DNS to use `.home.io` consistently
2. Validate all internal services work
3. Update documentation

### Phase 3: External Enablement
1. Enable external services one by one
2. Test each service thoroughly
3. Configure security policies

### Rollback Plan
If issues arise:
1. Disable Cloudflare tunnel deployment
2. External access stops, internal access unaffected
3. Debug and redeploy when ready

## Service Configuration Examples

### Adding a New External Service

1. **Create Kubernetes resources**:
   ```yaml
   # In kubernetes/apps/external/newservice.yaml
   apiVersion: networking.k8s.io/v1
   kind: Ingress
   metadata:
     name: newservice-external
   spec:
     rules:
     - host: newservice.home.io      # Internal
     - host: newservice.lab.techdufus.com # External
   ```

2. **Update Cloudflare tunnel config**:
   ```yaml
   # In configmap.yaml
   ingress:
     - hostname: newservice.lab.techdufus.com
       service: http://newservice.namespace.svc.cluster.local:80
   ```

3. **Add DNS record** in Cloudflare dashboard

### Services Recommendation

| Service | Internal Only | External Access | Reasoning |
|---------|---------------|-----------------|-----------|
| ArgoCD | ✓ | ✓ | Management interface, secure with auth |
| Home Assistant | ✓ | ✓ | Mobile access, configure auth carefully |
| Dashy | ✓ | ✗ | Contains internal network info |
| Pi-hole | ✓ | ✗ | Security risk if exposed |
| Proxmox | ✓ | ✗ | Hypervisor should stay internal |
| Jellyfin | ✓ | ✓ | Media streaming, add auth |
| Nextcloud | ✓ | ✓ | File sync, built-in security |

## Security Best Practices

### 1. Network Segmentation
- Keep admin interfaces (Proxmox, Pi-hole) internal only
- Use separate ingress classes if needed
- Monitor traffic patterns

### 2. Authentication
- Enable multi-factor authentication where possible
- Use Cloudflare Access for additional auth layer
- Implement SSO for enterprise apps

### 3. Monitoring
- Enable Cloudflare Analytics
- Monitor tunnel metrics in Kubernetes
- Set up alerts for unusual traffic

### 4. Regular Maintenance
- Update tunnel connector regularly
- Review access logs monthly
- Rotate API tokens quarterly

## Troubleshooting

### Common Issues

1. **Tunnel not connecting**:
   ```bash
   kubectl logs -n cloudflare-tunnel deployment/cloudflare-tunnel
   ```

2. **DNS resolution issues**:
   - Check Cloudflare DNS settings
   - Verify tunnel CNAME records
   - Test with `dig` command

3. **SSL certificate errors**:
   - Ensure Cloudflare SSL mode is "Full (strict)"
   - Check tunnel configuration
   - Verify service is accessible internally

### Debug Commands

```bash
# Check tunnel status
kubectl get pods -n cloudflare-tunnel

# View tunnel logs
kubectl logs -n cloudflare-tunnel -l app=cloudflare-tunnel

# Test internal connectivity
kubectl exec -it <test-pod> -- curl http://service.namespace.svc.cluster.local

# Check ingress configuration
kubectl get ingress -A
```

## Cost Considerations

- **Cloudflare Tunnel**: Free for up to 1000 requests/minute
- **Cloudflare Zero Trust**: Free tier includes 50 users
- **Bandwidth**: No additional charges for tunnel traffic
- **DNS**: Free with Cloudflare account

This setup provides enterprise-grade security and reliability at no additional cost for home lab usage.