# Changelog

All notable changes to **Deploy Packager** (`project_changes_generator`) will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

This file is managed by [release-please](https://github.com/googleapis/release-please).
Manual edits to `CHANGELOG.md` will be overwritten — add entries via conventional commits.

---

## [1.1.0](https://github.com/ekyaaa/deploy_packager/compare/v1.0.0...v1.1.0) (2026-09-11)


### Features

* add build feature (pnpm/npm and python collectstatic) ([58f9668](https://github.com/ekyaaa/deploy_packager/commit/58f96689927632dddf5a39c900501f78243a79d6))
* add file viewer and fix file picker bugs in windows ([a92721a](https://github.com/ekyaaa/deploy_packager/commit/a92721a9bd30bf740907c841dd3d6044306d0f1e))
* add github action to build windows apk ([2a63f2d](https://github.com/ekyaaa/deploy_packager/commit/2a63f2db263e8061831012195421b33de226e8ba))
* add history ([f1865f5](https://github.com/ekyaaa/deploy_packager/commit/f1865f5acf58f7f63887a8b80e4651c9d551ae85))
* add option to flush folder destination ([3ba5ba7](https://github.com/ekyaaa/deploy_packager/commit/3ba5ba7d0d2f711a1fc20ca2097d7ae87df81582))
* add remember last pick to folder picker ([c62ccc3](https://github.com/ekyaaa/deploy_packager/commit/c62ccc331465f98a640886ba1ca6b735b36e1c73))
* add support for tracking deleted files and file change statuses in git service and UI ([6787bf6](https://github.com/ekyaaa/deploy_packager/commit/6787bf62676be0d0361dfe639a915e7a0a600409))
* github action for windows instatller ([5b26462](https://github.com/ekyaaa/deploy_packager/commit/5b26462aa363df736f9b668ffe5eda1cb3c02878))
* implement project-specific export path persistence with global fallback ([1b8442e](https://github.com/ekyaaa/deploy_packager/commit/1b8442ef9421be78cab7a9d13d3adefda7aa2a66))
* init + finished ([b75e051](https://github.com/ekyaaa/deploy_packager/commit/b75e0519129e9fff11cd3bcad619ec8ec5016778))
* make build step optional with dynamic UI indicators and flow management ([61f7499](https://github.com/ekyaaa/deploy_packager/commit/61f7499acb3b57ac9ea6c7a7bdd5bb737b3ae0f9))


### Bug Fixes

* .exe build cmd ([bf3c0c3](https://github.com/ekyaaa/deploy_packager/commit/bf3c0c34dfcb41e10eeb5254e1dafd9312004c3d))
* build windows installer ([9036652](https://github.com/ekyaaa/deploy_packager/commit/9036652fa81eadb89c4f4bfcb8aca41e4c36eb65))
* crashing problem when view commit ([f053511](https://github.com/ekyaaa/deploy_packager/commit/f05351196aa3128765de4dc8890f3a10c7635583))
* github actions build windows installer ([e39e58d](https://github.com/ekyaaa/deploy_packager/commit/e39e58d4df51cebac4ad3718406373d54e35936f))
* github actions windows installer ([f018287](https://github.com/ekyaaa/deploy_packager/commit/f018287ba906a477ef9dddc90e6c9e0d9d59c6ed))
* output path independent. not harcoded always on working dir ([140f3a3](https://github.com/ekyaaa/deploy_packager/commit/140f3a364b2dd24e132e75cae6659f29186a3099))
* path and venv bug ([6ad2c9c](https://github.com/ekyaaa/deploy_packager/commit/6ad2c9ce91430d0fa20302537e2dafd06bc3ebfc))
* resolve Set&lt;dynamic&gt; type error on Select All button ([d2b7d22](https://github.com/ekyaaa/deploy_packager/commit/d2b7d22a5afaa208a55a17a33e5217d8576a5b52))

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
