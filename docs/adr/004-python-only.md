# 004: The template is Python-only

**Status**: superseded by [014](014-python-is-optional.md)
**Date**: 2026-11-16

## Context

`python` had three choices — `root`, `component`, `none` — with `none` as the default. No project was ever generated with `none`, and the variant had rotted: with `is_service` the Dockerfile copied a `pyproject.toml` and `uv.lock` that did not exist, and CI ran `pre-commit run --all-files`, where the always-run `no-commit-to-main` hook fails on every push to `main`. Supporting it cost a conditional branch in the justfile, AGENTS.md, four docs, the CI workflow, the Dockerfile, the release recipe and a validator on `hooks`.

## Decision

`python` has two choices, `root` (default) and `component`. Every generated project has a Python package, uv, ruff, pyright, pytest and git-cliff. The non-Python branches are removed, not kept behind a flag.

## Consequences

- One third fewer combinations to render and reason about; `just check` is the same shape everywhere (lint, typecheck, tests) and never runs pre-commit in CI.
- `is_service` can rely on Python being present, so the Dockerfile needs no guard.
- A non-Python project cannot use the template. Reintroduce the variant when a real project needs it, and test it then (`just test-render` plus a real CI run) — do not restore the old branches from history unchanged.
- A project with `python: none` in its answers file does not fail on `copier update --defaults`: the invalid answer falls back to `root` and the update adds a Python skeleton (`pyproject.toml`, `src/`, `tests/`). No such project is known to exist.
