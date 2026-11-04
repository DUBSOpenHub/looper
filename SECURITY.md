# 🔒 Security Policy

## 🛡️ Supported Versions

| Version | Supported |
|---------|-----------|
| 1.1.x   | ✅ Yes     |
| 1.0.x   | ❌ No; upgrade to 1.1.x |

## 🚨 Reporting a Vulnerability

We take security seriously! 🐙 If you discover a security vulnerability in this project, **please report it responsibly**.

### How to Report

1. **DO NOT** open a public GitHub issue for security vulnerabilities
2. Instead, email us at: **security@dubsopenhub.com**
3. Or use [GitHub's private vulnerability reporting](https://github.com/DUBSOpenHub/looper/security/advisories/new)

### What to Include

Please provide as much of the following as possible:

- 📝 Description of the vulnerability
- 🔄 Steps to reproduce
- 💥 Potential impact
- 💡 Suggested fix (if you have one)

### What to Expect

- ⏱️ **Acknowledgment** within 48 hours
- 🔍 **Assessment** within 1 week
- 🛠️ **Fix or mitigation** as quickly as possible
- 🎉 **Credit** in the release notes (unless you prefer anonymity)

## 🎯 Scope

**In scope:**

- Pass-budget bypass: any way to exceed, reset, or refund the 20-pass limit
- Ledger path containment: ledger operations escaping the selected project's `.ralph-loop/` or `.ralph-loop-NAME/` directory, including symlink and `..` tricks
- Ledger integrity: overwriting or rewriting an immutable reservation or result
- Evidence gates: getting `close passed` or `verdict` `complete=yes` without matching recorded runs, or exceeding the one-repair and three-executions-per-check limits
- Installer integrity: release-mode `quickstart.sh` installing files that fail its checks, or installing skill files outside `~/.copilot/skills/looper/` (temporary download and extraction directories are expected)
- Instructions in `SKILL.md` that lead an AI agent, such as GitHub Copilot, to bypass security controls, leak secrets into state or logs, or repeat uncertain destructive actions

**Out of scope:**

- Vulnerabilities in GitHub Copilot or any other AI agent that runs Looper
- Vulnerabilities in the underlying language models
- Local writers that maliciously replace pathnames concurrently (the helper assumes cooperating local writers)
- Code produced for a user's request; review generated changes before running them

## Trust Boundary

The helper is not a sandbox. Commands passed to `run` execute in the caller's working directory with the caller's permissions; ledger path checks do not restrict those commands' filesystem or network access.

Evidence, reservations, and results are ordinary local files. The helper refuses to rewrite published history through its own interface, but an actor with direct filesystem write access can alter it. Its guarantees assume cooperating local writers, meaningful verifiers, and an agent that follows the skill's policy.

## 🔐 Security Features

Configuration snapshot checked on November 4, 2026. These settings describe the repository, not a guarantee that every generated change is safe.

| Feature | Status | Notes |
|---------|--------|-------|
| ⏳ Dependabot Alerts | Disabled | Confirmed disabled on November 4, 2026; alerts must be enabled before security updates can act on them |
| ✅ Dependabot Security Updates | Enabled | Auto-creates PRs to fix vulnerable dependencies |
| ✅ Dependabot Version Updates | Enabled | Keeps GitHub Actions pinned and current |
| ✅ Secret Scanning | Enabled | Detects accidentally committed secrets |
| ✅ Secret Scanning Push Protection | Enabled | Blocks pushes containing secrets |
| ✅ Code Scanning (CodeQL) | Enabled | Default setup for Python and GitHub Actions, weekly |
| ✅ Private Vulnerability Reporting | Enabled | Confidential reports through a draft advisory |
| ✅ Branch Protection | Enabled | `main` requires a pull request and the `validate` check, with no force pushes or deletions |
| ✅ Tag Protection | Enabled | A ruleset blocks updating or deleting `v*` release tags |
| ✅ Immutable Releases | Enabled | Published release assets and their tags cannot be changed |
| ✅ Build Provenance | Enabled | Release assets carry GitHub artifact attestations from the `Release` workflow |

## 📋 Best Practices

Looper is a skill for GitHub Copilot and other AI agents that support Agent Skills, with a small Bash helper. The main security considerations are:

- 🔑 **No secrets in skill files or loop state.** Never put credentials in `SKILL.md`, `.ralph-loop/`, `.ralph-loop-NAME/`, commands, or logs. `run` persists command output; choose checks that do not print secrets.
- 📜 **Safe instructions.** Skill instructions must never tell the agent to bypass security controls or permissions.
- 🔗 **Containment first.** The helper rejects symlinked state paths and non-regular files before any read or write.
- 🧾 **Immutable history.** Reservations and results are never edited, and the budget has no reset operation.
- 📦 **Verified installs.** In release mode, the installer checks `SHA256SUMS`, can require an independently trusted checksum (`LOOPER_SHA256`) or verify build provenance (`LOOPER_VERIFY_ATTESTATION=1`), and refuses branch names. A local-checkout install deliberately skips release verification. See [Verify the Download](README.md#-verify-the-download) to verify the installer before executing it.
- 🔎 **Verification limits.** An archive and checksum from the same compromised release can still agree. An independently trusted hash pins the expected bytes; an attestation identifies the build source and workflow. Neither proves the code is safe, and a compromised trusted workflow can produce valid attestations. See [GitHub's attestation guidance](https://docs.github.com/en/actions/concepts/security/artifact-attestations).

## 📄 License

This project is licensed under the [MIT License](LICENSE).
