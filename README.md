# 🔁 Looper

**Turn any request into small, verified steps. A bounded 20-pass loop with durable state for GitHub Copilot and any AI agent that supports Agent Skills.**

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

Looper is a skill in the open [Agent Skills](https://agentskills.io/specification) format, built for GitHub Copilot, that carries a request all the way to **verified** completion instead of stopping at a plan or a green subset of tests. It breaks the request into numbered acceptance criteria and small steps, then repeats:

**read state → reserve → implement → validate → repair → revalidate → checkpoint**

Everything lives on disk, so a context reset, crash, or new session resumes exactly where the last one stopped.

### 💬 The Problem

Long agent runs fail in predictable ways: they lose context, claim success from a partial check, retry the same broken fix forever, or quietly redefine "done." Looper makes those failure modes mechanically hard.

### ⚡ What Makes It Different

- 🔢 **A hard 20-pass budget.** Passes are counted by creating directories, not by trusting memory. There is no reset and no way to configure the limit.
- 💾 **Durable, project-local state.** Goal, criteria, task graph, progress, and evidence are stored in `.ralph-loop/` inside your project.
- ✅ **Acceptance criteria you can't weaken.** Each `AC` has a concrete verifier and an expected result. Looper never removes or redefines a criterion to get green.
- 🧾 **Passing needs recorded evidence.** Checks run through the helper, which records each command, its output, and its exit code. A pass cannot be closed `passed`, and a loop cannot be called complete, unless those records prove it.
- 🔧 **One bounded repair per pass.** A pass gets at most one repair batch and one revalidation, and each check runs at most three times per phase. The helper enforces both.
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

Looper inspects your project instructions and existing changes, writes acceptance criteria and a step plan to `.ralph-loop/state.md`, then works pass by pass until it is done, blocked, or out of passes.

Use a named loop (`looper as NAME: …`) only for a genuinely independent goal; its state lives in `.ralph-loop-NAME/`. Loops that edit the same files should not run at the same time, so give each concurrent loop its own git worktree or run them one after another. A named loop is never a way to get more passes for the same goal.

## 🔌 Works With

Looper is built for GitHub Copilot and follows the open [Agent Skills](https://agentskills.io/specification) format, so other agents that support the format can load it too. To run it, an agent needs to read and edit files and run shell commands.

- **GitHub Copilot.** The GitHub Copilot CLI, the GitHub Copilot app, the GitHub Copilot cloud agent, and agent mode in VS Code, Visual Studio, and JetBrains IDEs [support Agent Skills](https://docs.github.com/en/copilot/concepts/customizations/agent-skills). IDE support depends on your version, and each surface reads skills from its own locations. The one-line installer above targets the GitHub Copilot CLI.
- **Other AI agents.** [`gh skill`](https://cli.github.com/manual/gh_skill) can install skills for Claude Code, Cursor, Codex, Gemini CLI, and many more, using the `--agent` flag shown above. `gh skill` is in preview, so its flags may change.
- **Anything else.** Point your agent at [`skills/looper/SKILL.md`](skills/looper/SKILL.md) and ask it to follow the instructions.

> **What is verified.** The pass-ledger helper and its self-tests are plain Bash and Python, and CI runs them on every pull request. The skill's wording is written for GitHub Copilot (for example, it uses `ask_user` when available and records a blocker when it is not), and how faithfully another agent follows it depends on the tool and the model behind it.

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

```bash
bash pass-ledger.sh .ralph-loop init
bash pass-ledger.sh .ralph-loop criteria 3                 # AC01..AC03
bash pass-ledger.sh .ralph-loop reserve work S01
bash pass-ledger.sh .ralph-loop run 01 --baseline -- python3 -m unittest
bash pass-ledger.sh .ralph-loop run 01 --ac AC01 --timeout 300 -- python3 -m unittest
bash pass-ledger.sh .ralph-loop repair 01                  # at most once, after a failed run
bash pass-ledger.sh .ralph-loop close 01 passed            # refused without passing evidence
bash pass-ledger.sh .ralph-loop reserve final ALL
bash pass-ledger.sh .ralph-loop run 02 --snapshot -- git ls-files -s
bash pass-ledger.sh .ralph-loop run 02 --ac AC01,AC02,AC03 -- python3 -m unittest
bash pass-ledger.sh .ralph-loop run 02 --snapshot -- git ls-files -s
bash pass-ledger.sh .ralph-loop close 02 passed
bash pass-ledger.sh .ralph-loop verdict                    # complete=yes final=02 criteria=3
bash pass-ledger.sh . loops                                # every loop in this project
```

In a real final pass, the snapshot command must cover every deliverable, including untracked files and uncommitted changes.

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

Every release is built by the [`Release` workflow](.github/workflows/release.yml) from a protected `vX.Y.Z` tag and published as an immutable GitHub release with three assets: `looper-vX.Y.Z.tar.gz`, `quickstart.sh`, and `SHA256SUMS`. Both the tarball and the installer carry a GitHub build provenance attestation.

- **Checksum (always on).** The installer refuses to install unless the tarball matches `SHA256SUMS`, and it installs only the four skill files.
- **Pin a checksum.** Set `LOOPER_SHA256` to the tarball hash you expect, so a changed file is refused even if `SHA256SUMS` changes with it.
- **Check provenance.** Set `LOOPER_VERIFY_ATTESTATION=1` to have the installer run `gh attestation verify` against this repository's release workflow and tag.
- **Pick a version.** `LOOPER_VERSION=vX.Y.Z` installs another release. Branch names such as `main` are refused.

```bash
curl -fsSLO https://github.com/DUBSOpenHub/looper/releases/download/v1.1.0/quickstart.sh
gh attestation verify quickstart.sh --repo DUBSOpenHub/looper
LOOPER_VERIFY_ATTESTATION=1 bash quickstart.sh
```

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
| `docs/PRD.md` | Product requirements and acceptance criteria |
| `docs/ARCH.md` | Design and persistence safeguards |
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
No. `close passed` exits `6` unless the helper's own run records show the checks finished and passed, and `verdict` re-checks the final pass's evidence. The helper cannot tell whether a test is meaningful, which is why the acceptance criteria and the final gate in `SKILL.md` still matter.

**Can I rename the skill without losing a running loop?**
Yes. Renaming the skill never migrates state, resets the budget, or discards history.

**Why does the helper say `state path must not contain symlinks`?**
Looper refuses to read or write loop state through a symlink, including a symlinked parent folder, so a link cannot redirect the ledger. On macOS, `/tmp` is a symlink to `/private/tmp`, so a project under `/tmp` is rejected. Start your agent from the project's real path (`cd "$(pwd -P)"` switches to it) and try again.

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Please report vulnerabilities privately as described in [SECURITY.md](SECURITY.md).

## 📄 License

[MIT](LICENSE)
