# gha-sbom-action

![Version](https://img.shields.io/badge/version-0.1.1-8A2BE2)
![License](https://img.shields.io/badge/license-Apache--2.0-blue)
![Test Action](https://github.com/qte77/gha-sbom-action/actions/workflows/test-action.yaml/badge.svg)
![CodeFactor](https://www.codefactor.io/repository/github/qte77/gha-sbom-action/badge)
![CodeQL](https://github.com/qte77/gha-sbom-action/actions/workflows/codeql.yaml/badge.svg)
[![Dependabot Updates](https://github.com/qte77/gha-sbom-action/actions/workflows/dependabot/dependabot-updates/badge.svg)](https://github.com/qte77/gha-sbom-action/actions/workflows/dependabot/dependabot-updates)

Composite GitHub Action that generates SPDX SBOM files using the GitHub dependency graph API and [Syft](https://github.com/anchore/syft), optionally opening a pull request with the results.

## Prerequisites

The calling repository must have a `pyproject.toml` (and optionally `uv.lock`). The action runs `uv sync` to resolve Python dependencies before scanning.

## Inputs

| Name | Required | Default | Description |
|------|----------|---------|-------------|
| `sbom_dir` | no | `docs/SBOM` | Directory to store SBOM output files |
| `python_version` | no | `3.12` | Python version for uv to install |
| `create_pr` | no | `true` | Whether to create a PR with SBOM changes |
| `github_token` | **yes** | — | GitHub token for API access and PR creation |

## Outputs

| Name | Description |
|------|-------------|
| `sbom_dir` | Path to the directory containing generated SBOM files |
| `changed` | Whether SBOM files changed (`true` or `false`) |
| `pr_url` | URL of the created PR (empty if no PR was created) |

## Usage

```yaml
name: Generate SBOM

on:
  push:
    branches: [main]
  schedule:
    - cron: "0 0 * * 0"
  workflow_dispatch:

permissions:
  contents: write
  pull-requests: write

jobs:
  sbom:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: qte77/gha-sbom-action@v0.1.1
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
```bash

## What it does

1. Installs uv and Python, then runs `uv sync` to resolve dependencies
2. Fetches the GitHub dependency graph SBOM via `gh api` (SPDX JSON)
3. Runs Syft against the repo directory (SPDX JSON)
4. If files changed and `create_pr` is `true`, opens a PR with the updates

## License

[Apache-2.0](LICENSE)
