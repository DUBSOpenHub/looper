# PRD: Looper for GitHub Copilot — Existing Skill Hardening

**Status:** Implemented skill; initial release being hardened, not a new product.
**Product:** `looper` skill for GitHub Copilot CLI, replacing the callable skill name `ralph-loop`.
**Authority:** User-supplied `ralph-loop-input-prd.md` plus the user's in-run name selection; this FULL-mode handoff preserves its requirements and eight acceptance statements and adds AC09 for the naming change.

## Goal
Harden the existing skill so GitHub Copilot carries requests through bounded, resumable implementation and appropriate verification, preserves progress on disk, and stops on verified completion, a genuine blocker, or exhaustion of 20 reserved passes.

## Problem Statement
Long coding and documentation tasks can outlive sessions or lose context. Conversation-only progress is difficult to resume, unbounded retries waste effort, and successful edits or partial checks can be mistaken for completion; users need durable state, bounded work, and fresh evidence.

## User Stories
- As a GitHub Copilot CLI user, I want to start a multi-step task by inspecting instructions and existing changes, then recording a verifiable plan and project-local state.
- As a returning user, I want interrupted work and the ledger reconciled so progress and budget survive session loss.
- As a user, I want one bounded step implemented and validated, with at most one repair batch per pass.
- As a blocked user, I want the missing input, permission, or dependency and next action recorded, with only independent work continuing.
- As a user, I want completion reported only after every criterion passes a separate final verification run.
- As a GitHub Copilot CLI user, I want to invoke the skill by the concise name `looper` while retaining existing resumable task state.

## Scope
- **In scope:** Harden the four existing skill artifacts under `skills/looper/`; install the callable skill under `~/.copilot/skills/looper`; maintain parity with the canonical workspace copy.
- Preserve `<project-root>/.ralph-loop/` state paths and histories. This renames the callable skill, not the durable state directory or format.
- **Out of scope:** A new autonomous runner, UI, service, orchestrator, continuous operation without an active GitHub Copilot session, or changes to Dark Factory, Havoc, or model configuration.
- **Out of scope:** Guarantees beyond defined checks; automatically obtaining permissions, credentials, or approvals; dependencies or frameworks added solely for the loop.
- **Forbidden shortcuts:** Resetting the budget, discarding prior state/evidence, weakening or removing criteria, or bypassing the final gate.

## Technical Constraints
- Bash helper compatible with macOS system Bash; Python 3 standard-library tests; Markdown instructions and template. No new dependencies, services, or frameworks are needed.
- Callable skill name and install directory: `looper` and `~/.copilot/skills/looper/`.
- Project-local state root remains `<project-root>/.ralph-loop/` for compatibility. Preserve unrelated project changes.
- Repository signals are filenames only; implementation inspection is not an input to this specification. No architecture or implementation is prescribed.

## Functional and Non-functional Requirements
### R1 — Scope and planning
- Support coding, documentation, investigation, and other requests, choosing verifiers appropriate to the deliverable.
- Inspect applicable project instructions and existing work; preserve unrelated changes.
- Define stable acceptance-criterion IDs (`AC01`, ...) with an observable assertion, verifier, expected outcome, and failure condition.
- Break the work into stable, dependency-aware steps (`S01`, ...). Do not weaken or remove criteria to make checks pass.
### R2 — Durable state and recovery
- Store loop state under `<project-root>/.ralph-loop/`, including the goal, criteria, task graph, append-only progress, and pass evidence.
- Use the bundled ledger helper as the authority for pass reservations and outcomes; session memory or SQL todos are not authoritative.
- On resume, inspect current project changes and relevant inputs against saved verification evidence. Mark stale criteria for re-verification.
- If state is missing but evidence of prior loop work remains, reconcile it instead of silently starting a new loop.
- Do not follow state-directory symlinks outside the project. Persistence errors block further untracked work.
### R3 — Bounded execution
- Reserve a pass before deliverable edits or acceptance/baseline test runs. Discovery and planning do not consume a pass.
- Each work pass targets one step and permits one implementation attempt, an initial validation bundle, and at most one repair batch with revalidation.
- Count failed, blocked, interrupted, and final-verification reservations toward the hard limit of 20. Never allocate pass 21 or reset the counter.
- Permit only one active writer; preserve lock ownership and never steal a live lock.
- Reserve capacity for final verification; exhaustion without a passing final gate means incomplete work, not permission to extend the limit.
### R4 — Verification and completion
- Run relevant baseline checks before the first deliverable edit, and distinguish pre-existing failures from regressions.
- Capture exact commands, working directory, outputs, exit codes, test counts, observations, and affected criteria as pass evidence.
- Require a separately reserved, read-only final pass that runs the complete verification matrix for every criterion and relevant suite.
- Reject skipped, unavailable, interrupted, inconclusive, or stale checks as passing evidence. Recompute the deliverable fingerprint and invalidate final evidence if relevant files or environment change.
- Set the task complete only after the final gate passes and the result is durably checkpointed. Otherwise report the precise blocker or exhaustion state and next action.
- Read-only final verification permits evidence/checkpoint writes, not deliverable repairs. A required repair needs a work reservation and another separate final reservation, within the same 20-pass budget.
### R5 — Failure and edge-case handling
- Diagnose validation failures from recorded evidence; do not retry an unchanged failure indefinitely.
- After two no-progress failures on a step, re-plan the approach without weakening acceptance criteria.
- For flaky checks, preserve failures and investigate; allow at most three executions per check in a validation phase. Previously flaky checks require three fresh consecutive passes in final verification.
- For missing test infrastructure, use minimal reproducible validation with available tools; do not add a framework solely for the loop.
- Ask for essential user input or permission when required; record the blocker and continue only on independent work.

