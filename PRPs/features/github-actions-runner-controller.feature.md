# Feature: GitHub Actions Runner Controller

## Overview
Deploy the GitHub Actions Runner Controller (ARC) to the homelab Kubernetes cluster via ArgoCD, enabling self-hosted GitHub Actions runners that can build and deploy container images within the cluster. This provides infrastructure for CI/CD workflows in public GitHub repositories while maintaining control over the build environment and enabling potential self-deployment capabilities in the future.

## Problem Statement
Currently, GitHub Actions workflows for public repositories run on GitHub-hosted runners, which:
- Cannot access internal homelab resources
- Lack persistent caching for faster builds
- Incur costs at scale
- Cannot leverage homelab compute resources
- Cannot be customized with specific tooling

Self-hosted runners in the Kubernetes cluster solve these issues while providing auto-scaling capabilities and ephemeral runner instances for security.

## Users/Stakeholders
- **Primary**: Matthew DeGarmo (repository maintainer)
- **Secondary**: Public GitHub repository contributors
- **System**: Kubernetes cluster workloads that may require self-deployment

## Requirements

### Functional
- Deploy ARC controller and runner scale sets via ArgoCD
- Authenticate to GitHub using Personal Access Token (initial implementation)
- Provide organization-level runners for personal GitHub account
- Auto-scale runners from 0 (idle) to 1 (max concurrent, resource-constrained)
- Allocate standard resources per runner (2 CPU, 4GB RAM)
- Integrate with existing MetalLB and Gateway API infrastructure
- Store secrets securely via 1Password
- Follow GitOps patterns consistent with existing infrastructure

### Non-Functional
- **Performance**: Runners must start within 60 seconds of workflow trigger
- **Security**:
  - No hardcoded credentials
  - PAT stored in 1Password
  - Runners run as non-root
  - Ephemeral runners (one-time use)
- **Scalability**: Scale from 0 to 1 runner automatically
- **Reliability**: Auto-heal via ArgoCD, retry on failures
- **Maintainability**: Manual updates only (no self-deployment initially)

## Technical Specification

### Architecture
```
GitHub Actions Workflow Trigger
    ↓
GitHub API notifies ARC Controller
    ↓
ARC Controller (in cluster)
    ↓
Runner Scale Set creates Runner Pod
    ↓
Runner Pod pulls workflow job
    ↓
Executes job, reports back to GitHub
    ↓
Runner Pod terminates (ephemeral)
```

**Integration Points**:
- ArgoCD: GitOps deployment and lifecycle management
- 1Password: Secret storage for GitHub PAT
- MetalLB: LoadBalancer IPs (if webhook receiver needed)
- Gateway API: Potential future webhook ingress
- Local Path Provisioner: Temporary storage for runner workspaces

### Dependencies

**External**:
- Helm chart: `actions-runner-controller/actions-runner-controller`
- Chart repository: `https://actions.github.io/actions-runner-controller`
- Latest stable version: TBD (check at implementation time)
- GitHub Personal Access Token (Classic) with `admin:org` scope (for org-level runners)

**Internal**:
- ArgoCD (already deployed)
- MetalLB (already deployed)
- Local Path Provisioner (already deployed)
- 1Password CLI (`op`) for secret management

### Data Model

**Kubernetes Resources**:
```yaml
Namespace: actions-runner-system
ConfigMap: runner-config (non-sensitive settings)
Secret: github-token (PAT from 1Password)
Deployment: actions-runner-controller
RunnerDeployment: github-runner-scaler
HorizontalRunnerAutoscaler: github-runner-autoscaler
```

**1Password Structure**:
```
Vault: Personal
Item: Github
Field: github-actions-runner-controller-organization
Value: <GitHub PAT Classic with admin:org scope>
```

### API Design
Not applicable - no external APIs exposed. Internal communication via Kubernetes API and GitHub API.

## Implementation Notes

### Patterns to Follow

