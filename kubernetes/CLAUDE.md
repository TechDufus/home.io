# Kubernetes

GitOps-managed k3s cluster. ArgoCD deploys platform services and applications via app-of-apps pattern. All services exposed via Tailscale — no public endpoints.

## App-of-Apps Structure

```
app-of-apps.yaml (Root)
├── Platform (apps/platform/)
│   ├── longhorn           # Block storage (2 replicas)
│   ├── tailscale-operator # Service exposure
│   └── csi-driver-nfs     # NFS provisioning
└── Applications (apps/applications/)
    └── immich             # Photo management
```

## Adding an Application

1. Create ArgoCD Application in `argocd/apps/applications/`:
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
    automated: { prune: true, selfHeal: true }
    syncOptions: [CreateNamespace=true]
    retry: { limit: 5, backoff: { duration: 5s, factor: 2, maxDuration: 3m } }
```
2. Create manifests in `argocd/manifests/my-app/`
3. For Helm charts, use multi-source Application (see `immich.yaml`)

Platform services: same pattern but in `argocd/apps/platform/`.

## Exposing via Tailscale

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-app-tailscale
spec:
  type: LoadBalancer
  loadBalancerClass: tailscale
  selector: { app: my-app }
  ports: [{ port: 80, targetPort: 8080 }]
```

## Secret Management

1. `bootstrap/setup-secrets.sh` reads from 1Password, creates K8s secrets
2. Required: Tailscale OAuth creds, Immich Postgres password
3. Bootstrap order: k3s running → `setup-secrets.sh` → `argocd.sh`

## Hidden Context

### ArgoCD Annotation Tracking
Must use annotation-based tracking (not label-based). Label tracking causes restart loops. Set via `application.resourceTrackingMethod: annotation` in argocd-cm.

### ArgoCD Insecure Mode
Server runs with `server.insecure: "true"` — TLS handled by Tailscale.

### Immich Multi-Source Application
Uses multiple sources: Helm chart (official repo) + local manifests for Postgres, PVCs, Tailscale service. Uses `ServerSideApply=true`.

### Immich Helm Value Nesting (bjw-s common library)
Resource limits, probes, container settings nest under `controllers.main.containers.main`, not component root. `server.resources` is silently ignored — use `server.controllers.main.containers.main.resources`.

### NFS CSI Driver vs Native NFS Volumes
The NFS CSI driver concatenates `share` + `subdir` into a single mount path. After UNAS firmware updates, CSI mount operations hang indefinitely while native K8s NFS volumes (`spec.nfs`) work fine. The `hard` mount option means hung mounts never timeout, leaving stale mounts on workers that block subsequent mounts.

**The immich-library PV uses a static native NFS volume for this reason. Do not convert back to CSI.**

For new NFS PVCs: prefer static PVs with native NFS over dynamic CSI provisioning. The `nfs-shared` StorageClass still uses CSI and may hit the same issue.

## Debugging

### NFS Mount Hanging / Stale Mounts
- Symptom: pods stuck in `ContainerCreating`, events show `MountVolume.SetUp failed ... time out`
- Check CSI logs: `kubectl logs -n kube-system -l app.kubernetes.io/name=csi-driver-nfs -c nfs --tail=20`
- Check stale mounts on node: `ssh techdufus@<node-ip> 'mount | grep nfs'`
- Clear stale mounts: `ssh techdufus@<node-ip> 'sudo umount -l <mount-path>'`
- If stuck, restart k3s agent: `ssh techdufus@<node-ip> 'sudo systemctl restart k3s-agent'`
- Nuclear: drain node, let pods reschedule to clean worker
- Root cause: CSI mount hang + `hard` option = indefinite hang

### Immich Issues
- Postgres not ready: `kubectl describe statefulset postgres -n immich`
- Library not mounting: check NFS to 10.0.0.254 (see NFS debugging above)
- ML cache: verify Longhorn PVC is bound (`kubectl get pvc -n immich`)
- Server running but not ready: likely background jobs (face detection, transcoding) causing probe timeouts

### ArgoCD Sync
- `kubectl describe application <app> -n argocd`
- Common causes: missing CRDs, namespace issues, secret not found
- Logs: `kubectl logs -n argocd deployment/argocd-application-controller`

### General
- Events: `kubectl get events -n <ns> --sort-by='.lastTimestamp'`
- Debug pod: `kubectl run debug --image=nicolaka/netshoot -it --rm`

## Style

- YAML: 2-space indent, kebab-case names, `app` label required
- Manifests per service: `namespace.yaml`, `deployment.yaml`, `service.yaml`, `tailscale-service.yaml`, `pvc.yaml`
- ArgoCD apps: always include finalizer + automated sync with prune/selfHeal
