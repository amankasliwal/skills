---
name: ship-feature
description: >-
  Use when you want to run a WHOLE feature end-to-end rather than one isolated step — e.g.
  "run my feature workflow", "kick off the pipeline", "start feature X end to end", "grill me
  then make the spec and tickets", "dispatch workers on the ready tickets", or "finish/verify this
  PR". A thin conductor that sequences grill → spec → tickets → triage, then dispatches local
  worker subagents that implement the ready tickets as a stack of open PRs (each: TDD → review →
  verify — never merging). Do NOT use for a single step a dedicated skill already owns (writing
  just a spec, only slicing tickets, a one-shot review, debugging one bug, a lone TDD fix).
---

# Ship Feature

A **thin conductor** for the end-to-end feature workflow. It **composes existing skills** — it never
reimplements them and never owns the process. Delegate each step to the skill that owns it, and
stop wherever the user's judgment is genuinely needed.

**The structural fact that shapes everything:** issues are implemented by **local worker
subagents you dispatch from this session**, each in its own git worktree, **stacked** on a
**feature base branch named after the work**, as **open PRs**. The skill **never merges
anything** — the user reviews the whole stack end-to-end and merges it at the end, so the
integration branch stays untouched until the feature is genuinely done.

> **Placeholders vs. real names.** `base` / `feat-1` / `feat-2` below are **stack-position
> shorthand, never literal branch names.** Name every branch after its work, per your repo's
> convention. `<issue-id>` is your tracker's id (Jira/Linear/GitHub #). `<integration-branch>`
> is wherever the team merges finished work (`main`, `develop`, …). Read these from the project;
> this skill hardcodes none of them.

## Dependencies — check at kickoff (before anything else)

This conductor does almost nothing itself, so it only runs end-to-end if the skills it drives
are installed. **At the start of a run, confirm each capability below resolves to an available
skill. If a required one is missing, STOP and tell the user what to install** (see
[`install.sh`](../../scripts/install.sh) / the repo README) — don't begin a run you can't finish.

