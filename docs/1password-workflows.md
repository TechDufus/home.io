# 1Password Secret Management Workflows

## Table of Contents
1. [Development Workflow](#development-workflow)
2. [Production Deployment](#production-deployment)
3. [Secret Rotation](#secret-rotation)
4. [Troubleshooting](#troubleshooting)
5. [Emergency Procedures](#emergency-procedures)
6. [Best Practices](#best-practices)

## Development Workflow

### Local Development Setup

1. **Install Prerequisites**
   ```bash
   # Install 1Password CLI
   curl -sSfL https://downloads.1password.com/linux/tar/stable/x86_64/1password-cli-latest.tar.gz | \
     tar -xzf - && sudo mv op /usr/local/bin/
   
   # Verify installation
   op --version
   ```

2. **Setup Development Service Account**
   ```bash
   # Get service account token from 1Password (Personal vault)
   export OP_SERVICE_ACCOUNT_TOKEN="ops_dev_xxxxx"
   
   # Test authentication
   op vault list
   ```

3. **Bootstrap Development Cluster**
   ```bash
   # Bootstrap with 1Password integration
   ./scripts/1password-bootstrap.sh --name dev --env dev --validate-only
   
   # Create cluster with 1Password operator
   ./kubernetes/capi/scripts/create-cluster.sh \
     --name dev --env dev --install-addons --use-1password
   ```

### Adding New Secrets to Development

1. **Add Secret to 1Password Vault**
   ```bash
   # Using 1Password CLI
   op item create \
     --category="API Credential" \
     --title="dev-myapp-api-key" \
     --vault="cicd" \
     api-key="your-secret-value"
   ```

2. **Create OnePasswordItem Resource**
   ```yaml
   # kubernetes/secrets/secret-references/dev-myapp.yaml
   apiVersion: onepassword.com/v1
   kind: OnePasswordItem
   metadata:
     name: myapp-api-key
     namespace: myapp
   spec:
     itemPath: "vaults/cicd/items/dev-myapp-api-key"
     secretKey: "api-key"
     secretName: "myapp-api-credentials"
   ```

3. **Apply to Development Cluster**
   ```bash
   kubectl apply -f kubernetes/secrets/secret-references/dev-myapp.yaml
   
   # Verify secret creation
   kubectl get onepassworditems -n myapp
   kubectl get secrets myapp-api-credentials -n myapp
   ```

### Testing Secret Access

```bash
# Check OnePasswordItem status
kubectl describe onepassworditem myapp-api-key -n myapp

# Verify secret contents (development only)
kubectl get secret myapp-api-credentials -n myapp -o yaml

# Test application deployment with secrets
kubectl create deployment myapp \
  --image=myapp:latest \
  --dry-run=client -o yaml > myapp-deployment.yaml

# Add secret volume mount to deployment
# Apply and test
kubectl apply -f myapp-deployment.yaml
```

## Production Deployment

### Pre-Production Checklist

- [ ] All secrets exist in production vault path
- [ ] Service account tokens are production-grade
- [ ] Network policies are applied
- [ ] RBAC permissions are restrictive
- [ ] Monitoring and alerting configured
- [ ] Backup procedures tested

### Production Bootstrap Process

1. **Validate Production Secrets**
   ```bash
   # Use production service account token
   export OP_SERVICE_ACCOUNT_TOKEN="ops_prod_xxxxx"
   
   # Validate all required secrets exist
   ./scripts/1password-bootstrap.sh --name prod --env prod --validate-only
   ```

2. **Deploy Production Cluster**
   ```bash
   # Bootstrap production with strict security
   ./scripts/1password-bootstrap.sh --name prod --env prod
   
   # Create production cluster
   ./kubernetes/capi/scripts/create-cluster.sh \
     --name prod --env prod --install-addons --use-1password
   ```

3. **Apply Production Secret References**
   ```bash
   # Apply production-specific secrets
   kubectl apply -f kubernetes/secrets/secret-references/prod-secrets.yaml
   
   # Verify all secrets are created
   kubectl get onepassworditems -A
   ```

### Production Security Validation

```bash
# Check Pod Security Standards
kubectl get namespaces -l pod-security.kubernetes.io/enforce=restricted

# Verify Network Policies
kubectl get networkpolicies -A

# Check RBAC permissions
kubectl auth can-i create secrets --as=app-developer

# Validate admission controllers
kubectl get validatingadmissionwebhooks
```

## Secret Rotation

### Automated Rotation (Recommended)

1. **Update Secret in 1Password**
   ```bash
   # Rotate secret using 1Password CLI
   op item edit "prod-database-password" \
     --vault="cicd" \
     password="new-secure-password"
   ```

2. **Trigger Operator Sync**
   ```bash
   # Restart operator to force immediate sync
   kubectl rollout restart deployment/onepassword-operator \
     -n onepassword-operator
   
   # Or wait for polling interval (default: 60s)
   kubectl logs -f deployment/onepassword-operator \
     -n onepassword-operator
   ```

3. **Restart Applications**
   ```bash
   # Restart applications to pick up new secrets
   kubectl rollout restart deployment/myapp -n myapp
   ```

### Manual Rotation Process

1. **Generate New Secret**
   ```bash
   # Generate secure password
   NEW_PASSWORD=$(openssl rand -base64 32)
   echo "New password: $NEW_PASSWORD"
   ```

2. **Update External Service**
   ```bash
   # Update the external service first
   # (e.g., database, API service)
   ```

3. **Update 1Password**
   ```bash
   op item edit "prod-database-password" \
     --vault="cicd" \
     password="$NEW_PASSWORD"
   ```

4. **Verify Propagation**
   ```bash
   # Check OnePasswordItem status
   kubectl get onepassworditems -o wide
   
   # Verify secret update timestamp
   kubectl get secret myapp-db-password -o yaml | grep creationTimestamp
   ```

### Rotation Scheduling

```yaml
# Example: Automated rotation with CronJob
apiVersion: batch/v1
kind: CronJob
metadata:
  name: secret-rotation-check
  namespace: security
spec:
  schedule: "0 2 * * 0"  # Weekly on Sunday at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: rotation-checker
            image: 1password/cli:latest
            env:
            - name: OP_SERVICE_ACCOUNT_TOKEN
              valueFrom:
                secretKeyRef:
                  name: rotation-service-account
                  key: token
            command:
            - /bin/sh
            - -c
            - |
              # Check secret ages and trigger rotation warnings
              # Implementation depends on requirements
          restartPolicy: OnFailure
```

## Troubleshooting

### Common Issues

#### 1. OnePasswordItem Not Creating Secrets

**Symptoms:**
```bash
kubectl get onepassworditems
# Status shows "Failed" or "Pending"
```

**Diagnosis:**
```bash
# Check operator logs
kubectl logs deployment/onepassword-operator -n onepassword-operator

# Check OnePasswordItem status
kubectl describe onepassworditem myapp-secret -n myapp

# Common causes:
# - Invalid item path
# - Missing permissions
# - Network connectivity issues
```

**Resolution:**
```bash
# Verify item exists in 1Password
op item get "myapp-secret" --vault="cicd"

# Check service account permissions
op vault list

# Test network connectivity
kubectl exec -it deployment/onepassword-operator -n onepassword-operator -- \
  wget -qO- https://connect-api.1password.com/v1/health
```

#### 2. Operator Authentication Failures

**Symptoms:**
```bash
# Operator logs show 401/403 errors
kubectl logs deployment/onepassword-operator -n onepassword-operator
```

**Diagnosis:**
```bash
# Check service account token
kubectl get secret onepassword-token -n onepassword-operator -o yaml

# Verify token is not expired
op account list
```

**Resolution:**
```bash
# Update service account token
export NEW_TOKEN="ops_new_token_xxxxx"
kubectl create secret generic onepassword-token \
  --namespace=onepassword-operator \
  --from-literal=token="$NEW_TOKEN" \
  --dry-run=client -o yaml | kubectl apply -f -

# Restart operator
kubectl rollout restart deployment/onepassword-operator -n onepassword-operator
```

#### 3. Application Can't Read Secrets

**Symptoms:**
```bash
# Application pods show mounting errors
kubectl describe pod myapp-xxx -n myapp
```

**Diagnosis:**
```bash
# Check if secret exists
kubectl get secret myapp-api-credentials -n myapp

# Check RBAC permissions
kubectl auth can-i get secrets --as=system:serviceaccount:myapp:default -n myapp

# Check security context
kubectl get pod myapp-xxx -n myapp -o yaml | grep -A 10 securityContext
```

**Resolution:**
```bash
# Fix RBAC if needed
kubectl create rolebinding myapp-secret-access \
  --role=secret-reader \
  --serviceaccount=myapp:default \
  -n myapp

# Ensure proper security context
# Update deployment with non-root user
```

### Debugging Commands

```bash
# Check operator health
kubectl get deployment/onepassword-operator -n onepassword-operator
kubectl get endpoints -n onepassword-operator

# View operator metrics
kubectl port-forward deployment/onepassword-operator 8080:8080 -n onepassword-operator &
curl http://localhost:8080/metrics

# Check CRD installation
kubectl get crd onepassworditems.onepassword.com
kubectl api-resources | grep onepassword

# Validate webhook configuration
kubectl get validatingadmissionwebhooks | grep onepassword
```

### Log Analysis

```bash
# Operator logs with timestamps
kubectl logs deployment/onepassword-operator -n onepassword-operator --timestamps

# Filter for specific OnePasswordItem
kubectl logs deployment/onepassword-operator -n onepassword-operator | \
  grep "myapp-secret"

# Check events
kubectl get events -n myapp --sort-by='.lastTimestamp'
kubectl get events -n onepassword-operator --sort-by='.lastTimestamp'
```

## Emergency Procedures

### Complete Operator Failure

1. **Immediate Response**
   ```bash
   # Check operator status
   kubectl get pods -n onepassword-operator
   
   # Get detailed error information
   kubectl describe pod <operator-pod> -n onepassword-operator
   ```

2. **Emergency Secret Access**
   ```bash
   # Use emergency RBAC access
   kubectl auth can-i create secrets --as=emergency-admin@techdufus.com
   
   # Manually create critical secrets if needed
   kubectl create secret generic emergency-db-password \
     --from-literal=password="fallback-password" \
     -n critical-app
   ```

3. **Operator Recovery**
   ```bash
   # Redeploy operator
   kubectl delete deployment onepassword-operator -n onepassword-operator
   kubectl apply -f kubernetes/secrets/1password/operator.yaml
   
   # Verify recovery
   kubectl get onepassworditems -A
   ```

### Service Account Token Compromise

1. **Immediate Actions**
   ```bash
   # Revoke compromised token in 1Password
   # Generate new service account token
   
   # Update Kubernetes secret immediately
   kubectl create secret generic onepassword-token \
     --namespace=onepassword-operator \
     --from-literal=token="$NEW_TOKEN" \
     --dry-run=client -o yaml | kubectl apply -f -
   ```

2. **Security Audit**
   ```bash
   # Check access logs
   kubectl get events -A | grep onepassword
   
   # Review secret access patterns
   kubectl auth can-i list secrets --as=system:serviceaccount:onepassword-operator:onepassword-operator
   ```

### Mass Secret Rotation

```bash
# Emergency rotation of all secrets
for item in $(op item list --vault=cicd --format=json | jq -r '.[].title'); do
  echo "Rotating: $item"
  # Implement rotation logic based on secret type
done
```

## Best Practices

### Security Best Practices

1. **Principle of Least Privilege**
   - Use specific service accounts per environment
   - Limit vault access to required secrets only
   - Regular RBAC permission audits

2. **Network Security**
   - Deploy NetworkPolicies for operator isolation
   - Use private container registries
   - Enable Pod Security Standards

3. **Monitoring and Alerting**
   - Monitor operator health and secret sync status
   - Alert on authentication failures
   - Track secret access patterns

### Operational Best Practices

1. **Secret Organization**
   - Use consistent naming conventions
   - Organize by environment and application
   - Document secret purposes and owners

2. **Change Management**
   - Test secret changes in development first
   - Use GitOps for secret reference deployment
   - Maintain secret rotation schedules

3. **Disaster Recovery**
   - Regular backup of secret references
   - Document emergency access procedures
   - Test recovery scenarios quarterly

### Development Best Practices

1. **Local Development**
   - Use development vault for non-production secrets
   - Never store production secrets locally
   - Use 1Password CLI for consistent access

2. **CI/CD Integration**
   - Use service accounts for automated deployments
   - Validate secret references in CI pipeline
   - Automate secret existence checks

3. **Application Design**
   - Design applications for secret rotation
   - Use health checks that include secret validation
   - Implement graceful handling of secret unavailability