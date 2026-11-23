# 012: Thin, generated adapters per agent tool

**Status**: accepted
**Date**: 2026-11-23

## Context

`AGENTS.md` and `.agents/skills/` are tool-neutral, but each harness needs something of its own before it uses them fully: Claude Code reads `CLAUDE.md` and looks for skills in `.claude/skills`; both Claude Code and Codex can refuse commands and run a hook when the agent stops, each in its own format. Claude Code is the tool in daily use; the setup must not depend on it.

## Decision

A copier multiselect `agents` (`claude`, `codex`; default `[claude]`, empty allowed) selects adapters:

- **claude:** `CLAUDE.md` containing only `@AGENTS.md`; `.claude/skills` as a symlink to `../.agents/skills` (hence `_preserve_symlinks: true`); `.claude/settings.json` with deny rules and a Stop hook.
- **codex:** `.codex/rules/default.rules` and `.codex/hooks.json`. Codex reads `AGENTS.md` and `.agents/skills` natively, so it needs no link. The files load only once the project is trusted in Codex.

Rules for adapters:

- **No logic.** Both Stop hooks call `just stop-check`: `just static` if the working tree has changes, exit 2 with the output on failure, and no second round when the hook already made the agent continue. The full `just check` stays a step of `implement-issue`; running the test suite on every stop was rejected as too slow.
- **Same refusals in both:** merging a PR and pushing to `main`.
- **`just review N`** is tool-neutral as well: it pipes the `review-pr` skill plus the PR text and diff to `$AGENT_REVIEWER` on stdin and posts what comes back. The reviewer needs neither forge access nor write access. Without the variable the first selected agent is used (`claude -p`, else `codex exec -`), because paying for a second model through an API is not wanted today; a different model remains one environment variable away.

## Consequences

- Adding a tool means adding a choice and a directory, not touching skills or docs.
- The refusals match command text. They stop a slip (`git push origin main`, `fj … pr merge`), not a script, an alias or an API call. Enforcement is branch protection plus a non-admin agent account ([ADR 011](011-setup-doctor-and-branch-protection.md)).
- Codex prefix rules cannot skip arguments, so the fj rule exists twice: bare and with the pinned host.
- With the default reviewer, author and reviewer are the same model.
- **The Codex adapter is written from the Codex documentation and has never been run**; Codex was not installed. Its rules format is marked experimental upstream.
- Symlinks: a checkout on a filesystem without symlink support loses Claude's skill discovery; the skills index in `AGENTS.md` still works.
