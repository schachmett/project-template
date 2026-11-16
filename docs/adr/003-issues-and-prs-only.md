# 003: Issues and PRs are the only workflow

**Status**: accepted
**Date**: 2026-11-16

## Context

The `workflow_style` question offered `issues-prs` (agent opens issues and PRs, human merges) and `direct` (agent stages, human commits to `main`). Every workflow doc, AGENTS.md and the pre-commit config carried both branches. The `direct` flow was at most useful before a project's first alpha.

## Decision

The question and the `direct` flow are removed. Generated projects always get the issues + PR flow, and the `no-commit-to-main` hook whenever hooks are enabled. Committing straight to `main` is not a template option; a project that needs it temporarily disables the hook or branch protection by hand.

## Consequences

- One fewer axis of conditionals in the docs and in the render matrix.
- Projects generated with `workflow_style: direct` gain the hook and the issues/PR docs on their next `copier update`. The update itself is clean: copier drops the unknown answer from `.copier-answers.yml` (checked by `just test-render` and once manually from the pre-removal template).
