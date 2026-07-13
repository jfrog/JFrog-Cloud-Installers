#!/bin/bash
# generate_ansible_release_notes.sh
#
# Generates structured GitHub Release notes for the JFrog Platform Ansible
# Collection.
#
# releases.jfrog.io is the single source of truth:
# https://releases.jfrog.io/artifactory/ansible/collections/jfrog/platform/
# lists every published collection version and its .tar.gz, which contains
# the collection's own CHANGELOG.md and each role's defaults/main.yml (where
# artifactory_version/xray_version/distribution_version are pinned). Each
# role's official release notes are linked from docs.jfrog.com using its
# pinned app version.
#
# Nothing is read from git history/tags — this repo's checkout is not
# consulted at all.
#
# Usage:
#   ./generate_ansible_release_notes.sh NEW_VERSION [OLD_VERSION] PR_NUMBER
#
# Arguments:
#   NEW_VERSION - Collection version being released (e.g. "11.5.7")
#   OLD_VERSION - Previous collection version to diff against. If omitted,
#                 resolved as the greatest published version strictly less
#                 than NEW_VERSION.
#   PR_NUMBER   - The pull request carrying this update. The workflow always
#                 creates this PR before generating release notes, so its
#                 number is available here; the "Full Changelog" line links
#                 straight to that PR's /files diff.
#
# Requirements: curl, tar, yq, sort -V, awk, sed, grep
# Compatible with bash 3.2+ (macOS default) and bash 4+/5+ (Linux/CI)

set -euo pipefail

COLLECTION_INDEX_URL="https://releases.jfrog.io/artifactory/ansible/collections/jfrog/platform/"
ROLES=(artifactory xray distribution)
GITHUB_REPO="jfrog/JFrog-Cloud-Installers"

NEW_VERSION="${1:?Usage: $0 NEW_VERSION [OLD_VERSION] PR_NUMBER}"
OLD_VERSION="${2:-}"
PR_NUMBER="${3:?Usage: $0 NEW_VERSION [OLD_VERSION] PR_NUMBER}"

capitalize() {
    echo "$1" | awk '{print toupper(substr($0,1,1)) substr($0,2)}'
}

# "Full changelog" link straight to the PR carrying this update, e.g.
# https://github.com/jfrog/JFrog-Cloud-Installers/pull/512/files — the PR is
# the actual reviewable unit of change, so this links there rather than to a
# generic tag compare view. Appended inline to the Changelog heading line.
full_changelog_link_text() {
    local pr_number="$1"
    printf '<sub>Full changes refer [here](https://github.com/%s/pull/%s/files)</sub>' "$GITHUB_REPO" "$pr_number"
}

# ---------------------------------------------------------------------------
# Working files (downloaded archives, changelogs), cleaned up on exit
# ---------------------------------------------------------------------------

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

# ---------------------------------------------------------------------------
# Version comparison using sort -V
# ---------------------------------------------------------------------------

version_gt() {
    [[ "$1" != "$2" ]] && [[ "$(printf '%s\n%s' "$1" "$2" | sort -V | tail -1)" == "$1" ]]
}

# ---------------------------------------------------------------------------
# releases.jfrog.io: published collection versions + archives
# ---------------------------------------------------------------------------

# Every published collection version, one per line (parsed from the
# directory listing).
list_collection_versions() {
    curl -sSL --max-time 60 "$COLLECTION_INDEX_URL" 2>/dev/null \
        | grep -oE 'href="[0-9]+(\.[0-9]+)+/"' \
        | sed -E 's/href="([0-9.]+)\/"/\1/'
}

# The greatest published version strictly less than NEW_VERSION.
resolve_prev_version() {
    local new_version="$1" v best=""
    while IFS= read -r v; do
        [[ -z "$v" ]] && continue
        if version_gt "$new_version" "$v"; then
            if [[ -z "$best" ]] || version_gt "$v" "$best"; then
                best="$v"
            fi
        fi
    done < <(list_collection_versions)
    echo "$best"
}

