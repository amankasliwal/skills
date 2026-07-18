# Repo guide (for agents)

A collection of **portable agent skills**. Each skill is a folder under `skills/<name>/` with a
`SKILL.md` (the portable contract, read by Claude Code and any Agent Skills-compatible harness such
as Codex) plus optional supporting files.

## Layout

```
skills/<name>/
  SKILL.md            # portable skill contract (name + description frontmatter, markdown body)
  agents/openai.yaml  # OpenAI/Codex interface + invocation metadata (optional but recommended)
  references/*.md     # progressive-disclosure detail the SKILL.md links to
  evals/evals.json    # behavioral evals
```

Group into category buckets (`skills/engineering/<name>/`, `skills/productivity/<name>/`) once the
set grows; a flat `skills/<name>/` is fine while it's small.

## Cross-harness

Skills are harness-agnostic. Install them into the directories each harness reads:

- `~/.claude/skills` — Claude Code
- `~/.agents/skills` — Codex and other [Agent Skills](https://agentskills.io/specification)-compatible harnesses

`scripts/install.sh` copies every skill in this repo into both, and installs each skill's external
dependencies. Claude Code users can instead install the whole set as a **plugin** (see below).

## Plugin capability (Claude Code)

The repo is its own single-plugin marketplace:

- `.claude-plugin/marketplace.json` — the `amankasliwal` marketplace, listing one plugin.
- `.claude-plugin/plugin.json` — the `amankasliwal-skills` plugin; its `skills` array lists every
  skill the plugin ships. **Add a skill → add its path here.**

When bumping a release, keep `plugin.json`'s `version` current (Claude uses it to offer updates) and
run `claude plugin validate . --strict` after touching either manifest.

## Adding / changing a skill

1. Create `skills/<name>/SKILL.md` (portable frontmatter: `name`, `description` starting with "Use
   when…"; add `disable-model-invocation: true` for user-only skills).
2. Add `skills/<name>/agents/openai.yaml` (display name, short description, invocation policy).
3. Add its path to `.claude-plugin/plugin.json`'s `skills` array.
4. Add a row to the top-level `README.md` skill index, linking the name to its `SKILL.md`.
5. If the skill depends on other skills/plugins, wire their install into `scripts/install.sh`.

## Invocation model

Each skill is **user-invoked** (reachable only when the human types it — set
`disable-model-invocation: true` in `SKILL.md` and `policy.allow_implicit_invocation: false` in
`agents/openai.yaml`) or **model-invoked** (fires on matching intent). State which in the skill's
frontmatter/metadata so both harnesses agree.
