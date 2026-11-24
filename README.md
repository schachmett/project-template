# project-template

[Copier](https://copier.readthedocs.io/) template for new projects. Generates agent workflow docs, CI/CD pipelines, and a Python project skeleton.

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
| `github_owner_type` | choice | `personal` | `personal` / `organization`. Asked when platform = github; organizations use native issue types, everything else `type/` labels |
| `python` | choice | `root` | `root` / `component` |
| `python_version` | choice | `3.14` | `3.14` / `3.13` / `3.12` |
| `is_service` | bool | `false` | Adds `operations.md`, `Dockerfile`, `cd.yml` |
| `license` | choice | `mit` | `mit` / `agpl` / `proprietary` / `none` |
| `secrets` | choice | `none` | `sops` / `env-only` / `none` |
| `hooks` | choice | `minimal` | `minimal` / `python` / `none` |
| `component_dir` | str | `backend` | Asked when python=component |
| `agents` | multi-choice | `[claude]` | `claude`, `codex`, both or none. Selects the adapters; `AGENTS.md` and the skills are always generated |

The template is Python-only: every generated project has a Python package, either at the repo root or in a component directory ([ADR 004](docs/adr/004-python-only.md)).

## Generated output

```
<project>/
├── AGENTS.md                    # agent entry point: rules, skills index, docs map
├── README.md
├── .gitignore
├── .env.example                 # (if secrets=env-only)
├── Dockerfile                   # (if is_service)
├── CLAUDE.md · .claude/         # (if agents has claude) @AGENTS.md, skills link, deny rules, Stop hook
├── .codex/                      # (if agents has codex) command rules, Stop hook
├── .agents/skills/              # procedures as SKILL.md files
│   ├── plan-issue/ · implement-issue/ · review-pr/ · release/
│   └── (one SKILL.md each; they call only just)
├── docs/
│   ├── workflow.md              # gates and why, conventions, quality gates, definition of done
│   ├── codestyle.md             # code and test conventions
│   ├── architecture.md
│   ├── operations.md            # (if is_service)
│   ├── adr/
│   └── domain/
├── .copier/                     # owned by the template, replaced on update — never edit
│   ├── recipes.just             # quality, forge and setup recipes (imported by justfile)
│   ├── setup.sh                 # installs the tools on a clean machine / cloud agent environment
│   ├── cliff.toml               # git-cliff release notes config
│   └── answers.yml              # copier answers
├── justfile                     # owned by the project: imports .copier/recipes.just, holds project recipes
├── .pre-commit-config.yaml      # (if hooks ≠ none)
├── .forgejo/workflows/          # (if platform ≠ github)
│   ├── ci.yml
│   └── cd.yml                   # (if is_service)
├── .github/workflows/           # (if platform ≠ forgejo)
│   ├── ci.yml
│   └── cd.yml                   # (if is_service)
│
├── [python=root]
│   ├── pyproject.toml · .python-version
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
just template-update          # = uvx copier update --answers-file .copier/answers.yml
```

Copier does a 3-way merge (old template rendering + your local changes + new template rendering) and writes conflict markers where both sides changed. Resolve conflicts, then commit. Everything under `.copier/` is replaced; the root `justfile` is never touched.

### Migrating from v1 to v2

v2 moves procedures into skills, merges the rule docs, routes all forge operations through `just`, and puts the template-owned files into `.copier/`. A v1 project gets there with one update and a few manual steps. The steps are written so they can be handed to the project's agent as they are. Tried on a real v1.0.0 service project: 9 files with conflicts, mostly one hunk each.

**1. Update on a branch.** v1 keeps its answers in `.copier-answers.yml` and has no `template-update` recipe yet:

```bash
git checkout -b chore/template-v2
mkdir .copier && git mv .copier-answers.yml .copier/answers.yml
git commit -m "chore: move copier answers"
uvx copier update --answers-file .copier/answers.yml
```

Answer the new questions; do not pass `--defaults` blindly:

- `agents` — the agent tools you use (`claude`, `codex`).
- `github_owner_type` (GitHub only) — `organization` if the repository belongs to one, else `personal`. Organisations use native issue types, everything else `type/` labels.

`workflow_style` no longer exists and is dropped. `python: none` no longer exists either.

**2. Rescue what the update deletes, before committing.** `docs/agent-workflow.md`, `docs/quality-gates.md` and `docs/testing.md` are deleted without a conflict, also when you edited them. They are still in `HEAD` (`git show HEAD:docs/agent-workflow.md`). Move project-specific content to its new home:

| v1 | v2 |
|---|---|
| `docs/agent-workflow.md`: session flow, mandatory stops, handoff | `.agents/skills/` (`plan-issue`, `implement-issue`); project rules go in `docs/workflow.md` |
| `docs/agent-workflow.md`: branching, issue conventions, releases | `docs/workflow.md` |
| `docs/quality-gates.md` | `docs/workflow.md`, "Quality gates" |
| `docs/testing.md` | `docs/codestyle.md`, "Testing" |
| handoff notes in `.ai/` | the PR body; `.ai/` is scratch, body files go in `.ai/forge/` |
| raw `gh` / `fj` commands in docs | `just` recipes (`just --list`) |
| `cliff.toml`, `scripts/setup.sh` | `.copier/` |
| `CHANGELOG.md` | release notes on the forge (`just release`); delete the file if you want that |
| `docker-compose.yml`, `just up` | no longer generated; keep yours if you use them |

**3. Rewrite the `justfile` — the one step that cannot be skipped.** The file now belongs to the project, so the update leaves it exactly as it was: your recipes plus the old v1 template recipes, and without the import none of the new recipes exist. Delete the v1 template recipes (`fix`, `lint`, `typecheck`, `test`, `static`, `check`, `up`), keep your own, and put this at the top:

```just
set allow-duplicate-recipes

import '.copier/recipes.just'
```

A bare `just` runs the first recipe of the root file; add `default:` with `@just --list` if you have none. `just --list` must then show `doctor`, `issues`, `pr`, `release` and the rest.

**4. Resolve the conflicts.** The template wins for `AGENTS.md`, `.agents/`, `.copier/`, CI workflows and `.pre-commit-config.yaml`; the project wins for `src/`, `tests/`, its own `pyproject.toml` sections, `README.md`, `Dockerfile` and `docs/architecture.md` / `docs/operations.md` content. Things that came up in the trial:

- `.gitignore`: if the project ignores `.claude/`, the Claude adapter is generated but never committed. Ignore only `.claude/settings.local.json`.
- `.pre-commit-config.yaml`: detect-secrets now runs without `--baseline`. Keep the argument if the project has a `.secrets.baseline` it relies on.
- `tests/<package>/test_package.py` is new; delete it if the project already has an equivalent test.
- `just release` needs `git-cliff` in the dev dependencies (`uv add --dev git-cliff`).

**5. Check and finish.** `just doctor`, `just check`, commit, open the PR. Then once per repository: `just labels-init`, branch protection (`just forge-protect` on GitHub, by hand on Forgejo) and an agent account without admin rights — see "Enforcement" in the generated `docs/workflow.md`.

### Onboarding an existing repo (no copier history)

The first import is manual — no `.copier/answers.yml` means no merge baseline.

1. **Generate a fresh copy into a temp branch:**
   ```bash
   git checkout -b template-import
   copier copy --overwrite \
     --data project_name=... \
     --data python=root \
     ... \
     /path/to/project-template .
   ```
   This writes `.copier/answers.yml` and overwrites all template files including `pyproject.toml` and `src/`.

2. **Restore your existing Python files:**
   ```bash
   git checkout HEAD -- pyproject.toml src/ tests/
   ```

3. **Manually merge pyproject.toml sections** you want from the template version (`git show template-import:pyproject.toml`): `[tool.pytest.*]`, `[tool.coverage.*]`, `[tool.pyright]`, `[tool.ruff.*]`.

4. **Keep the template versions** of: `docs/`, `AGENTS.md`, `.agents/`, `.copier/`, CI workflows, `.pre-commit-config.yaml`. Put your own recipes into the generated `justfile` below the import.

5. Commit. The repo now has `.copier/answers.yml` so future `just template-update` calls work.

| File | Action |
|---|---|
| `AGENTS.md`, `.agents/`, `.copier/`, `docs/`, CI | Keep template version |
| `justfile` | Generated one, plus your own recipes |
| `.pre-commit-config.yaml` | Keep template version |
| `pyproject.toml` | Restore yours, cherry-pick `[tool.*]` sections |
| `src/`, `tests/` | Always restore yours |
| `README.md` | Restore yours, manually add `just` commands table |

## Testing the template

```bash
just test-render
```

Renders every platform × python × is_service combination and checks the output. See [docs/testing.md](docs/testing.md) for what it checks and how forge recipes are smoke-tested, [docs/operations.md](docs/operations.md) for what a forge needs so generated projects work (CI secret), and [docs/adr/](docs/adr/README.md) for design decisions.
