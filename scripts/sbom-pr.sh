#!/usr/bin/env bash
# Open the SBOM PR for <branch>, or reuse the one already open for it, then try to merge it.
# Usage: sbom-pr.sh <owner/repo> <branch> <commit-sha> <base-sha> <title> <body> <auto_merge: true|false>
#   <commit-sha>: the commit api-commit.sh just pointed <branch> at; <base-sha>: its parent.
# Prints progress lines, then the PR URL as the last line. Needs GH_TOKEN for gh.
#
# Reason: a fixed branch keeps at most one SBOM PR open per repo; api-commit.sh force-moves the
# branch, which updates that PR in place. Merging follows qte77/gha-rxiv-feed-action#249:
# auto-merge (squash) when the repo allows it, else a direct squash merge if the PR is mergeable
# now. Unlike that action this step does not wait: the next run rebuilds the branch from the
# current base anyway, and a required check that never runs on a GITHUB_TOKEN PR (#37) must not
# fail the run. A PR that can't merge yet stays open with a notice.
set -euo pipefail

if [[ $# -ne 7 ]]; then
  echo "usage: $0 <owner/repo> <branch> <commit-sha> <base-sha> <title> <body> <auto_merge>" >&2
  exit 2
fi
repo=$1 branch=$2 commit=$3 base=$4 title=$5 body=$6 auto_merge=$7
if [[ ! $commit =~ ^[0-9a-f]{40}$ || ! $base =~ ^[0-9a-f]{40}$ ]]; then
  echo "commit and base must be full commit shas" >&2
  exit 2
fi

# Reason: --head matches the branch name in any repository, so a fork PR named like this branch
# would match too; only a PR from this repository's own branch is the SBOM PR.
url=$(gh pr list --repo "$repo" --head "$branch" --state open --json url,isCrossRepository \
  --jq '[.[] | select(.isCrossRepository == false)][0].url // empty')
if [[ -n $url ]]; then
  echo "Updated the open SBOM PR in place: $url"
else
  url=$(gh pr create --repo "$repo" --base main --head "$branch" --title "$title" --body "$body")
fi

if [[ $auto_merge == true ]]; then
  # Reason: the SBOM commit's parent is the checked-out HEAD. Merging is only safe when that is
  # main's current tip; otherwise the PR would also bring in commits nobody reviewed for main.
  main_tip=$(gh api "repos/$repo/git/ref/heads/main" --jq '.object.sha')
  if [[ $base != "$main_tip" ]]; then
    echo "::notice::SBOM PR left open for review: it was built from $base, not main's current tip. $url"
  # Reason: both merges are pinned to the commit made in this run, so nothing pushed to the
  # branch afterwards is merged unseen.
  elif gh pr merge "$url" --repo "$repo" --auto --squash --match-head-commit "$commit"; then
    echo "Auto-merge (squash) enabled; the PR merges once its required checks pass."
  elif gh api -X PUT "repos/$repo/pulls/${url##*/}/merge" \
    -f merge_method=squash -f "commit_title=$title" -f "sha=$commit" > /dev/null; then
    echo "Auto-merge is not available; merged directly (squash)."
  else
    echo "::notice::SBOM PR left open: auto-merge is not enabled in this repository and the PR can't merge yet. $url"
  fi
fi

echo "$url"
