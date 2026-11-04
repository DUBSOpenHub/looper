# Validation Report

Recorded results for Looper v1.1.0, tested on November 4, 2026. This is release-specific evidence, not a claim that every agent or future revision has passed the same checks.

| Suite | Result |
|-------|--------|
| Helper self-tests (`skills/looper/scripts/test_pass_ledger.py`) | 37 / 37 passed (macOS; Ubuntu in CI) |
| Installer and release-build tests (`tests/test_quickstart.py`) | 8 / 8 passed |
| End-to-end run through the GitHub Copilot CLI (`e2e/run-copilot-e2e.sh`) | Passed (details below) |
| Bash syntax check and ShellCheck | Passed for every shell script |
| v1.0.0 sealed acceptance tests (Dark Factory, hidden from the builder) | 17 / 17 passed at v1.0.0 |

## End-to-end run

On 2026-11-04 the GitHub Copilot CLI 1.0.105 ran Looper v1.1.0 non-interactively (`copilot -p`, autopilot, no `ask_user`, no custom instructions, model chosen automatically) in a fresh Git project. The request was to build `slug.py` with `slugify(text, max_length=None)`, a CLI, and unittest tests, following eight stated rules.

| Check | Result |
|-------|--------|
| GitHub Copilot loaded the `looper` skill and used the bundled helper | Yes |
| Acceptance criteria recorded | 6 (`criteria 6`) |
| Passes used | 2 of 20: one work pass, one final pass |
| Recorded runs | 9 |
| Work pass 01 | Baseline `python3 -m unittest -v` exited 5 (no tests yet), recorded before any edit. Three initial checks (unit tests, a standard-library import and documentation check, `git diff --check`) exited 0. No repair was needed. Closed `passed`. |
| Final pass 02 | Snapshot of every deliverable file's SHA-256 plus the Python and Unicode versions, then the three checks covering AC01–AC06, then the same snapshot with identical output. Closed `passed`. |
| `verdict` | `complete=yes final=02 criteria=6` |
| Project tests, rerun by the harness | Passed |
| Hidden acceptance checks the agent never saw | 11 / 11 passed (accents, non-Latin text, empty and all-separator input, truncation without a trailing hyphen, `ValueError` for `max_length` < 1, and the CLI) |
| Wall time | 3 minutes 36 seconds |

The harness checks the result independently of the agent's own report: it asks the helper for the verdict, reruns the project's tests, and only then runs hidden checks written into the harness rather than the project.

## What changed since v1.0.0

- **Evidence gates.** `close passed` and `verdict` now depend on run records the helper writes itself, so passing can no longer rest on the agent's word. The helper also enforces one repair per work pass, three executions per check per phase, command timeouts that stop the whole process group, and criteria counts that can only grow.
- **Named loops.** Independent goals can use `.ralph-loop-NAME/` with their own budgets, and `loops` lists them.
- **Verified installs.** Releases are built from protected tags by the `Release` workflow, published immutably with `SHA256SUMS` and build provenance attestations, and installed by a `quickstart.sh` that verifies the checksum and refuses branch names.

## Limitations

- The end-to-end run covers one small task on macOS with automatic model selection, not a cross-model or cross-agent test matrix. The repair path, exhaustion, and recovery after an interrupted pass were exercised by the helper self-tests, not by a live GitHub Copilot session, because this task passed on its first attempt.
- The helper proves that recorded checks ran and passed, that snapshots match, and that every criterion has a check. It cannot prove that a check meaningfully tests its criterion; the policy in `SKILL.md` and human review cover that.
- Named loops isolate state and budgets, not concurrent edits to shared deliverables. Give concurrent loops separate worktrees.
- `SHA256SUMS` comes from the same release as the tarball, so matching it does not establish trust if both are compromised. `LOOPER_SHA256` requires an independently trusted expected hash; `LOOPER_VERIFY_ATTESTATION=1` verifies build provenance, not code safety or the integrity of a compromised trusted workflow. See [SECURITY.md](../SECURITY.md#trust-boundary) and [GitHub's attestation guidance](https://docs.github.com/en/actions/concepts/security/artifact-attestations).
- Individual renames are not a multi-file transaction, and the helper assumes cooperating local writers.
