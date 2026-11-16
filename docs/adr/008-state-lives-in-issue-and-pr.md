# 008: Plan and handoff live in the issue and the PR

**Status**: accepted
**Date**: 2026-11-17

## Context

Session handoffs went to `.ai/`, which is gitignored. A cloud session, a second machine, another tool or a reviewing agent could not see them, and they were lost with the working copy.

## Decision

- The **plan** is a comment on the issue; changes to it are further comments.
- The **handoff** is the PR body, with a fixed set of sections: what changed, how it was verified, assumptions, open questions, ADRs. The template is in the `implement-issue` skill.
- If a session ends before a PR exists, the branch is pushed and a progress comment goes on the issue.
- `.ai/` is scratch only: body files for the `just` recipes, notes, throwaway scripts.

Two recipes exist because of this: `pr-view N` (body, comments, mergeability and CI status) to read the state back, and `pr-body N FILE` to keep the handoff current after follow-up commits.

## Consequences

- Any session can resume from `just issue N` and `just pr-view N`; nothing depends on local files or chat history.
- The human reads the same record the agents use.
- Plans and handoffs are visible to everyone with access to the repository, so they must not contain secrets or private notes.
- `fj pr edit … body` takes the body as an argument, not a file; `pr-body` passes the file content inline, like `release` does.
