# project-template

[Copier](https://copier.readthedocs.io/) template for new projects. Generates agent workflow docs, CI/CD pipelines, and an optional Python project skeleton.

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
| `org` | str | — | GitHub/Forgejo org or username |
| `python` | choice | `none` | `root` / `component` / `none` |
| `python_version` | choice | `3.14` | `3.14` / `3.13` / `3.12` |
| `has_api` | bool | `false` | Adds `operations.md`, `Dockerfile`, `docker-compose.yml`, `cd.yml` |
| `has_cli` | bool | `false` | Adds `[project.scripts]` entry to `pyproject.toml` |
| `license` | choice | `mit` | `mit` / `agpl` / `proprietary` / `none` |
| `secrets` | choice | `none` | `sops` / `env-only` / `none` |
| `hooks` | choice | `minimal` | `minimal` / `python` / `none` |
| `component_dir` | str | `backend` | Asked when python=component |
| `workflow_style` | choice | `issues-prs` | `issues-prs` / `direct` |

`hooks=python` requires `python ≠ none`.

## Generated output

```
<project>/
├── AGENTS.md                    # agent entry point → links to all docs
├── README.md
├── .gitignore
├── .env.example                 # (if secrets=env-only)
├── cliff.toml                   # (if python ≠ none) git-cliff changelog config
├── Dockerfile                   # (if has_api)
├── docker-compose.yml           # (if has_api)
├── docs/
│   ├── agent-workflow.md        # branching, PR/issue CLI, releases, session flow
│   ├── architecture.md
│   ├── codestyle.md
│   ├── quality-gates.md         # make targets and CI mapping
│   ├── testing.md               # (if python ≠ none)
│   ├── operations.md            # (if has_api)
│   ├── adr/
│   └── domain/
├── Makefile                     # fix, lint, check, (up if has_api)
├── .pre-commit-config.yaml      # (if hooks ≠ none)
├── .forgejo/workflows/          # (if platform ≠ github)
│   ├── ci.yml
│   └── cd.yml                   # (if has_api)
├── .github/workflows/           # (if platform ≠ forgejo)
│   ├── ci.yml
│   └── cd.yml                   # (if has_api)
│
├── [python=root]
│   ├── pyproject.toml · .python-version · cliff.toml
│   ├── src/<package>/
│   │   ├── __init__.py          # exposes __version__
│   │   └── py.typed
│   └── tests/
│       ├── conftest.py
│       ├── test_imports.py      # architectural boundary enforcement
│       ├── <package>/           # mirrors src/<package>/
│       └── integration/
│
└── [python=component]
    └── <component_dir>/         # default: backend/
        ├── pyproject.toml · .python-version
        ├── src/<package>/
        │   ├── __init__.py      # exposes __version__
        │   └── py.typed
        └── tests/
            ├── conftest.py
            ├── test_imports.py
            ├── <package>/
            └── integration/
```

## Updating a generated project

```bash
copier update --trust
```
