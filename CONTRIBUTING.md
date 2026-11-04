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

Read [AGENTS.md](AGENTS.md) for repository invariants and [SECURITY.md](SECURITY.md) for private vulnerability reporting.

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
cd ../..
/bin/bash -n quickstart.sh
/bin/bash -n tools/build-release.sh
/bin/bash -n e2e/run-copilot-e2e.sh
shellcheck quickstart.sh tools/build-release.sh e2e/run-copilot-e2e.sh
python3 -B tests/test_quickstart.py
```

To exercise the skill itself, install your checkout with `./quickstart.sh` and run `e2e/run-copilot-e2e.sh`. It drives the GitHub Copilot CLI through a small task, then checks the ledger verdict, the project's tests, and hidden acceptance checks. It uses your GitHub Copilot subscription, so it is not part of CI.

CI runs the same checks on every pull request. Branch protection on `main` requires the `validate` check to pass.

For documentation-only changes, check changed links and runnable examples; a live AI run is not required unless execution behavior needs verification. Record documentation corrections under `Unreleased` without changing historical release results.

## ✅ Ground Rules

- **The 20-pass budget is fixed.** Do not add a reset, refund, or configurable-limit operation.
- **Preserve loop identity and history.** Keep `.ralph-loop/` for the default goal, `.ralph-loop-NAME/` for independent named goals, and the `ralph-loop-pass-ledger-v1` marker. A named loop is not a budget reset. Use separate worktrees for concurrent edits.
- **No new runtime dependencies.** The helper stays Bash-only; tests stay on the Python standard library.
- **Never weaken verification.** Changes must not let a criterion be removed, skipped, or redefined to obtain green results.
- **Never let `passed` succeed without recorded evidence.** `close passed` and `verdict` must keep depending on the helper's own run records.
- **Add a test for every behavior change** to `scripts/test_pass_ledger.py` or `tests/test_quickstart.py`.
- **Write "GitHub Copilot" in full** in all user-facing text.
- Update [CHANGELOG.md](CHANGELOG.md) for every user-visible change.

## 📦 Releasing

1. Bump `LOOPER_VERSION` in `quickstart.sh`, add a `## [X.Y.Z] - DATE` section to the changelog, and update the pinned install commands in the README and AGENTS.md. Merge through a pull request.
2. Tag the merge commit `vX.Y.Z` and push the tag. The `Release` workflow runs the tests, builds the assets with `tools/build-release.sh`, attests their build provenance, and publishes the release.
3. Releases are immutable and `v*` tags are protected, so a published version never changes. Fix mistakes with a new patch release.

## 🔒 Security

Do not open public issues for vulnerabilities. See [SECURITY.md](SECURITY.md).

## 📄 License

By contributing, you agree that your contributions are licensed under the [MIT License](LICENSE).
