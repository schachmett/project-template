# Architecture Decision Records

ADRs capture non-obvious design decisions about the template: choices that affect every generated project, that reject alternatives, or that would surprise a future contributor.

## When to write an ADR

Write one before or alongside any change that:

- adds or removes a copier question, or changes what a choice generates
- changes an interface generated projects rely on (`just` recipes, CI/CD workflows, hooks)
- adopts, replaces, or removes a tool the generated projects depend on
- rejects a seemingly obvious approach for a non-obvious reason

Small fixes and additions that follow established patterns do not need an ADR.

## Format

File naming: `NNN-short-title.md` (e.g. `001-just-is-the-forge-interface.md`)

```markdown
# NNN: Title

**Status**: proposed | accepted | superseded by [NNN](NNN-title.md)
**Date**: YYYY-MM-DD

## Context

What is the situation that forces this decision?

## Decision

What was decided?

## Consequences

What becomes easier or harder as a result?
```

## Index

- [001: `just` is the only interface to the forge](001-just-is-the-forge-interface.md)
- [002: Release notes live on the forge, not in a changelog file](002-release-notes-on-the-forge.md)
- [003: Issues and PRs are the only workflow](003-issues-and-prs-only.md)
- [004: The template is Python-only](004-python-only.md)
- [005: detect-secrets runs without a baseline file](005-detect-secrets-without-baseline.md)
- [006: No docker-compose file in generated projects](006-no-docker-compose.md)
- [007: Procedures are skills, docs explain why](007-procedures-are-skills.md)
- [008: Plan and handoff live in the issue and the PR](008-state-lives-in-issue-and-pr.md)
- [009: Type and priority labels, native relations, all through recipes](009-labels-and-relations.md)
- [010: Small changes skip the plan gate](010-small-changes-skip-the-plan-gate.md)
- [011: Setup script, `just doctor`, and branch protection as after-copy steps](011-setup-doctor-and-branch-protection.md)
- [012: Thin, generated adapters per agent tool](012-thin-agent-adapters.md)
- [013: The project owns `justfile`; template-owned files live in `.copier/`](013-project-owns-justfile.md)
