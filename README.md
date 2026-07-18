# Agent Skills

Portable, composable **agent skills** for real engineering. Each is small, easy to adapt, and
works with any model — hack on them, make them your own.

**Cross-harness:** every skill is a plain `SKILL.md` contract that runs on [Claude
Code](https://claude.com/claude-code), [Codex](https://developers.openai.com/codex/), and any other
[Agent Skills](https://agentskills.io/specification)-compatible harness. The set also ships as a
native **Claude Code plugin**.

## Skills

**Model-invoked** — fire automatically when your request matches:

| Skill | What it does |
|---|---|
| [`ship-feature`](skills/ship-feature/SKILL.md) | A thin conductor for the whole feature workflow: grill → spec → tickets → triage, then dispatches local worker subagents that implement the ready tickets as a **stack of open PRs** (each: TDD → review → verify — never merging). You review the stack and merge. Tracker- and repo-agnostic. |
| [`code-reviewer`](skills/code-reviewer/SKILL.md) | Structured, prioritized code-diff review (bugs, security, smells, spec-compliance). Vendored from [Jeffallan/claude-skills](https://github.com/Jeffallan/claude-skills) (MIT) — it's a required dependency of `ship-feature`, bundled so one install covers it. |

## Install

### Option A — Claude Code plugin (self-updating, recommended for Claude Code)

Installs the whole set as a managed bundle that updates when a new version ships:

```bash
claude plugin marketplace add amankasliwal/skills
claude plugin install amankasliwal-skills@amankasliwal
```

### Option B — cross-harness script (Claude Code, Codex, others)

Copies every skill into the directories each harness reads (`~/.claude/skills` **and**
`~/.agents/skills`) and installs each skill's external dependencies:

```bash
git clone https://github.com/amankasliwal/skills.git
cd skills
./scripts/install.sh
```

Restart your agent afterward so the new skills load. Re-run the script to refresh.

## Dependencies

Skills compose other skills, so a skill's dependencies must be installed too. `scripts/install.sh`
handles them; the plugin install does **not** pull a skill's cross-repo dependencies, so plugin
users should also run the script (or install the deps below) once.

**`ship-feature`** drives:

| | Skill | Source | Fallback |
|---|---|---|---|
| Required | `grill-with-docs`, `to-spec`, `to-tickets`, `triage`, `tdd` | [`mattpocock/skills`](https://github.com/mattpocock/skills) — `npx skills add mattpocock/skills` | — |
| Required | worktrees, parallel-subagent fan-out, critical review (`superpowers:*`) | [superpowers](https://github.com/obra/superpowers) | — |
| Required | code review (Opus subagent, diff vs base) | `code-reviewer` — **bundled in this repo** (vendored from [Jeffallan/claude-skills](https://github.com/Jeffallan/claude-skills), MIT) | — |
| Required | local worker dispatch | the harness's Agent/subagent tool | — |
| Recommended | commit + push + PR | `commit-commands:commit-push-pr` | `git` + `gh pr create` |
| Recommended | flag over-engineering | `ponytail-review` ([ponytail](https://github.com/DietrichGebert/ponytail)) | skip the flag pass |
| Recommended | apply simplifications; E2E verify | `simplify`, `verify` (built into Claude Code) | manual |

Recommended deps degrade gracefully — if one is absent the skill uses the fallback and keeps going.

## Harness compatibility

- **Claude Code** — plugin (Option A) or `~/.claude/skills` (Option B).
- **Codex** and other **Agent Skills**-compatible harnesses — `~/.agents/skills` (Option B).

Some dependencies of `ship-feature` (the `superpowers:*` / `commit-commands:*` plugins) are
Claude-Code-specific; on other harnesses use the fallbacks in the table above.

## Repo layout & contributing

See [AGENTS.md](AGENTS.md) for the layout, the plugin manifests, and how to add a skill.

## License

MIT — see [LICENSE](LICENSE). Dependency skills/plugins are owned by their respective authors and
installed from their own repos.
