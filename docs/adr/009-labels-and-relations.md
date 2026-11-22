# 009: Type and priority labels, native relations, all through recipes

**Status**: accepted
**Date**: 2026-11-22

## Context

Generated projects had no convention for classifying issues or relating them, and the few operations for it (labels, dependencies, closing) were raw CLI commands in a `forge` skill — the one exception to "everything goes through `just`".

GitHub has native issue types, but only in repositories owned by an organisation. Forgejo has none. GitHub has sub-issues and blocked-by relations independent of Projects; Forgejo has dependencies but no sub-issues. Both are supported by current CLIs (gh ≥ 2.105 as tested, fj 0.7.0).

## Decision

- **Type labels** `type/bug`, `type/feature`, `type/task`, `type/docs`, `type/research`, `type/epic`, `type/operations`, created by `just labels-init`. Every issue has exactly one, set at creation (`just issue-new TITLE FILE LABEL…`). On Forgejo the labels are exclusive within their scope.
- **Priority labels** `prio/high`, `prio/low` everywhere; no label means normal priority.
- **GitHub organisations use native issue types instead of `type/` labels.** Whether the owner is an organisation cannot be derived from its name, so copier asks (`github_owner_type`, only when `platform = github`). Organisation projects get the `issue-type` recipe, no `type/` labels from `labels-init`, and a workflow doc that says so; personal repositories and Forgejo get the labels and no `issue-type` recipe. A type is therefore never recorded twice.
- **The label set follows the types used on the organisation project board** (Feature, Bug, Task, Research, Epic, Deployment), with `operations` as the wider name for manual work outside the code, plus `docs`.
- **No status labels.** Open/closed, the linked PR and the relations carry the state.
- **Relations are native:** `issue-blocked-by` / `issue-unblock` on both forges; `issue-parent` on GitHub. On Forgejo an epic is blocked by its parts. "Related" stays a line in the issue body: gh has no flag for it and Forgejo no such relation.
- **`issue-close N FILE`** comments with a pointer to the result, then closes.
- **The `forge` skill is removed.** No raw `gh`/`fj` command appears in any rendered file.
- A repository on a shared project board documents its types and fields in its own `docs/project-management.md`, which takes precedence; that file is not part of the template.

## Consequences

- Personal GitHub repositories and Forgejo share one vocabulary; organisation repositories use whatever types the organisation defines. Agents get the guidance that is true for their repository, at the cost of one more template question and one more render dimension.
- With labels the type is set in the call that creates the issue; with native types it takes a second call (`issue-type`).
- Moving a repository between a personal account and an organisation means changing the answer and running `copier update`.
- GitHub projects need gh 2.105 or newer; Debian and Ubuntu ship older versions, so gh has to come from GitHub's own package repository.
- The recipes parse fj's human-readable output in two places (new issue number, existing labels); an fj release that changes the format breaks `issue-new` with labels and `labels-init`. The smoke test covers both.
- Milestones and GitHub Projects fields have no recipe.
- The gh recipes were not run against GitHub.
