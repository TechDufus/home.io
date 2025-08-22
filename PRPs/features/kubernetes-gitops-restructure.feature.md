# Feature: Kubernetes GitOps Structure Simplification

## Overview
Restructure the Kubernetes GitOps directory to consolidate all ArgoCD-related resources in a single, simplified structure. Currently, the separation between ArgoCD app definitions (`kubernetes/argocd/`) and application manifests (`kubernetes/apps/`) creates unnecessary complexity for a homelab environment. This feature consolidates everything under the ArgoCD directory while maintaining GitOps best practices with base/overlay patterns.

## Problem Statement
The current structure splits related components across multiple directory trees:
- ArgoCD app definitions live in `kubernetes/argocd/base/apps/`
- Raw Kubernetes manifests live in `kubernetes/apps/`
- Helm values live in `kubernetes/argocd/overlays/dev/values/`

This separation makes it difficult to:
- Understand where to add new applications
- Manage environment-specific patches consistently
- Navigate between related files
- Maintain a simple homelab setup

## Users/Stakeholders
- **Primary User**: Homelab operator (single developer/maintainer)
- **Secondary Benefits**: 
  - Future employers reviewing GitOps competency
  - Community members referencing the setup

## Requirements

### Functional
- Consolidate all ArgoCD-managed resources under `kubernetes/argocd/`
- Support both Helm charts and raw Kubernetes manifests
- Maintain base/overlay pattern for environment management
- Preserve GitOps workflow: commit → ArgoCD sync → deployment
- Bootstrap script continues to work with minimal changes
- Support Kustomize-based patching in overlays

### Non-Functional
- **Simplicity**: Reduce cognitive load for homelab management
- **Maintainability**: Single location for all GitOps resources
- **Flexibility**: Easy to add new applications (Helm or manifests)
- **Learning**: Demonstrate enterprise patterns in simplified form
- **Performance**: No impact on ArgoCD sync times

## Technical Specification

### Architecture
New directory structure:
```
kubernetes/
├── argocd/
│   ├── base/
│   │   ├── apps/              # ArgoCD Application definitions
│   │   │   ├── cloudflared.yaml
│   │   │   ├── monitoring.yaml
│   │   │   └── cloudnative-pg.yaml
│   │   ├── charts/            # Custom Helm charts (local)
│   │   │   └── cloudflared/   # Example: cloudflared as Helm chart
│   │   │       ├── Chart.yaml
│   │   │       ├── values.yaml
│   │   │       └── templates/
│   │   │           ├── deployment.yaml
│   │   │           ├── configmap.yaml
│   │   │           ├── secret.yaml
│   │   │           └── namespace.yaml
│   │   ├── manifests/         # Raw K8s manifests (when Helm is overkill)
│   │   │   └── simple-job/
│   │   │       └── job.yaml
│   │   ├── values/            # Default Helm values (if any)
│   │   └── kustomization.yaml
│   └── overlays/
│       └── dev/
│           ├── kustomization.yaml    # Imports base, applies patches
│           ├── patches/              # Patches for raw manifests only
│           │   └── simple-job/
│           │       └── job-patch.yaml
│           └── values/               # Environment-specific Helm values
│               ├── monitoring.yaml   # External chart values
│               ├── cloudnative-pg.yaml
│               └── cloudflared.yaml  # Local chart values
├── bootstrap/                        # Unchanged
│   ├── argocd.sh
│   └── setup-secrets.sh
└── README.md                         # Updated with new structure
```

### Dependencies
- **External**: None (uses existing tools)
- **Internal**: 
  - ArgoCD v2.11.3+ (already in use)
  - Kustomize (built into kubectl)
  - Helm (for chart deployments)

### Data Model
Not applicable - configuration only

### API Design
Not applicable - GitOps declarative configuration

## Implementation Notes

### Patterns to Follow
1. **ArgoCD App Definitions** (`base/apps/*.yaml`):
   - External Helm apps point to chart repos + values files
   - Local Helm charts point to `base/charts/` directory
   - Raw manifest apps point to overlay path (gets patched version)
   - All use automated sync with prune and self-heal

2. **Custom Helm Charts** (`base/charts/`):
   - Create when templating provides value (multiple environments, instances)
   - Follow standard Helm chart structure
   - Use for apps that need frequent value changes
   - Simpler than maintaining multiple manifest patches

3. **Raw Manifests** (`base/manifests/`):
   - Use for simple, one-off resources
   - Base versions without environment specifics
   - When Helm would be overkill (single ConfigMap, Job, etc.)

4. **Overlay Structure** (`overlays/dev/`):
   - Main kustomization.yaml imports all base apps
   - Patches directory for raw manifest modifications only
   - Values directory for ALL Helm overrides (external and local charts)

5. **Application Type Decision Tree**:
   ```
   Need to deploy an app?
   ├── Is there an official Helm chart? → Use external Helm chart
   ├── Do you need templating/multiple instances? → Create local Helm chart
   └── Simple one-off manifest? → Use raw manifests
   ```

6. **Application Types**:
   ```yaml
   # External Helm Application
   spec:
     sources:
       - chart: prometheus-stack
         repoURL: https://prometheus-community.github.io/helm-charts
         targetRevision: "60.0.0"
         helm:
           valueFiles:
             - $values/argocd/overlays/dev/values/monitoring.yaml
       - repoURL: https://github.com/TechDufus/home.io
         targetRevision: main
         ref: values
   
   # Local Helm Chart Application
   spec:
     sources:
       - repoURL: https://github.com/TechDufus/home.io
         targetRevision: main
         path: kubernetes/argocd/base/charts/cloudflared
         helm:
           valueFiles:
             - $values/argocd/overlays/dev/values/cloudflared.yaml
       - repoURL: https://github.com/TechDufus/home.io
         targetRevision: main
         ref: values
   
   # Raw Manifest Application
   spec:
     source:
       repoURL: https://github.com/TechDufus/home.io
       targetRevision: main
       path: kubernetes/argocd/overlays/dev
       # Kustomize will handle the manifest inclusion
   ```

