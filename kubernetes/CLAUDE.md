# CLAUDE.md - Kubernetes Directory

This file provides guidance to Claude Code when working with the Kubernetes configurations in this directory.

## Overview

GitOps-managed Kubernetes infrastructure for a k3s homelab cluster. ArgoCD deploys three platform services (Longhorn, Tailscale Operator, NFS CSI Driver) and one application (Immich) using an app-of-apps pattern. All services are exposed exclusively via Tailscale — there are no public endpoints.

- **GitOps**: ArgoCD (Helm-installed, annotation-based resource tracking)
- **Storage**: Longhorn (block, 2 replicas) + NFS CSI Driver (UNAS at 10.0.0.254)
- **Networking**: Tailscale Operator (`loadBalancerClass: tailscale`)
- **Architecture**: App-of-apps → platform (3 apps) + applications (1 app)

## Quick Start

```bash
# Set kubeconfig
export KUBECONFIG=~/dev/techdufus/home.io/terraform/proxmox/environments/dev/kubeconfig

# Bootstrap secrets from 1Password
cd kubernetes/bootstrap
./setup-secrets.sh

# Install ArgoCD and deploy app-of-apps
./argocd.sh

# Check everything is running
kubectl get applications -n argocd
kubectl get pods -A
```

### Prerequisites
- kubectl with cluster access
- Helm >= 3.0
- 1Password CLI (`op`) configured
- Tailscale account with OAuth client credentials

## Essential Commands

### ArgoCD
```bash
# Application status
kubectl get applications -n argocd

# Detailed sync status
kubectl get app -n argocd -o wide

# Force sync
kubectl patch application <app-name> -n argocd \
  --type merge -p '{"operation": {"initiatedBy": {"username": "admin"}, "sync": {}}}'

# ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:80

# Admin password
kubectl get secret argocd-initial-admin-secret -n argocd \
  -o jsonpath='{.data.password}' | base64 -d

# Application controller logs
kubectl logs -n argocd deployment/argocd-application-controller
```

### Longhorn
```bash
# Volume status
kubectl get volumes -n longhorn-system

# Longhorn UI
kubectl port-forward svc/longhorn-frontend -n longhorn-system 9090:80

# Check replicas
kubectl get replicas -n longhorn-system
```

### Tailscale
```bash
# Operator status
kubectl get pods -n tailscale

# Check exposed services
kubectl get svc -A -l tailscale.com/managed=true

# Operator logs
kubectl logs -n tailscale -l app=tailscale-operator
```

### Immich
```bash
# All Immich pods
kubectl get pods -n immich

# Postgres status
kubectl get statefulset -n immich

# Immich logs
kubectl logs -n immich -l app.kubernetes.io/name=immich-server

# Postgres logs
kubectl logs -n immich statefulset/postgres
```

### Resource Monitoring
```bash
kubectl top nodes
kubectl top pods -A
kubectl top pods -n <namespace>
```

## Architecture

### App-of-Apps Structure
```
app-of-apps.yaml (Root)
    ├── Platform (kubernetes/argocd/apps/platform/)
    │   ├── longhorn              # Block storage
    │   ├── tailscale-operator    # Service exposure
    │   └── csi-driver-nfs        # NFS volume provisioning
    └── Applications (kubernetes/argocd/apps/applications/)
        └── immich                # Photo management
```

### Immich Stack
Immich uses a Helm chart with supporting manifests:
- **Immich server/microservices/ML**: Helm chart (official `immich-app/immich`)
- **PostgreSQL**: Standalone StatefulSet with pgvector extension (not CNPG)
- **Valkey**: In-memory cache (bundled with Helm chart)
- **Storage**: Longhorn PVCs for Postgres data + ML cache, NFS for photo library
- **Exposure**: Tailscale LoadBalancer service

## Project Structure

```
kubernetes/
├── bootstrap/
│   ├── argocd.sh                # Helm-install ArgoCD + deploy app-of-apps
│   ├── setup-secrets.sh         # 1Password → K8s secrets
│   └── README.md                # k3s install + bootstrap instructions
└── argocd/
    ├── app-of-apps.yaml         # Root ArgoCD application
    ├── apps/
    │   ├── platform/
    │   │   ├── longhorn.yaml
    │   │   ├── tailscale-operator.yaml
    │   │   └── csi-driver-nfs.yaml
    │   └── applications/
    │       └── immich.yaml      # Multi-source: Helm + manifests
    ├── manifests/
    │   ├── immich/
    │   │   ├── namespace.yaml
    │   │   ├── postgres-statefulset.yaml
    │   │   ├── postgres-configmap.yaml
    │   │   ├── postgres-service.yaml
    │   │   ├── library-pvc.yaml
    │   │   ├── ml-cache-pvc.yaml
    │   │   └── tailscale-service.yaml
    │   └── tailscale/
    │       └── namespace.yaml
    └── values/
        ├── argocd.yaml
        ├── longhorn.yaml
        ├── tailscale-operator.yaml
        ├── csi-driver-nfs.yaml
        └── immich.yaml
```

## Important Patterns

### Adding a New Application

1. **Create ArgoCD Application** in `argocd/apps/applications/`:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/TechDufus/home.io
    targetRevision: main
    path: kubernetes/argocd/manifests/my-app
  destination:
    server: https://kubernetes.default.svc
    namespace: my-app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
```

2. **Create manifests** in `argocd/manifests/my-app/` (deployment, service, etc.)

3. **Expose via Tailscale** (if needed):
```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-app-tailscale
  namespace: my-app
spec:
  type: LoadBalancer
  loadBalancerClass: tailscale
  selector:
    app: my-app
  ports:
    - port: 80
      targetPort: 8080
