# project-template

[Copier](https://copier.readthedocs.io/) template for new projects. Generates agent workflow docs, CI/CD pipelines, and an optional Python project skeleton.

## Quick start

```bash
copier copy gh:schachmett/project-template <destination>
# or from Forgejo:
copier copy https://git.pw13.eu/simon/project-template.git <destination>
```

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
| `is_service` | bool | `false` | Adds `operations.md`, `Dockerfile`, `docker-compose.yml`, `cd.yml` |
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
├── Dockerfile                   # (if is_service)
├── docker-compose.yml           # (if is_service)
├── docs/
│   ├── agent-workflow.md        # branching, PR/issue CLI, releases, session flow
│   ├── architecture.md
│   ├── codestyle.md
│   ├── quality-gates.md         # just targets and CI mapping
│   ├── testing.md               # (if python ≠ none)
│   ├── operations.md            # (if is_service)
│   ├── adr/
│   └── domain/
├── justfile                     # fix, lint, check, (up if is_service)
├── .pre-commit-config.yaml      # (if hooks ≠ none)
├── .forgejo/workflows/          # (if platform ≠ github)
│   ├── ci.yml
│   └── cd.yml                   # (if is_service)
├── .github/workflows/           # (if platform ≠ forgejo)
│   ├── ci.yml
│   └── cd.yml                   # (if is_service)
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

## Rolling out changes

### Updating a repo generated from this template

```bash
copier update
```

Copier does a 3-way merge (old template rendering + your local changes + new template rendering) and writes conflict markers where both sides changed. Resolve conflicts, then commit.

All template files render directly to their final paths — no post-copy tasks. The 3-way merge works correctly across the entire project including `pyproject.toml`.

### Onboarding an existing repo (no copier history)

The first import is manual — no `.copier-answers.yml` means no merge baseline.

1. **Generate a fresh copy into a temp branch:**
   ```bash
   git checkout -b template-import
   copier copy --overwrite \
     --data project_name=... \
     --data python=root \
     ... \
     /path/to/project-template .
   ```
   This writes `.copier-answers.yml` and overwrites all template files including `pyproject.toml` and `src/`.

2. **Restore your existing Python files:**
   ```bash
   git checkout HEAD -- pyproject.toml src/ tests/
   ```

3. **Manually merge pyproject.toml sections** you want from the template version (`git show template-import:pyproject.toml`): `[tool.pytest.*]`, `[tool.coverage.*]`, `[tool.pyright]`, `[tool.ruff.*]`.

4. **Keep the template versions** of: `docs/`, `AGENTS.md`, `justfile`, CI workflows, `.pre-commit-config.yaml`.

5. Commit. The repo now has `.copier-answers.yml` so future `copier update` calls work.

| File | Action |
|---|---|
| `AGENTS.md`, `docs/`, `justfile`, CI | Keep template version |
| `.pre-commit-config.yaml` | Keep template version |
| `pyproject.toml` | Restore yours, cherry-pick `[tool.*]` sections |
| `src/`, `tests/` | Always restore yours |
| `README.md` | Restore yours, manually add `just` commands table |
