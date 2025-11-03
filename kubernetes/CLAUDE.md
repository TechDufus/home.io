# CLAUDE.md - Kubernetes Directory

This file provides guidance to Claude Code (claude.ai/code) when working with the Kubernetes configurations in this directory.

## Repository Overview

This directory contains the **GitOps-based Kubernetes infrastructure** for the home.io homelab, implementing a modern cloud-native architecture with ArgoCD, Gateway API, and enterprise-grade secret management. The infrastructure emphasizes operational simplicity while maintaining production-ready practices.

### Project Statistics
- **Primary format**: YAML manifests and Helm values
- **GitOps platform**: ArgoCD v2.11.3
- **Networking**: Gateway API v1.2.1 with Traefik
- **Active since**: March 2024 (major expansion June 2025)
- **Architecture**: App-of-Apps pattern with automated sync

## Quick Start

### Prerequisites
- **kubectl** >= 1.28 with cluster access
- **1Password CLI** (op) configured and signed in
- **Git repository** access (GitHub)
- **Terraform-provisioned** Talos Kubernetes cluster
- **Domain access**: lab.techdufus.com (Cloudflare)

### Initial Setup
```bash
# 1. Ensure kubeconfig is available
export KUBECONFIG=~/dev/techdufus/home.io/terraform/proxmox/environments/dev/kubeconfig

# 2. Setup secrets from 1Password
cd kubernetes/bootstrap
./setup-secrets.sh

# 3. Bootstrap ArgoCD with App-of-Apps
./argocd.sh

# 4. Access services
echo "Homarr Dashboard: https://lab.techdufus.com/"
echo "ArgoCD UI: https://lab.techdufus.com/argocd"
echo "Username: admin"
echo "Password: $(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d)"
```

## Essential Commands

### ArgoCD Operations
```bash
# Check application status
kubectl get applications -n argocd

# Force sync an application
kubectl patch application <app-name> -n argocd --type merge -p '{"operation": {"initiatedBy": {"username": "admin"}, "sync": {}}}'

# View application logs
kubectl logs -n argocd deployment/argocd-server

# Port-forward for direct access
kubectl port-forward svc/argocd-server -n argocd 8080:80
```

### Gateway and Routing
```bash
# Check Gateway status
kubectl get gateway lab-gateway -n traefik

# List HTTPRoutes
kubectl get httproute -A

# Verify LoadBalancer IP
kubectl get svc traefik -n traefik

# Check Cloudflare tunnel
kubectl logs deployment/cloudflared -n cloudflare

# Check Homarr dashboard
kubectl get pods -n homarr
kubectl logs deployment/homarr -n homarr
```

### GitHub Actions Runners
```bash
# Check runner status
kubectl get autoscalingrunnerset -n actions-runner-system
kubectl get pods -n actions-runner-system

# View runner logs
kubectl logs -n actions-runner-system -l app.kubernetes.io/component=runner-scale-set-listener
kubectl logs -n actions-runner-system deployment/arc-controller-gha-rs-controller

# Watch runner scaling in real-time
watch -n 5 'kubectl get pods -n actions-runner-system | grep runner'

# Check RBAC permissions
kubectl describe clusterrole arc-controller-gha-rs-controller
```

### Resource Monitoring
```bash
# View node resource usage
kubectl top nodes

# View pod resource usage (all namespaces)
kubectl top pods -A

# View pod resource usage (specific namespace)
kubectl top pods -n <namespace>

# Check metrics-server status
kubectl get deployment metrics-server -n kube-system
```

### Troubleshooting
```bash
# Check ArgoCD sync status
kubectl get app -n argocd -o wide

# View Gateway API resources
kubectl get gatewayclass,gateway,httproute,referencegrant -A

# Check MetalLB IP allocation
kubectl get ipaddresspool -n metallb-system

# Debug service connectivity
kubectl exec -it deployment/traefik -n traefik -- curl http://argocd-server.argocd.svc.cluster.local
```

## Architecture and Key Concepts

### GitOps Architecture

The infrastructure follows an **App-of-Apps pattern** where a single root ArgoCD application manages all other applications:

