# 🔁 Looper

**Break your request into small steps, check the results, and save progress so work can resume after an interruption. Stops when everything is verified, a blocker prevents progress, or 20 attempts are used. Built for GitHub Copilot and other AI agents that support Agent Skills.**

[![Validate](https://github.com/DUBSOpenHub/looper/actions/workflows/validate.yml/badge.svg)](https://github.com/DUBSOpenHub/looper/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Security Policy](https://img.shields.io/badge/Security-Policy-brightgreen?logo=github)](SECURITY.md)
![Version: v1.1.0](https://img.shields.io/badge/version-v1.1.0-5E5E5E.svg)
![Works with: GitHub Copilot and Agent Skills](https://img.shields.io/badge/works%20with-GitHub%20Copilot%20%7C%20Agent%20Skills-232F3E.svg)

> ### ⚡ Install
>
> ```bash
> curl -fsSL https://github.com/DUBSOpenHub/looper/releases/download/v1.1.0/quickstart.sh | bash
> ```
>
> The installer downloads the pinned v1.1.0 release and checks it against the release's `SHA256SUMS` before installing anything. See [Verify the Download](#-verify-the-download).
>
> Then open the [GitHub Copilot CLI](https://docs.github.com/copilot/concepts/agents/about-copilot-cli) in any project and say: `looper`
>
> **Using another AI agent?** Install with the [GitHub CLI](https://cli.github.com/) instead:
>
> ```bash
> gh skill install DUBSOpenHub/looper looper@v1.1.0 --agent claude-code --scope user
> ```
>
> Swap `claude-code` for the agent you use; `gh skill install --help` lists the supported `--agent` values. See [Works With](#-works-with).
>
> *Requires Bash, a writable project folder, and an AI agent that supports [Agent Skills](https://agentskills.io/specification). macOS, Linux, or WSL. GitHub Copilot also needs an active [GitHub Copilot subscription](https://github.com/features/copilot/plans).*

---

## 🤔 What Is This?

Looper is a skill in the open [Agent Skills](https://agentskills.io/specification) format, built for GitHub Copilot. It breaks your request into small steps and defines checks for what “done” means. It works toward **verified completion**, rather than stopping after writing a plan or passing only some tests:

**Read saved progress → count an attempt → make a change → test → fix if needed → retest → save progress.**

Fixing and retesting happen only when checks fail. Each work attempt allows one round of fixes; if the checks still fail, another attempt is needed.

### What do “pass” and “durable state” mean?

A **pass** is one recorded attempt at a small step, or a separate final verification attempt. The limit is **20 attempts total**, not 20 steps or 20 minutes. Failed and interrupted attempts count too. Looper can finish earlier, but reaching the limit does not mean the work succeeded.

**Durable state** means progress is saved in files, not just in the chat. Looper records the goal, checks, completed steps, results, remaining work, and attempts used in your project folder. After an interruption or context reset, the next active agent session reads those records and compares them with the current files before resuming. It does not start over or reset the attempt count.

### 💬 The Problem

Long agent runs fail in predictable ways: they lose context, claim success from a partial check, retry the same broken fix forever, or quietly redefine "done." Looper makes those failure modes mechanically hard.

### ⚡ What Makes It Different

- 🔢 **At most 20 recorded attempts.** The helper records each attempt in a numbered folder, rather than relying on chat memory. The limit cannot be raised or reset.
- 💾 **Progress saved in your project.** The goal, checks, step plan, progress, and results are stored in `.ralph-loop/`, or `.ralph-loop-NAME/` for an independent named loop.
- ✅ **Criteria that must not be weakened.** Each `AC` has a concrete verifier and an expected result. The helper prevents lowering the criteria count; the skill's policy forbids removing or redefining criteria to get green.
- 🧾 **Passing needs recorded evidence.** Checks run through the helper, which records each command, its output, and its exit code. `close passed` and `verdict` refuse success without passing run records. Choosing meaningful checks remains the agent's responsibility.
- 🔧 **One round of fixes per work attempt.** If checks fail, the agent can make one round of fixes and check again. Each check can run at most three times in the initial testing phase and three times in the retesting phase. The helper enforces both limits.
- 🧪 **A mandatory final gate.** A separate, read-only final pass re-runs every verifier, covers every acceptance criterion, and must produce the same deliverable snapshot at its start and end before completion can be declared.
- 🗂️ **Named loops for independent goals.** One project can hold several loops, each with its own budget and evidence.
- 🛟 **Honest stopping.** It stops on verified acceptance, a genuine blocker, or exhaustion of the 20 passes, and reports which one.

## 🚀 Usage

In GitHub Copilot, or any other agent that has Looper installed, from your project folder:

```text
looper
looper add a --dry-run flag to the deploy script and prove it works
looper resume
looper as docs: refresh the README for the new CLI flags
looper resume docs
looper list
```

Looper reads your project instructions and existing changes, saves the checks for completion and a step plan to `.ralph-loop/state.md`, then works one attempt at a time until everything is verified, it is blocked, or all 20 attempts are used.

Use a named loop (`looper as NAME: …`) only for a genuinely independent goal; its state lives in `.ralph-loop-NAME/`. Loops that edit the same files should not run at the same time, so give each concurrent loop its own git worktree or run them one after another. A named loop is never a way to get more passes for the same goal.

## 🔌 Works With

Looper is built for GitHub Copilot and follows the open [Agent Skills](https://agentskills.io/specification) format, so other agents that support the format can load it too. To run it, an agent needs to read and edit files and run shell commands.

- **GitHub Copilot.** The GitHub Copilot CLI, the GitHub Copilot app, the GitHub Copilot cloud agent, and agent mode in VS Code, Visual Studio, and JetBrains IDEs [support Agent Skills](https://docs.github.com/en/copilot/concepts/customizations/agent-skills). IDE support depends on your version, and each surface reads skills from its own locations. The one-line installer above targets the GitHub Copilot CLI.
- **Other AI agents.** [`gh skill`](https://cli.github.com/manual/gh_skill) can install skills for Claude Code, Cursor, Codex, Gemini CLI, and many more, using the `--agent` flag shown above. `gh skill` is in preview, so its flags may change.
- **Anything else.** Point your agent at [`skills/looper/SKILL.md`](skills/looper/SKILL.md) and ask it to follow the instructions.

> **What is verified.** v1.1.0 has 37 helper tests and 8 installer/release-build tests, plus one successful end-to-end task through the GitHub Copilot CLI on macOS: 2 passes and 11 independent acceptance checks. Other agent surfaces have not had equivalent end-to-end testing. See [the validation report and its limitations](docs/VALIDATION.md).

## 🗂️ State Layout

```text
.ralph-loop/             # or .ralph-loop-NAME/ for a named loop
  format                 # helper protocol marker
  criteria               # number of acceptance criteria; can only grow
  state.md               # goal, criteria, task graph, latest evidence, next action
  progress.md            # append-only decisions, failures, checkpoints
  passes/01..20/
    reservation          # immutable mode, target, reservation time
    runs/001..           # recorded command, cwd, output, exit code, phase, AC IDs
    repair               # present once the pass has used its one repair batch
    result               # immutable passed / failed / blocked / interrupted
```

> The skill is called `looper`, but the state directory keeps the name `.ralph-loop/` and the `ralph-loop-pass-ledger-v1` marker so ledgers created before the rename stay resumable.

## 🛠️ Pass Ledger Helper

`skills/looper/scripts/pass-ledger.sh` enforces reservations, the budget, the repair and retry limits, command timeouts, and the evidence needed to pass. It cannot judge whether a verifier really tests its criterion; the policy in `SKILL.md` covers that.

Run this happy-path example from a project's real root directory with Looper installed and no existing loop. It assumes `slug.py`, `test_slug.py`, and `README.md` are the complete deliverable set, and the unittest suite verifies AC01. Adapt the files and criteria to your actual task.

```bash
LEDGER="$HOME/.copilot/skills/looper/scripts/pass-ledger.sh"
bash "$LEDGER" .ralph-loop init
bash "$LEDGER" .ralph-loop criteria 1                     # AC01
bash "$LEDGER" .ralph-loop reserve work S01
bash "$LEDGER" .ralph-loop run 01 --baseline -- python3 -B -m unittest
# Implement the scoped change here.
bash "$LEDGER" .ralph-loop run 01 --ac AC01 --timeout 300 -- python3 -B -m unittest
bash "$LEDGER" .ralph-loop close 01 passed
bash "$LEDGER" .ralph-loop reserve final ALL
bash "$LEDGER" .ralph-loop run 02 --snapshot -- shasum -a 256 slug.py test_slug.py README.md
bash "$LEDGER" .ralph-loop run 02 --ac AC01 -- python3 -B -m unittest
bash "$LEDGER" .ralph-loop run 02 --snapshot -- shasum -a 256 slug.py test_slug.py README.md
bash "$LEDGER" .ralph-loop close 02 passed
bash "$LEDGER" .ralph-loop verdict                       # complete=yes final=02 criteria=1
bash "$LEDGER" . loops                                   # every loop in this project
```

A failed baseline is recorded with exit code `7`; assess it before editing rather than treating it as a passing check. If initial validation fails, call `bash "$LEDGER" .ralph-loop repair 01` once before the repair edits, then rerun the same failing check and the affected regression checks before closing the pass. Do not call `repair` after a passing check. If revalidation fails, close the pass `failed`, not `passed`.

The final snapshots must hash the actual contents of every deliverable, including untracked files and uncommitted changes, and capture relevant inputs and environment versions. `git ls-files -s` alone only fingerprints the index, not current working-tree contents.

| Exit code | Meaning |
|-----------|---------|
| `0` | Success |
| `2` | Budget exhausted (20 passes reserved) |
| `3` | A pass is already open, or already closed |
| `4` | Ledger locked by another writer |
| `5` | Invalid or unsafe state (symlinks, corruption, missing ledger) |
| `6` | Refused by an evidence gate or rule (for example `close passed` without passing runs, a second `repair`, or a fourth run of the same check) |
| `7` | `run` recorded a failing command |
| `64` | Invalid usage |

## 🧪 Run the Tests

The self-tests use only the Python standard library and create their fixtures inside the skill directory.

```bash
cd skills/looper
/bin/bash -n scripts/pass-ledger.sh
shellcheck scripts/pass-ledger.sh
python3 -B scripts/test_pass_ledger.py
cd ../..
python3 -B tests/test_quickstart.py      # installer and release-build tests
```

To exercise the skill itself, install your checkout with `./quickstart.sh` and run `e2e/run-copilot-e2e.sh`. It drives the GitHub Copilot CLI through a small task and then checks the result independently. See [VALIDATION.md](docs/VALIDATION.md) for the latest recorded run.

## 🔐 Verify the Download

Starting with v1.1.0, releases are built by the [`Release` workflow](.github/workflows/release.yml) from a protected `vX.Y.Z` tag and published as immutable GitHub releases with three assets: `looper-vX.Y.Z.tar.gz`, `quickstart.sh`, and `SHA256SUMS`. Both the tarball and the installer carry a GitHub build provenance attestation.

- **Checksum (always on).** The installer refuses to install unless the tarball matches `SHA256SUMS`, and it installs only the four skill files.
- **Pin a checksum.** Set `LOOPER_SHA256` to a tarball hash obtained through an independently trusted channel, so a changed file is refused even if `SHA256SUMS` changes with it.
- **Check provenance.** Set `LOOPER_VERIFY_ATTESTATION=1` to have the installer run `gh attestation verify` against this repository's release workflow and tag.
- **Pick a version.** `LOOPER_VERSION=vX.Y.Z` installs another release. Branch names such as `main` are refused.

The one-line installer executes the downloaded installer before it checks the tarball. To verify the installer itself first, use an up-to-date, authenticated GitHub CLI and run this from a separate download directory, not a Looper checkout:

```bash
curl -fsSLO https://github.com/DUBSOpenHub/looper/releases/download/v1.1.0/quickstart.sh &&
gh attestation verify quickstart.sh --repo DUBSOpenHub/looper \
  --signer-workflow DUBSOpenHub/looper/.github/workflows/release.yml \
  --source-ref refs/tags/v1.1.0 &&
LOOPER_VERIFY_ATTESTATION=1 bash quickstart.sh
```

`SHA256SUMS` alone cannot establish trust if both the archive and checksum are compromised. [Attestations establish build provenance, not that the code is safe](https://docs.github.com/en/actions/concepts/security/artifact-attestations). A compromised trusted source or release workflow can still produce an attested artifact.

Running `./quickstart.sh` inside a clone deliberately installs the local checkout instead; release checksum and attestation checks do not apply in that mode.

## 📁 Repository Layout

| Path | Purpose |
|------|---------|
| `skills/looper/SKILL.md` | The skill: execution policy and the final verification gate |
| `skills/looper/scripts/pass-ledger.sh` | Pass counter, immutable reservations, and evidence gates |
| `skills/looper/scripts/test_pass_ledger.py` | Behavioral self-tests for the helper |
| `skills/looper/templates/state.md` | Durable checkpoint and evidence template |
| `quickstart.sh` | Installs a pinned, checksum-verified release into `~/.copilot/skills/looper/` |
| `tools/build-release.sh` | Builds the release tarball, installer copy, and `SHA256SUMS` |
| `tests/test_quickstart.py` | Installer and release-build tests |
| `e2e/run-copilot-e2e.sh` | End-to-end run through the GitHub Copilot CLI with hidden acceptance checks |
| `AGENTS.md` | Contributor instructions, invariants, and validation commands |
| `SECURITY.md` | Supported versions, private vulnerability reporting, and trust boundaries |
| `CONTRIBUTING.md` | Development and release workflow |
| `CHANGELOG.md` | Release history and unreleased changes |
| `docs/PRD.md` | Original v1.0 requirements with a v1.1 contract update |
| `docs/ARCH.md` | Original design with v1.1 evidence-gate and release additions |
| `docs/VALIDATION.md` | Test and gap-score results for the current release |

## ❓ FAQ

**Do I need GitHub Copilot to use Looper?**
No. It is built for GitHub Copilot, but any agent that supports Agent Skills can load it. See [Works With](#-works-with).

**Does Looper run on its own in the background?**
No. It only runs while an agent session, such as GitHub Copilot, is active. The on-disk state lets the next session resume it.

**Can I raise the 20-pass limit?**
No. The helper has no reset or configurable-limit operation, by design.

**Can I run more than one loop in a project?**
Yes, for independent goals. Say `looper as NAME: <request>`; state goes to `.ralph-loop-NAME/` with its own 20-pass budget, and `looper list` shows every loop. Use separate git worktrees if the loops would run at the same time.

**Can an agent just mark a pass as passed?**
Not through the helper without evidence: `close passed` exits `6` unless its run records satisfy the gate, and `verdict` re-checks the final pass. The helper cannot tell whether a test is meaningful, and its local files are not tamper-proof against an agent with write access. See the [security trust boundary](SECURITY.md#trust-boundary).

**What happens to a v1.0 loop after upgrading?**
Its history and spent passes stay intact. Close an open legacy pass `failed` or `interrupted`, then reserve new passes for evidence-backed validation within the remaining budget. An old `passed` result without run records does not satisfy the v1.1 completion gate. Never delete state or reset the budget to upgrade.

**Can I rename the skill without losing a running loop?**
Yes. Renaming the skill never migrates state, resets the budget, or discards history.

**Why does the helper say `state path must not contain symlinks`?**
Looper refuses to read or write loop state through a symlink, including a symlinked parent folder, so a link cannot redirect the ledger. On macOS, `/tmp` is a symlink to `/private/tmp`, so a project under `/tmp` is rejected. Start your agent from the project's real path (`cd "$(pwd -P)"` switches to it) and try again.

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Please report vulnerabilities privately as described in [SECURITY.md](SECURITY.md).

## 📄 License

[MIT](LICENSE)
