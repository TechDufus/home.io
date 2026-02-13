# k3s Cluster Bootstrap

## Prerequisites
- 3 Ubuntu VMs provisioned via Terraform (k3s-cp-1, k3s-worker-1, k3s-worker-2)
- Tailscale OAuth client created in admin console (Devices scope, Read+Write, tag:k8s-operator)
- Tailscale OAuth credentials stored in 1Password as "tailscale-operator-oauth"
- Immich Postgres password stored in 1Password as "immich-postgres-password"
- NFS share on UNAS: /var/nfs/shared with RW access for 10.0.20.21-22
- kubectl and helm installed locally
- 1Password CLI (op) configured

## 1. Install k3s

### Control Plane (k3s-cp-1 — 10.0.20.20)
```bash
ssh techdufus@10.0.20.20
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik --disable servicelb --disable local-storage" sh -
# Get join token
sudo cat /var/lib/rancher/k3s/server/node-token
# Get kubeconfig
sudo cat /etc/rancher/k3s/k3s.yaml
```

### Workers (k3s-worker-1, k3s-worker-2)
```bash
ssh techdufus@10.0.20.21  # or .22
curl -sfL https://get.k3s.io | K3S_URL=https://10.0.20.20:6443 K3S_TOKEN=<token-from-above> sh -
```

## 2. Configure Local Access
Copy kubeconfig from control plane, update server URL to 10.0.20.20.

## 3. Bootstrap Secrets
```bash
cd kubernetes/bootstrap
./setup-secrets.sh
```

## 4. Bootstrap ArgoCD
```bash
./argocd.sh
```

## 5. Verify
```bash
kubectl get applications -n argocd
kubectl get nodes
```
