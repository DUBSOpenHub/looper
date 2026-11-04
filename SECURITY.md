# 🔒 Security Policy

## 🛡️ Supported Versions

| Version | Supported |
|---------|-----------|
| 1.0.x   | ✅ Yes     |

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
- Instructions in `SKILL.md` that lead GitHub Copilot to bypass security controls, leak secrets into state or logs, or repeat uncertain destructive actions

**Out of scope:**

- Vulnerabilities in the GitHub Copilot CLI itself
- Vulnerabilities in the underlying language models
- Local writers that maliciously replace pathnames concurrently (the helper assumes cooperating local writers)
- Code produced for a user's request; review generated changes before running them

## 🔐 Security Features

This repository has the following GitHub security features configured:

| Feature | Status | Notes |
|---------|--------|-------|
| ⏳ Dependabot Alerts | Pending | Not yet enabled: GitHub has not finished initializing this new repository's dependency graph |
| ✅ Dependabot Security Updates | Enabled | Auto-creates PRs to fix vulnerable dependencies |
| ✅ Dependabot Version Updates | Enabled | Keeps GitHub Actions pinned and current |
| ✅ Secret Scanning | Enabled | Detects accidentally committed secrets |
| ✅ Secret Scanning Push Protection | Enabled | Blocks pushes containing secrets |
| ✅ Code Scanning (CodeQL) | Enabled | Default setup for Python and GitHub Actions, weekly |
| ✅ Private Vulnerability Reporting | Enabled | Confidential reports through a draft advisory |
| ✅ Branch Protection | Enabled | `main` requires a pull request and the `validate` check, with no force pushes or deletions |

## 📋 Best Practices

Looper is a GitHub Copilot CLI skill with a small Bash helper. The main security considerations are:

- 🔑 **No secrets in skill files or loop state.** Never put credentials in `SKILL.md`, `.ralph-loop/`, commands, or logs.
- 📜 **Safe instructions.** Skill instructions must never tell the agent to bypass security controls or permissions.
- 🔗 **Containment first.** The helper rejects symlinked state paths and non-regular files before any read or write.
- 🧾 **Immutable history.** Reservations and results are never edited, and the budget has no reset operation.

## 📄 License

This project is licensed under the [MIT License](LICENSE).
