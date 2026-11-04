# 🔁 Looper

**Turn any request into small, verified steps. A bounded 20-pass loop with durable state, built for the GitHub Copilot CLI.**

[![Validate](https://github.com/DUBSOpenHub/looper/actions/workflows/validate.yml/badge.svg)](https://github.com/DUBSOpenHub/looper/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Security Policy](https://img.shields.io/badge/Security-Policy-brightgreen?logo=github)](SECURITY.md)
![Version: v1.0.0](https://img.shields.io/badge/version-v1.0.0-5E5E5E.svg)
![Platform: GitHub Copilot CLI](https://img.shields.io/badge/platform-GitHub%20Copilot%20CLI-232F3E.svg)

> ### ⚡ Install
>
> ```bash
> curl -fsSL https://raw.githubusercontent.com/DUBSOpenHub/looper/main/quickstart.sh | bash
> ```
>
> Then open the [GitHub Copilot CLI](https://docs.github.com/copilot/concepts/agents/about-copilot-cli) in any project and say: `looper`
>
> *Requires an active [GitHub Copilot subscription](https://github.com/features/copilot/plans), Bash, and a writable project folder. macOS, Linux, or WSL.*

---

## 🤔 What Is This?

Looper is a GitHub Copilot CLI skill that carries a request all the way to **verified** completion instead of stopping at a plan or a green subset of tests. It breaks the request into numbered acceptance criteria and small steps, then repeats:

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

In the GitHub Copilot CLI, from your project folder:

```text
looper
looper add a --dry-run flag to the deploy script and prove it works
looper resume
```

Looper inspects your project instructions and existing changes, writes acceptance criteria and a step plan to `.ralph-loop/state.md`, then works pass by pass until it is done, blocked, or out of passes.

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

**Does Looper run on its own in the background?**
No. It only runs while a GitHub Copilot session is active. The on-disk state lets the next session resume it.

**Can I raise the 20-pass limit?**
No. The helper has no reset or configurable-limit operation, by design.

**Can I rename the skill without losing a running loop?**
Yes. Renaming the skill never migrates state, resets the budget, or discards history.

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Please report vulnerabilities privately as described in [SECURITY.md](SECURITY.md).

## 📄 License

[MIT](LICENSE)
