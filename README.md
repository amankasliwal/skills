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

> ⚠️ Installing **only** `amankasliwal-skills` gives you `ship-feature` + `code-reviewer`, but **not**
> its engine skills (mattpocock, superpowers) — Claude Code plugins don't cross-install skills from
> other repos. Use a complete path below (**Option A** installs the engine skills as plugins too, or
> **Option B** via the script), otherwise `ship-feature` stops at preflight asking you to install them.

### Option A — Claude Code plugins (no shell script)

`ship-feature`'s engine skills also ship as plugins, so you can install everything with `claude`
alone — no `npx`, no clone. Each `plugin install` is a managed bundle that updates when a new version
ships:

```bash
# ship-feature's required engine skills (grill / spec / tickets / triage / tdd; worktrees; review):
claude plugin marketplace add mattpocock/skills && claude plugin install mattpocock-skills@mattpocock
claude plugin marketplace add anthropics/claude-plugins-official && claude plugin install superpowers@claude-plugins-official

# this repo — ship-feature + the bundled code-reviewer:
claude plugin marketplace add amankasliwal/skills && claude plugin install amankasliwal-skills@amankasliwal

# optional niceties (ship-feature degrades gracefully without them):
claude plugin install commit-commands@claude-plugins-official   # marketplace already added above
claude plugin marketplace add DietrichGebert/ponytail && claude plugin install ponytail@ponytail
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

Skills compose other skills, so a skill's dependencies must be installed too. **Option A** (all
plugins) and `scripts/install.sh` both install them; installing *only* the `amankasliwal-skills`
plugin does **not** pull the cross-repo engine skills, so pair it with the rest of Option A — or run
the script — once.

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
