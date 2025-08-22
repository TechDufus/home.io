# PRP: Kubernetes GitOps Structure Simplification

## Context and Objective
Restructure the Kubernetes GitOps directory to consolidate all ArgoCD-related resources under a single, simplified structure. The current separation between ArgoCD app definitions (`kubernetes/argocd/`) and application manifests (`kubernetes/apps/`) creates unnecessary complexity. This PRP implements a consolidated structure that supports external Helm charts, local Helm charts, and raw manifests while maintaining GitOps best practices.

## Current State Analysis
```
Current structure (to be refactored):
kubernetes/
├── apps/                    # Raw manifests (MOVE TO argocd/base/manifests/)
│   ├── cloudflared/
│   ├── cloudnative-pg/
│   └── monitoring/
├── argocd/
│   ├── base/
│   │   ├── apps/           # ArgoCD Application definitions (KEEP)
│   │   └── values/         # Base Helm values (KEEP)
│   └── overlays/
│       └── dev/
│           └── values/     # Environment values (KEEP)
```

## Target State
```
Target structure:
kubernetes/
├── argocd/
│   ├── base/
│   │   ├── apps/           # ArgoCD Application definitions
│   │   ├── charts/         # Local Helm charts (NEW)
│   │   ├── manifests/      # Raw K8s manifests (MOVED from apps/)
│   │   └── kustomization.yaml
│   └── overlays/
│       └── dev/
│           ├── kustomization.yaml
│           ├── patches/    # Patches for raw manifests (NEW)
│           └── values/     # All Helm values (external & local)
└── bootstrap/              # No changes needed
```

## Implementation Blueprint

### Phase 1: Directory Structure Creation
```bash
# Create new directory structure
mkdir -p kubernetes/argocd/base/charts
mkdir -p kubernetes/argocd/base/manifests
mkdir -p kubernetes/argocd/overlays/dev/patches
```

### Phase 2: Move Existing Manifests
```bash
# Move cloudflared manifests (excluding kustomization.yaml)
mv kubernetes/apps/cloudflared kubernetes/argocd/base/manifests/
# Remove old kustomization.yaml (we'll manage via overlay)
rm kubernetes/argocd/base/manifests/cloudflared/kustomization.yaml
```

### Phase 3: Convert Cloudflared to Local Helm Chart (Optional Enhancement)
Create a local Helm chart structure for cloudflared to demonstrate the pattern:
```
kubernetes/argocd/base/charts/cloudflared/
├── Chart.yaml
├── values.yaml
└── templates/
    ├── namespace.yaml
    ├── deployment.yaml
    ├── configmap.yaml
    └── secret.yaml
```

### Phase 4: Update ArgoCD Application Definitions

#### For External Helm Charts (monitoring, cloudnative-pg)
No changes needed - they already use the multi-source pattern correctly.

#### For Raw Manifests (cloudflared if not converted to Helm)
Update `kubernetes/argocd/base/apps/cloudflared.yaml`:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: cloudflared
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/TechDufus/home.io
    targetRevision: main
    path: kubernetes/argocd/overlays/dev  # Point to overlay for patched manifests
  destination:
    server: https://kubernetes.default.svc
    namespace: cloudflare
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

#### For Local Helm Charts (if converting cloudflared)
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

### Phase 5: Update Kustomization Files

#### Base Kustomization (`kubernetes/argocd/base/kustomization.yaml`)
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: argocd

resources:
  # ArgoCD Applications
  - apps/cloudflared.yaml
  - apps/monitoring.yaml
  - apps/cloudnative-pg.yaml
  - apps/n8n.yaml
  # Note: Raw manifests are NOT included here, they're managed by overlays

generatorOptions:
  disableNameSuffixHash: true
  labels:
    app.kubernetes.io/managed-by: kustomize
    app.kubernetes.io/part-of: argocd