### R6 — Callable skill identity
- Name the installed GitHub Copilot CLI skill `looper`, with matching frontmatter, invocation guidance, and canonical/installed directory names.
- Preserve the `.ralph-loop/` project state path so existing budgets and recovery records remain discoverable; do not silently migrate or initialize a fresh ledger.

## Frozen Public Helper Contract
This is the existing reservation/accounting interface, not new functionality. From `skills/looper`, invoke `bash scripts/pass-ledger.sh STATE <operation>`; `STATE` is the selected project-local loop-state directory.
| Operation | Public behavior |
|---|---|
| `init` | Initialize state; never erase/reset an existing task's history to regain budget. |
| `status` | Print `used=N limit=20 remaining=N open=none|NN`; reservations, including an open one, count as used; remaining is 20 minus used. |
| `reserve work S01` | Reserve a work pass for the selected stable step; print its two-digit ID. |
| `reserve final ALL` | Reserve a separately counted final pass; print its two-digit ID. |
| `close NN passed\|failed\|blocked\|interrupted` | Close that reservation with one listed outcome; closing does not refund budget. |
IDs are sequential `01`–`20`; never `21`. `init`/`status` do not reserve work. Only one reservation may remain open.
Known nonzero exits: **2** exhausted; **3** open/already-closed conflict; **4** locked; **5** invalid state; **64** invalid usage.
The helper is **not an acceptance oracle**: closing a reservation `passed` does not prove a criterion or task complete. Repair bounds, verifier selection, snapshots/freshness, and final acceptance belong to `SKILL.md` and the state template; no new helper commands, flags, or policy engine are required.

## Acceptance Criteria and Verification
The numbered statements below are verbatim from the input. **M** = automated mechanical tests through the public helper; **P** = transparent requirement-to-instruction/template inspection; **E** = controlled disposable lifecycle observation. Policy inspection is not proof that an AI always follows instructions.

### AC01 — New task initialization
1. **New task initialization:** A new task has a project-local state directory, original request, explicit acceptance criteria, step graph, and append-only progress record.
- **Given** a new request and existing project changes, **When** discovery/planning finishes, **Then** applicable instructions and unrelated work are preserved, and state contains the original request/goal, full criterion definitions, stable dependency-aware steps, progress, and evidence locations; no pass is consumed.
- **Verify:** M checks `init`/`status` without reservations; P maps R1–R2 to instructions and template fields; E observes initialization for a disposable task and preservation of pre-existing work.

### AC02 — Durable budget
2. **Durable budget:** The helper reserves sequential passes, rejects concurrent open reservations and malformed/gapped state, and refuses pass 21.
- **Given** valid state, **When** work/final passes are reserved and closed with mixed outcomes, **Then** all reservations remain counted in order through 20, including failed, blocked, and interrupted passes; no close, reload, or reinitialization refunds or resets budget.
- **Given** competing callers, an open reservation, malformed/gapped state, or exhausted budget, **When** reservation is attempted, **Then** it is rejected as appropriate without duplicate allocation or lost history.
- **Verify:** M covers IDs `01`–`20`, refusal of `21`, status counts, mixed work/final outcomes, open conflicts, double close, invalid arguments/outcomes/IDs, malformed/gapped fixtures, reload/reinit, and concurrent subprocesses; assert documented stdout and exit semantics. P verifies reservation-before-edit/check instructions (R3).

### AC03 — Recovery
3. **Recovery:** An interrupted pass remains counted; resuming requires reconciliation and does not reset or discard prior evidence.
- **Given** interruption after reservation, partial edits, validation, or final verification, **When** work resumes, **Then** the reservation stays counted, unresolved work is reconciled against current changes/relevant inputs, stale evidence is invalidated, and history is retained rather than silently restarted.
- **Given** missing state but surviving loop-work evidence, **When** resumption is attempted, **Then** reconciliation or a recorded blocker precedes further work; a fresh budget is not silently initialized.
- **Verify:** M reserves, interrupts before close, reloads in a new process, closes `interrupted`, and checks the next ID/count; P maps reconciliation and missing-state rules; E observes interrupted resume and relevant-input changes (R2–R4).

