# 📋 Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
