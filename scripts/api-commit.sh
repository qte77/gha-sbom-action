#!/usr/bin/env bash
# Commit the staged changes through the GitHub Git Data API and create a branch at the new commit.
# Usage: api-commit.sh <owner/repo> <base-sha> <branch> <message>
# Prints the new commit sha. Needs GH_TOKEN (or GITHUB_TOKEN) for gh, run from the repo root.
#
# Reason: a commit created through the API with no author or committer is signed by GitHub and
# shows as Verified, so it passes a required_signatures rule; a local `git commit` from a runner
# is unsigned. Nothing is committed or pushed locally.
set -euo pipefail

if [[ $# -ne 4 ]]; then
  echo "usage: $0 <owner/repo> <base-sha> <branch> <message>" >&2
  exit 2
fi
repo=$1 base=$2 branch=$3 message=$4
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

base_tree=$(gh api "repos/$repo/git/commits/$base" --jq '.tree.sha')

# Reason: blobs go through --input files, since an SBOM can exceed the per-argument size limit.
entries="$tmp/entries.jsonl"
: > "$entries"
while IFS=$'\t' read -r status path; do
  if [[ $status == D ]]; then
    jq -nc --arg p "$path" '{path: $p, mode: "100644", type: "blob", sha: null}' >> "$entries"
  else
    base64 -w0 "$path" | jq -Rs '{content: ., encoding: "base64"}' > "$tmp/blob.json"
    sha=$(gh api "repos/$repo/git/blobs" --input "$tmp/blob.json" --jq '.sha')
    jq -nc --arg p "$path" --arg s "$sha" '{path: $p, mode: "100644", type: "blob", sha: $s}' >> "$entries"
  fi
done < <(git diff --cached --name-status --no-renames)

jq -s --arg b "$base_tree" '{base_tree: $b, tree: .}' "$entries" > "$tmp/tree.json"
tree=$(gh api "repos/$repo/git/trees" --input "$tmp/tree.json" --jq '.sha')

jq -n --arg m "$message" --arg t "$tree" --arg p "$base" '{message: $m, tree: $t, parents: [$p]}' > "$tmp/commit.json"
commit=$(gh api "repos/$repo/git/commits" --input "$tmp/commit.json" --jq '.sha')

gh api "repos/$repo/git/refs" -f "ref=refs/heads/$branch" -f "sha=$commit" --jq '.ref' > /dev/null
echo "$commit"