# Download and extract a collection version's .tar.gz. Prints the extracted
# directory path (cached per version), or empty if unavailable.
fetch_collection() {
    local version="$1"
    local out_dir="${WORK_DIR}/collection-${version}"
    [[ -d "$out_dir" ]] && { echo "$out_dir"; return; }

    local url="${COLLECTION_INDEX_URL}${version}/jfrog-platform-${version}.tar.gz"
    local tgz="${WORK_DIR}/collection-${version}.tar.gz"
    if curl -sSLf --max-time 120 "$url" -o "$tgz" 2>/dev/null; then
        mkdir -p "$out_dir"
        tar -xzf "$tgz" -C "$out_dir" 2>/dev/null || true
        rm -f "$tgz"
    fi

    [[ -d "$out_dir" && -n "$(ls -A "$out_dir" 2>/dev/null)" ]] && echo "$out_dir" || echo ""
}

# Version pinned by a role's defaults/main.yml inside an extracted collection
# directory (empty if the collection dir or role file is unavailable).
role_version_in_collection() {
    local collection_dir="$1" role="$2"
    [[ -z "$collection_dir" ]] && { echo ""; return; }
    local path="${collection_dir}/roles/${role}/defaults/main.yml"
    [[ -f "$path" ]] || { echo ""; return; }
    grep -E "^${role}_version:" "$path" | head -1 \
        | sed -E 's/^[a-zA-Z_]+_version:[[:space:]]*"?([^"[:space:]]+)"?.*/\1/'
}

# ---------------------------------------------------------------------------
# Official JFrog docs release-notes links
# ---------------------------------------------------------------------------

docs_release_url() {
    local product="$1" app_version="$2"
    local compact="${app_version//./}"
    local base="https://docs.jfrog.com/releases/docs"
    case "$product" in
        artifactory)
            echo "${base}/artifactory-self-managed-releases#artifactory-${compact}-self-managed" ;;
        xray)
            echo "${base}/security-self-managed-releases#${compact}" ;;
        distribution)
            echo "${base}/distribution-release-notes#distribution-${compact}" ;;
        *)
            echo "" ;;
    esac
}

release_notes_suffix() {
    local product="$1" app_version="$2" url
    url=$(docs_release_url "$product" "$app_version")
    [[ -z "$url" ]] && { echo ""; return; }
    printf '%s<sub>📖 Official release notes: [%s %s](%s)</sub>' \
        "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;" \
        "$product" "$app_version" "$url"
}

# ---------------------------------------------------------------------------
# CHANGELOG parsing for the collection's own CHANGELOG.md
# ---------------------------------------------------------------------------

extract_changelog_section() {
    local file="$1" version="$2"
    [[ -n "$file" && -f "$file" ]] || return 0

    awk -v ver="$version" '
    /^(## )?\[/ {
        s = index($0, "[") + 1
        e = index($0, "]")
        v = substr($0, s, e - s)
        if (v == ver) { p = 1; next }
        else if (p) { exit }
    }
    p { print }
    ' "$file"
}

# Core true-delta algorithm: lines in NEW not present anywhere in OLD, with a
# fallback (only surfacing genuinely different content) when the only
# difference is the version header itself.
diff_changelog_content() {
    local old_file="$1" new_file="$2" old_version="$3" new_version="$4"

    if [[ -z "$new_file" || ! -f "$new_file" ]]; then
        echo "_No changelog found for \`$new_version\`._"
        return
    fi
    if [[ -z "$old_file" || ! -f "$old_file" ]]; then
        local section
        section=$(extract_changelog_section "$new_file" "$new_version")
        [[ -n "$section" ]] && echo "$section" || echo "_No changelog entry for \`$new_version\`._"
        return
    fi

    local raw content
    raw=$({ grep -vxF -f "$old_file" "$new_file" || true; } | sed '/^[[:space:]]*$/d')
    content=$(printf '%s\n' "$raw" | grep -vE '^#*[[:space:]]*\[[^]]*\]' || true)
    if [[ -z "$raw" || -z "$content" ]]; then
        local new_section old_section
        new_section=$(extract_changelog_section "$new_file" "$new_version")
        old_section=$(extract_changelog_section "$old_file" "$old_version")
        if [[ -n "$new_section" && "$new_section" != "$old_section" ]]; then
            echo "**[$new_version]**"
            printf '%s\n' "$new_section" | sed '/^[[:space:]]*$/d'
        else
            echo "_No changelog entries in range \`$new_version\` .. \`$old_version\`._"
        fi
        return
    fi
    printf '%s\n' "$raw" | sed 's/^#\{1,\}[[:space:]]*\(\[.*\)/**\1**/'
}

