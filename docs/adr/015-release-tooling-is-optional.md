# 015: Release tooling is optional

**Status**: accepted
**Date**: 2026-11-28

## Context

Every generated project got the release tooling of [ADR 002](002-release-notes-on-the-forge.md): the `release` skill, `.copier/cliff.toml`, the `release` and `releases` recipes, the "Releases" section in `docs/workflow.md` and the release row in the `AGENTS.md` skills index. Some repositories never release anything — an infrastructure repository deployed with Ansible from a checkout has no versions, tags or CD. Such a project had to delete the files and carry that deletion through every `just template-update`, and an agent reading the skills index saw a procedure that does not apply.

## Decision

A question `releases` (bool, default `true`). With `false` the template generates none of the release tooling and no mention of it: no skill, no `cliff.toml`, no recipes, no "Releases" section, no row in the skills index, and no reference to releases or release notes in the README, `docs/workflow.md` or the recipes file.

- The default is `true`, so a project generated before the question existed keeps everything on its next update.
- **`is_service` needs `releases`.** The CD workflow is triggered by the release tag, so a service without releases would never deploy. The combination is refused by a validator, like `is_service` and `hooks = python` without Python ([ADR 014](014-python-is-optional.md)).
- Hiding the question for services (`when: not is_service`) was rejected: it would force `true` silently, and a project that answered `false` and later becomes a service would get the release files back without a word. The validator makes the contradiction an error.

## Consequences

- A repository that never releases can use the template without local deletions.
- ADR 002 still describes how releases work; it applies when `releases` is `true`.
- A Python project with `releases = false` stays at the hatch-vcs fallback version `0.0.0`, because no tag is ever created.
- Conventional commits stay the convention without releases, although nothing generates notes from them.
- Switching the answer later works in both directions with one `just template-update`: `false` removes the files and recipes, `true` brings them back.
- The render test checks `releases = false` by searching the whole output for `releas`, `cliff` and `changelog`. A new template text that mentions releases outside a `releases` guard fails the test.
