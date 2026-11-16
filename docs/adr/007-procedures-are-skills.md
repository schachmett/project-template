# 007: Procedures are skills, docs explain why

**Status**: accepted
**Date**: 2026-11-17

## Context

Generated projects carried their process in always-loaded prose: AGENTS.md had 81 lines with capitalised STOP blocks and two recipe tables, `agent-workflow.md` a 13-step session flow, `quality-gates.md` and `testing.md` repeated the commands again. An agent paid for all of it in every session, whatever the task, and the same step was described in up to four places. See issue #5.

## Decision

- **Procedures are skills** in `.agents/skills/<name>/SKILL.md` (frontmatter `name` and `description`, body = the steps): `plan-issue`, `implement-issue`, `review-pr`, `release`, `forge`. `.agents/skills/` is the tool-neutral location; harness-specific adapters point at it (planned as a separate change).
- **Skills call only `just`.** The `forge` skill is the single exception and the only place raw `gh`/`fj` commands may appear; it is rendered per platform and names the tested CLI version.
- **AGENTS.md is a map:** four hard rules, the skills index, the docs index — 35 lines. No recipe tables; `just --list` carries the descriptions.
- **Two rule docs remain:** `docs/workflow.md` (the gates and why, enforcement on the forge, conventions, quality gates, definition of done, releases) and `docs/codestyle.md` (code and test conventions). `agent-workflow.md`, `quality-gates.md` and `testing.md` are gone.
- **Enforcement is described as forge configuration** (agent account without merge rights, branch protection on `main`), not as emphasis in prose.

## Consequences

- An agent loads AGENTS.md plus the one skill it needs.
- Each procedure has one home; `just test-render` fails if a raw `gh`/`fj` command appears outside the `forge` skill, if a skill is missing or its frontmatter is wrong, or if a markdown link is broken.
- Until the adapters exist, no harness discovers `.agents/skills/` on its own; agents find the skills through the index in AGENTS.md.
- Projects generated earlier lose three doc files on `copier update`. Copier deletes them even when they were edited locally, without a conflict (tested with an edited `agent-workflow.md`); the README tells users to review the deletion before committing.
- The `gh` half of the `forge` skill is checked against `gh --help` only.
