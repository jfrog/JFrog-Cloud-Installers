#!/bin/bash

set -eu

repo_uri="https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"

remote_name="doc-upstream"
main_branch=$(basename "$(git symbolic-ref --short refs/remotes/origin/HEAD)")
target_branch="gh-pages"

cd "$GITHUB_WORKSPACE"
git config --local user.email "action@github.com"
git config --local user.name "GitHub Action"
git add -A
git add images
git add index.html
git commit -a -m "Updating documentation"
if [ $? -ne 0 ]; then
    echo "nothing to commit"
    exit 0
fi

git remote set-url origin ${repo_uri}
git push origin HEAD:${target_branch} --force
