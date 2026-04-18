# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.1.0] - 2026-04-17

### Added

- Composite GitHub Action for SBOM generation
- GitHub dependency graph SBOM export (SPDX JSON)
- Syft directory scan SBOM generation (SPDX JSON)
- Optional PR creation with SBOM updates
- Configurable inputs: `sbom_dir`, `python_version`, `create_pr`, `github_token`
- Syft DB caching via `actions/cache`
- uv caching via `astral-sh/setup-uv`
- CodeQL security scanning workflow
- Manual test workflow for action validation