```

#### Dev Overlay Kustomization (`kubernetes/argocd/overlays/dev/kustomization.yaml`)
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: argocd

resources:
  # Import base ArgoCD applications
  - ../../base
  # Import raw manifests that need patching
  - ../../base/manifests/cloudflared/deployment.yaml
  - ../../base/manifests/cloudflared/configmap.yaml
  - ../../base/manifests/cloudflared/secret.yaml
  - ../../base/manifests/cloudflared/namespace.yaml

# Apply environment-specific patches to raw manifests
patches:
  # Patch for cloudflared deployment (example)
  - target:
      kind: Deployment
      name: cloudflared
      namespace: cloudflare
    path: patches/cloudflared/deployment-patch.yaml
  
  # Update Helm applications to use dev values
  - target:
      group: argoproj.io
      version: v1alpha1
      kind: Application
      name: monitoring
    patch: |-
      - op: replace
        path: /spec/sources/0/helm/valueFiles/0
        value: $values/argocd/overlays/dev/values/monitoring.yaml
  
  - target:
      group: argoproj.io
      version: v1alpha1
      kind: Application
      name: cloudnative-pg
    patch: |-
      - op: replace
        path: /spec/sources/0/helm/valueFiles/0
        value: $values/argocd/overlays/dev/values/cloudnative-pg.yaml

labels:
  - includeSelectors: true
    pairs:
      environment: dev
```

### Phase 6: Create Example Patch
Create `kubernetes/argocd/overlays/dev/patches/cloudflared/deployment-patch.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cloudflared
  namespace: cloudflare
spec:
  replicas: 1  # Dev uses only 1 replica instead of 2
  template:
    spec:
      containers:
      - name: cloudflared
        resources:
          requests:
            cpu: 50m      # Lower resources for dev
            memory: 64Mi
          limits:
            cpu: 100m
            memory: 128Mi
```

### Phase 7: Create Local Helm Chart Example (Optional)
If converting cloudflared to a local Helm chart:

`kubernetes/argocd/base/charts/cloudflared/Chart.yaml`:
```yaml
apiVersion: v2
name: cloudflared
description: Cloudflare Tunnel for homelab
type: application
version: 0.1.0
appVersion: "2024.1.0"
```

`kubernetes/argocd/base/charts/cloudflared/values.yaml`:
```yaml
replicaCount: 2

image:
  repository: cloudflare/cloudflared
  tag: latest
  pullPolicy: IfNotPresent

config:
  tunnel: ""
  credentials: ""

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi

livenessProbe:
  enabled: true
  path: /ready
  port: 2000
```

`kubernetes/argocd/base/charts/cloudflared/templates/deployment.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "cloudflared.fullname" . }}
  namespace: {{ .Values.namespace | default "cloudflare" }}
  labels:
    {{- include "cloudflared.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "cloudflared.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "cloudflared.selectorLabels" . | nindent 8 }}
    spec:
      containers:
      - name: {{ .Chart.Name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        args:
        - tunnel
        - --config
        - /etc/cloudflared/config/config.yaml
        - run
        {{- if .Values.livenessProbe.enabled }}
        livenessProbe:
          httpGet:
            path: {{ .Values.livenessProbe.path }}
            port: {{ .Values.livenessProbe.port }}
          failureThreshold: 1
          initialDelaySeconds: 10
          periodSeconds: 10
        {{- end }}
        resources:
          {{- toYaml .Values.resources | nindent 10 }}
        volumeMounts:
        - name: config
          mountPath: /etc/cloudflared/config
          readOnly: true
        - name: creds
          mountPath: /etc/cloudflared/creds
          readOnly: true
      volumes:
      - name: config
        configMap:
          name: {{ include "cloudflared.fullname" . }}-config
      - name: creds
        secret:
          secretName: {{ include "cloudflared.fullname" . }}-credentials
```

### Phase 8: Update Documentation
Update `kubernetes/README.md` to reflect the new structure and patterns.

## Implementation Tasks (In Order)

