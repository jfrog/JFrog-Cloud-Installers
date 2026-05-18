#!/bin/bash
# Fetch the latest stable version of the JFrog Platform Helm chart.
# Requires: curl, grep (no Helm CLI needed).

set -euo pipefail

REPO_INDEX_URL="https://charts.jfrog.io/index.yaml"

# Fetches the latest stable chart version from the JFrog Helm repo index.
# The index lists entries newest-first; we match the first .tgz URL for
# the target chart to extract the version without needing yq or Helm CLI.
get_latest_chart_version() {
  local chart_name="$1"
  local index tgz_match
  index=$(curl -sL "$REPO_INDEX_URL" 2>/dev/null) || return 1
  tgz_match=$(grep -oEm1 "${chart_name}-[0-9]+\.[0-9]+\.[0-9]+\.tgz" <<< "$index") || return 1
  grep -oE '[0-9]+\.[0-9]+\.[0-9]+' <<< "$tgz_match"
}

CHARTS=(
  "jfrog-platform"
)

echo "--- Latest Stable JFrog Platform Helm Chart Version ---"
echo ""

for chart in "${CHARTS[@]}"; do
  version=$(get_latest_chart_version "$chart")
  if [[ -n "$version" ]]; then
    echo "  JFrog Platform Helm chart (${chart}): ${version}"
  else
    echo "  JFrog Platform Helm chart (${chart}): (unable to fetch)"
  fi
done

echo ""
echo "Pass this as the 'chart_version' input when deploying the blueprint."
