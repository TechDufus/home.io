# Monitoring Stack (kube-prometheus-stack)

This directory contains the configuration for the kube-prometheus-stack, which provides comprehensive monitoring for the Kubernetes cluster.

## Components

- **Prometheus**: Time-series database for metrics
- **Grafana**: Visualization platform
- **Alertmanager**: Alert management
- **Node Exporter**: Hardware and OS metrics
- **kube-state-metrics**: Kubernetes API metrics

## Files

- `values-dev.yaml`: Development environment configuration
  - Reduced resource requirements
  - 7-day retention
  - Single replica mode
  - Local storage

## Accessing Services

### Grafana
```bash
# Port forward
kubectl port-forward -n monitoring svc/grafana 3000:80

# Default login: admin/admin
```

### Prometheus
```bash
# Port forward
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
```

### Alertmanager
```bash
# Port forward
kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093
```

## Adding Custom Dashboards

1. Create a ConfigMap with your dashboard JSON:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-dashboard
  namespace: monitoring
  labels:
    grafana_dashboard: "1"
data:
  my-dashboard.json: |
    {
      "dashboard": { ... }
    }
```

2. The sidecar will automatically import it into Grafana

## ServiceMonitor Example

To scrape metrics from your applications:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: my-app
  namespace: my-namespace
spec:
  selector:
    matchLabels:
      app: my-app
  endpoints:
  - port: metrics
    interval: 30s
    path: /metrics
```

## Storage Considerations

The current configuration uses local-path storage. For production:
- Consider using a distributed storage solution
- Increase retention period
- Configure backup strategies

## Resource Tuning

Current settings are optimized for homelab use. For larger deployments:
- Increase memory limits for Prometheus
- Add more Grafana replicas
- Enable Prometheus HA mode