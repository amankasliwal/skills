#!/usr/bin/env bash
#
# install.sh — install every skill in this repo across agent harnesses, and install
# each skill's external dependencies.
#
# Copies each skills/*/SKILL.md folder into the skill directory every harness reads:
#   ~/.claude/skills   — Claude Code
#   ~/.agents/skills   — Codex + other Agent Skills-compatible harnesses
# Then installs the dependencies the bundled skills drive (see "Dependencies" below).
# Re-run any time to refresh. Restart your agent afterward so new skills load.
#
# Claude Code users can instead install the whole set as a self-updating plugin:
#   claude plugin marketplace add amankasliwal/skills
#   claude plugin install amankasliwal-skills@amankasliwal

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DESTS=("${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}" "${AGENTS_SKILLS_DIR:-$HOME/.agents/skills}")

say()  { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m  ✓\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m  ! \033[0m%s\n' "$*"; }

# ---------------------------------------------------------------------------
# 1. Install every skill in this repo into each harness's skill directory
# ---------------------------------------------------------------------------
say "Installing skills into: ${DESTS[*]}"
skill_dirs=()
while IFS= read -r skill_md; do
  skill_dirs+=("$(dirname "$skill_md")")
done < <(find "$REPO/skills" -name SKILL.md -not -path '*/deprecated/*' | sort)

if [ "${#skill_dirs[@]}" -eq 0 ]; then
  warn "no skills found under $REPO/skills"; exit 1
fi
for dest in "${DESTS[@]}"; do
  mkdir -p "$dest"
  for src in "${skill_dirs[@]}"; do
    name="$(basename "$src")"
    rm -rf "${dest:?}/$name"
    cp -R "$src" "$dest/$name"
    ok "$name → $dest/$name"
  done
done

# ---------------------------------------------------------------------------
# 2. Dependencies of the bundled skills
#    ship-feature drives these; required ones are load-bearing, recommended
#    ones degrade gracefully (see each skill's SKILL.md dependency table).
# ---------------------------------------------------------------------------
say "Installing skill dependencies (for ship-feature)"

# Required: the engineering-workflow skills (grill/prd/issues/triage/tdd)
if command -v npx >/dev/null 2>&1; then
  if npx --yes skills add mattpocock/skills; then ok "mattpocock/skills installed"
  else warn "run manually: npx skills add mattpocock/skills"; fi
else
  warn "npx not found (needs Node.js). Then run: npx skills add mattpocock/skills"
fi

# Required + recommended plugins (best-effort; skip cleanly if the CLI is absent)
if command -v claude >/dev/null 2>&1; then
  claude plugin marketplace add obra/superpowers >/dev/null 2>&1 || true
  claude plugin marketplace add anthropics/claude-plugins-official >/dev/null 2>&1 || true
  claude plugin marketplace add DietrichGebert/ponytail >/dev/null 2>&1 || true
  claude plugin install superpowers@superpowers >/dev/null 2>&1 && ok "superpowers installed" \
    || warn "REQUIRED superpowers not installed — see https://github.com/obra/superpowers"
  claude plugin install commit-commands@claude-plugins-official >/dev/null 2>&1 && ok "commit-commands installed" \
    || warn "optional commit-commands not installed (fallback: git + gh pr create)"
  claude plugin install ponytail@ponytail >/dev/null 2>&1 && ok "ponytail installed" \
    || warn "optional ponytail not installed (fallback: skip the over-engineering flag pass)"
else
  warn "'claude' CLI not found — install plugins yourself:"
  warn "    claude plugin marketplace add obra/superpowers && claude plugin install superpowers@superpowers   # REQUIRED"
  warn "    claude plugin marketplace add anthropics/claude-plugins-official && claude plugin install commit-commands@claude-plugins-official"
  warn "    claude plugin marketplace add DietrichGebert/ponytail && claude plugin install ponytail@ponytail"
fi

say "Note: 'simplify' and 'verify' ship with current Claude Code — no install needed."
echo
ok "Done. Restart your agent, then say e.g. \"run my feature workflow on <X>\"."
