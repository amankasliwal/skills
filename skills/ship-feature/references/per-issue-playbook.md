# Per-issue playbook

The contract for taking **one** issue from "ready" to an **open, verified PR stacked on its
base branch** — *not* merged. Used in two places, identically:

- **Phase B** — a local worker subagent runs the whole thing for one `ready-for-agent` issue.
- **Phase C** — this session runs it from the *review step* onward to finish a PR.

Keep them in sync by keeping them here, in one file.

**Work from the agent brief.** The issue's agent brief (posted during triage) is the
authoritative spec — its acceptance criteria are your definition of done. The issue body and
discussion are context; the brief is the contract. Don't widen scope beyond it.

**Base = your assigned stack branch, NOT the integration branch.** The agent brief / worker prompt
names your **base branch** — the feature base (spec/ADR/domain-doc base) for the first worker, or
a prior worker's branch for later ones. You branch from it and PR onto it; it already contains the
spec context and all prior work in the stack below you, so you inherit both for free. Before
coding, skim the base branch's recent history and the parent PRD's done sibling issues so you
**build on prior slices instead of duplicating them**.

## 1. Branch correctly

`git fetch`, then branch **off your assigned base branch** (`origin/<base-branch>`) — *not* off
the integration branch. Work in your own git worktree on that base. Name the branch per the repo's
convention (project `CLAUDE.md` / contributing guide). Never commit or push on a throwaway
worktree branch that CI rejects.

## 2. Implement with the TDD skill

Drive the implementation through `tdd` (red → green → refactor). Tests come first — they are both
the spec and the safety net that makes autonomous re-rolls safe. Don't delete or weaken existing
tests to go green; if a test seems wrong, surface it, don't quietly drop it.

## 3. Pre-PR review (if the project mandates it — before the PR exists)

If the project requires a review **before** opening the PR, dispatch a code-review subagent (Agent
tool, `model: opus`) against the diff vs **your base branch**, then fix every **Critical** and
**Major** finding. Doing this pre-PR keeps noise out of the PR thread and cuts review round-trips.

## 4. Open the PR — onto your base branch

Commit and open the PR (`commit-commands:commit-push-pr`, `/ship`, or plain `git` + `gh pr
create`), **targeting your base branch as the PR base — NOT the integration branch**. Write a
why-focused description and link the issue. **On an unattended (AFK) run there is no human to
confirm** — commit / push / PR non-interactively; don't pause for a confirmation prompt.

## 5. Post-PR review loop

Loop until a pass yields no new *actionable* feedback — covering **both correctness and
simplicity**:

1. **Correctness** — dispatch a code-review subagent (Agent tool, `model: opus`) to review the PR
   diff against **your base branch** for bugs, security, and correctness.
2. **Simplicity pass** — on the same diff:
   - **Flag over-engineering** (`ponytail-review` or equivalent): dead code, reinvented stdlib,
     needless dependencies, speculative abstractions, code that can shrink. It only *reports*; its
     findings feed step 3.
   - **Apply cleanups** (`simplify` or equivalent): reuse / simplification / efficiency / altitude.
     It *changes code*, so re-run the test suite after; never let a cleanup weaken a test or break
     an acceptance criterion (surface a now-inconvenient test, don't drop it).
3. **`superpowers:receiving-code-review`** — work all the feedback with technical rigor: verify
   each point, implement the real ones, push back (with reasoning) on the questionable ones. Not
   performative agreement — a wrong "fix" is worse than the original.
4. Re-run the loop. Stop when both the correctness review and the simplicity pass are clean.

## 6. E2E verify

Prove the agent brief's acceptance criteria actually hold, end-to-end, on local — don't infer it
from "tests pass":

- **Backend:** real API calls against the locally-running service. Capture request + response.
- **Frontend:** drive it through a browser (e.g. a Chrome MCP). Capture screenshots / DOM state.

Use the `verify` skill if it fits. Tie each piece of evidence back to a specific criterion. **If
E2E can't actually be run in this environment** (no local service, no browser, no DB access),
don't fake it — stop-and-surface the issue as `ready-for-human` (see below) rather than claim
verification you didn't do.

## 7. Hand back — leave the PR open, do NOT merge

Once the review loop is clean **and** E2E passes, **leave the PR open** — do **not** merge it. Move
the issue to its in-review / verified state, **remove the `ready-for-agent` label** (so it's no
longer eligible for pickup), leave a trail (PR link + verification evidence), and return your
**branch name + PR link** (it becomes the base for whatever stacks on top). **Workers never
merge** — the entire stack is reviewed and merged by the human at the end. (See
worker-orchestration.md for how the stack is handed back.)

---

### Stop-and-surface conditions (AFK runs)

Autonomy has limits. A worker should **stop, re-label the issue `ready-for-human`** (leaving its
branch/PR as-is), post what's blocking (prefixed `> *Generated by AI.*`), and stop — rather than
push through — if it hits any of these. They mean the issue belongs in the human lane:

- The spec turns out ambiguous enough that you'd be guessing at product / UX behavior.
- The work wants an irreversible action a worker shouldn't take alone (a destructive migration, a
  secret rotation, prod data, auth/security — see afk-handoff.md).
- The review loop can't converge — the same class of finding keeps reappearing.
- E2E verification fails (or can't be run here) and the fix isn't obviously mechanical.
