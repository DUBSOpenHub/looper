# Agents

## Overview

This repository ships one skill in the open [Agent Skills](https://agentskills.io/specification) format, **looper**, built for GitHub Copilot. It is a skill, not a standalone agent.

## Available Skills

### looper

- **Purpose**: Carries a request to verified completion through a bounded loop of small, testable steps, with durable project-local state and a hard limit of 20 passes.
- **Usage**: Open GitHub Copilot, or any agent that has the skill installed, in a project and say:
  ```
  looper
  looper <your request>
  looper resume
  looper as <name>: <an independent request>
  looper resume <name>
  looper list
  ```
- **Install**:
  ```bash
  curl -fsSL https://github.com/DUBSOpenHub/looper/releases/download/v1.1.0/quickstart.sh | bash
  ```
  The installer downloads that pinned release and checks it against `SHA256SUMS`.
  For another agent, use the GitHub CLI (`gh skill` is in preview):
  ```bash
  gh skill install DUBSOpenHub/looper looper@v1.1.0 --agent claude-code --scope user
  ```
- **Location**: `skills/looper/SKILL.md`

## File Map

| Path | Purpose |
|------|---------|
| `skills/looper/SKILL.md` | Execution policy and final verification gate |
| `skills/looper/scripts/pass-ledger.sh` | Pass counter, immutable ledger, and evidence gates |
| `skills/looper/scripts/test_pass_ledger.py` | Standard-library self-tests |
| `skills/looper/templates/state.md` | Durable checkpoint template |
| `quickstart.sh` | Pinned, checksum-verified installer |
| `tools/build-release.sh` | Builds release assets and `SHA256SUMS` |
| `tests/test_quickstart.py` | Installer and release-build tests |
| `e2e/run-copilot-e2e.sh` | End-to-end run through the GitHub Copilot CLI |
| `.github/workflows/release.yml` | Publishes attested release assets for `vX.Y.Z` tags |
| `README.md` | User-facing installation, usage, and compatibility guidance |
| `SECURITY.md` | Supported versions, private reporting, and trust boundaries |
| `CONTRIBUTING.md` | Development and release process |
| `CHANGELOG.md` | Release history and unreleased changes |
| `docs/` | PRD, architecture, and validation report |

## Non-Negotiables

1. **The 20-pass budget is fixed.** Never add a reset, refund, or configurable limit.
2. **Preserve state compatibility.** The default loop stays in `.ralph-loop/`; independent named goals use `.ralph-loop-NAME/`. Keep the `ralph-loop-pass-ledger-v1` marker and spent-pass history. Never use a new name to renew a goal's budget; use separate worktrees for concurrent edits.
3. **Passing needs recorded evidence.** Never let `close passed` or `verdict` succeed without the helper's own run records.
4. **No new runtime dependencies.** Bash for the helper, Python standard library for tests.
5. **Immutable history.** Reservations and results are never rewritten.
6. **Write "GitHub Copilot" in full** in all user-facing text.
7. **Keep claims evidence-based.** The helper enforces recorded results, not verifier quality or a sandbox. Preserve the distinction between tested hosts and intended Agent Skills compatibility, and between checksum integrity, provenance, and code safety.

Read [CONTRIBUTING.md](CONTRIBUTING.md) before changing the project and [SECURITY.md](SECURITY.md) before handling vulnerability reports. The PRD and original architecture are historical v1.0 records with v1.1 addenda; the current skill, helper, and changelog define the current behavior.

## Before Opening a PR

Run from `skills/looper/`:

```bash
/bin/bash -n scripts/pass-ledger.sh
shellcheck scripts/pass-ledger.sh
python3 -B scripts/test_pass_ledger.py
```

From the repository root:

```bash
/bin/bash -n quickstart.sh
/bin/bash -n tools/build-release.sh
/bin/bash -n e2e/run-copilot-e2e.sh
shellcheck quickstart.sh tools/build-release.sh e2e/run-copilot-e2e.sh
python3 -B tests/test_quickstart.py
```

For documentation-only changes, check changed links and any changed runnable examples; do not rerun a live AI task unless execution behavior needs verification. Add user-visible changes under `Unreleased` in the changelog. Do not rewrite released validation results or retag an immutable release.

CI (`validate`) must pass; `main` is protected and requires a pull request. Preserve pre-existing changes and do not bypass branch protection.
