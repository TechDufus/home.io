#!/usr/bin/env bash
# Pre-deployment validation for GitHub Actions Runner Controller
# Run this before deploying ARC to catch configuration issues early

set -euo pipefail

echo "==> Pre-deployment validation for ARC..."
echo ""

FAILED=0

# Check 1Password authentication
echo -n "Checking 1Password authentication... "
if ! op vault list &>/dev/null; then
  echo "❌ FAIL"
  echo "   Not authenticated to 1Password. Run: op signin"
  FAILED=1
else
  echo "✓ PASS"
fi

# Check PAT exists in 1Password
echo -n "Checking GitHub PAT in 1Password... "
if ! op item get Github --vault "Personal" --field label=github-actions-runner-controller-organization &>/dev/null 2>&1; then
  echo "❌ FAIL"
  echo "   PAT not found in Personal/Github/github-actions-runner-controller-organization"
  echo "   Create PAT (Classic) at: https://github.com/settings/tokens/new"
  echo "   Required scope: admin:org (for organization-level runners)"
  echo "   Add field to 1Password: Personal/Github/github-actions-runner-controller-organization"
  FAILED=1
else
  echo "✓ PASS"
fi

# Check kubectl access
echo -n "Checking Kubernetes cluster access... "
if ! kubectl cluster-info &>/dev/null; then
  echo "❌ FAIL"
  echo "   Cannot access Kubernetes cluster"
  echo "   Verify KUBECONFIG is set correctly"
  FAILED=1
else
  echo "✓ PASS"
fi

# Check ArgoCD is running
echo -n "Checking ArgoCD deployment... "
if ! kubectl get deployment argocd-server -n argocd &>/dev/null 2>&1; then
  echo "❌ FAIL"
  echo "   ArgoCD not deployed. Deploy ArgoCD first."
  FAILED=1
else
  echo "✓ PASS"
fi

# Check cluster resources
echo -n "Checking cluster resources... "
TOTAL_CPU=$(kubectl top nodes --no-headers 2>/dev/null | awk '{sum+=$3} END {print sum}' || echo "0")
if [[ "$TOTAL_CPU" == "0" ]]; then
  echo "⚠️  WARNING"
  echo "   Cannot determine cluster resources (metrics-server may not be running)"
  echo "   Ensure cluster has capacity for 1x runner (2 CPU, 4GB RAM)"
else
  echo "✓ PASS (${TOTAL_CPU}m available)"
fi

# Validate YAML files
echo ""
echo "==> Validating YAML syntax..."
YAML_FILES=(
  "kubernetes/argocd/apps/platform/actions-runner-controller.yaml"
  "kubernetes/argocd/apps/platform/actions-runner-scale-set.yaml"
  "kubernetes/argocd/values/actions-runner-controller.yaml"
  "kubernetes/argocd/values/actions-runner-scale-set.yaml"
)

for file in "${YAML_FILES[@]}"; do
  echo -n "  Checking $file... "
  if [[ ! -f "$file" ]]; then
    echo "❌ FAIL (file not found)"
    FAILED=1
  elif ! kubectl apply --dry-run=client -f "$file" &>/dev/null; then
    echo "❌ FAIL (invalid YAML)"
    FAILED=1
  else
    echo "✓ PASS"
  fi
done

# Check for GitHub username placeholder (OK if exists - bootstrap script will fix)
echo ""
echo -n "Checking GitHub username configuration... "
if [[ -f "kubernetes/argocd/values/actions-runner-scale-set.yaml" ]]; then
  if grep -q "<GITHUB_USERNAME>" kubernetes/argocd/values/actions-runner-scale-set.yaml 2>/dev/null; then
    echo "⚠️  INFO"
    echo "   Placeholder <GITHUB_USERNAME> found (will be replaced by bootstrap script)"
  else
    echo "✓ PASS (already configured)"
  fi
else
  echo "⚠️  INFO"
  echo "   Values file not yet created (will be created in Task 5)"
fi

echo ""
if [[ $FAILED -eq 0 ]]; then
  echo "✅ All pre-deployment checks passed"
  echo ""
  echo "Next steps:"
  echo "1. Run: ./scripts/bootstrap-arc-secrets.sh"
  echo "2. Commit and push ArgoCD manifests"
  echo "3. Run: ./validation/arc-post-deployment.sh"
  exit 0
else
  echo "❌ Pre-deployment validation failed"
  echo "Fix the issues above before deploying"
  exit 1
fi