**ArgoCD Application Pattern** (reference: `kubernetes/argocd/apps/platform/metallb.yaml:1-37`):
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: actions-runner-controller
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  sources:
    - chart: actions-runner-controller
      repoURL: https://actions.github.io/actions-runner-controller
      targetRevision: "0.x.x"  # Latest stable
      helm:
        releaseName: actions-runner-controller
        valueFiles:
          - $values/kubernetes/argocd/values/actions-runner-controller.yaml
    - repoURL: https://github.com/TechDufus/home.io
      targetRevision: main
      ref: values
  destination:
    server: https://kubernetes.default.svc
    namespace: actions-runner-system
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
      - ServerSideApply=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
  revisionHistoryLimit: 10
```

**Resource Constraints Pattern** (reference: `kubernetes/argocd/values/metallb.yaml:8-14`):
```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

**Security Context Pattern** (from CLAUDE.md):
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

**Secret Management Pattern** (reference: bootstrap/setup-secrets.sh approach):
```bash
# Retrieve PAT from 1Password
GITHUB_TOKEN=$(op item get Github --vault "Personal" --field label=github-actions-runner-controller-organization --reveal)

# Create Kubernetes secret
kubectl create secret generic github-token \
  --namespace actions-runner-system \
  --from-literal=token="${GITHUB_TOKEN}" \
  --dry-run=client -o yaml | kubectl apply -f -
```

### File Structure
```
kubernetes/argocd/
├── apps/
│   └── platform/
│       └── actions-runner-controller.yaml    # ArgoCD Application
├── values/
│   └── actions-runner-controller.yaml        # Helm values
└── manifests/
    └── actions-runner-system/
        ├── namespace.yaml                     # Namespace definition
        └── runner-deployment.yaml             # RunnerDeployment CRD
```

### Testing Strategy

**Unit Testing**:
- Not applicable - infrastructure deployment

**Integration Testing**:
```bash
# 1. Verify ArgoCD application sync
kubectl get application actions-runner-controller -n argocd

# 2. Verify controller deployment
kubectl get pods -n actions-runner-system

# 3. Verify runner scale set
kubectl get runnerdeployment -n actions-runner-system

# 4. Check controller logs
kubectl logs -n actions-runner-system deployment/actions-runner-controller-controller-manager

# 5. Verify GitHub registration
# Check GitHub Settings > Actions > Runners for registered runners
```

**E2E Testing**:
1. Create test workflow in repository:
   ```yaml
   name: Test Self-Hosted Runner
   on: [push]
   jobs:
     test:
       runs-on: self-hosted
       steps:
         - run: echo "Running on self-hosted runner"
         - run: kubectl version  # Verify cluster access
   ```
2. Trigger workflow
3. Verify runner pod creation
4. Verify workflow success
5. Verify runner pod termination

## Success Criteria
- [ ] ArgoCD application deploys successfully without manual intervention
- [ ] Controller pod reaches Ready state
- [ ] GitHub recognizes registered runners (visible in GitHub UI)
- [ ] Test workflow executes successfully on self-hosted runner
- [ ] Runner pods auto-scale from 0 → 1 → 0 after job completion
- [ ] Second workflow queues when runner at max capacity (1)
- [ ] PAT stored securely in 1Password, not in Git
- [ ] Controller auto-heals if pods fail (ArgoCD self-heal)
- [ ] Resource limits prevent runaway resource consumption
- [ ] Documentation added to kubernetes/CLAUDE.md

## Out of Scope
- Self-deployment capabilities (manual updates only for initial implementation)
- GitHub App authentication (using PAT for simplicity)
- Enterprise or multi-org support (personal account only)
- Webhook receiver deployment (GitHub API polling sufficient)
- Custom runner images (use default images initially)
- Dind (Docker-in-Docker) for container builds (evaluate later)
- Runner metrics and monitoring (Prometheus/Grafana not yet deployed)
- Runner node affinity/taints (any node acceptable initially)

## Future Considerations