### Testing Strategy
- **Manual Validation**: 
  - Deploy to dev cluster
  - Verify all apps sync successfully
  - Test adding new app (both Helm and manifest)
- **GitOps Testing**: 
  - Make change, commit, verify ArgoCD syncs
  - Test rollback via Git revert

## Success Criteria
- [x] All ArgoCD resources in single directory tree
- [x] Bootstrap script works without modification
- [x] Existing apps (cloudflared, monitoring, cloudnative-pg) deploy successfully
- [x] Adding new external Helm app requires only 2 files (app definition + values)
- [x] Adding new local Helm chart follows standard Helm structure
- [x] Adding new manifest app requires manifests + app definition
- [x] Environment patches apply correctly via Kustomize
- [x] Local Helm charts work with value overrides
- [x] Directory navigation is intuitive
- [x] README accurately reflects new structure

## Out of Scope
- Multi-environment support beyond dev (can be added later)
- CI/CD pipeline integration
- Automated testing framework
- Secret management changes (keep using 1Password)
- CAPI or infrastructure provisioning
- ArgoCD installation method changes
- ApplicationSets or other advanced ArgoCD features

## Future Considerations
- Add production overlay when needed
- Consider ApplicationSets for multi-cluster deployments
- Potential Helm chart for entire homelab stack
- Integration with Renovate for dependency updates
- ArgoCD Image Updater for automatic container updates

## Examples

### Adding an External Helm Application (n8n)
1. Create ArgoCD app: `kubernetes/argocd/base/apps/n8n.yaml`
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: n8n
  namespace: argocd
spec:
  project: default
  sources:
    - chart: n8n
      repoURL: https://8gears.container-registry.com/chartrepo/library
      targetRevision: "0.23.0"
      helm:
        valueFiles:
          - $values/argocd/overlays/dev/values/n8n.yaml
    - repoURL: https://github.com/TechDufus/home.io
      targetRevision: main
      ref: values
  destination:
    server: https://kubernetes.default.svc
    namespace: n8n
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

2. Add values: `kubernetes/argocd/overlays/dev/values/n8n.yaml`
```yaml
persistence:
  enabled: true
  size: 10Gi
ingress:
  enabled: false  # Using Gateway API instead
```

3. Update base kustomization: Add to `kubernetes/argocd/base/kustomization.yaml`
```yaml
resources:
  - apps/n8n.yaml
```

### Creating a Local Helm Chart (cloudflared)
1. Create chart structure: `kubernetes/argocd/base/charts/cloudflared/`
```yaml
# Chart.yaml
apiVersion: v2
name: cloudflared
description: Cloudflare Tunnel for homelab
version: 0.1.0
appVersion: "2024.1.0"

# values.yaml
replicaCount: 1
image:
  repository: cloudflare/cloudflared
  tag: "2024.1.0"
tunnel:
  token: ""  # Override in environment values
resources:
  limits:
    memory: 128Mi
  requests:
    memory: 64Mi
```

2. Create templates: `kubernetes/argocd/base/charts/cloudflared/templates/`
```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}
spec:
  replicas: {{ .Values.replicaCount }}
  template:
    spec:
      containers:
      - name: cloudflared
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        args: ["tunnel", "run", "--token", "{{ .Values.tunnel.token }}"]
        resources:
          {{- toYaml .Values.resources | nindent 10 }}
```

3. Create ArgoCD app: `kubernetes/argocd/base/apps/cloudflared.yaml`
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: cloudflared
  namespace: argocd
spec:
  project: default
  sources:
    - repoURL: https://github.com/TechDufus/home.io
      targetRevision: main
      path: kubernetes/argocd/base/charts/cloudflared
      helm:
        valueFiles:
          - $values/argocd/overlays/dev/values/cloudflared.yaml
    - repoURL: https://github.com/TechDufus/home.io
      targetRevision: main
      ref: values
  destination:
    server: https://kubernetes.default.svc
    namespace: cloudflare
```

4. Add environment values: `kubernetes/argocd/overlays/dev/values/cloudflared.yaml`
```yaml
replicaCount: 2  # Dev environment uses 2 replicas
tunnel:
  token: "secret-token-from-1password"
```

### Adding a Raw Manifest Application (simple-job)
1. Add manifest: `kubernetes/argocd/base/manifests/simple-job/job.yaml`
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: database-backup
spec:
  template:
    spec:
      containers:
      - name: backup
        image: postgres:15
        command: ["pg_dump"]
      restartPolicy: OnFailure
```

2. Create ArgoCD app pointing to overlay
3. Add patch if needed: `kubernetes/argocd/overlays/dev/patches/simple-job/job-patch.yaml`
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: database-backup
spec:
  schedule: "0 2 * * *"  # Dev runs at 2 AM
```

4. Update overlay kustomization to include manifests

## References
- Current implementation: `kubernetes/` directory
- ArgoCD documentation: https://argo-cd.readthedocs.io/
- Kustomize documentation: https://kustomize.io/
- Similar homelab examples: k8s-at-home community patterns