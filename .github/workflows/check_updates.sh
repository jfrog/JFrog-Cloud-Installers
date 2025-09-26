#!/bin/bash

set -euo pipefail
set -x

FORCE_UPDATE="${FORCE_UPDATE:-false}"

ANSIBLE_COLLECTION_PATH="Ansible/ansible_collections/jfrog/platform/galaxy.yml"
ANSIBLE_UPDATE_AVAILABLE="false"
CURRENT_ANSIBLE_VERSION=""
LATEST_ANSIBLE_VERSION=""
SUMMARY_FILE="summary.md"

# Get current version from local galaxy.yml
if [ -f "$ANSIBLE_COLLECTION_PATH" ]; then
  CURRENT_ANSIBLE_VERSION=$(yq '.version' "$ANSIBLE_COLLECTION_PATH")
else
  echo "galaxy.yml not found at $ANSIBLE_COLLECTION_PATH"
  echo "ansible-update-available=false" >> "$GITHUB_OUTPUT"
  echo "current-ansible-version=" >> "$GITHUB_OUTPUT"
  echo "latest-ansible-version=" >> "$GITHUB_OUTPUT"
  exit 0
fi

# Get latest version from Ansible Galaxy API
GALAXY_URL="https://galaxy.ansible.com/api/v2/collections/jfrog/platform/"
LATEST_ANSIBLE_VERSION=$(curl -s "$GALAXY_URL" | jq -r '.latest_version.version // empty')

if [ -z "$LATEST_ANSIBLE_VERSION" ]; then
  echo "Could not fetch latest version from Ansible Galaxy."
  echo "ansible-update-available=false" >> "$GITHUB_OUTPUT"
  echo "current-ansible-version=$CURRENT_ANSIBLE_VERSION" >> "$GITHUB_OUTPUT"
  echo "latest-ansible-version=" >> "$GITHUB_OUTPUT"
  exit 0
fi

# Determine if update is needed
if [[ "$LATEST_ANSIBLE_VERSION" != "$CURRENT_ANSIBLE_VERSION" ]] || [[ "$FORCE_UPDATE" == "true" ]]; then
  ANSIBLE_UPDATE_AVAILABLE="true"
else
  ANSIBLE_UPDATE_AVAILABLE="false"
fi

# Write outputs for GitHub Actions
echo "ansible-update-available=$ANSIBLE_UPDATE_AVAILABLE" >> "$GITHUB_OUTPUT"
echo "current-ansible-version=$CURRENT_ANSIBLE_VERSION" >> "$GITHUB_OUTPUT"
echo "latest-ansible-version=$LATEST_ANSIBLE_VERSION" >> "$GITHUB_OUTPUT"

# Generate markdown summary
{
  echo "## Ansible Collection Update Status"
  echo ""
  if [[ "$ANSIBLE_UPDATE_AVAILABLE" == "true" ]]; then
    echo "| Collection       | Current Version   | Latest Version    |"
    echo "|------------------|-------------------|-------------------|"
    printf "| %-16s | %-17s | %-17s |\n" "jfrog.platform" "$CURRENT_ANSIBLE_VERSION" "$LATEST_ANSIBLE_VERSION"
  else
    echo "_Ansible collection is already up to date._"
  fi
} > "$SUMMARY_FILE"

# Add to GitHub Actions summary output
echo "update-summary<<EOF" >> "$GITHUB_OUTPUT"
cat "$SUMMARY_FILE" >> "$GITHUB_OUTPUT"
echo "EOF" >> "$GITHUB_OUTPUT"
