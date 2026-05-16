# project-template

[Copier](https://copier.readthedocs.io/) template for new projects. Generates agent workflow docs, Claude rules, CI/CD pipelines, and an optional Python project skeleton.

## Quick start

```bash
copier copy --trust gh:schachmett/project-template <destination>
# or from Forgejo:
copier copy --trust https://git.pw13.eu/simon/project-template <destination>
```

`--trust` is required: after copying, a short shell task arranges the Python project files into their final layout.

## Parameters

| Variable | Type | Default | Notes |
|---|---|---|---|
| `project_name` | str | — | |
| `author_name` | str | _(empty)_ | Optional |
| `platform` | choice | `forgejo` | `forgejo` / `github` / `both` |
| `forgejo_url` | str | — | Asked when platform ≠ github |
| `python` | choice | `none` | `root` / `component` / `none` |
| `python_version` | choice | `3.14` | `3.14` / `3.13` / `3.12` |
| `has_api` | bool | `false` | Adds `operations.md`, `runbooks.md`, `cd.yml` |
| `has_cli` | bool | `false` | Adds `[project.scripts]` entry to `pyproject.toml` |
| `license` | choice | `mit` | `mit` / `agpl` / `proprietary` / `none` |
| `secrets` | choice | `none` | `sops` / `env-only` / `none` |
| `hooks` | choice | `minimal` | `minimal` / `python` / `none` |

`hooks=python` requires `python ≠ none`.

## Generated output

```
<project>/
├── AGENTS.md                    # agent entry point → links to all docs
├── README.md
├── .gitignore
├── .ai/                         # gitignored scratch space (dir kept via .gitkeep)
├── .claude/rules/
│   ├── docs.yml                 # glob: docs/**
│   └── python.yml               # glob: src/**/*.py  (if python ≠ none)
├── docs/
│   ├── agent-workflow.md        # branching, PR/issue CLI, releases
│   ├── architecture.md
│   ├── codestyle.md
│   ├── quality-gates.md         # make targets and CI mapping
│   ├── operations.md            # (if has_api)
│   ├── runbooks.md              # (if has_api)
│   ├── adr/
│   └── domain/
├── Makefile                     # fmt, lint, typecheck, test, check, (up)
├── .pre-commit-config.yaml      # (if hooks ≠ none)
├── .forgejo/workflows/          # (if platform ≠ github)
│   ├── ci.yml
│   └── cd.yml                   # (if has_api)
├── .github/workflows/           # (if platform ≠ forgejo)
│   ├── ci.yml
│   └── cd.yml                   # (if has_api)
│
├── [python=root]
│   ├── pyproject.toml · .python-version
│   ├── src/<package>/
│   └── tests/
│
└── [python=component]
    └── backend/
        ├── pyproject.toml · .python-version
        ├── src/<package>/
        └── tests/
```

## Updating a generated project

```bash
copier update --trust
```
