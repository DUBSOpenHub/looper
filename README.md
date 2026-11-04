# 🔁 Looper

**Turn any request into small, verified steps. A bounded 20-pass loop with durable state for GitHub Copilot and any AI agent that supports Agent Skills.**

[![Validate](https://github.com/DUBSOpenHub/looper/actions/workflows/validate.yml/badge.svg)](https://github.com/DUBSOpenHub/looper/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Security Policy](https://img.shields.io/badge/Security-Policy-brightgreen?logo=github)](SECURITY.md)
![Version: v1.0.0](https://img.shields.io/badge/version-v1.0.0-5E5E5E.svg)
![Works with: GitHub Copilot and Agent Skills](https://img.shields.io/badge/works%20with-GitHub%20Copilot%20%7C%20Agent%20Skills-232F3E.svg)

> ### ⚡ Install
>
> ```bash
> curl -fsSL https://raw.githubusercontent.com/DUBSOpenHub/looper/main/quickstart.sh | bash
> ```
>
> Then open the [GitHub Copilot CLI](https://docs.github.com/copilot/concepts/agents/about-copilot-cli) in any project and say: `looper`
>
> **Using another AI agent?** Install with the [GitHub CLI](https://cli.github.com/) instead:
>
> ```bash
> gh skill install DUBSOpenHub/looper looper --agent claude-code --scope user
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
- 🔧 **One bounded repair per pass.** A pass gets at most one repair batch and one revalidation, so there is no hidden inner retry loop.
- 🧪 **A mandatory final gate.** A separate, read-only final pass re-runs every verifier against an unchanged deliverable before completion can be declared.
- 🛟 **Honest stopping.** It stops on verified acceptance, a genuine blocker, or exhaustion of the 20 passes, and reports which one.

## 🚀 Usage

In GitHub Copilot, or any other agent that has Looper installed, from your project folder:

```text
looper
looper add a --dry-run flag to the deploy script and prove it works
looper resume
```

Looper inspects your project instructions and existing changes, writes acceptance criteria and a step plan to `.ralph-loop/state.md`, then works pass by pass until it is done, blocked, or out of passes.

## 🔌 Works With

Looper is built for GitHub Copilot and follows the open [Agent Skills](https://agentskills.io/specification) format, so other agents that support the format can load it too. To run it, an agent needs to read and edit files and run shell commands.

- **GitHub Copilot.** The GitHub Copilot CLI, the GitHub Copilot app, the GitHub Copilot cloud agent, and agent mode in VS Code, Visual Studio, and JetBrains IDEs [support Agent Skills](https://docs.github.com/en/copilot/concepts/customizations/agent-skills). IDE support depends on your version, and each surface reads skills from its own locations. The one-line installer above targets the GitHub Copilot CLI.
- **Other AI agents.** [`gh skill`](https://cli.github.com/manual/gh_skill) can install skills for Claude Code, Cursor, Codex, Gemini CLI, and many more, using the `--agent` flag shown above. `gh skill` is in preview, so its flags may change.
- **Anything else.** Point your agent at [`skills/looper/SKILL.md`](skills/looper/SKILL.md) and ask it to follow the instructions.

> **What is verified.** The pass-ledger helper and its self-tests are plain Bash and Python, and CI runs them on every pull request. The skill's wording is written for GitHub Copilot (for example, it uses `ask_user` when available and records a blocker when it is not), and how faithfully another agent follows it depends on the tool and the model behind it.

## 🗂️ State Layout

```text
.ralph-loop/
  format                 # helper protocol marker
  state.md               # goal, criteria, task graph, latest evidence, next action
  progress.md            # append-only decisions, failures, checkpoints
  passes/01..20/
    reservation          # immutable mode, target, reservation time
    result               # immutable passed / failed / blocked / interrupted
    ...                  # exact commands, outputs, exit codes, snapshots
```

> The skill is called `looper`, but the state directory keeps the name `.ralph-loop/` and the `ralph-loop-pass-ledger-v1` marker so ledgers created before the rename stay resumable.

## 🛠️ Pass Ledger Helper

`skills/looper/scripts/pass-ledger.sh` enforces reservations and the budget. It does **not** judge acceptance correctness; the final gate in `SKILL.md` does.

```bash
bash pass-ledger.sh .ralph-loop init
bash pass-ledger.sh .ralph-loop status
bash pass-ledger.sh .ralph-loop reserve work S01
bash pass-ledger.sh .ralph-loop close 01 passed
bash pass-ledger.sh .ralph-loop reserve final ALL
```

| Exit code | Meaning |
|-----------|---------|
| `0` | Success |
| `2` | Budget exhausted (20 passes reserved) |
| `3` | A pass is already open, or already closed |
| `4` | Ledger locked by another writer |
| `5` | Invalid or unsafe state (symlinks, corruption, missing ledger) |
| `64` | Invalid usage |

## 🧪 Run the Tests

The self-tests use only the Python standard library and create their fixtures inside the skill directory.

```bash
cd skills/looper
/bin/bash -n scripts/pass-ledger.sh
shellcheck scripts/pass-ledger.sh
python3 -B scripts/test_pass_ledger.py
```

## 📁 Repository Layout

| Path | Purpose |
|------|---------|
| `skills/looper/SKILL.md` | The skill: execution policy and the final verification gate |
| `skills/looper/scripts/pass-ledger.sh` | Pass counter with safe, immutable reservations |
| `skills/looper/scripts/test_pass_ledger.py` | Behavioral self-tests for the helper |
| `skills/looper/templates/state.md` | Durable checkpoint and evidence template |
| `quickstart.sh` | Installs the skill into `~/.copilot/skills/looper/` |
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

**Can I rename the skill without losing a running loop?**
Yes. Renaming the skill never migrates state, resets the budget, or discards history.

**Why does the helper say `state path must not contain symlinks`?**
Looper refuses to read or write loop state through a symlink, including a symlinked parent folder, so a link cannot redirect the ledger. On macOS, `/tmp` is a symlink to `/private/tmp`, so a project under `/tmp` is rejected. Start your agent from the project's real path (`cd "$(pwd -P)"` switches to it) and try again.

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Please report vulnerabilities privately as described in [SECURITY.md](SECURITY.md).

## 📄 License

[MIT](LICENSE)
