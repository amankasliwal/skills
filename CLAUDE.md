# CLAUDE.md

This repo's full guide for agents — layout, cross-harness install, plugin manifests, and how to
add a skill — lives in [AGENTS.md](AGENTS.md). Read it before changing anything here.

Claude Code specifics:

- Install the whole set as a plugin: `claude plugin marketplace add amankasliwal/skills` then
  `claude plugin install amankasliwal-skills@amankasliwal`.
- Skills the plugin ships are listed in `.claude-plugin/plugin.json`'s `skills` array — keep it in
  sync when adding a skill.
- After editing either manifest, run `claude plugin validate . --strict`.