```
app-of-apps.yaml (Root)
    ├── gateway-api-crds           # Gateway API CRDs (deployed first)
    ├── metallb                    # Load balancer for bare metal
    ├── metallb-config             # IP pool configuration
    ├── traefik                   # Gateway controller
    ├── gateway-config            # Gateway and HTTPRoutes
    ├── metrics-server            # Resource metrics for kubectl top
    ├── homarr                    # Dashboard application
    ├── cloudflared               # External access tunnel
    └── actions-runner-controller # GitHub Actions self-hosted runners
```

### Network Architecture

**Traffic Flow**:
1. External traffic → `lab.techdufus.com` (Cloudflare DNS)
2. Cloudflare Tunnel → `cloudflared` pods in cluster
3. Tunnel → Traefik LoadBalancer (`10.0.20.200:8000`)
4. Gateway API → HTTPRoute → Backend Services

**IP Allocation**:
- **MetalLB Pool**: `10.0.20.200-10.0.20.210`
- **Traefik Fixed IP**: `10.0.20.200`
- **Gateway Port**: `8000` (HTTP only, TLS at Cloudflare)

### Gateway API Implementation

Instead of traditional Ingress, this project uses the modern Gateway API:

```yaml
GatewayClass: traefik (controller)
    └── Gateway: lab-gateway (listener on :8000)
        └── HTTPRoute: argocd-route (path: /argocd)
            └── Service: argocd-server
```

**Cross-namespace routing** enabled via ReferenceGrant for service access.

### GitHub Actions Runner Controller

Self-hosted GitHub Actions runners deployed with **scale-to-zero architecture** using the official Actions Runner Controller (ARC).

**Architecture**:
```
Controller (cluster-wide)
    └── ApplicationSet (generates runner sets per-repo)
        ├── AutoscalingRunnerSet (home.io)
        │   └── Listener Pod → EphemeralRunner (created on-demand)
        └── AutoscalingRunnerSet (dotfiles)
            └── Listener Pod → EphemeralRunner (created on-demand)
```

**Key Configuration Requirements**:

1. **Container Mode**: Use `dind` (Docker-in-Docker) for standard GitHub Actions compatibility
   - `kubernetes` mode requires all workflows to specify `container:` which breaks most standard actions
   - dind mode allows workflows to run unmodified

2. **PodSecurity**: Namespace must allow **privileged** containers for dind
   ```yaml
   pod-security.kubernetes.io/enforce: privileged
   ```

3. **ArgoCD Tracking**: Must use **annotation-based** tracking (not label-based)
   - Label tracking causes listener pod restart loops
   - Configure via: `application.resourceTrackingMethod: annotation` in argocd-cm
   - Exclude ArgoCD labels from propagating to runner pods in controller values

4. **RBAC Permissions**: Upstream chart missing critical permissions
   - Controller needs `create/delete` for roles/rolebindings (chart only grants list/watch/patch)
   - Fixed via separate ClusterRole manifest as additional ArgoCD source
   - Also needs `list/get` for secrets (cleanup operations)

**Multi-Repository Pattern**:

Uses ApplicationSet to generate runner scale sets per repository:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: actions-runner-scale-sets
spec:
  generators:
    - list:
        elements:
          - repo: home.io
            runnerScaleSetName: home.io-runners
            minRunners: "0"
            maxRunners: "2"
  template:
    # Generates Application per repository
```

**Configuration Files**:
- `apps/platform/actions-runner-controller.yaml` - Controller Application
- `apps/platform/actions-runner-scale-sets.yaml` - ApplicationSet for runners
- `values/actions-runner-controller.yaml` - Controller config (15 lines)
- `values/actions-runner-scale-set-template.yaml` - Runner template (23 lines)
- `manifests/actions-runner-controller/clusterrole-patch.yaml` - RBAC fix
- `manifests/actions-runner-controller/namespace.yaml` - PodSecurity config

### Secret Management

All secrets are managed through 1Password with fallback to environment variables:

```bash
# Secret flow
1Password Vault "Personal"
    ├── cloudflared-credentials → credentials.json
    ├── argocd-admin → initial admin password
    └── [service]-secrets → Kubernetes secrets