```

4. **For Helm charts**, use multi-source Application (see `immich.yaml` for reference)

### Adding a Platform Service

Same pattern as applications, but place the ArgoCD Application in `argocd/apps/platform/`. Platform services are infrastructure components (storage, networking, operators).

### Secret Management

Secrets are bootstrapped via `bootstrap/setup-secrets.sh`:
1. Script reads credentials from 1Password using `op`
2. Creates Kubernetes secrets in the appropriate namespaces
3. Applications reference these secrets in their manifests

Required 1Password items (see `bootstrap/README.md` for current list):
- Tailscale OAuth client credentials
- Immich Postgres password
- ArgoCD admin password (optional — auto-generated if not set)

### ArgoCD Application Standards
```yaml
# Always include:
metadata:
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## Code Style

### YAML
- Indentation: 2 spaces (never tabs)
- Resource naming: kebab-case (`my-service-name`)
- Labels: include `app` at minimum

### File Organization
```
manifests/{service}/
├── namespace.yaml        # If needed
├── deployment.yaml       # Or statefulset.yaml
├── service.yaml
├── tailscale-service.yaml  # If exposed via Tailscale
└── pvc.yaml              # If persistent storage needed
```

## Hidden Context

### ArgoCD Annotation Tracking
Must use annotation-based resource tracking. Label-based tracking causes restart loops with certain controllers. Set via `application.resourceTrackingMethod: annotation` in argocd-cm.

### ArgoCD Insecure Mode
ArgoCD server runs with `server.insecure: "true"` — TLS is handled by Tailscale, not ArgoCD.

### Immich Multi-Source Application
The Immich ArgoCD Application uses multiple sources: Helm chart from the official repo + local manifests for Postgres, PVCs, and the Tailscale service. Uses `ServerSideApply=true` for complex resources.

### NFS CSI Driver vs Native NFS Volumes
The NFS CSI driver (`csi-driver-nfs`) concatenates `share` + `subdir` into a single NFS mount path. After a UNAS firmware update, the CSI driver's mount operations started hanging indefinitely while native Kubernetes NFS volumes (`spec.nfs`) mount the same paths without issue. The `hard` mount option causes hung mounts to never timeout, leaving stale mounts on worker nodes that block all subsequent mount attempts for that volume.

**The immich-library PV uses a static native NFS volume (not CSI) for this reason.** Do not convert it back to a CSI-provisioned volume. If adding new NFS PVCs for other apps, prefer static PVs with native NFS over dynamic CSI provisioning.

The `nfs-shared` StorageClass still uses the CSI driver for dynamic provisioning. Any dynamically-provisioned PVCs may hit the same issue if the NAS firmware changes NFS behavior.

### Immich Helm Chart Value Nesting (bjw-s common library)
The Immich Helm chart uses the bjw-s common library. Resource limits, probes, and other container-level settings must be nested under `controllers.main.containers.main`, not at the component root. For example, `server.resources` is silently ignored — use `server.controllers.main.containers.main.resources`.

### Bootstrap Order
1. k3s must be running on all nodes
2. `setup-secrets.sh` creates required secrets
3. `argocd.sh` installs ArgoCD and deploys app-of-apps
4. ArgoCD syncs all platform services and applications automatically

## Debugging Guide

### Application Won't Sync
- Check: `kubectl describe application <app> -n argocd`
- Common causes: missing CRDs, namespace issues, secret not found
- Logs: `kubectl logs -n argocd deployment/argocd-application-controller`

### Longhorn Volume Stuck
- Check: `kubectl get volumes -n longhorn-system`
- UI: port-forward to Longhorn frontend on 9090
- Common cause: node not schedulable or disk pressure

### Tailscale Service Not Reachable
- Check operator is running: `kubectl get pods -n tailscale`
- Check service has Tailscale IP: `kubectl get svc <name> -n <ns>`
- Check Tailscale admin console for the device
- Logs: `kubectl logs -n tailscale -l app=tailscale-operator`

### NFS Mount Hanging / Stale Mounts
- Symptom: pods stuck in `ContainerCreating`, events show `MountVolume.SetUp failed ... time out`
- Check CSI driver logs: `kubectl logs -n kube-system -l app.kubernetes.io/name=csi-driver-nfs -c nfs --tail=20`
- Check for stale mounts on the node: `ssh techdufus@<node-ip> 'mount | grep nfs'`
- Clear stale mounts: `ssh techdufus@<node-ip> 'sudo umount -l <mount-path>'`
- If stale mounts won't clear, restart the k3s agent: `ssh techdufus@<node-ip> 'sudo systemctl restart k3s-agent'`
- Nuclear option: drain the node and let pods reschedule to a clean worker
- **Root cause**: NFS CSI driver mount hangs + `hard` mount option = indefinite hang. See Hidden Context section.

### Immich Issues
- Postgres not ready: `kubectl describe statefulset postgres -n immich`
- Library not mounting: check NFS connectivity to 10.0.0.254 (see NFS Mount Hanging above)
- ML cache: verify Longhorn PVC is bound (`kubectl get pvc -n immich`)
- Server not ready but running: likely saturated with background jobs (face detection, transcoding) — probe timeouts, not a crash

### General
```bash
# Service connectivity
kubectl run debug --image=nicolaka/netshoot -it --rm

# Events
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# Metrics
kubectl top nodes
kubectl top pods -n <namespace>
```

## Resources

- [ArgoCD Docs](https://argo-cd.readthedocs.io/)
- [Longhorn Docs](https://longhorn.io/docs/)
- [Tailscale Kubernetes Operator](https://tailscale.com/kb/1236/kubernetes-operator)
- [NFS CSI Driver](https://github.com/kubernetes-csi/csi-driver-nfs)
- [Immich Docs](https://immich.app/docs)
- [Main Project CLAUDE.md](../CLAUDE.md)