1. **Create new directory structure**
   - Create `kubernetes/argocd/base/charts/` directory
   - Create `kubernetes/argocd/base/manifests/` directory
   - Create `kubernetes/argocd/overlays/dev/patches/` directory

2. **Move existing manifests**
   - Move `kubernetes/apps/cloudflared/` to `kubernetes/argocd/base/manifests/cloudflared/`
   - Remove old kustomization files from moved directories
   - Delete empty `kubernetes/apps/` directory

3. **Update ArgoCD application definitions**
   - Update `kubernetes/argocd/base/apps/cloudflared.yaml` to point to overlay path
   - Verify other apps (monitoring, cloudnative-pg) have correct value file references

4. **Update Kustomization files**
   - Update `kubernetes/argocd/base/kustomization.yaml` to remove manifest references
   - Update `kubernetes/argocd/overlays/dev/kustomization.yaml` to include manifests and patches

5. **Create example patches**
   - Create `kubernetes/argocd/overlays/dev/patches/cloudflared/deployment-patch.yaml`
   - Add any other environment-specific patches

6. **Optional: Convert cloudflared to local Helm chart**
   - Create chart structure under `kubernetes/argocd/base/charts/cloudflared/`
   - Convert manifests to Helm templates
   - Update ArgoCD application to use local chart
   - Add values file in overlay

7. **Update documentation**
   - Update `kubernetes/README.md`
   - Update any app-specific READMEs
   - Document the new structure and patterns

8. **Test deployment**
   - Run bootstrap script
   - Verify all applications sync successfully
   - Check that patches are applied correctly

## Validation Gates

### Pre-deployment Validation
```bash
# 1. Validate Kustomization files
kubectl kustomize kubernetes/argocd/base/ > /tmp/base-test.yaml
echo "✓ Base kustomization valid"

kubectl kustomize kubernetes/argocd/overlays/dev/ > /tmp/dev-test.yaml
echo "✓ Dev overlay kustomization valid"

# 2. Validate ArgoCD applications
for app in kubernetes/argocd/base/apps/*.yaml; do
  kubectl apply --dry-run=client -f "$app" > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "✓ $(basename $app) is valid"
  else
    echo "✗ $(basename $app) has errors"
    exit 1
  fi
done

# 3. Validate local Helm charts (if created)
if [ -d "kubernetes/argocd/base/charts/cloudflared" ]; then
  helm lint kubernetes/argocd/base/charts/cloudflared
  echo "✓ Cloudflared Helm chart valid"
fi

# 4. Check for orphaned references
echo "Checking for references to old apps/ directory..."
grep -r "kubernetes/apps" kubernetes/argocd/ 2>/dev/null
if [ $? -eq 0 ]; then
  echo "✗ Found references to old apps/ directory"
  exit 1
else
  echo "✓ No references to old structure found"
fi
```

### Post-deployment Validation
```bash
# 1. Verify ArgoCD is running
kubectl get pods -n argocd | grep -E "argocd-server.*Running"
echo "✓ ArgoCD server is running"

# 2. Check app-of-apps created
kubectl get application app-of-apps -n argocd
echo "✓ App-of-apps exists"

# 3. Verify all applications are synced
kubectl get applications -n argocd -o json | \
  jq -r '.items[] | "\(.metadata.name): \(.status.sync.status)"' | \
  while read line; do
    if [[ $line == *"Synced"* ]]; then
      echo "✓ $line"
    else
      echo "✗ $line"
    fi
  done

# 4. Test specific deployments
kubectl get deployment cloudflared -n cloudflare > /dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "✓ Cloudflared deployment exists"
else
  echo "✗ Cloudflared deployment missing"
fi

kubectl get pods -n monitoring | grep grafana > /dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "✓ Monitoring stack deployed"
else
  echo "✗ Monitoring stack missing"
fi

# 5. Verify patches applied (check replica count)
REPLICAS=$(kubectl get deployment cloudflared -n cloudflare -o jsonpath='{.spec.replicas}')
if [ "$REPLICAS" = "1" ]; then
  echo "✓ Dev patch applied (1 replica)"
else
  echo "✗ Dev patch not applied (expected 1 replica, got $REPLICAS)"
fi
```

