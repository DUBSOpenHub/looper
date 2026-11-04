# 📋 Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- README "Works With" section and a `gh skill install` route for using Looper with AI agents other than the GitHub Copilot CLI.
- README FAQ entries on whether GitHub Copilot is required and on the `state path must not contain symlinks` error (for example, projects under `/tmp` on macOS).

### Changed
- Positioned Looper as a skill in the open Agent Skills format, built for GitHub Copilot, rather than as a GitHub Copilot CLI-only skill. README, AGENTS.md, SECURITY.md, CONTRIBUTING.md, and the bug report template now say so.

### Fixed
- Corrected the Dependabot alerts status note in SECURITY.md, which still blamed the dependency graph for alerts not being enabled.

## [1.0.0] - 2026-11-04

### Added
- 🔁 First public release of Looper, a bounded 20-pass loop skill for the GitHub Copilot CLI.
- `quickstart.sh` installer for `~/.copilot/skills/looper/`.
- GitHub Actions `validate` workflow: Bash syntax, ShellCheck, self-tests, and skill frontmatter checks.

### Changed
- Renamed the callable skill from `ralph-loop` to `looper`. The `.ralph-loop/` state directory and `ralph-loop-pass-ledger-v1` marker are unchanged, so existing ledgers stay resumable.
- Hardened the pass-ledger helper: safer path and record validation, staged writes, immutable outcomes, and lock/signal cleanup.
- Clarified recovery, safe checkpoint, evidence-freshness, bounded-repair, and final-gate instructions in `SKILL.md`.
- Extended `templates/state.md` with writer/recovery, evidence, snapshot, repair, and final-gate fields.
- Grew the self-tests from 8 to 27 cases.

### Fixed
- Lock acquisition now stays correct when `mkdir` is not a reliable mutex. Some implementations (for example uutils coreutils, the default on Ubuntu 26.04) report success to a concurrent caller that lost the race, so two processes could both believe they held `.lock`. The exclusive create of `.lock/owner` now decides the winner; the loser exits `4` ("locked") and never claims or cleans up the winner's lock. Previously the loser exited `1`.
- CI now covers this on a current Ubuntu runner, and a regression test models the lenient `mkdir` on any platform.
