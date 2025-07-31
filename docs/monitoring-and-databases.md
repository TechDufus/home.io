# Monitoring and Database Setup

This document describes the monitoring stack and database operator deployed in the homelab.

## Monitoring Stack (kube-prometheus-stack)

The monitoring stack includes:
- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization and dashboards
- **Alertmanager**: Alert routing and management
- **Node Exporter**: Host-level metrics
- **kube-state-metrics**: Kubernetes object metrics

### Accessing Grafana

Once deployed, Grafana can be accessed via:
1. Port forwarding: `kubectl port-forward -n monitoring svc/grafana 3000:80`
2. Default credentials: `admin` / `admin` (change this immediately)

### Adding Datasources

Prometheus is automatically configured as a datasource in Grafana.

### Custom Dashboards

Place dashboard JSON files in any namespace with the label `grafana_dashboard=1` and they will be automatically imported.

## CloudNative-PG (PostgreSQL Operator)

CloudNative-PG provides:
- PostgreSQL cluster management
- Automated failover
- Backup/restore capabilities
- Monitoring integration

### Creating a PostgreSQL Cluster

1. Create credentials secret:
```bash
kubectl create secret generic my-postgres-credentials \
  --from-literal=username=myapp \
  --from-literal=password="$(op item get 'PostgreSQL Cluster' --fields password)"
```

2. Deploy cluster (see `example-cluster.yaml` for template):
```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: my-postgres
spec:
  instances: 3
  storage:
    size: 10Gi
  bootstrap:
    initdb:
      database: myapp
      owner: myapp
      secret:
        name: my-postgres-credentials
```

3. Connect to the database:
```bash
# Primary (read-write)
kubectl port-forward svc/my-postgres-rw 5432:5432

# Read-only replicas
kubectl port-forward svc/my-postgres-r 5433:5432
```

### Connection Strings

- **Primary**: `postgresql://username:password@my-postgres-rw:5432/myapp?sslmode=require`
- **Read replicas**: `postgresql://username:password@my-postgres-r:5432/myapp?sslmode=require`

## Integration Examples

### Using PostgreSQL with n8n

1. Create database and credentials:
```bash
kubectl apply -f - <<EOF
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: n8n-postgres
  namespace: n8n
spec:
  instances: 2
  storage:
    size: 5Gi
  bootstrap:
    initdb:
      database: n8n
      owner: n8n
      secret:
        name: n8n-postgres-credentials
EOF
```

2. Update n8n deployment to use PostgreSQL:
```yaml
env:
  - name: DB_TYPE
    value: "postgresdb"
  - name: DB_POSTGRESDB_HOST
    value: "n8n-postgres-rw"
  - name: DB_POSTGRESDB_DATABASE
    value: "n8n"
  - name: DB_POSTGRESDB_USER
    valueFrom:
      secretKeyRef:
        name: n8n-postgres-credentials
        key: username
  - name: DB_POSTGRESDB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: n8n-postgres-credentials
        key: password
```

### Monitoring PostgreSQL with Grafana

CloudNative-PG exports Prometheus metrics. Import dashboard ID `20417` in Grafana for PostgreSQL monitoring.

## Maintenance

### Prometheus Storage

Monitor Prometheus storage usage:
```bash
kubectl exec -n monitoring prometheus-kube-prometheus-stack-prometheus-0 -- df -h /prometheus
```

### PostgreSQL Backups

Configure automated backups (example):
```yaml
apiVersion: postgresql.cnpg.io/v1
kind: ScheduledBackup
metadata:
  name: postgres-backup
spec:
  schedule: "0 0 * * *"  # Daily at midnight
  cluster:
    name: my-postgres
  backupOwnerReference: self
  method: barmanObjectStore
  retentionPolicy: "7d"
```

## Troubleshooting

### Prometheus Not Scraping

Check ServiceMonitor labels:
```bash
kubectl get servicemonitor -A -o yaml | grep -A5 "selector:"
```

### PostgreSQL Connection Issues

Check cluster status:
```bash
kubectl get cluster -A
kubectl describe cluster my-postgres
kubectl logs -n cnpg-system deployment/cloudnative-pg
```

### Grafana Login Issues

Reset admin password:
```bash
kubectl exec -n monitoring deployment/grafana -c grafana -- grafana-cli admin reset-admin-password newpassword
```