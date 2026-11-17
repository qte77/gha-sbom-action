# Configuration

## Prerequisites

The calling repository must have a `pyproject.toml` (and optionally `uv.lock`). The action runs
`uv sync` to resolve Python dependencies before scanning.

## Inputs

| Name | Required | Default | Description |
| --- | --- | --- | --- |
| `sbom_dir` | no | `docs/SBOM` | Directory to store SBOM output files |
| `python_version` | no | `3.12` | Python version for uv to install |
| `create_pr` | no | `true` | Whether to open (or update) a PR with SBOM changes |
| `auto_merge` | no | `true` | Enable auto-merge (squash) on the SBOM PR, or merge it directly if auto-merge is unavailable and it is mergeable, and only when the run built on `main`'s current tip; `false` leaves it open for review |
| `github_token` | **yes** | — | GitHub token for API access and PR creation |

## Outputs

| Name | Description |
| --- | --- |
| `sbom_dir` | Path to the directory containing generated SBOM files |
| `changed` | Whether SBOM files changed (`true` or `false`) |
| `pr_url` | URL of the SBOM PR: newly opened, or the open one updated in place (empty if `create_pr` is `false` or nothing changed) |

## How it works

1. Installs uv and Python, then runs `uv sync` to resolve dependencies
2. Fetches the GitHub dependency graph SBOM via `gh api` (SPDX JSON) into `github-depgraph.spdx.json`
3. Runs Syft against the repo directory (SPDX JSON) into `syft-scan.spdx.json`
4. If files changed and `create_pr` is `true`, commits them through the GitHub Git Data API
   (`scripts/api-commit.sh`: blobs, tree, commit with no author or committer, branch ref). GitHub
   signs API-created commits, so the PR passes a required-signatures rule; nothing is committed or
   pushed from the runner
5. The commit goes to one fixed branch, `auto/sbom-update`, created on the first run and
   force-moved to the new commit on later runs (`scripts/sbom-pr.sh`). If a PR for that branch is
   open, it is updated in place; otherwise a new one is opened. So at most one SBOM PR is open per
   repository. A PR from a fork that happens to use the same branch name is never treated as the
   SBOM PR
6. With `auto_merge: true`, the action enables auto-merge (squash), which merges once the required
   checks pass. If the repository doesn't allow auto-merge, it tries a direct squash merge and
   otherwise leaves the PR open with a notice. It never waits or fails the run on a merge it can't
   make. A required check that only runs on `push` won't report on a PR opened with
   `GITHUB_TOKEN`, so such a PR stays open (#37). Both merges are pinned to the commit made in
   that run, so a later push to the branch is not merged unseen. The action only merges when the
   run built on the current tip of `main` (for example a run on `main` or on a schedule); a run on
   any other commit, such as a feature branch, leaves the PR open for review with a notice, since
   merging it would also bring that branch's commits into `main`

The calling workflow needs `contents: write` and `pull-requests: write` permissions for step 4.
