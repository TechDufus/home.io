# CloudNative-PG Operator

This directory contains the configuration for the CloudNative-PG operator, which manages PostgreSQL clusters on Kubernetes.

## Components

- **Operator**: Manages PostgreSQL cluster lifecycle
- **CRDs**: Custom resources for PostgreSQL clusters
- **Webhook**: Validates and mutates PostgreSQL resources

## Files

- `values-dev.yaml`: Operator configuration for development
- `example-cluster.yaml`: Example PostgreSQL cluster definition

## Creating a PostgreSQL Cluster

### 1. Create Credentials

```bash
# Using 1Password
kubectl create secret generic my-postgres-app \
  --from-literal=username=appuser \
  --from-literal=password="$(op item get 'My PostgreSQL' --fields password)" \
  -n my-namespace
```

### 2. Deploy Cluster

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: my-postgres
  namespace: my-namespace
spec:
  instances: 3  # 1 primary + 2 replicas
  
  storage:
    size: 10Gi
    storageClass: local-path
  
  bootstrap:
    initdb:
      database: myapp
      owner: appuser
      secret:
        name: my-postgres-app
  
  resources:
    requests:
      cpu: 250m
      memory: 512Mi
    limits:
      cpu: 1000m
      memory: 1Gi
```

### 3. Access the Database

```bash
# Primary (read-write)
kubectl port-forward -n my-namespace svc/my-postgres-rw 5432:5432

# Connect with psql
PGPASSWORD=$(kubectl get secret my-postgres-app -o jsonpath='{.data.password}' | base64 -d) \
  psql -h localhost -U appuser -d myapp
```

## Service Endpoints

Each cluster creates multiple services:

- `<cluster-name>-rw`: Primary (read-write) endpoint
- `<cluster-name>-r`: Read-only replicas endpoint
- `<cluster-name>-ro`: Any instance (read-only) endpoint

## Connection String Examples

### From Within Cluster
```
# Primary
postgresql://user:pass@my-postgres-rw.namespace:5432/myapp

# Read replicas
postgresql://user:pass@my-postgres-r.namespace:5432/myapp
```

### Using Secrets in Apps
```yaml
env:
  - name: DATABASE_URL
    value: "postgresql://$(DB_USER):$(DB_PASS)@my-postgres-rw:5432/myapp"
  - name: DB_USER
    valueFrom:
      secretKeyRef:
        name: my-postgres-app
        key: username
  - name: DB_PASS
    valueFrom:
      secretKeyRef:
        name: my-postgres-app
        key: password
```

## Monitoring

CloudNative-PG exports Prometheus metrics:

- Enable monitoring in cluster spec
- Metrics available at `:9187/metrics`
- Use Grafana dashboard ID: 20417

## Backup Configuration

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: ScheduledBackup
metadata:
  name: daily-backup
spec:
  schedule: "0 2 * * *"  # 2 AM daily
  cluster:
    name: my-postgres
  backupOwnerReference: self
  retentionPolicy: "7d"
```

## Common Operations

### Scale Cluster
```bash
kubectl patch cluster my-postgres --type merge \
  -p '{"spec":{"instances":5}}'
```

### Promote Replica
```bash
kubectl cnpg promote my-postgres my-postgres-2
```

### Check Status
```bash
kubectl get cluster -A
kubectl describe cluster my-postgres
kubectl cnpg status my-postgres
```

## Troubleshooting

### View Operator Logs
```bash
kubectl logs -n cnpg-system deployment/cloudnative-pg
```

### View PostgreSQL Logs
```bash
kubectl logs my-postgres-1 -c postgres
```

### Connection Issues
1. Check service endpoints exist
2. Verify credentials in secret
3. Check network policies
4. Review PostgreSQL logs