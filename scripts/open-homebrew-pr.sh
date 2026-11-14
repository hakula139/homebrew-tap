#!/usr/bin/env bash
set -euo pipefail

case "$FORMULA" in
  kiln | oxide-code) ;;
  *) exit 1 ;;
esac
[[ "$TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$ ]]

source_repo="hakula139/$FORMULA"
# Follow the latest stable release, or the newest prerelease before the first stable one.
latest=$(
  gh api graphql \
    -F owner=hakula139 \
    -F name="$FORMULA" \
    -f query="query(\$owner: String!, \$name: String!) {
      repository(owner: \$owner, name: \$name) {
        latestRelease { tagName }
      }
    }" \
    --jq '.data.repository.latestRelease.tagName // empty'
)
if [[ -z "$latest" ]]; then
  latest=$(
    gh release list \
      --repo "$source_repo" \
      --exclude-drafts \
      --limit 1 \
      --json tagName \
      --jq '.[0].tagName // empty'
  )
fi
if [[ -z "$latest" ]]; then
  echo '::error::No published release found for the Homebrew formula'
  exit 1
fi
if [[ "$latest" != "$TAG" ]]; then
  echo "Skipping $FORMULA $TAG, since the formula follows $latest."
  exit 0
fi

scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
gh release download "$TAG" \
  --repo "$source_repo" \
  --pattern "$FORMULA-*.sha256" \
  --dir "$scratch"
nu scripts/update-homebrew-formula.nu "$FORMULA" "$TAG" "$scratch" \
  --output "$scratch/formula.rb"

branch="chore/homebrew-$FORMULA-$TAG"
title="chore($FORMULA): refresh Homebrew formula for $TAG"
existing=false
if git ls-remote \
  --exit-code \
  origin "refs/heads/$branch" \
  >/dev/null; then
  existing=true
  git fetch origin "refs/heads/$branch"
  git switch -c "$branch" FETCH_HEAD
else
  rc=$?
  if [[ "$rc" != 2 ]]; then
    exit "$rc"
  fi
  git switch -c "$branch"
fi

cp "$scratch/formula.rb" "Formula/$FORMULA.rb"
if git diff --quiet -- "Formula/$FORMULA.rb"; then
  echo "The formula already points at $TAG."
  if [[ "$existing" == false ]]; then
    exit 0
  fi
else
  git add "Formula/$FORMULA.rb"
  git diff --cached --name-only
  git \
    -c user.name='hakula-release-bot[bot]' \
    -c user.email='351352052+hakula-release-bot[bot]@users.noreply.github.com' \
    commit \
    -m "$title" \
    -- "Formula/$FORMULA.rb"
  git push origin "$branch"
fi

number=$(
  gh pr list \
    --head "$branch" \
    --state open \
    --json number \
    --jq '.[0].number // empty'
)
if [[ -z "$number" ]]; then
  gh pr create \
    --base main \
    --head "$branch" \
    --title "$title" \
    --assignee hakula139 \
    --label chore \
    --body-file .github/templates/homebrew-formula-pr.md
else
  gh pr edit "$number" \
    --title "$title" \
    --body-file .github/templates/homebrew-formula-pr.md
fi