| Capability (required) | Reference implementation |
|---|---|
| Grill a plan against domain docs | `grill-with-docs` |
| Synthesize a spec onto the tracker | `to-spec` |
| Break a spec into tracer-bullet tickets, marking each HITL/AFK | `to-tickets` |
| Triage tickets + write agent briefs | `triage` (+ its per-repo config, e.g. `setup-matt-pocock-skills`) |
| Test-drive an implementation | `tdd` |
| Correctness/security code review (Opus subagent, diff vs base) | `code-reviewer` — bundled in this repo (from [Jeffallan/claude-skills](https://github.com/Jeffallan/claude-skills), MIT) |
| Isolated worktrees + parallel subagent fan-out | `superpowers:using-git-worktrees`, `superpowers:dispatching-parallel-agents` |
| Engage critically with review feedback | `superpowers:receiving-code-review` |
| Local worker dispatch | the **Agent tool** (built-in) — workers are local subagents, *not* cloud agents |

| Capability (recommended — degrades gracefully) | Reference implementation | Fallback if absent |
|---|---|---|
| Commit + push + open PR non-interactively | `commit-commands:commit-push-pr` | plain `git` + `gh pr create` |
| Flag over-engineering | `ponytail-review` | skip the simplicity flag pass |
| Apply reuse/simplification cleanups | `simplify` (built-in) | manual cleanup in the review loop |
| Exercise acceptance criteria end-to-end | `verify` (built-in) | manual E2E with real API calls / a browser |

Skill names above (`superpowers:…`, `commit-commands:…`) are how the reference install resolves
them. If a machine exposes them under different names, update the references — otherwise the
calls silently fail to resolve.

## Preflight (kickoff only)

The engineering skills read **per-repo config** (issue tracker, triage-label vocabulary,
domain-doc layout). If that config is missing, **ask the user to run their toolchain's setup
command and pause until they confirm** — many setup skills are user-invoked only, so you can't
run them yourself. Without it, spec/tickets/triage fall back to defaults and the ready/human roles
won't map to your tracker's real labels.

## Which phase are you in?

Read the request and pick the entry point — don't assume "kickoff" just because the skill fired.

| If… | Go to |
|---|---|
| New feature — no spec or issues yet | **Phase A — Kickoff** (from step 1) |
| spec/issues exist but no workers running | **Phase A from step 3** (ensure `base` → briefs → dispatch) |
| Pointed at an existing PR / one issue: review, finish, or verify it | **Phase C — Finish** |
| A `ready-for-human` issue flagged for you to drive | **HITL handling** |
| Relaunch / continue an existing feature's workers | **Phase A step 6** (re-dispatch on the existing stack) |

When genuinely ambiguous, ask one short question — the wrong phase wastes downstream work.

---

## Phase A — Kickoff (interactive)

Run steps 1–6 in order as **one continuous flow — advance automatically; do NOT stop between
steps to ask permission.** The only pauses are the **preflight** and the **grill Q&A** (step 1).

**Grilling (step 1) is the SINGLE alignment gate** — where the user shapes the work and you get
on the same page. Run it thoroughly; don't auto-answer for them. **Once grilling is done, steps
2–6 run autonomously** — don't ask the user to approve the spec, the test seams, the ticket
breakdown, the HITL/AFK split, or publishing. The reversibility gate is the safety net: anything
uncertain or irreversible becomes a `ready-for-human` issue (surfaced later), so you never
auto-ship a risky call. The only human touchpoints after grilling are `ready-for-human` issues
and the **final stack review**.

1. **Grill** (`grill-with-docs`) — pressure-test the idea against the domain model and docs;
   sharpen terminology. It writes spec context (domain docs, ADRs) into the working tree — that
   context rides onto `base` in step 3, so every worker inherits it.
2. **spec** (`to-spec`) — synthesize the agreed design into a spec on the tracker. It would normally
   quiz the user on test seams / modules — **don't pause**; decide them yourself from the grilled
   design + codebase and let it publish. (The spec issue's id names `base`.)
3. **Create the feature base branch** off `<integration-branch>`, named after the feature per the
   repo convention. Bring the grill's still-uncommitted spec docs onto it and commit + push.
   **`base` carries the spec/ADR context and is the bottom of the stack** — the first worker
   branches from it; later workers stack on prior workers' branches. **`base` is pushed but NEVER
   merged** until the whole feature is done and reviewed. Record its name.
4. **Break into tickets** (`to-tickets`) — break the spec into tracer-bullet tickets (vertical
   slices, parented to the spec). This step **marks each ticket HITL or AFK** (prefer AFK) and
   publishes AFK tickets with the `ready-for-agent` role. **Decide the breakdown and the split
   yourself — don't pause.**
5. **Triage → agent briefs** (`triage`) — for each `ready-for-agent` issue, post an **agent
   brief**: the durable, behavioral, file-path-free contract the worker works from — and state
   its **base = its assigned stack branch** (never `<integration-branch>`) and that the worker
   **must not merge**. Confirm HITL tickets carry `ready-for-human`. Default to `ready-for-human`
   when unsure. See [`references/afk-handoff.md`](references/afk-handoff.md).
6. **Dispatch the local workers** (only after step 5's briefs are posted). Following
   [`references/worker-orchestration.md`](references/worker-orchestration.md): build the stack
   from the issues' dependency graph and dispatch each `ready-for-agent` issue as a local worker
   subagent (Agent tool, each in its own worktree). Workers run in dependency **waves** — parallel
   where independent, sequential where stacked — each branches **from its base**, runs the
   per-issue playbook, opens a **PR onto its base**, and **stops without merging**.
   `ready-for-human` issues are *surfaced*, not implemented. When every worker is done, **report
   the whole stack** (PRs + merge order) for review — do **not** merge.

After step 6, kickoff is done. You'll be pulled back for `ready-for-human` issues, the per-PR
finish, and the final stack review.

---

## Phase B — Autonomous implementation (local workers build the stack)

Each issue is implemented by a **local worker subagent** (in its own worktree) that executes
[`references/per-issue-playbook.md`](references/per-issue-playbook.md) against one
`ready-for-agent` issue, from its agent brief. Each worker **branches from its base** and **opens
a PR onto that base — it never merges**. The conductor orchestrates the waves and hands the
**stack of open PRs** back for review — see
[`references/worker-orchestration.md`](references/worker-orchestration.md). The playbook is the
single source of truth for *how an issue becomes a verified, open PR* — the same contract Phase C
uses.

## Phase C — Finish a PR / issue (interactive or on demand)

When pointed at a specific PR or issue, run
[`references/per-issue-playbook.md`](references/per-issue-playbook.md) **from the review step
onward**:

1. **Review loop** — each pass pairs correctness with simplicity: a code-review subagent (diff vs
   the PR's base) **plus a simplicity pass** (flag over-engineering, apply cleanups, re-run tests)
   ⇄ `superpowers:receiving-code-review`, looping until a pass surfaces no new *actionable*
   feedback. Engage critically — verify each point, push back on the questionable ones — don't
   rubber-stamp.
2. **E2E verify** — exercise the issue's acceptance criteria end-to-end on local: real API calls
   for backend, a browser for frontend. Capture evidence tied to each criterion.

Leave the PR **open** — the stack is merged by the user at the end.

## HITL handling

When a `ready-for-human` issue is flagged, drive it yourself: walk the user through the
ambiguous / risky parts, implement with `tdd` (on its stack branch), then run Phase C. Once
verified, it rejoins the stack.

---

## Guardrails

- **Defer to the project, don't restate it.** Branch naming, any pre-PR review mandate, and
  worktree-branch rules live in the repo's `CLAUDE.md` / contributing guide. The playbook points
  at them so this skill never drifts out of sync with project policy.
- **Thin & composable.** Delegate to each skill; never reimplement one. Tempted to inline what
  `to-tickets` or `tdd` already does? Stop and invoke it.
- **Workers run locally, never on the cloud.** They are subagents in *this* session, each in its
  own worktree — so they have the working tree, write permissions, and full context. Don't use a
  cloud/cron routine (it lacks all three).
- **Stacked PRs; the skill never merges.** `base` and the worker branches stack as **open PRs**
  (`base ← feat-1 ← feat-2 …`); each worker PRs onto its base and stops. Nothing is merged by the
  skill — not into a base branch, not into `<integration-branch>`. The user reviews the whole
  stack and merges it up at the end.
- **Low friction — grilling is the only gate.** Stop for the user in exactly two places: the
  **grilling** (step 1) and **`ready-for-human` issues**. Everything else you decide and execute
  without asking. The single review is the **final stack review**.
- **Reversibility gates autonomy.** The `ready-for-agent` lane is for work that's safe to get
  wrong and re-roll. Anything irreversible stays `ready-for-human` — see afk-handoff.md.
- **AI disclaimer.** Any tracker comment this pipeline posts starts with a clear AI-generated
  marker (e.g. `> *Generated by AI.*`) — following your triage skill's convention for briefs.
