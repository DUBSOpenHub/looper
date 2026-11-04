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
  ```
- **Install**:
  ```bash
  curl -fsSL https://raw.githubusercontent.com/DUBSOpenHub/looper/main/quickstart.sh | bash
  ```
  For another agent, use the GitHub CLI (`gh skill` is in preview):
  ```bash
  gh skill install DUBSOpenHub/looper looper --agent claude-code --scope user
  ```
- **Location**: `skills/looper/SKILL.md`

## File Map

| Path | Purpose |
|------|---------|
| `skills/looper/SKILL.md` | Execution policy and final verification gate |
| `skills/looper/scripts/pass-ledger.sh` | Pass counter and immutable ledger |
| `skills/looper/scripts/test_pass_ledger.py` | Standard-library self-tests |
| `skills/looper/templates/state.md` | Durable checkpoint template |
| `quickstart.sh` | Installer |
| `docs/` | PRD, architecture, and validation report |

## Non-Negotiables

1. **The 20-pass budget is fixed.** Never add a reset, refund, or configurable limit.
2. **State stays in `.ralph-loop/`.** Keep the directory name and `ralph-loop-pass-ledger-v1` marker for backward compatibility.
3. **No new runtime dependencies.** Bash for the helper, Python standard library for tests.
4. **Immutable history.** Reservations and results are never rewritten.
5. **Write "GitHub Copilot" in full** in all user-facing text.

## Before Opening a PR

Run from `skills/looper/`:

```bash
/bin/bash -n scripts/pass-ledger.sh
shellcheck scripts/pass-ledger.sh
python3 -B scripts/test_pass_ledger.py
```

CI (`validate`) must pass; `main` is protected and requires a pull request.
