# 001: `just` is the only interface to the forge

**Status**: accepted
**Date**: 2026-11-16

## Context

The generated docs used to show raw `gh` / `fj` commands. The `fj` ones did not match forgejo-cli (`fj issue list` does not exist, titles are positional, `fj release create` has no `--title`/`--notes`), so agents copied them, failed, and guessed. The two CLIs also differ enough that every doc needed a per-platform branch. See issue #5.

## Decision

Generated projects get forge recipes in their `justfile`, rendered per `platform` (`github` → `gh`; `forgejo` and `both` → `fj`): `issues`, `issue`, `issue-new`, `comment`, `prs`, `pr`, `pr-diff`, `comment-pr`, `releases`, `release`. Docs and agent instructions name only these recipes.

Rules the recipes follow:

- **Bodies are files, titles are arguments.** No multi-line text on a command line.
- **Arguments are passed positionally** (`set positional-arguments`, `"$1"`), never interpolated into the recipe, so titles containing quotes or `$` are not re-parsed by the shell. This also keeps just's `{{ }}` out of the Jinja template.
- **Every `fj` call is pinned to the host of `origin`** (`fj -H "$(just _forge-host)" …`). fj fails with "no repo info specified" when a repo has several remotes and the current branch has no upstream — the normal state of a fresh branch on the `both` platform. The `fj pr` subcommands have no `--remote` option, and `-H` accepts a bare host only, so the host is extracted from the remote URL.
- **`pr` pushes the branch first** and refuses to run on `main`/`master`.
- **There is no merge recipe.** Merging is the human's step.

## Consequences

- A CLI change is fixed in one place, and `just test-render` plus a smoke test can check it (see [testing.md](../testing.md)).
- The recipe set is a contract: skills and docs depend on the names and argument order.
- Anything the recipes do not cover (labels, milestones, dependencies) still needs the raw CLI; that is to be documented in one place only (the planned `forge` skill, issue #5).
- For `https://host:port/…` remotes the port is passed to `fj -H`; this is untested.
- The `gh` recipes have only been dry-run, not exercised against GitHub.