### Phase 2 Enhancements
- **Self-deployment**:
  - Grant runner ServiceAccount RBAC to ArgoCD
  - Create workflow that updates ArgoCD manifests
  - Test with canary deployments
- **GitHub App authentication**: More secure, better permission model
- **Custom runner images**: Pre-install common tools (Docker, kubectl, Helm)
- **Webhook receiver**: Faster response than API polling
- **Persistent cache volumes**: Speed up builds with shared caches
- **Runner node affinity**: Dedicate specific nodes for runners

### Integration Opportunities
- **Image registry**: Deploy Harbor for local image storage
- **CI/CD pipelines**: Build/test/deploy other homelab services
- **Infrastructure updates**: Runners update Terraform/Ansible
- **Backup workflows**: Automate etcd/PVC backups

## Examples

### Helm Values File
```yaml
# kubernetes/argocd/values/actions-runner-controller.yaml
authSecret:
  create: false
  name: github-token

githubWebhookServer:
  enabled: false  # Use polling for simplicity

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 128Mi

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

### Runner Deployment Manifest
```yaml
# kubernetes/argocd/manifests/actions-runner-system/runner-deployment.yaml
apiVersion: actions.summerwind.dev/v1alpha1
kind: RunnerDeployment
metadata:
  name: github-runner
  namespace: actions-runner-system
spec:
  replicas: 1
  template:
    spec:
      organization: <GITHUB_USERNAME>  # Replace with actual username
      labels:
        - self-hosted
        - linux
        - kubernetes
      resources:
        requests:
          cpu: 2000m
          memory: 4Gi
        limits:
          cpu: 2000m
          memory: 4Gi
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
---
apiVersion: actions.summerwind.dev/v1alpha1
kind: HorizontalRunnerAutoscaler
metadata:
  name: github-runner-autoscaler
  namespace: actions-runner-system
spec:
  scaleTargetRef:
    name: github-runner
  minReplicas: 0
  maxReplicas: 1
  scaleUpTriggers:
    - githubEvent:
        workflowJob: {}
      duration: 5m
```

### Secret Setup Integration

GitHub Actions Runner Controller secrets are integrated into the consolidated secret management script:
`kubernetes/bootstrap/setup-secrets.sh`

**To bootstrap all secrets (including ARC):**
```bash
cd kubernetes/bootstrap
./setup-secrets.sh dev
```

**What the script does for ARC:**
1. Retrieves PAT from 1Password: `Personal/Github/github-actions-runner-controller-organization`
2. Creates `actions-runner-system` namespace
3. Creates `github-token` secret with `github_token` key
4. Updates `<GITHUB_USERNAME>` to "TechDufus" in values file (if exists)
5. Strips trailing newlines from PAT (critical for authentication)

**ARC-specific function in setup-secrets.sh:**
```bash
setup_github_actions_runner_secrets() {
    # Retrieves PAT from 1Password
    # Creates kubernetes secret
    # Updates GitHub username placeholder
    # Handles errors gracefully
}
```

### GitHub Workflow Example
```yaml
# .github/workflows/build-and-deploy.yml
name: Build and Deploy Image

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: self-hosted
    steps:
      - uses: actions/checkout@v4

      - name: Build container image
        run: |
          docker build -t my-app:${{ github.sha }} .

      - name: Deploy to cluster
        run: |
          kubectl set image deployment/my-app \
            my-app=my-app:${{ github.sha }} \
            -n applications
```

## References
- [Actions Runner Controller GitHub](https://github.com/actions/actions-runner-controller)
- [ARC Documentation](https://github.com/actions/actions-runner-controller/blob/master/docs/README.md)
- [GitHub Actions Self-Hosted Runners](https://docs.github.com/en/actions/hosting-your-own-runners)
- [Kubernetes RBAC for Self-Deployment](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- Existing patterns: `kubernetes/argocd/apps/platform/metallb.yaml`
- Existing patterns: `kubernetes/argocd/values/metallb.yaml`
- Security patterns: `kubernetes/CLAUDE.md` lines 250-258
