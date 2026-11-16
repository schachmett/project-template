# 002: Release notes live on the forge, not in a changelog file

**Status**: accepted
**Date**: 2026-11-16

## Context

The documented release flow was: regenerate `CHANGELOG.md` with git-cliff, commit it to `main`, push, then create the release. With the `no-commit-to-main` hook and a protected `main` that commit needs its own PR, which the human has to merge for every release.

The usual alternatives are a release PR (release-please, changesets) — needed where the version lives in a file — or release notes generated at release time. Generated projects take their version from the git tag (`hatch-vcs`), so a release needs no commit at all.

## Decision

Generated projects have no `CHANGELOG.md`. `just release vX.Y.Z`:

1. refuses unless on a clean `main` equal to `origin/main`, and unless the version looks like `v1.2.3`;
2. generates the notes with `git-cliff --unreleased --tag VERSION --strip header` (config in `cliff.toml`);
3. creates the tag and the release page on the forge with those notes.

`fj release create` has no `--body-file`, so this recipe is the one place where a body is passed inline — generated inside the recipe, never typed by an agent.

## Consequences

- A release is one command, with no commit, no PR and nothing to approve. The human's gate stays the feature PRs.
- The changelog is not readable in a checkout or source tarball, only on the forge (`just releases`). `git-cliff -o CHANGELOG.md` can regenerate it from the tags at any time.
- Release notes are only as good as the conventional commits on `main`.