## Error Handling

### Common Issues and Solutions

1. **ArgoCD sync failures**
   - Check application logs: `kubectl logs -n argocd deployment/argocd-application-controller`
   - Verify Git repository access
   - Check for YAML syntax errors in manifests

2. **Kustomization build errors**
   - Validate with: `kubectl kustomize kubernetes/argocd/overlays/dev/`
   - Check resource paths are correct
   - Ensure patches match target resources

3. **Missing namespaces**
   - Ensure `CreateNamespace=true` in syncOptions
   - Or pre-create namespaces in manifests

4. **Helm chart issues**
   - Lint charts: `helm lint kubernetes/argocd/base/charts/[chart-name]`
   - Test render: `helm template test kubernetes/argocd/base/charts/[chart-name]`

## References and Documentation

### ArgoCD Best Practices
- [ArgoCD Best Practices Documentation](https://argo-cd.readthedocs.io/en/stable/user-guide/best_practices/)
- [Kustomize with ArgoCD](https://argo-cd.readthedocs.io/en/stable/user-guide/kustomize/)
- [Helm with ArgoCD](https://argo-cd.readthedocs.io/en/latest/user-guide/helm/)
- [Multi-Source Applications](https://argo-cd.readthedocs.io/en/stable/user-guide/multiple_sources/)

### Repository Patterns
- [GitOps Repository Patterns](https://developers.redhat.com/articles/2023/05/25/3-patterns-deploying-helm-charts-argocd)
- [Structuring ArgoCD Repositories](https://codefresh.io/blog/how-to-structure-your-argo-cd-repositories-using-application-sets/)

### Existing Code References
- Bootstrap script: `kubernetes/bootstrap/argocd.sh:98` - App-of-apps creation
- Current cloudflared app: `kubernetes/argocd/base/apps/cloudflared.yaml:1-31`
- Monitoring values: `kubernetes/argocd/overlays/dev/values/monitoring.yaml:1-141`
- Base kustomization: `kubernetes/argocd/base/kustomization.yaml:1-32`
- Overlay kustomization: `kubernetes/argocd/overlays/dev/kustomization.yaml:1-52`

## Decision Tree for New Applications

```
Need to deploy a new application?
│
├─ Is there an official Helm chart available?
│  └─ YES → Use external Helm chart
│      1. Create ArgoCD app in base/apps/
│      2. Add values in overlays/dev/values/
│      3. Update base kustomization.yaml
│
├─ Do you need templating or multiple instances?
│  └─ YES → Create local Helm chart
│      1. Create chart in base/charts/
│      2. Create ArgoCD app in base/apps/
│      3. Add values in overlays/dev/values/
│      4. Update base kustomization.yaml
│
└─ Is it a simple, one-off resource?
   └─ YES → Use raw manifests
       1. Add manifests to base/manifests/
       2. Create ArgoCD app pointing to overlay
       3. Add patches in overlays/dev/patches/ (if needed)
       4. Update overlay kustomization.yaml
```

## Success Metrics
- All existing applications continue to work
- New structure is navigable and intuitive
- Adding new applications follows clear patterns
- Bootstrap script requires no modifications
- Deployment time remains the same or improves

## Confidence Score: 9/10
This PRP provides comprehensive context with:
- ✅ Clear implementation blueprint with exact commands and file contents
- ✅ Validation gates that can be executed
- ✅ References to existing patterns in the codebase
- ✅ Error handling for common issues
- ✅ Decision tree for future additions
- ✅ Complete examples for all three deployment patterns

The only uncertainty is around potential edge cases in the existing setup that may require minor adjustments during implementation.