### AC04 — Safe persistence
4. **Safe persistence:** Symlinked state and unsafe checkpoint paths are rejected; an existing lock is not stolen.
- **Given** symlinked state, an unsafe checkpoint path, an existing lock, or a persistence failure, **When** state is accessed or a checkpoint attempted, **Then** unsafe writes are rejected, external files and lock ownership remain intact, and persistence errors block further untracked work and completion.
- **Verify:** M uses helper-generated disposable state for symlink, lock/contention, and write-failure cases, checking exit behavior, retained history/ownership, and unchanged external sentinels. P inspects checkpoint-path rejection and stop rules; E observes refusal/blocker reporting, without treating helper tests as checkpoint-policy enforcement (R2–R3).

### AC05 — Bounded repair
5. **Bounded repair:** A work pass limits repair to one batch and records unresolved failures rather than looping indefinitely.
- **Given** a reserved work pass for one step, **When** initial validation fails, **Then** there is at most one implementation attempt, one initial validation bundle, and one repair batch with revalidation; unresolved failures and diagnosis are recorded.
- **Given** two no-progress failures or a flaky check, **When** continuation is considered, **Then** the approach is re-planned without weaker criteria, failures remain visible, and each check has at most three executions per validation phase.
- **Verify:** P traces R3/R5 limits and failure records to instructions/template; E injects a repeatable failure and observes bounded repair, unresolved reporting, and no-progress re-planning. The helper only accounts for these passes; text matches cannot establish runtime compliance.

### AC06 — Evidence-backed status
6. **Evidence-backed status:** Every completed criterion maps to fresh, observable verification evidence; blockers and incomplete work are reported as such.
- **Given** a criterion reported complete, **When** evidence is reviewed, **Then** its assertion/verifier/outcome maps to exact commands, working directory, outputs, exits, counts, observations, and affected IDs; baseline checks preceded the first edit and pre-existing failures are distinguished from regressions.
- **Given** skipped, unavailable, interrupted, inconclusive, or stale checks, **When** status is evaluated, **Then** they are not passes; changed inputs invalidate affected evidence, and blockers/exhaustion identify unresolved work and the precise next action.
- **Given** missing infrastructure or essential input/permission/dependencies, **When** work cannot be verified or continued, **Then** use available minimal reproducible validation where adequate; otherwise record/request the dependency and continue only on independent work, without inventing approval.
- **Verify:** P maps R1/R2/R4/R5 to the evidence matrix and reporting instructions; E records baseline failures, fresh/stale evidence, and blocker/exhaustion reports. Observed outputs, not a helper `passed` label or keyword check, support completion claims.

### AC07 — Final gate
7. **Final gate:** Completion requires a separate final pass covering all criteria, unchanged deliverables, and all required verifiers.
- **Given** work criteria appear satisfied and budget remains, **When** final verification starts, **Then** a distinct `reserve final ALL` consumes a pass, runs the complete matrix and relevant suites without deliverable edits, and requires three fresh consecutive passes for previously flaky checks within the three-execution limit.
- **Given** final evidence, **When** completion is considered, **Then** recomputed fingerprints and relevant file/environment snapshots remain current, every required verifier is conclusive and passing, and the result is durably checkpointed before completion is reported.
- **Given** a changed deliverable/environment, failed/interrupted/missing check, failed checkpoint, or exhausted budget, **When** the gate is evaluated, **Then** completion is withheld; invalidated final evidence requires a new separately reserved gate after any needed work, never pass 21.
- **Verify:** M tests final reservation/counting/conflicts/interruption/exhaustion only; P inspects the full R4/R5 gate; E observes a read-only final run, deliberate stale-evidence rejection, flaky-check handling, and durable completion or precise failure reporting.

### AC08 — Installed usability
8. **Installed usability:** The skill's instructions and helper are installed for GitHub Copilot CLI use and match the canonical workspace copy.
- **Given** the hardened canonical skill and its installation, **When** GitHub Copilot CLI uses the installed skill, **Then** instructions/helper match the workspace copy, the bundled template/tests are available consistently, and documented helper usage works on macOS system Bash without additional dependencies.
- **Verify:** Compare installed artifacts with canonical artifacts; rerun the existing Python standard-library suite and lifecycle/edge tests on the changed helper using macOS system Bash; inspect installed instructions/template and perform E with the installed skill. Installation parity is not proof of task quality.

