# 013: The project owns `justfile`; template-owned files live in `.copier/`

**Status**: accepted
**Date**: 2026-11-24

## Context

The `justfile` was a template file that projects extended with their own recipes, so it conflicted on every `copier update`. Template-owned files were also spread over the project root (`cliff.toml`, `scripts/setup.sh`, `.copier-answers.yml`), with nothing telling a reader which files are the project's and which get replaced.

## Decision

- **`.copier/` holds what the template owns** and replaces on every update: `recipes.just`, `setup.sh`, `cliff.toml`, `answers.yml`. Nothing in it is edited in a project. The name says which tool rewrites it.
- **The root `justfile` belongs to the project.** It is generated once (`_skip_if_exists`) with an import of `.copier/recipes.just`, `set allow-duplicate-recipes`, and a `default` recipe that lists the recipes. Updates never touch it.
- **A project recipe replaces a template recipe of the same name.** That is how a project customises `check`.
- `set positional-arguments`, which the forge recipes need, stays in `recipes.just`: with just 1.40 a setting in an imported file applies to the whole justfile, so the root file needs the import and nothing else.
- **`just template-update`** wraps `copier update --answers-file .copier/answers.yml`, because copier does not find an answers file outside the default path by itself.

Files a tool looks for at the root stay there: `AGENTS.md`, `CLAUDE.md`, `.claude/`, `.codex/`, `.agents/skills/`, `.pre-commit-config.yaml`, `pyproject.toml`, CI workflow folders.

## Consequences

- Project recipes no longer conflict with template updates, and three template files leave the root.
- A project recipe silently hides a template recipe of the same name, including one the template adds later.
- A project must not set `positional-arguments` itself (just rejects the duplicate); the setting also applies to its own recipes, which only adds `$1`, `$2`.
- Without the `default` recipe a bare `just` would run the first imported recipe, `template-update`; the generated file therefore has one.
- A plain `copier update` no longer works; it must be `just template-update` or carry `--answers-file`.
- v1 projects have to rewrite their `justfile` by hand once: the update leaves the old file in place, and without the import none of the new recipes exist (README, "Migrating from v1 to v2").