```

## Project Structure

```
kubernetes/
├── argocd/                      # GitOps configurations
│   ├── app-of-apps.yaml        # Root application (deploy this first)
│   ├── apps/                   # Individual application definitions
│   │   ├── gateway-api-crds.yaml    # Gateway API CRDs
│   │   ├── traefik.yaml             # Traefik gateway controller
│   │   ├── metallb.yaml             # MetalLB load balancer
│   │   ├── metallb-config.yaml      # IP pool configuration
│   │   ├── gateway-config.yaml      # Gateway and routes
│   │   ├── metrics-server.yaml      # Resource metrics server
│   │   ├── homarr.yaml              # Dashboard application
│   │   └── cloudflared.yaml         # Cloudflare tunnel
│   ├── manifests/              # Kubernetes resource manifests
│   │   ├── cloudflared/        # Tunnel deployment
│   │   │   ├── deployment.yaml
│   │   │   └── argocd-config.yaml
│   │   ├── gateway/            # Gateway API resources
│   │   │   └── lab-gateway.yaml
│   │   ├── homarr/             # Dashboard configuration
│   │   │   └── namespace.yaml
│   │   ├── metallb/            # MetalLB configuration
│   │   │   ├── ip-pool.yaml
│   │   │   └── namespace.yaml
│   │   └── actions-runner-controller/ # GitHub Actions runners
│   │       ├── namespace.yaml         # PodSecurity privileged config
│   │       └── clusterrole-patch.yaml # RBAC permissions fix
│   └── values/                 # Helm chart values
│       ├── traefik.yaml        # Traefik configuration
│       ├── metallb.yaml        # MetalLB settings
│       ├── metrics-server.yaml # Metrics server configuration
│       ├── homarr.yaml         # Dashboard configuration
│       ├── actions-runner-controller.yaml # ARC controller config
│       └── actions-runner-scale-set-template.yaml # Runner template
└── bootstrap/                  # Bootstrap scripts
    ├── argocd.sh              # ArgoCD installation
    └── setup-secrets.sh       # 1Password secret setup
```

## Important Patterns

### Adding a New Application

1. **Create ArgoCD Application definition**:
```yaml
# kubernetes/argocd/apps/my-service.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-service
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/TechDufus/home.io
    targetRevision: main
    path: kubernetes/argocd/manifests/my-service
  destination:
    server: https://kubernetes.default.svc
    namespace: my-service
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      allowEmpty: false
    syncOptions:
      - CreateNamespace=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
```

2. **Create service manifests**:
```yaml
# kubernetes/argocd/manifests/my-service/deployment.yaml
# Include: deployment, service, configmap, etc.
# Follow security contexts and resource limits patterns
```

3. **Expose via Gateway (if needed)**:
```yaml
# kubernetes/argocd/manifests/gateway/my-service-route.yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: my-service-route
  namespace: traefik
spec:
  parentRefs:
    - name: lab-gateway
      namespace: traefik
  hostnames:
    - lab.techdufus.com
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /my-service
      backendRefs:
        - name: my-service
          namespace: my-service
          port: 80
```

### Security Patterns

All deployments must include:

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 65532
  runAsGroup: 65532
  fsGroup: 65532
  capabilities:
    drop: [ALL]
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
```

### Resource Management

Standard resource constraints:

```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

### Health Checks

Always include probes:

```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
```

## Code Style

### YAML Conventions
- **Indentation**: 2 spaces (never tabs)
- **Resource naming**: Kebab-case (`my-service-name`)
- **Labels**: Include `app`, `version`, `component`
- **Annotations**: Document non-obvious configurations

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
  revisionHistoryLimit: 10  # Infrastructure apps
  # or
  revisionHistoryLimit: 3   # Regular apps
```

### File Organization
```
manifests/{service}/
├── namespace.yaml      # If custom namespace needed
├── deployment.yaml     # Main workload
├── service.yaml        # Service definition
├── configmap.yaml      # Configuration
└── secret.yaml         # Only references, actual secrets from 1Password
```

## Hidden Context

### ArgoCD Path-Based Routing Quirks
ArgoCD requires specific configuration for path-based access:
```yaml
# Must set both basehref and rootpath for UI to work
server.basehref: "/argocd"
server.rootpath: "/argocd"
server.insecure: "true"  # TLS handled by Cloudflare
```