# Changelog delta for the collection's own CHANGELOG.md, sourced from
# releases.jfrog.io.
collection_changelog_delta() {
    local old_version="$1" new_version="$2"
    local old_dir new_dir
    old_dir=$(fetch_collection "$old_version")
    new_dir=$(fetch_collection "$new_version")
    local old_file="" new_file=""
    [[ -n "$old_dir" && -f "${old_dir}/CHANGELOG.md" ]] && old_file="${old_dir}/CHANGELOG.md"
    [[ -n "$new_dir" && -f "${new_dir}/CHANGELOG.md" ]] && new_file="${new_dir}/CHANGELOG.md"
    diff_changelog_content "$old_file" "$new_file" "$old_version" "$new_version"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

if [[ -z "$OLD_VERSION" ]]; then
    OLD_VERSION=$(resolve_prev_version "$NEW_VERSION")
fi

NEW_COLLECTION_DIR=$(fetch_collection "$NEW_VERSION")
if [[ -z "$NEW_COLLECTION_DIR" ]]; then
    echo "::error::Collection version ${NEW_VERSION} not found on ${COLLECTION_INDEX_URL}" >&2
    exit 1
fi

echo "## Ansible Collection Details"
echo ""
echo "| | Previous | New | Status |"
echo "|---|----------|-----|--------|"
printf '| **Collection Version** | `%s` | `%s` | :arrows_counterclockwise: Updated |\n' "${OLD_VERSION:-none}" "$NEW_VERSION"
echo ""

if [[ -n "$OLD_VERSION" ]]; then
    echo "## Changelog (\`$OLD_VERSION\` → \`$NEW_VERSION\`) $(full_changelog_link_text "$PR_NUMBER")"
else
    echo "## Changelog"
fi
echo ""
if [[ -n "$OLD_VERSION" ]]; then
    collection_changelog_delta "$OLD_VERSION" "$NEW_VERSION"
else
    section=$(extract_changelog_section "${NEW_COLLECTION_DIR}/CHANGELOG.md" "$NEW_VERSION")
    [[ -n "$section" ]] && echo "$section" || echo "_No changelog entry for \`$NEW_VERSION\`._"
fi
echo ""

if [[ -z "$OLD_VERSION" ]]; then
    echo "## Collection Changes"
    echo ""
    echo "_No previous collection version found — unable to compute dependency diffs._"
    exit 0
fi

OLD_COLLECTION_DIR=$(fetch_collection "$OLD_VERSION")

# ---- collection version summary ----
echo "## Collection Version Summary"
echo ""
echo "| Role | Previous | New | Status |"
echo "|------|----------|-----|--------|"

declare -a CHANGED_ROLES=()
for role in "${ROLES[@]}"; do
    old_v=$(role_version_in_collection "$OLD_COLLECTION_DIR" "$role")
    new_v=$(role_version_in_collection "$NEW_COLLECTION_DIR" "$role")
    if [[ "$old_v" != "$new_v" ]]; then
        printf '| **%s** | `%s` | `%s` | :arrows_counterclockwise: Updated |\n' "$(capitalize "$role")" "${old_v:-none}" "${new_v:-none}"
        CHANGED_ROLES+=("$role")
    else
        printf '| %s | `%s` | `%s` | Unchanged |\n' "$(capitalize "$role")" "$old_v" "$new_v"
    fi
done
echo ""

echo "## Collection Changes"
echo ""

if [[ "${#CHANGED_ROLES[@]}" -eq 0 ]]; then
    echo "_No dependency version changes detected._"
    exit 0
fi

for role in "${CHANGED_ROLES[@]}"; do
    old_v=$(role_version_in_collection "$OLD_COLLECTION_DIR" "$role")
    new_v=$(role_version_in_collection "$NEW_COLLECTION_DIR" "$role")

    echo "---"
    echo ""
    echo "### $(capitalize "$role") (\`$old_v\` → \`$new_v\`)$(release_notes_suffix "$role" "$new_v")"
    echo ""
    echo "Updated from \`$old_v\` to \`$new_v\`."
    echo ""
done
