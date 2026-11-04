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
- Grew the self-tests from 8 to 26 cases.
