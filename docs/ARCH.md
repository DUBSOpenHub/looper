# Architecture: Looper existing-skill hardening

Run: `run-20261103-162029`  
Decision: preserve the existing four-file architecture and v1 helper contract.

> **v1.1 update:** This document records the v1.0 design. v1.1 deliberately extends the helper contract with evidence gates, named loops, and verified releases; see [v1.1 additions](#v11-additions).

## Scope and current strengths

Harden the existing skill for GitHub Copilot; expose it under the callable name `looper` without replacing it with another product. Install from `skills/looper/` into `~/.copilot/skills/looper/`. Preserve `.ralph-loop/` project-local durable state unchanged for existing runs. Keep Bash 3.2/macOS compatibility, Python standard-library tests, existing user work, and all eight original tests.
The existing implementation already has a fixed 20-pass cap, directory-based reservation accounting, immutable outcomes, mutation locking, interrupted-pass handling, and substantial planning/final-gate instructions. Preserve these rather than rebuild them.
The reported eight-test, Bash syntax, and ShellCheck baseline is historical context, not freshly observed release evidence. This architecture task changes only `ARCH.md`.

## Components and interfaces

| Component | Responsibility and targeted change |
|---|---|
| `skills/looper/SKILL.md` | GitHub Copilot's execution policy and skill identity. Set `name: looper`, use matching invocation guidance, and clarify safe checkpoint writes, writer reconciliation, failure recovery, evidence freshness, and completion ordering. |
| `skills/looper/scripts/pass-ledger.sh` | Reservations, accounting, and safe ledger persistence only. Tighten validation of published v1 records and unsafe paths; make partial-write and cleanup behavior explicit. |
| `skills/looper/templates/state.md` | Human-readable projection of goal, criteria, graph, evidence, blockers, and next action. Add only fields needed to record the existing policy and recovery decisions. |
| `skills/looper/scripts/test_pass_ledger.py` | Preserve the eight tests; extend this file with focused public-interface regressions for changed behavior and missing PRD-coupled edge coverage. |

Project-local storage remains `.ralph-loop/{format,state.md,progress.md,passes/01..20/}` with the existing reservation/result records and pass evidence. No new runtime dependency, schema migration, command, flag, service, or orchestration layer.

The interface stays `bash "$SKILL_DIR/scripts/pass-ledger.sh" "$STATE" OP ...`:
- `init` and `status`: `used=N limit=20 remaining=N open=none|NN`; neither consumes a pass.
- `reserve work TARGET` or `reserve final ALL`: print `NN`, sequentially `01`–`20`.
- `close NN passed|failed|blocked|interrupted`: print `closed=NN outcome=OUTCOME`.
- Preserve exits `2` exhausted, `3` open/already-closed conflict, `4` locked, `5` invalid state, `64` invalid usage. Unexpected I/O failures remain nonzero stop conditions.
- Preserve valid target syntax and exhaustion-before-open-conflict behavior at pass 20. Do not impose acceptance-dependent restrictions on work/final reservations.
- A successful reservation or `close ... passed` is accounting, never proof of criterion satisfaction or task completion.

## Data flow and authority

1. Discovery reads project instructions and existing changes, reconciles any prior loop evidence, and establishes the original goal, AC IDs, and dependency-aware steps without spending a pass.
2. The helper reserves one work pass before baseline checks or deliverable edits. GitHub Copilot executes one step and records each validation attempt and any single repair batch.
3. GitHub Copilot appends progress, publishes the state projection safely, then closes the reservation. An unsuccessful persistence operation stops further untracked work.
4. Resume compares disk state, ledger, current deliverables/relevant inputs, and environment against saved evidence; it never trusts conversation memory or resets the budget.
5. Once preliminary criteria pass, a separate final reservation runs the complete matrix without deliverable repairs. Fresh, unchanged results and successful completion checkpoints are prerequisites to a completion report.

Ledger directories determine reservations spent; `result` determines a reservation's recorded outcome. `state.md` and SQL todos cannot refund passes. Evidence and acceptance decisions remain the skill's responsibility.

## Helper hardening: narrow mechanical boundaries

### State validation

- Preserve the reservation commit point: successful creation of `passes/NN` spends NN, even if metadata publication subsequently fails.
- Extend the existing scan to validate present `reservation` records against their existing v1 fields and mode/target rules, as data, never sourced shell. Reject malformed published records, unsafe file types, gaps, unexpected pass IDs, and multiple open reservations before further mutation.
- Require the single open reservation, if any, to be the highest ID; an earlier open reservation followed by a closed one is inconsistent history, not a recoverable normal sequence.
- Distinguish absent metadata from malformed published metadata. An absent reservation remains spent/open and can close only `interrupted`; an already interrupted closure with missing metadata remains valid. A non-interrupted closure cannot legitimize missing metadata.
- Do not parse arbitrary evidence files or require acceptance evidence for helper operations. Timestamps are auxiliary and never determine budget or acceptance.
- Keep valid `init` idempotent. Missing markers, unrecognized nonempty state, or corrupt history require reconciliation/blocking, not reconstruction or deletion to regain budget.

### Paths and publication

- Before physical resolution, reject symlink components in the supplied state path, including ancestor and trailing-slash aliases. Preserve ordinary relative/absolute paths and spaces. The skill, not the helper's caller working directory, establishes the selected project root and containment.
- Validate helper-owned directory/file destinations, including metadata, timestamp, and checkpoint candidates, before reads/writes. Reject symlinks and non-regular file destinations; prevent rename-to-directory behavior.
- Retain sibling staging and same-directory rename. Create staging files exclusively rather than truncating existing candidates; stage `finished-at` too. This avoids modifying external hard-linked targets through in-place truncation.
- Check timestamp generation, writes, and renames explicitly. Publish reservation metadata only after it is fully written; publish the close timestamp before `result`, whose rename commits closure. Do not expose partial final records.
- Preserve surviving regular `.new` files as incomplete-write evidence rather than reuse or overwrite them. Reconciliation must retain their contents before safely moving an obstructing candidate aside; never promote an uncertain candidate into a passing result.
- Maintain the original unsafe `result.new` rejection even when improving staging. Existing safety tests must not be bypassed by ignoring previously protected paths.

### Locking, failures, and interruption

- Keep atomic `mkdir .lock` around ledger mutations and the existing one-open-reservation rule. The exclusive (`noclobber`) create of `.lock/owner` is what decides the winner, because some `mkdir` implementations report success to a concurrent loser; a loser exits `4` without claiming the lock. `status` remains read-only and usable while a lock exists, as the original tests require; it is not a writer lease or an acceptance decision.
- Never steal an existing lock, including one with missing/unknown ownership. Cleanup touches only the current invocation's owned owner record and empty lock directory; never recursively delete foreign contents or replace ownership.
- Preserve the operation's failure/signal status through cleanup. Cleanup failure must not become an apparent successful operation; callers must check exit status, not stdout alone.
- Failure after reservation-directory creation leaves that reservation spent. Failure before result publication leaves it open; failure after publication does not authorize changing/refunding its immutable outcome.
- Catchable interruption may release only the owned lock; an uncatchable termination may leave it behind. Recovery requires proof that the recorded writer and associated commands are inactive; uncertainty is a blocker.
- Multi-file updates are not a transaction. Partial initialization, close, progress append, or state publication must be recognizable and reconciled conservatively rather than silently retried as fresh work.

## Skill and template changes

Preserve existing limits: one step, one implementation attempt, one initial validation bundle, at most one repair batch/revalidation per work pass; re-plan after two no-progress failures; at most three executions/check/validation phase. These are instructions and observed behavior, not helper-enforced AI policy.

- **Safe checkpoints:** extend the current sibling-rename guidance to validate project containment, parent components, `state.md`, `progress.md`, candidates, and evidence output paths before access. Reject unsafe links/file types and refuse existing staging candidates. Never append through an unsafe or multiply linked progress file; preserve prior progress bytes and partial-write evidence.
- **Recovery:** distinguish the helper's short-lived lock from the active GitHub Copilot writer and commands. Record observable writer/command identities and liveness findings; absence of `.lock` alone does not authorize taking over an open pass. Retain partial edits, evidence, and unresolved side effects.
- **Freshness:** extend the snapshot recipe to name relevant inputs and environment/configuration as well as all tracked, untracked, and non-Git deliverables. Record exclusions explicitly; never exclude deliverables. Compare on resume and around final verification, invalidate affected criteria, and invalidate all when impact is uncertain.
- **Evidence:** retain exact invocation, cwd, deadline, times, output, actual exit, executed/skipped counts, observations, and AC mappings for every attempt. Keep baseline failures separate from regressions; skipped, unavailable, interrupted, inconclusive, stale, and unresolved flaky results are not passing evidence.
- **Budget:** leave capacity for final verification. A failed final needing repairs requires a work reservation and another final reservation; if capacity is insufficient, checkpoint incomplete rather than extending or resetting the cap.
- **Final checkpoint:** append/persist the final evidence matrix and snapshots while not complete, close the final pass `passed`, then atomically publish `complete` with its references. Any failure withholds completion. A recorded `passed` result with an absent/failed completion checkpoint is not success on resume.

Add focused template fields for active pass/writer and recovery findings; relevant-input/environment snapshot references; initial-validation versus repair evidence; per-phase check execution counts/flaky history; final-gate checkpoint references. Reuse the existing AC, step, baseline, blocker, final-gate, and progress structures rather than introduce a second state model.

## PRD mapping

| Criterion / requirements | Implementation boundary and evidence |
|---|---|
| AC01 / R1–R2 | Preserve skill §1 and template request, scope, AC definitions, graph, and progress; M initialization, P field/rule inspection, E existing-work preservation. |
| AC02 / R2–R3 | Preserve cap/output/lock behavior; tighten ledger consistency and record validation; M lifecycle, malformed-state, usage, and concurrency cases; P reservation-before-work. |
| AC03 / R2–R4 | Spent partial reservations plus skill recovery, writer checks, and snapshot invalidation; M interruption/reload, P/E reconciliation without reset. |
| AC04 / R2–R3 | Helper path/publication/lock fixes; skill checkpoint safeguards and stop rules; M helper hazards, P/E checkpoint behavior and preserved sentinels. |
| AC05 / R3/R5 | Preserve skill §3 limits and expose attempt/no-progress evidence in template; P/E repair, re-plan, and flaky-check bounds. |
| AC06 / R1–R2/R4–R5 | Baseline, evidence matrix, freshness, blocker and exhaustion reporting; P/E actual observations, not helper outcome labels. |
| AC07 / R3–R5 | Preserve skill §4 separate read-only final gate; clarify snapshots and final publication ordering; M accounting only, P/E acceptance and stale-gate rejection. |
| AC08 / technical constraints | Preserve Bash/Python interfaces and four-artifact distribution; authorized canonical/installed comparison, installed checks, and observed lifecycle. |
| AC09 / R6 | Set `name: looper`, align callable and installed paths, preserve `.ralph-loop/`; inspect identity and compare the prior ledger through a disposable copy. |

## Validation plan

### M — Mechanical regression tests

Run from `skills/looper`: `/bin/bash -n scripts/pass-ledger.sh`, `python3 -B scripts/test_pass_ledger.py`, and the existing `shellcheck scripts/pass-ledger.sh` when available. Use macOS system Bash for helper subprocesses; no package manifests, dependencies, or new runner.
Preserve all eight original cases and fixtures beneath the skill directory. Derive new malformed/path fixtures from publicly initialized/reserved state, not private implementation imports.
Add focused coverage for published metadata corruption and impossible open ordering; state-path aliases and unsafe output types; incomplete/stale staging, deterministic write/rename failure, interruption/reload, and immutable history after failure. Assert exact applicable stdout/exits, retained counts/ownership, and unchanged external sentinels.
Keep full 20-pass mixed-outcome/final coverage and concurrent subprocess reservations. Use bounded subprocesses and controlled fixture-local faults, not timing-dependent sleeps, production paths, reset hooks, or a new runtime fault-injection interface. Record actual executed/skipped counts and tool availability.

### P — Semantic instruction/template inspection

Record each R1–R6 requirement and AC01–AC09 against exact skill sections/template fields, expected behavior, findings, and gaps. Inspect failure paths and internal consistency, not keyword presence.
Specifically inspect baseline-before-edit, missing-state reconciliation, checkpoint hazards, repair/no-progress limits, three-attempt flaky handling, stale-evidence rejection, independent work under blockers, final capacity, and completion publication. This demonstrates instruction coverage, not that an AI always obeys it.

### E — Controlled disposable lifecycle and installation

The release owner compares all four canonical and installed artifacts, preserving divergent user work before any authorized synchronization. Rerun mechanical checks on the installed copy and use the installed skill for the exercise; unavailable installation access leaves AC08 and AC09 blocked. Architecture design itself does not require installed-copy access.
In a dedicated project-local disposable task, observe GitHub Copilot initialize without consuming a pass, preserve a pre-existing change, reserve baseline/work, edit, validate, inject a repeatable failure, and perform only one repair batch. Across two no-progress passes, observe a changed plan without weaker criteria.
Interrupt an open pass, resume in a new invocation, prove writer inactivity, retain history, and close it interrupted. Change a relevant input and observe stale-evidence rejection. Exercise a separately reserved read-only final gate, previously flaky checks, unchanged before/after snapshots, and successful durable completion only when all verifiers pass.
Exercise unsafe-checkpoint, blocker, and exhaustion branches in separate disposable scenarios; do not reset an existing task to obtain more passes. Preserve exact commands/cwd/outputs/exits/counts, observations, criterion mappings, and failures before removing fixtures.
This demo is release evidence, not a new runtime feature. Report mechanical, inspected, observed, blocked, and unmeasured results separately; do not infer production task quality or reliability from it.

## Callable-name compatibility

The GitHub Copilot CLI skill name and install-directory basename are `looper`; update frontmatter, invocation examples, path references to the skill, and parity checks. Do not rename the parent workspace project solely for this request. Preserve the existing `.ralph-loop/` project-state path, contents, format marker, and pass history so old runs remain resumable. Test this in disposable copies; never migrate or initialize a live ledger as part of installation.

## Limits and handoff

The helper cannot infer project ownership from `STATE` alone or enforce the skill's repair, evidence, or acceptance decisions. Ordinary local filesystem semantics and cooperating writers are assumed; Bash pathname checks are not a race-proof sandbox against hostile concurrent directory replacement.
Same-directory rename prevents partially published individual records, not a multi-file transaction or guaranteed power-loss durability. Preserve evidence and block ambiguous recovery rather than claim stronger guarantees.
Implement only the justified changes above in the four scoped files, retain existing behavior where sufficient, and validate before claiming release acceptance. No daemon, UI, orchestrator, plugins, resettable limits, sealed-source access, or fabricated production outcomes.

## v1.1 additions

v1.0 left acceptance evidence entirely to the agent. v1.1 moves the parts that can be checked mechanically into the helper, without changing the ledger marker, the 20-pass cap, or the `status` output.

- **Run records.** `run NN [--baseline|--snapshot] [--ac IDS] [--label NAME] [--timeout S] -- COMMAND` writes `passes/NN/runs/NNN/{command,cwd,meta,output,finished-at,exit}`. `meta` is published last before the command starts; `exit` is published last after it finishes. A run with `meta` but no `exit` is in flight or interrupted and blocks `close passed`.
- **Lock and process handling.** The ledger lock is released while the command runs. The command and its timeout watcher run in separate process groups (`set -m`), so a timeout or an interrupted helper stops grandchildren too. The main shell stops the watcher with `SIGKILL`, which it cannot catch, so the watcher can never record a late timeout. A command that outlives its limit never counts as passing.
- **Phases.** In a work pass, runs are `baseline` (before any other run), `initial`, or, after the one allowed `repair`, `revalidate`. A final pass has only `final` runs. The same command and working directory may run at most three times per phase.
- **Gates.** A work pass closes `passed` only if every run finished and every run in the deciding phase exited 0, including a rerun of each check that failed before the repair. A final pass also needs at least three runs, identical opening and closing snapshot runs with non-empty output, and a check covering every `AC01`..`ACnn` up to the recorded `criteria` count, which can only grow. `verdict` re-applies the final gate to the last pass.
- **Named loops.** `.ralph-loop-NAME/` directories are independent ledgers that use the same helper; `PROJECT_ROOT loops` lists them and refuses to follow symlinks.
- **Releases.** `tools/build-release.sh` builds the tarball, installer copy, and `SHA256SUMS` from a commit. The `Release` workflow runs on protected `v*` tags, attests build provenance, and publishes an immutable release. `quickstart.sh` installs a pinned version only after checksum and path checks.

