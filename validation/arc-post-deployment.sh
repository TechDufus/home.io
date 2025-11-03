#!/usr/bin/env bash
# Post-deployment validation for GitHub Actions Runner Controller
# Run this after deploying ARC to verify successful installation

set -euo pipefail

echo "==> Post-deployment validation for ARC..."
echo ""

FAILED=0

# Wait for ArgoCD sync
echo "Waiting for ArgoCD applications to sync (10 seconds)..."
sleep 10

# Check ArgoCD applications
echo ""
echo "==> Checking ArgoCD applications..."
APPS=("actions-runner-controller" "actions-runner-scale-set")

for app in "${APPS[@]}"; do
  echo -n "  Checking application '$app'... "

  if ! kubectl get application "$app" -n argocd &>/dev/null; then
    echo "❌ FAIL (not found)"
    FAILED=1
    continue
  fi

  STATUS=$(kubectl get application "$app" -n argocd -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "Unknown")
  HEALTH=$(kubectl get application "$app" -n argocd -o jsonpath='{.status.health.status}' 2>/dev/null || echo "Unknown")

  if [[ "$STATUS" != "Synced" ]]; then
    echo "❌ FAIL (status: $STATUS)"
    echo "     Run: kubectl describe application '$app' -n argocd"
    FAILED=1
  elif [[ "$HEALTH" != "Healthy" && "$HEALTH" != "Progressing" ]]; then
    echo "⚠️  WARNING (health: $HEALTH)"
    echo "     Application may still be deploying"
  else
    echo "✓ PASS (status: $STATUS, health: $HEALTH)"
  fi
done

# Check namespace
echo ""
echo -n "Checking namespace 'actions-runner-system'... "
if ! kubectl get namespace actions-runner-system &>/dev/null; then
  echo "❌ FAIL"
  FAILED=1
else
  echo "✓ PASS"
fi

# Check secret
echo -n "Checking GitHub token secret... "
if ! kubectl get secret github-token -n actions-runner-system &>/dev/null; then
  echo "❌ FAIL"
  echo "   Run: ./scripts/bootstrap-arc-secrets.sh"
  FAILED=1
else
  # Verify secret has correct key
  if ! kubectl get secret github-token -n actions-runner-system -o jsonpath='{.data.github_token}' &>/dev/null; then
    echo "❌ FAIL (missing 'github_token' key)"
    FAILED=1
  else
    echo "✓ PASS"
  fi
fi

# Check controller deployment
echo ""
echo "==> Checking controller deployment..."
echo -n "  Waiting for controller to be ready... "

if kubectl wait --for=condition=available --timeout=120s \
  deployment/arc-controller-gha-runner-scale-set-controller \
  -n actions-runner-system &>/dev/null; then

  CONTROLLER_READY=$(kubectl get deployment arc-controller-gha-runner-scale-set-controller \
    -n actions-runner-system -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")

  if [[ "$CONTROLLER_READY" == "1" ]]; then
    echo "✓ PASS"
  else
    echo "❌ FAIL (ready replicas: $CONTROLLER_READY)"
    echo "     Check logs: kubectl logs -n actions-runner-system deployment/arc-controller-gha-runner-scale-set-controller"
    FAILED=1
  fi
else
  echo "❌ FAIL (timeout waiting for deployment)"
  FAILED=1
fi

# Check listener deployment
echo -n "  Checking listener pod... "
LISTENER_COUNT=$(kubectl get pods -n actions-runner-system \
  -l app.kubernetes.io/name=gha-runner-scale-set \
  --field-selector=status.phase=Running \
  --no-headers 2>/dev/null | wc -l | tr -d ' ')

if [[ "$LISTENER_COUNT" -ge "1" ]]; then
  echo "✓ PASS"
else
  echo "❌ FAIL (no running listener pods)"
  echo "     Check: kubectl get pods -n actions-runner-system -l app.kubernetes.io/name=gha-runner-scale-set"
  FAILED=1
fi

# Check for errors in controller logs
echo ""
echo "==> Checking controller logs for errors..."
if kubectl logs -n actions-runner-system \
  deployment/arc-controller-gha-runner-scale-set-controller --tail=100 2>/dev/null | \
  grep -i "error\|fatal\|failed" | grep -v "level=info" | grep -v "success" | head -5; then
  echo "⚠️  WARNING: Errors found in controller logs (review above)"
  echo "     Full logs: kubectl logs -n actions-runner-system deployment/arc-controller-gha-runner-scale-set-controller"
else
  echo "✓ No critical errors in recent logs"
fi

# Summary
echo ""
if [[ $FAILED -eq 0 ]]; then
  echo "✅ All post-deployment checks passed"
  echo ""
  echo "Next steps:"
  echo "1. Verify runners in GitHub UI:"
  echo "   https://github.com/settings/actions/runners"
  echo "2. Create test workflow with 'runs-on: self-hosted'"
  echo "3. Monitor runner pod creation:"
  echo "   kubectl get pods -n actions-runner-system -w"
  exit 0
else
  echo "❌ Post-deployment validation failed"
  echo ""
  echo "Troubleshooting steps:"
  echo "1. Check ArgoCD application status:"
  echo "   kubectl get applications -n argocd"
  echo "2. Check pod status:"
  echo "   kubectl get pods -n actions-runner-system"
  echo "3. Check controller logs:"
  echo "   kubectl logs -n actions-runner-system deployment/arc-controller-gha-runner-scale-set-controller"
  echo "4. Check listener logs:"
  echo "   kubectl logs -n actions-runner-system -l app.kubernetes.io/name=gha-runner-scale-set"
  exit 1
fi
