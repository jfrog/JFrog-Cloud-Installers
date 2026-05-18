#!/bin/bash
# Build-time generator for the NGINX mainConf override.
#
# Extracts nginx-main-conf.yaml from the JFrog Platform Helm chart,
# overrides worker_processes, and outputs it as artifactory.nginx.mainConf.
#
# Output (build artifact, not committed to source):
#   build/nginx-main-conf.txt  (raw nginx.conf content)
#
# Usage:
#   scripts/sync_networking_modes.sh [chart_version] [worker_processes]

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

BUILD_DIR="build"
REQUESTED_VERSION="${1:-}"
WORKER_PROCESSES="${2:-4}"

read -r CHART_VERSION CHART_URL <<EOF
$(python3 - "$REQUESTED_VERSION" <<'PY'
import sys
import urllib.request
import yaml

requested = sys.argv[1] if len(sys.argv) > 1 else ""
idx = urllib.request.urlopen("https://charts.jfrog.io/index.yaml", timeout=30).read().decode()
data = yaml.safe_load(idx)
entries = data["entries"]["jfrog-platform"]

selected = None
if requested:
    requested = requested[1:] if requested.startswith("v") else requested
    for e in entries:
        if str(e.get("version", "")) == requested:
            selected = e
            break
    if selected is None:
        raise SystemExit(f"ERROR: Chart version '{requested}' not found in jfrog-platform index")
else:
    selected = entries[0]

print(selected["version"], selected["urls"][0])
PY
)
EOF

echo "Syncing nginx main conf from jfrog-platform chart ${CHART_VERSION}"
echo "Source: ${CHART_URL}"
echo "worker_processes override: ${WORKER_PROCESSES}"

TMP_DIR="$(mktemp -d)"
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

curl -sL "$CHART_URL" -o "$TMP_DIR/chart.tgz"

TAR_PATH="jfrog-platform/charts/artifactory/files/nginx-main-conf.yaml"
if ! tar -tzf "$TMP_DIR/chart.tgz" "$TAR_PATH" >/dev/null 2>&1; then
  echo "ERROR: Not found in chart: $TAR_PATH" >&2
  exit 1
fi
tar -xzf "$TMP_DIR/chart.tgz" -C "$TMP_DIR" "$TAR_PATH"

SRC="$TMP_DIR/$TAR_PATH"
sed -i.bak -E "s/^worker_processes[[:space:]]+[^;]+;/worker_processes  ${WORKER_PROCESSES};/" "$SRC"
rm -f "${SRC}.bak"

# Strip Go template whitespace trim modifiers ({{- and -}}) so that
# rendered nginx.conf preserves newlines between directives.
sed -i.bak -E 's/\{\{-/\{\{/g; s/-\}\}/\}\}/g' "$SRC"
rm -f "${SRC}.bak"

mkdir -p "$BUILD_DIR"

cp "$SRC" "$BUILD_DIR/nginx-main-conf.txt"

echo "Wrote: $BUILD_DIR/nginx-main-conf.txt (synced from chart ${CHART_VERSION})"
