# Changelog

All notable changes to **Deploy Packager** (`project_changes_generator`) will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

This file is managed by [release-please](https://github.com/googleapis/release-please).
Manual edits to `CHANGELOG.md` will be overwritten — add entries via conventional commits.

---

## [1.0.0] - 2026-09-02

> Initial stable release. Covers all changes from repository inception (`b75e051`) to `3ba5ba7` (last commit before versioning automation).

### Added
- Core Deploy Packager flow: Project picker → Commits → Changed Files → Export (`b75e051`)
- README and project documentation (`91ae4ca`)
- Commit history and persistence (`f1865f5`)
- Remember last picked folder for project/export pickers (`c62ccc3`)
- File viewer dialog + Windows file-picker bug fixes (`a92721a`)
- Windows build GitHub Actions (`2a63f2d`, `5b26462`)
- Build feature: `pnpm`/`npm` and `python collectstatic` with configurable commands (`58f9668`)
- Option to flush destination folder + static-dist info path improvements (`3ba5ba7`)

### Fixed
- `.exe` build command in workflow (`bf3c0c3`)
- Windows installer GitHub Actions (`f018287`, `e39e58d`, `9036652`)
- Crash when viewing commit diff (`f053511`)
- `Set<dynamic>` type error on Select All button (`d2b7d22` via `dbe359f`)
- Path / venv bugs + custom command handling (`6ad2c9c`)
- Hardcoded output path — now independent of working dir (`140f3a3`)

### Changed
- Windows installer hardening across multiple iterations (`5b26462` → `9036652`)

### Technical
- Flutter desktop (Windows/Linux/macOS), Material 3 dark theme, Riverpod single-file providers (`lib/providers/app_providers.dart`)
- Git operations via CLI (`git diff-tree --name-status -r`, empty-tree fallback `4b825de`)
- `BuildService` via `Process.run` for npm/pnpm/python

---

## [Unreleased]

<!-- release-please will insert new releases above this line; keep this section empty -->

