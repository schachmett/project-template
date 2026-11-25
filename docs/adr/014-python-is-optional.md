# 014: Python is optional again

**Status**: accepted
**Date**: 2026-11-25

## Context

[ADR 004](004-python-only.md) removed `python = none` because the variant was unused and had rotted: the Dockerfile copied files that did not exist, and CI ran pre-commit, whose always-run `no-commit-to-main` hook fails on `main`. Since then almost everything the template generates has become language-neutral (skills, forge recipes, adapters, `.copier/`), and a real non-Python repository — ABAP, checked with abaplint and a Node script — wants that layer.

## Decision

`python` has three choices again: `root` (default), `component`, `none`.

With `none` the template generates no Python files and **no quality recipes**. It relies on recipe names the project owns in its root `justfile` ([ADR 013](013-project-owns-justfile.md)):

| Recipe | | Picked up by |
|---|---|---|
| `check` | required | CI, the skills |
| `static` | optional | `stop-check`, i.e. the agents' Stop hook |
| `setup` | optional | CI and `.copier/setup.sh`, before `check` |
| `fix` | optional | mentioned in docs and skills |

- Optional recipes are looked up at run time (`just --summary`): a missing one is skipped, one added later is used from then on. No stubs are generated for them.
- A new project gets one stub, `check`, which **fails** until replaced: a green CI that checks nothing would be a false signal.
- `just doctor` insists on `check` only.
- `is_service` and `hooks = python` are rejected without Python, so there is no Dockerfile to get wrong.
- CI for `none` is checkout, just, `setup` if present, `check`. It does not run pre-commit.
- uv stays a required tool: it runs copier and git-cliff and installs just and pre-commit in `setup.sh`.
- **git-cliff runs through `uvx` for every variant** and is no longer a dev dependency of generated Python projects.

## Consequences

- The workflow layer can be used by any repository; language support is the project's business, not a template variant per language.
- What broke the old variant is now tested: `none` is in the render matrix, the invalid combinations are checked to be refused, and a `none` project with filled-in recipes runs its gates, the CI setup step and an update in `just test-render`.
- The names `check`, `static`, `setup` and `fix` are a contract; renaming one breaks projects silently for the optional ones.
- `set allow-duplicate-recipes` and `positional-arguments` apply to the project's recipes too, and a `set shell` of the project applies to the template's. Checked with `bash -euo pipefail` on the ABAP repository.
- Release notes need network access to fetch git-cliff on first use.
- Python projects keep a stale `git-cliff` dev dependency until they remove it; it is harmless.
