#!/bin/bash
# Download jfrog-platform sizing templates from Helm chart and sync locally.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

SIZING_DIR="target/sizing"
REQUESTED_VERSION="${1:-}"

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

echo "Syncing sizing templates from jfrog-platform chart ${CHART_VERSION}"
echo "Source: ${CHART_URL}"

TMP_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

curl -sL "$CHART_URL" -o "$TMP_DIR/chart.tgz"

mkdir -p "$SIZING_DIR"
find "$SIZING_DIR" -mindepth 1 -maxdepth 1 -type f -name 'platform-*.yaml' -delete

for template in platform-xsmall.yaml platform-small.yaml platform-medium.yaml platform-large.yaml platform-xlarge.yaml platform-2xlarge.yaml; do
  TAR_PATH="jfrog-platform/sizing/${template}"
  if ! tar -tzf "$TMP_DIR/chart.tgz" "$TAR_PATH" >/dev/null 2>&1; then
    echo "ERROR: Template not found in chart: $TAR_PATH" >&2
    exit 1
  fi
  tar -xzf "$TMP_DIR/chart.tgz" -C "$TMP_DIR" "$TAR_PATH"
  cp "$TMP_DIR/$TAR_PATH" "$SIZING_DIR/$template"
done

# Normalize the upstream templates for YAML lint compliance: prepend the
# document start marker, strip trailing whitespace, and ensure a single
# trailing newline. The chart ships these without those conventions, which
# otherwise surface as SonarQube findings on the synced files.
python3 - "$SIZING_DIR" <<'PY'
import glob
import os
import sys

sizing_dir = sys.argv[1]
for path in sorted(glob.glob(os.path.join(sizing_dir, "platform-*.yaml"))):
    with open(path) as fh:
        lines = [ln.rstrip() for ln in fh.read().split("\n")]
    while lines and lines[-1] == "":
        lines.pop()
    if not lines or lines[0].strip() != "---":
        lines.insert(0, "---")
    with open(path, "w", newline="\n") as fh:
        fh.write("\n".join(lines) + "\n")
PY

echo "Synced sizing templates to: $SIZING_DIR"
find "$SIZING_DIR" -mindepth 1 -maxdepth 1 -type f -name 'platform-*.yaml' -print | sort | sed 's|.*/|  - |'
