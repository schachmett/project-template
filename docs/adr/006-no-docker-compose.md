# 006: No docker-compose file in generated projects

**Status**: accepted
**Date**: 2026-11-16

## Context

With `is_service`, the template generated a `docker-compose.yml` (one service, port 8000, a TODO for volumes and healthcheck) and a `just up` recipe wrapping `docker compose up`. Every service project replaced the file with its own, since ports, dependencies and volumes are project-specific.

## Decision

`docker-compose.yml` and `just up` are no longer generated. The Dockerfile stays: it encodes the uv layer caching and the version build-arg that the CD workflow depends on.

## Consequences

- `is_service` now means: Dockerfile, CD workflow, `operations.md`.
- A project that wants a local stack writes its own compose file and recipe.
- On `copier update`, an unmodified `docker-compose.yml` and the `up` recipe are deleted (checked on a project generated from the previous template). Projects that customised them have to keep or restore their versions when reviewing the update; that case was not tested.
