#!/usr/bin/env bash
# Open the SBOM PR for <branch>, or reuse the one already open for it, then try to merge it.
# Usage: sbom-pr.sh <owner/repo> <branch> <title> <body> <auto_merge: true|false>
# Prints progress lines, then the PR URL as the last line. Needs GH_TOKEN for gh.
#
# Reason: a fixed branch keeps at most one SBOM PR open per repo; api-commit.sh force-moves the
# branch, which updates that PR in place. Merging follows qte77/gha-rxiv-feed-action#249:
# auto-merge (squash) when the repo allows it, else a direct squash merge if the PR is mergeable
# now. Unlike that action this step does not wait: the next run rebuilds the branch from the
# current base anyway, and a required check that never runs on a GITHUB_TOKEN PR (#37) must not
# fail the run. A PR that can't merge yet stays open with a notice.
set -euo pipefail

if [[ $# -ne 5 ]]; then
  echo "usage: $0 <owner/repo> <branch> <title> <body> <auto_merge>" >&2
  exit 2
fi
repo=$1 branch=$2 title=$3 body=$4 auto_merge=$5

url=$(gh pr list --repo "$repo" --head "$branch" --state open --json url --jq '.[0].url // empty')
if [[ -n $url ]]; then
  echo "Updated the open SBOM PR in place: $url"
else
  url=$(gh pr create --repo "$repo" --base main --head "$branch" --title "$title" --body "$body")
fi

if [[ $auto_merge == true ]]; then
  if gh pr merge "$url" --repo "$repo" --auto --squash; then
    echo "Auto-merge (squash) enabled; the PR merges once its required checks pass."
  elif gh api -X PUT "repos/$repo/pulls/${url##*/}/merge" \
    -f merge_method=squash -f "commit_title=$title" > /dev/null; then
    echo "Auto-merge is not available; merged directly (squash)."
  else
    echo "::notice::SBOM PR left open: auto-merge is not enabled in this repository and the PR can't merge yet. $url"
  fi
fi

echo "$url"
