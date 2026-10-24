# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Release workflows as thin callers of the `qte77/.github` reusables: `bump-version` (dispatch, opens a signed bump PR and syncs `uv.lock`), `tag-release` (tags `vX.Y.Z` when the `pyproject.toml` version changes on `main`) and `publish-release` (dispatch, GitHub Release from the CHANGELOG block); none of them delete or overwrite tags or releases (#23)

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
