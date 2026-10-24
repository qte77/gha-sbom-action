# Configuration

## Prerequisites

The calling repository must have a `pyproject.toml` (and optionally `uv.lock`). The action runs
`uv sync` to resolve Python dependencies before scanning.

## Inputs

| Name | Required | Default | Description |
| --- | --- | --- | --- |
| `sbom_dir` | no | `docs/SBOM` | Directory to store SBOM output files |
| `python_version` | no | `3.12` | Python version for uv to install |
| `create_pr` | no | `true` | Whether to create a PR with SBOM changes |
| `github_token` | **yes** | — | GitHub token for API access and PR creation |

## Outputs

| Name | Description |
| --- | --- |
| `sbom_dir` | Path to the directory containing generated SBOM files |
| `changed` | Whether SBOM files changed (`true` or `false`) |
| `pr_url` | URL of the created PR (empty if no PR was created) |

## How it works

1. Installs uv and Python, then runs `uv sync` to resolve dependencies
2. Fetches the GitHub dependency graph SBOM via `gh api` (SPDX JSON) into `github-depgraph.spdx.json`
3. Runs Syft against the repo directory (SPDX JSON) into `syft-scan.spdx.json`
4. If files changed and `create_pr` is `true`, opens a PR with the updates

The calling workflow needs `contents: write` and `pull-requests: write` permissions for step 4.
