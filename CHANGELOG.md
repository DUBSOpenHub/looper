# 📋 Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Documentation
- Updated the README introduction to explain how Looper helps AI coding agents complete complex tasks, preserve progress, and verify results.
- Added a profile-style animated SVG header with a reduced-motion fallback, simplified explanations throughout the README, and aligned the README, skill description, and repository About wording.
- Rewrote the README introduction, skill description, and supporting overviews in plain language; explained the work cycle, saved progress (“durable state”), and the 20-attempt limit without changing behavior.
- Corrected the README helper example to use the installed helper path, hash working-tree file contents, and keep repair instructions separate from the passing path.
- Aligned AGENTS.md, CONTRIBUTING.md, and SECURITY.md with named loops, evidence boundaries, and documentation-only checks.
- Clarified tested agent coverage, legacy-loop upgrades, local versus release installs, and the limits of checksums and build provenance.
- Added prominent links to the repository's agent instructions, security policy, contribution guide, and release history.

## [1.1.0] - 2026-11-04

### Added
- Evidence gates in the pass-ledger helper. `run` executes a check, records its exact command, working directory, output, exit code, phase, and covered acceptance criteria under `passes/NN/runs/`, enforces a timeout on the whole process group, and releases the ledger lock while the command runs. `repair` records the single repair batch a work pass may use.
- `criteria COUNT` records the number of acceptance criteria. The count can only grow, so criteria cannot be dropped to get a green final gate.
- `verdict` reports whether a loop is complete (`complete=yes final=NN criteria=N`) or why it is not.
- Named loops for independent goals: `.ralph-loop-<name>/` state with its own budget, and `PROJECT_ROOT loops` to list every loop in a project.
- Pinned, verifiable releases. Each tagged release publishes `looper-vX.Y.Z.tar.gz`, `quickstart.sh`, and `SHA256SUMS`, with GitHub build provenance attestations.
- Installer tests (`tests/test_quickstart.py`) and the release builder `tools/build-release.sh`.
- A recorded end-to-end run through the GitHub Copilot CLI in `docs/VALIDATION.md`.
- README "Works With" section and a `gh skill install` route for using Looper with AI agents other than the GitHub Copilot CLI.
- README FAQ entries on whether GitHub Copilot is required and on the `state path must not contain symlinks` error (for example, projects under `/tmp` on macOS).

### Changed
- `close NN passed` now requires recorded evidence and exits `6` without it. A work pass needs every run in its deciding phase to exit 0, including a rerun of every check that failed before `repair`. A final pass needs matching opening and closing snapshots, every run to exit 0, and a check for every acceptance criterion. Each command may run at most three times per phase. Ledgers created by v1.0 stay readable, but their open passes must be closed `failed` or `interrupted` and verified again.
- New exit codes: `6` (refused by an evidence gate or rule) and `7` (the recorded command failed).
- `quickstart.sh` installs a pinned release version, verifies it against `SHA256SUMS`, accepts an optional `LOOPER_SHA256` pin and `LOOPER_VERIFY_ATTESTATION=1` provenance check, refuses branch names, and rejects archives with unexpected paths or links. It no longer downloads from the `main` branch.
- Positioned Looper as a skill in the open Agent Skills format, built for GitHub Copilot, rather than as a GitHub Copilot CLI-only skill. README, AGENTS.md, SECURITY.md, CONTRIBUTING.md, and the bug report template now say so.
- Grew the helper self-tests from 27 to 37 cases.

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
