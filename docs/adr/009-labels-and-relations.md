# 009: Type and priority labels, native relations, all through recipes

**Status**: accepted
**Date**: 2026-11-22

## Context

Generated projects had no convention for classifying issues or relating them, and the few operations for it (labels, dependencies, closing) were raw CLI commands in a `forge` skill — the one exception to "everything goes through `just`".

GitHub has native issue types, but only in repositories owned by an organisation. Forgejo has none. GitHub has sub-issues and blocked-by relations independent of Projects; Forgejo has dependencies but no sub-issues. Both are supported by current CLIs (gh ≥ 2.105 as tested, fj 0.7.0).

## Decision

- **Labels, same set on both forges**, created by `just labels-init`: `type/bug`, `type/feature`, `type/task`, `type/research`, `type/epic`, `type/operations`, and `prio/high`, `prio/low`. Every issue has exactly one `type/` label, set at creation (`just issue-new TITLE FILE LABEL…`). No label means normal priority. On Forgejo the labels are exclusive within their scope.
- **`type/` labels are used on GitHub too**, so the convention is the same in personal and organisation repositories. Where native issue types exist, `just issue-type` sets them in addition.
- **The type set mirrors the one used on the organisation project board** (Feature, Bug, Task, Research, Epic, Deployment); `operations` is the wider name for manual work outside the code. There is no `type/docs`: documentation work is a task.
- **No status labels.** Open/closed, the linked PR and the relations carry the state.
- **Relations are native:** `issue-blocked-by` / `issue-unblock` on both forges; `issue-parent` on GitHub. On Forgejo an epic is blocked by its parts. "Related" stays a line in the issue body: gh has no flag for it and Forgejo no such relation.
- **`issue-close N FILE`** comments with a pointer to the result, then closes.
- **The `forge` skill is removed.** No raw `gh`/`fj` command appears in any rendered file.
- A repository on a shared project board documents its types and fields in its own `docs/project-management.md`, which takes precedence; that file is not part of the template.

## Consequences

- One vocabulary for issues across forges; agents classify an issue in the same call that creates it.
- GitHub projects need gh 2.105 or newer; Debian and Ubuntu ship older versions, so gh has to come from GitHub's own package repository.
- In an organisation repository the type exists twice (label and native type) and the two can disagree.
- The recipes parse fj's human-readable output in two places (new issue number, existing labels); an fj release that changes the format breaks `issue-new` with labels and `labels-init`. The smoke test covers both.
- Milestones and GitHub Projects fields have no recipe.
- The gh recipes were not run against GitHub.
