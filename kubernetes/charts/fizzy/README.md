# Fizzy Helm Chart

A Helm chart for deploying [Fizzy](https://github.com/basecamp/fizzy) - Basecamp's self-hostable Kanban board.

## Overview

Fizzy is a Kanban-style tracking application by 37signals (Basecamp). This chart provides:

- Fizzy deployment with SQLite persistence
- Optional in-cluster image building via Kaniko (no official Docker image exists)
- Optional Gateway API HTTPRoute for external access
- Configurable probes, resources, and security contexts

## Prerequisites

- Kubernetes 1.28+
- Helm 3.x
- A container image of Fizzy (see [Image Building](#image-building))
- A Kubernetes secret containing `SECRET_KEY_BASE`

## Installation

### Quick Start

```bash
# Create the namespace
kubectl create namespace fizzy

# Create the required secret
kubectl create secret generic fizzy-secrets \
  --from-literal=SECRET_KEY_BASE=$(openssl rand -hex 64) \
  -n fizzy

# Install the chart
helm install fizzy ./charts/fizzy -n fizzy
```

### With Custom Values

```bash
helm install fizzy ./charts/fizzy -n fizzy -f my-values.yaml
```

## Image Building

**Important**: Basecamp does not publish official Docker images for Fizzy. You have several options:

### Option 1: In-Cluster Building (Recommended for Homelab)

This chart includes Kaniko-based image building. Enable it in your values:

```yaml
imageBuilder:
  enabled: true
  gitRepo: "github.com/basecamp/fizzy.git"
  gitRef: "refs/heads/main"
  registry: "your-registry.local:5000"
  insecure: true  # For in-cluster registries without TLS

  initialBuild:
    enabled: true  # Build on install

  cronJob:
    enabled: true
    schedule: "0 3 * * 0"  # Weekly rebuilds
```

**Requires**: An accessible container registry (e.g., in-cluster registry, Harbor, or cloud registry)

### Option 2: Pre-built Image

Build and push the image yourself:

```bash
git clone https://github.com/basecamp/fizzy.git
cd fizzy
docker build -t your-registry/fizzy:latest .
docker push your-registry/fizzy:latest
```

Then configure the chart:

```yaml
image:
  repository: your-registry/fizzy
  tag: latest

imageBuilder:
  enabled: false
```

### Option 3: GitHub Actions

Set up a GitHub Actions workflow in your own repo to build and push the image on a schedule.

## Configuration

### Key Values

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Image repository | `registry.registry.svc.cluster.local:5000/fizzy` |
| `image.tag` | Image tag | `latest` |
| `fizzy.secret.existingSecret` | Secret name for SECRET_KEY_BASE | `fizzy-secrets` |
| `persistence.enabled` | Enable SQLite persistence | `true` |
| `persistence.size` | PVC size | `5Gi` |
| `imageBuilder.enabled` | Enable Kaniko building | `true` |
| `httpRoute.enabled` | Enable Gateway API route | `false` |
| `httpRoute.hostname` | External hostname | `""` |

### Full Values Reference

See [values.yaml](./values.yaml) for all configurable options.

## Gateway API / Ingress

### Using Gateway API (HTTPRoute)

```yaml
httpRoute:
  enabled: true
  hostname: "board.example.com"
  gatewayName: "my-gateway"
  gatewayNamespace: "traefik"
  createReferenceGrant: true
```

### Using Traditional Ingress

This chart doesn't include Ingress resources yet. You can create one manually or contribute a PR!

## Updating Fizzy

1. **Trigger a rebuild** (if using imageBuilder):
   ```bash
   kubectl create job fizzy-build-$(date +%s) \
     --from=cronjob/fizzy-builder \
     -n fizzy
   ```

2. **Wait for build to complete**:
   ```bash
   kubectl logs -n fizzy -l app.kubernetes.io/component=builder -f
   ```

3. **Restart the deployment**:
   ```bash
   kubectl rollout restart deployment/fizzy -n fizzy
   ```

## Persistence

Fizzy uses SQLite by default. The database is stored in a PersistentVolumeClaim.

To use an existing PVC:

```yaml
persistence:
  enabled: true
  existingClaim: "my-existing-pvc"
```

## Security

### Secret Management

The chart expects a pre-existing secret with `SECRET_KEY_BASE`. This is intentional - secrets should not be managed in Helm values.

Create the secret before installing:

```bash
# Generate and create
kubectl create secret generic fizzy-secrets \
  --from-literal=SECRET_KEY_BASE=$(openssl rand -hex 64) \
  -n fizzy

# Or from 1Password (if using their CLI)
op item get "[Homelab] Fizzy" --fields secret_key_base --reveal | \
  xargs -I {} kubectl create secret generic fizzy-secrets \
    --from-literal=SECRET_KEY_BASE={} \
    -n fizzy
```

### Pod Security

The chart runs with restricted security contexts by default:

```yaml
securityContext:
  runAsNonRoot: false  # Fizzy runs as uid 1000
  runAsUser: 1000
  runAsGroup: 1000
  allowPrivilegeEscalation: false
  capabilities:
    drop: [ALL]
```

## Troubleshooting

### Pod won't start - ImagePullBackOff

The image doesn't exist yet. Either:
- Wait for the initial build job to complete
- Check build job logs: `kubectl logs -n fizzy -l app.kubernetes.io/component=builder`
- Ensure your registry is accessible

### Pod crashes - SECRET_KEY_BASE missing

Create the required secret:
```bash
kubectl create secret generic fizzy-secrets \
  --from-literal=SECRET_KEY_BASE=$(openssl rand -hex 64) \
  -n fizzy
```

### Build fails - Registry unreachable

Ensure your registry is accessible from the cluster. For in-cluster registries:
```bash
kubectl run test --rm -it --image=busybox -- wget -q -O- http://registry.registry.svc.cluster.local:5000/v2/
```

## Contributing

This chart is part of [TechDufus/home.io](https://github.com/TechDufus/home.io).

Contributions welcome! Please open an issue or PR.

## License

This Helm chart is open source. Fizzy itself is licensed under the [O'Saasy License](https://github.com/basecamp/fizzy/blob/main/LICENSE.md).