### Gateway API Cross-Namespace References
Services in different namespaces require ReferenceGrant:
```yaml
# Required in target namespace to allow HTTPRoute references
apiVersion: gateway.networking.k8s.io/v1beta1
kind: ReferenceGrant
```

### MetalLB IP Assignment
Traefik service uses annotation for fixed IP:
```yaml
metallb.universe.tf/loadBalancerIPs: "10.0.20.200"
```

### Cloudflare Tunnel Requirements
- Requires 2 replicas with anti-affinity for HA
- Credentials must be base64 encoded JSON from 1Password
- Metrics available on port 2000 (not exposed externally)

### Bootstrap Order Dependencies
1. Gateway API CRDs **must** deploy before Traefik
2. MetalLB **must** be ready before Traefik gets LoadBalancer IP
3. Traefik **must** be ready before Gateway configuration
4. All infrastructure **must** be ready before application deployments

### Historical Context
- **March 2024**: Started with traditional IngressRoute
- **June 2025**: Major migration to Gateway API and CAPI
- **August 2025**: Simplified to essential components, removed complex monitoring stack
- **Current**: Stabilized on path-based routing after trying subdomains

### Known Issues and Workarounds

**Traefik Dashboard Access**:
- Multiple attempts to expose dashboard securely
- Currently disabled due to path-based routing conflicts
- Access via port-forward if needed

**ArgoCD Sync Drift**:
- Requires explicit field declarations to prevent drift
- Use `ServerSideApply=true` for complex resources

**Cross-Namespace Service Access**:
- Gateway API requires explicit ReferenceGrant
- More complex than traditional Ingress but more secure

