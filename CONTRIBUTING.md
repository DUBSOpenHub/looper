# 🤝 Contributing to Looper

First off, **thank you!** 💜 Every contribution makes the loop safer and more reliable.

## 🎯 Ways to Contribute

### 💡 No Code Required!

Open an [Issue](https://github.com/DUBSOpenHub/looper/issues) to:

- 🐛 **Report a bug**: did a loop miscount passes, lose state, or stop early?
- 💡 **Suggest a feature**: a new recovery case or evidence check?
- ✏️ **Fix a typo**: spotted a mistake in the docs? We appreciate it!

### 🧑‍💻 Code Contributions

1. **Fork** this repo
2. **Create a branch**: `git checkout -b my-improvement`
3. **Make your changes**: see the development guide below
4. **Test your changes**: run the checks below
5. **Open a PR**: fill out the template and describe what you changed

## 🛠️ Development Setup

### Prerequisites

- Bash, Python 3, and [ShellCheck](https://www.shellcheck.net/), which are all you need to run the helper and its tests
- Optional, to try the skill end to end: an AI agent that supports [Agent Skills](https://agentskills.io/specification), such as the [GitHub Copilot CLI](https://github.com/github/copilot-cli) (which requires an active [GitHub Copilot subscription](https://github.com/features/copilot/plans))

### Checks to run before opening a PR

```bash
cd skills/looper
/bin/bash -n scripts/pass-ledger.sh
shellcheck scripts/pass-ledger.sh
python3 -B scripts/test_pass_ledger.py
```

CI runs the same checks on every pull request. Branch protection on `main` requires the `validate` check to pass.

## ✅ Ground Rules

- **The 20-pass budget is fixed.** Do not add a reset, refund, or configurable-limit operation.
- **Keep `.ralph-loop/` and the `ralph-loop-pass-ledger-v1` marker.** They keep ledgers created before the rename resumable.
- **No new runtime dependencies.** The helper stays Bash-only; tests stay on the Python standard library.
- **Never weaken verification.** Changes must not let a criterion be removed, skipped, or redefined to obtain green results.
- **Add a test for every behavior change** to `scripts/test_pass_ledger.py`.
- **Write "GitHub Copilot" in full** in all user-facing text.
- Update [CHANGELOG.md](CHANGELOG.md) for every user-visible change.

## 🔒 Security

Do not open public issues for vulnerabilities. See [SECURITY.md](SECURITY.md).

## 📄 License

By contributing, you agree that your contributions are licensed under the [MIT License](LICENSE).
