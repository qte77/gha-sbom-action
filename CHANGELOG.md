# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Changed

- Release workflows re-pinned to `qte77/.github@a32769a` (main 2026-11-12, qte77/.github#64); compatibility checked, no breaking input/output changes.

## [0.1.2] - 2026-11-11

### Added

- Release workflows as thin callers of the `qte77/.github` reusables: `bump-version` (dispatch, opens a signed bump PR and syncs `uv.lock`), `tag-release` (tags `vX.Y.Z` when the `pyproject.toml` version changes on `main`) and `publish-release` (dispatch, GitHub Release from the CHANGELOG block); none of them delete or overwrite tags or releases (#23)

### Changed

- Release workflows re-pinned to `qte77/.github@43ad121`. `tag-release` now also publishes the GitHub Release for a new tag in the same run, chained on the reusable's new `tag` output, so a merged bump no longer needs a manual `publish-release` dispatch (it stays as a retry). Upstream, the bump commit is now created through `createCommitOnBranch`, so GitHub signs it; the new optional App-token inputs stay unset.
- README follows the qte77 doc-structure canon (What → How → Why → Refs → License); prerequisites, inputs, outputs and internals moved to `docs/configuration.md` (#21)
- CI pins `actions/checkout` and `github/codeql-action` to full commit SHAs (with a `# vX.Y.Z` comment), so the workflows run under a "require full-length SHA pinning" Actions policy; Dependabot uses the `uv` ecosystem instead of `pip` and groups its updates (codeql-action together; minor and patch per ecosystem; majors as separate PRs)

### Fixed

- SBOM PRs are no longer blocked by a required-signatures rule: the action commits through the GitHub Git Data API (`scripts/api-commit.sh`, no author or committer, so GitHub signs the commit) instead of a local `git commit` and `git push` as `github-actions`. Covered by BATS tests (`tests/api-commit.bats`) run in the new `Test scripts` workflow
- Dependency-graph SBOM export no longer commits the API error body (e.g. 404 when Dependency Graph is disabled) as `github-depgraph.spdx.json`; the file is only written when the response is a valid SPDX document, otherwise the step emits a warning and skips it (#16)

## [0.1.1] - 2026-04-22

### Changed

- Rename action for GitHub Marketplace uniqueness
- Add prerequisites section and badge set to README

## [0.1.0] - 2026-04-17

### Added

- Composite GitHub Action for SBOM generation (SPDX JSON)
- GitHub dependency graph export and Syft directory scan
- Optional PR creation with SBOM updates
- Syft DB and uv caching for faster runs
- All third-party actions pinned to commit SHA
- CodeQL scanning and manual test workflows