### AC09 — Callable skill name
9. **Callable skill name:** The frontmatter, folder basename, and installation path all use `looper`; references to the legacy callable name are absent from invocation guidance, while project state still uses `.ralph-loop/` and an existing history remains unchanged and resumable.
- **Given** a canonical skill named `looper` and an existing `.ralph-loop/` task ledger, **When** the canonical skill is installed and invoked as `looper`, **Then** the GitHub Copilot CLI entry point uses that name, all four artifacts are present and identical, and the previous ledger's content and pass count are unchanged and accessible through documented setup.
- **Verify:** Inspect name metadata, folder and installation basename, trigger wording, and legacy invocation references; hash-compare all four skill artifacts; use a disposable copy of an existing-format ledger to confirm installation does not rename, initialize, or reset `.ralph-loop/`. The parent repository directory need not be renamed.

## Release Validation and Evidence Limits
- **M:** Automate initialization, full 20-pass lifecycle, mixed outcomes, concurrent callers, lock preservation, duplicate close, interruption/reload, malformed/gapped state, invalid usage, symlinks, persistence failure, and exhausted final-gate scenarios. Derive fixtures from publicly generated state; do not require implementation-source access or invented private interfaces.
- **P:** Record each R1–R6 requirement and AC01–AC09 ID against an exact instruction section/template field, expected rule, observed finding, and gap. Inspect semantics and failure paths; label missing instructions as failures. Text checks never prove an AI always obeys policy.
- **P/E naming check:** Inspect AC09's metadata, skill folder and installation basename, invocation triggers, and durable-state compatibility; compare the four delivered skill artifacts and verify a disposable copy of existing-format `.ralph-loop/` state is neither migrated nor reset.
- **E:** Run a controlled, disposable end-to-end lifecycle in a dedicated project-local fixture, not a production task or new product feature: initialize, reserve baseline/work, edit, validate, inject failure, bounded repair, interrupt/resume, change relevant inputs, invalidate stale evidence, reserve final, verify unchanged deliverables, and checkpoint. Exercise blocker/exhaustion branches separately; retain evidence before cleaning up the disposable fixture.
- Record exact commands, working directories, outputs, exits, actual test counts, observations, criterion mappings, and failures for release validation. Report automated, inspected, observed, blocked, and unmeasured results separately; do not silently replace unavailable checks with passes.
- The existing eight helper tests reportedly passed before this run: historical context only, not fresh release evidence. Re-run on hardened artifacts and include the additional lifecycle/edge coverage; helper success alone does not establish end-to-end acceptance.
- Production-task quality, reliability, and completion outcomes remain **unmeasured unless actually observed**. A controlled exercise supports only its recorded scenarios; this PRD asserts no new execution results.

## Success Criteria and KPIs
Targets below express requirement compliance, not measured improvements or benchmarks. Production baselines are unmeasured; the historical helper-test result is not a substitute.
| KPI | Baseline | Target | Measurement |
|---|---|---|---|
| Verified completion rate | Unmeasured | Every declared completion has a passing final evidence matrix | Audit declarations against fresh, separately reserved final gates and durable checkpoints |
| Resume integrity | Unmeasured | Every resumed task retains history and invalidates stale evidence appropriately | Compare pre-interruption and resumed state/evidence |
| Name consistency | Unmeasured | Skill metadata, folder, and install path use `looper`; old project-state location remains readable | Inspect name contract, compare four installed artifacts, and verify state path/history is unchanged |
| Budget integrity | Historical eight-test pass only; production unmeasured | Zero runs exceed 20 reservations or reset the same task's budget | Lifecycle/edge tests and observed reservation histories |
| Traceability | Unmeasured | Every criterion has a verifier/outcome at completion or a stated blocker | Inspect criterion/evidence matrices and incomplete reports |
| Bounded recovery | Unmeasured | No unbounded retries; one repair batch/pass, re-plan after two no-progress failures, at most three executions/check/phase | Inspect policy and audit observed pass/failure records |

## Risks and Mitigations
- Poor checks can give false confidence: require observable assertions, actual counts, and full final verification; ledger correctness is not acceptance correctness.
- Context resets can leave partial edits: disk state is authoritative and reconciliation precedes resumption.
- Relevant changes stale evidence: compare saved input/deliverable/environment snapshots, rerun affected checks and the final gate.
- The cap may precede completion: preserve final-verification capacity, report exhaustion honestly, and never evade the cap.
- External/human dependencies can block progress: record the precise dependency and unblocking action, not assumed approval.
- Renaming a skill can strand existing runs if its durable state is renamed too: retain `.ralph-loop/` and verify the rename does not reset or migrate history.

## Open Questions
No new product decisions beyond the user's `looper` skill name are introduced by this handoff. Unavailable verification or permissions become explicit validation blockers; no company OKRs, market research, stakeholder commitments, or capability claims are inferred.
