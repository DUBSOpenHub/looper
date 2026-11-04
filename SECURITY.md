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
- Path containment: the helper reading or writing outside the selected project's `.ralph-loop/` directory, including symlink and `..` tricks
- Ledger integrity: overwriting or rewriting an immutable reservation or result
- Evidence gates: getting `close passed` or `verdict` `complete=yes` without matching recorded runs, or exceeding the one-repair and three-executions-per-check limits
- Installer integrity: `quickstart.sh` installing anything other than the verified release files, or writing outside `~/.copilot/skills/looper/`
- Instructions in `SKILL.md` that lead an AI agent, such as GitHub Copilot, to bypass security controls, leak secrets into state or logs, or repeat uncertain destructive actions

**Out of scope:**

- Vulnerabilities in GitHub Copilot or any other AI agent that runs Looper
- Vulnerabilities in the underlying language models
- Local writers that maliciously replace pathnames concurrently (the helper assumes cooperating local writers)
- Code produced for a user's request; review generated changes before running them

## 🔐 Security Features

This repository has the following GitHub security features configured:

| Feature | Status | Notes |
|---------|--------|-------|
| ⏳ Dependabot Alerts | Pending | Not yet enabled on this new repository; Dependabot security updates will open PRs once alerts are on |
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

- 🔑 **No secrets in skill files or loop state.** Never put credentials in `SKILL.md`, `.ralph-loop/`, commands, or logs.
- 📜 **Safe instructions.** Skill instructions must never tell the agent to bypass security controls or permissions.
- 🔗 **Containment first.** The helper rejects symlinked state paths and non-regular files before any read or write.
- 🧾 **Immutable history.** Reservations and results are never edited, and the budget has no reset operation.
- 📦 **Verified installs.** Install a pinned release. The installer checks `SHA256SUMS`, can require a pinned checksum (`LOOPER_SHA256`) or verify build provenance (`LOOPER_VERIFY_ATTESTATION=1`), and refuses branch names. `SHA256SUMS` comes from the same release, so it detects corrupted or altered downloads but not a compromised release; use the pin or provenance check for that.

## 📄 License

This project is licensed under the [MIT License](LICENSE).