**GitHub Actions Runner Controller**:
- Upstream chart v0.13.0 has RBAC bugs (GitHub issue #3160)
- ArgoCD label tracking conflicts with listener pods (use annotation tracking)
- Kubernetes container mode breaks standard workflows (use dind mode)
- dind mode requires privileged PodSecurity (not baseline/restricted)

## Debugging Guide

### Common Issues

1. **Application Won't Sync**
   - **Symptoms**: Stuck in "Progressing" state
   - **Check**: `kubectl describe application <app-name> -n argocd`
   - **Solution**: Usually missing CRDs or namespace issues

2. **Service Not Accessible**
   - **Symptoms**: 404 or connection refused
   - **Check**: `kubectl get endpoints <service> -n <namespace>`
   - **Solution**: Verify service selector matches pod labels

3. **Gateway Routes Not Working**
   - **Symptoms**: 404 on expected paths
   - **Check**: `kubectl describe httproute -n traefik`
   - **Solution**: Verify parentRef matches Gateway name/namespace

4. **LoadBalancer IP Not Assigned**
   - **Symptoms**: Service shows `<pending>` for EXTERNAL-IP
   - **Check**: `kubectl get ipaddresspool -n metallb-system`
   - **Solution**: Verify MetalLB pool has available IPs

5. **Metrics Server Not Working**
   - **Symptoms**: `kubectl top` commands fail with "Metrics API not available"
   - **Check**: `kubectl get pods -n kube-system | grep metrics-server`
   - **Solution**: Verify metrics-server pod is running and has proper TLS configuration

6. **GitHub Actions Runners Not Scaling**
   - **Symptoms**: Workflow jobs stay queued, no runners created
   - **Check**: `kubectl get autoscalingrunnerset -n actions-runner-system`
   - **Check**: `kubectl logs -n actions-runner-system -l app.kubernetes.io/component=runner-scale-set-listener`
   - **Solution**: Verify listener pods running and check controller logs for RBAC errors

7. **Runner Pods Restarting Continuously**
   - **Symptoms**: Listener pods restart every 10-30 seconds
   - **Check**: `kubectl describe configmap argocd-cm -n argocd | grep resourceTrackingMethod`
   - **Solution**: Set `application.resourceTrackingMethod: annotation` in argocd-cm ConfigMap

### Debugging Tools
```bash
# ArgoCD application issues
kubectl logs -n argocd deployment/argocd-application-controller

# Gateway API issues
kubectl get events -n traefik --sort-by='.lastTimestamp'

# Service connectivity
kubectl run debug --image=nicolaka/netshoot -it --rm

# Cloudflare tunnel status
kubectl logs -n cloudflare deployment/cloudflared --tail=50

# Metrics server status
kubectl logs -n kube-system deployment/metrics-server --tail=50

# GitHub Actions runner status
kubectl get autoscalingrunnerset -n actions-runner-system
kubectl get pods -n actions-runner-system
kubectl logs -n actions-runner-system -l app.kubernetes.io/component=runner-scale-set-listener --tail=50
kubectl logs -n actions-runner-system deployment/arc-controller-gha-rs-controller --tail=50

# Watch runner scaling
watch -n 5 'kubectl get pods -n actions-runner-system && echo "---" && kubectl get autoscalingrunnerset -n actions-runner-system'
```

## Monitoring and Observability

### Current Monitoring
- **ArgoCD UI**: Application sync status at `/argocd`
- **Metrics endpoints**: Traefik (9100), Cloudflared (2000)
- **Kubernetes native**: `kubectl top nodes/pods`

### Planned Monitoring
- Prometheus/Grafana stack (removed in simplification)
- Loki for log aggregation
- AlertManager for notifications

## Testing Approach

### Current Validation
- **GitOps validation**: ArgoCD validates all manifests
- **Health checks**: Liveness/readiness probes
- **Resource limits**: Enforced on all workloads
- **Security contexts**: Non-root containers required

### Missing Testing
- No pre-commit YAML validation hooks
- No policy engine (OPA/Kyverno)
- No automated testing pipeline
- No chaos engineering tools

## Resources

### Internal Documentation
- [Bootstrap README](bootstrap/README.md)
- [ArgoCD Manifests](argocd/manifests/README.md)
- [Main Project CLAUDE.md](../CLAUDE.md)

### External Resources
- [Gateway API Documentation](https://gateway-api.sigs.k8s.io/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Traefik Gateway Provider](https://doc.traefik.io/traefik/providers/kubernetes-gateway/)
- [MetalLB Documentation](https://metallb.universe.tf/)

### Key Files
- **Bootstrap**: `bootstrap/argocd.sh` - ArgoCD installation
- **Secrets**: `bootstrap/setup-secrets.sh` - 1Password integration
- **Root App**: `argocd/app-of-apps.yaml` - GitOps entry point
- **Gateway**: `argocd/manifests/gateway/lab-gateway.yaml` - Main gateway

## Maintenance Tasks

### Regular Maintenance
- **Daily**: Check ArgoCD sync status
- **Weekly**: Review resource utilization
- **Monthly**: Update Helm chart versions
- **Quarterly**: Review and update deprecated APIs

### Update Procedures
```bash
# Update ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.11.3/manifests/install.yaml

# Update application versions (edit in Git)
vi argocd/apps/traefik.yaml  # Update targetRevision

# Force sync after updates
kubectl patch application <app> -n argocd --type merge -p '{"operation": {"initiatedBy": {"username": "admin"}, "sync": {"prune": true}}}'
```

## Contributing Guidelines

### Making Changes
1. **Never edit resources directly** - All changes through Git
2. **Test locally first** - Use `kubectl diff` before committing
3. **Follow patterns** - Maintain consistency with existing resources
4. **Document changes** - Update relevant READMEs
5. **Use conventional commits**: `feat:`, `fix:`, `docs:`

### Code Review Checklist
- [ ] Security context defined
- [ ] Resource limits specified
- [ ] Health checks included
- [ ] Labels and annotations consistent
- [ ] No hardcoded secrets
- [ ] ArgoCD application updated if needed
- [ ] Gateway routes tested if added

### Definition of Done
- Resources deployed successfully via ArgoCD
- Health checks passing
- Service accessible as expected
- Documentation updated
- No ArgoCD sync drift

## Evolution Notes

This infrastructure has evolved from simple IngressRoute (2024) to modern Gateway API (2025), with a trend toward operational simplicity. Recent simplification removed complex monitoring stacks in favor of essential services, demonstrating a pragmatic approach to homelab infrastructure management.