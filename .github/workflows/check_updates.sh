#!/bin/bash

set -euo pipefail
set -x

FORCE_UPDATE="${FORCE_UPDATE:-false}"
ARTIFACTORY_URL="${ARTIFACTORY_URL:-https://releases.jfrog.io/artifactory/ansible/collections/jfrog/platform/}"
ANSIBLE_UPDATE_AVAILABLE="false"
CURRENT_VERSION=""
LATEST_VERSION=""
COLLECTION_NAME="jfrog.platform"
COLLECTION_DIR="Ansible/ansible_collections/jfrog/platform"

# Get latest version from Ansible Galaxy
LATEST_VERSION=$(curl -s "$ARTIFACTORY_URL" | \
  sed -nE 's|.*href="([0-9]+\.[0-9]+\.[0-9]+)/?".*|\1|p' | \
  sort -V | tail -n 1)

if [[ -z "$LATEST_VERSION" ]]; then
  echo "Failed to fetch latest version from $ARTIFACTORY_URL"
  exit 1
fi

echo "Latest version : $LATEST_VERSION"

# Get current version from galaxy.yml
if [ -f "$COLLECTION_DIR/galaxy.yml" ]; then
  CURRENT_VERSION=$(yq '.version' "$COLLECTION_DIR/galaxy.yml")
else
  echo "galaxy.yml not found in $COLLECTION_DIR"
fi

echo "Current: $CURRENT_VERSION | Latest: $LATEST_VERSION"

if [[ "$CURRENT_VERSION" != "$LATEST_VERSION" ]] || [[ "$FORCE_UPDATE" == "true" ]]; then
  ANSIBLE_UPDATE_AVAILABLE="true"
fi

# GitHub Action outputs
echo "ansible-update-available=$ANSIBLE_UPDATE_AVAILABLE" >> "$GITHUB_OUTPUT"
echo "current-ansible-version=$CURRENT_VERSION" >> "$GITHUB_OUTPUT"
echo "latest-ansible-version=$LATEST_VERSION" >> "$GITHUB_OUTPUT"

# Markdown summary
{
  echo "## Ansible Collection Update Check"
  echo ""
  echo "| Collection       | Current Version | Latest Version |"
  echo "|------------------|-----------------|----------------|"
  printf '| %-16s | %-15s | %-14s |\n' "$COLLECTION_NAME" "$CURRENT_VERSION" "$LATEST_VERSION"
  echo ""
  if [[ "$ANSIBLE_UPDATE_AVAILABLE" == "true" ]]; then
    echo "Update available!"
  else
    echo "Already up to date."
  fi
} > summary.md

echo "update-summary<<EOF" >> "$GITHUB_OUTPUT"
cat summary.md >> "$GITHUB_OUTPUT"
echo "EOF" >> "$GITHUB_OUTPUT"
