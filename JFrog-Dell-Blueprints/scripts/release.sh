#!/bin/bash
# Create a new Git release branch and tag for a JFrog Dell Blueprint,
# triggering the GitHub Actions workflow that builds the zip artifact.

set -euo pipefail

# ── Non-interactive mode ─────────────────────────────────────────────
ASSUME_YES=${ASSUME_YES:-0}
if [[ "${1:-}" == "-y" ]]; then
  ASSUME_YES=1
  shift || true
fi

# ── Helpers ──────────────────────────────────────────────────────────

confirm() {
  local prompt="$1"
  if [[ "$ASSUME_YES" == "1" ]]; then
    echo "$prompt (auto-yes)"
    return 0
  fi
  echo ""
  read -p "$prompt (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Operation cancelled."
    exit 0
  fi
}

detect_default_branch() {
  git remote show origin 2>/dev/null | sed -n '/HEAD branch/s/.*: //p'
}

ensure_clean_worktree() {
  if ! git diff-index --quiet HEAD --; then
    echo "Your working tree has uncommitted changes."
    confirm "Proceed anyway?"
  fi
}

normalize_version() {
  local input="$1"
  if [[ ! "$input" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Version must be SemVer (e.g., 1.2.3 or v1.2.3)." >&2
    exit 1
  fi
  local ver="${input#v}"
  echo "v${ver}"
}

TAG_PREFIX="jfrog-dell-blueprints"

tag_exists() {
  local tag="$1"
  git fetch --tags >/dev/null 2>&1 || true
  if git rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
    return 0
  fi
  if git ls-remote --tags origin | grep -q "refs/tags/$tag$"; then
    return 0
  fi
  return 1
}

get_latest_local_tag() {
  git tag -l "${TAG_PREFIX}/v*" --sort='-v:refname' | head -n 1
}

get_latest_chart_version() {
  local chart_name="$1"
  local repo_index="https://charts.jfrog.io/index.yaml"
  local index tgz_match
  index=$(curl -sL "$repo_index" 2>/dev/null) || return 1
  tgz_match=$(grep -oEm1 "${chart_name}-[0-9]+\.[0-9]+\.[0-9]+\.tgz" <<< "$index") || return 1
  grep -oE '[0-9]+\.[0-9]+\.[0-9]+' <<< "$tgz_match"
}

# ── Blueprint catalogue ─────────────────────────────────────────────
# Each entry is <directory>:<display-name>.
# Add new blueprints here as they are created.
BLUEPRINTS=(
  "blueprints/jfrog-platform:JFrog Dell Blueprint"
)

# ── Show existing releases ───────────────────────────────────────────
echo "--- Current JFrog Dell Blueprint Releases ---"

git fetch --tags >/dev/null 2>&1 || true
LATEST_TAG=$(get_latest_local_tag)
if [[ -n "$LATEST_TAG" ]]; then
  echo "Latest tag: ${LATEST_TAG}"
else
  echo "No existing version tags found."
fi

echo ""
echo "Available blueprints:"
for entry in "${BLUEPRINTS[@]}"; do
  IFS=':' read -r dir name <<< "$entry"
  echo "  - ${name} (${dir}/)"
done

echo ""
echo "--- Latest JFrog Platform Helm Chart Version ---"
LATEST_CHART=$(get_latest_chart_version "jfrog-platform")
if [[ -n "$LATEST_CHART" ]]; then
  echo "  JFrog Platform Helm chart: ${LATEST_CHART}"
else
  echo "  JFrog Platform Helm chart: (unable to fetch)"
fi

echo "-------------------------------------"
echo ""

# ── Select blueprint ─────────────────────────────────────────────────
if [[ ${#BLUEPRINTS[@]} -eq 1 ]]; then
  IFS=':' read -r BLUEPRINT_DIR BLUEPRINT_NAME <<< "${BLUEPRINTS[0]}"
  echo "Using blueprint: ${BLUEPRINT_NAME} (${BLUEPRINT_DIR}/)"
else
  echo "Select a blueprint:"
  select entry in "${BLUEPRINTS[@]}"; do
    IFS=':' read -r BLUEPRINT_DIR BLUEPRINT_NAME <<< "$entry"
    break
  done
fi

# ── Version input ────────────────────────────────────────────────────
if [[ -z "${NEW_VERSION:-}" ]]; then
  read -r -p "Please enter the new version number (e.g., 1.2.3): " NEW_VERSION
fi
NEW_VERSION=$(normalize_version "$NEW_VERSION")

# ── Pre-flight checks ───────────────────────────────────────────────
BRANCH_TO_CHECKOUT="$(detect_default_branch)"
[[ -z "$BRANCH_TO_CHECKOUT" ]] && BRANCH_TO_CHECKOUT="master"

ensure_clean_worktree

RELEASE_TAG="${TAG_PREFIX}/${NEW_VERSION}"

if tag_exists "$RELEASE_TAG"; then
  echo "Error: Tag ${RELEASE_TAG} already exists locally or on origin." >&2
  exit 1
fi

# Verify the blueprint directory exists
if [[ ! -d "$BLUEPRINT_DIR" ]]; then
  echo "Error: Blueprint directory '${BLUEPRINT_DIR}' not found." >&2
  exit 1
fi

echo ""
echo "--- Starting release process for '${BLUEPRINT_NAME}' ${NEW_VERSION} ---"
echo ""

# ── Git workflow ─────────────────────────────────────────────────────

# 1. Checkout the base branch
echo "About to checkout branch '${BRANCH_TO_CHECKOUT}'..."
confirm "Proceed to checkout '${BRANCH_TO_CHECKOUT}'?"
git checkout "${BRANCH_TO_CHECKOUT}"

# 2. Pull latest
echo "About to pull latest code from '${BRANCH_TO_CHECKOUT}'..."
confirm "Proceed to pull from '${BRANCH_TO_CHECKOUT}'?"
git pull --ff-only

# 3. Create release branch
RELEASE_BRANCH="jfrog-dell-blueprints/${NEW_VERSION}"
echo "About to create release branch: ${RELEASE_BRANCH}..."
confirm "Proceed to create branch '${RELEASE_BRANCH}'?"
git checkout -b "${RELEASE_BRANCH}"

# 4. Push release branch
echo "About to push release branch to origin..."
confirm "Proceed to push branch '${RELEASE_BRANCH}' to origin?"
git push -u origin "${RELEASE_BRANCH}"

# 5. Create tag
echo "About to create tag: ${RELEASE_TAG}..."
confirm "Proceed to create tag '${RELEASE_TAG}'?"
git tag -a "${RELEASE_TAG}" -m "Release ${NEW_VERSION} – ${BLUEPRINT_NAME}"

# 6. Push tag (triggers the Release Blueprint workflow)
echo "About to push tag to origin (this triggers the GitHub Actions release)..."
confirm "Proceed to push tag '${RELEASE_TAG}' to origin?"
git push origin tag "${RELEASE_TAG}"

echo ""
echo "--- Release process completed successfully! ---"
echo ""
echo "  Blueprint : ${BLUEPRINT_NAME}"
echo "  Version   : ${NEW_VERSION}"
echo "  Branch    : ${RELEASE_BRANCH}"
echo "  Tag       : ${RELEASE_TAG}"
echo ""
echo "The GitHub Actions 'Release JFrog Dell Blueprint' workflow will now"
echo "build the zip artifact and publish the GitHub Release automatically."
