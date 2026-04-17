# gha-sbom-action

![Version](https://img.shields.io/badge/version-0.1.0-8A2BE2)

Generate SPDX SBOM via GitHub dependency graph and Syft.

## Inputs

| Name | Required | Default | Description |
|------|----------|---------|-------------|
| `github_token` | Yes | `${{ github.token }}` | GitHub token for API access and PR creation |
| `sbom_dir` | No | `docs/SBOM` | Output directory for SBOM files |
| `create_pr` | No | `true` | Create a PR with changes (true/false) |

## Outputs

| Name | Description |
|------|-------------|
| `changed` | Whether SBOM files changed (true/false) |
| `pr_url` | URL of created PR (empty if unchanged or create_pr=false) |

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
  generate-sbom:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: qte77/gha-sbom-action@v0
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
```

## What it does

1. Exports the GitHub dependency graph SBOM (SPDX format) via the GitHub API
2. Installs [Syft](https://github.com/anchore/syft) and scans the repository
3. Writes both SBOMs to the configured output directory
4. Creates a PR if files changed (optional)

## License

[Apache-2.0](LICENSE)
