# Testing

The template has no unit tests. It is tested by rendering it and checking the result.

## Render test

```bash
just test-render
```

Renders every platform × python × is_service combination with `uvx copier` and checks, for each:

- `just --list` parses the rendered justfile
- `just --dry-run` resolves every forge recipe
- the justfile calls the CLI of its platform and not the other one
- no removed question (`workflow_style`) appears in the output
- no raw `gh`/`fj` command is left in `AGENTS.md`, `README.md` or `docs/`
- every file ends with exactly one newline and has no trailing whitespace
- `.pre-commit-config.yaml` loads (`pre-commit validate-config`)
- detect-secrets 1.5.0 reports nothing in the fresh project, apart from the excluded answers file (see [ADR 005](adr/005-detect-secrets-without-baseline.md))

The projects are rendered with `secrets=env-only`, so `.env.example` is part of what is checked.

Then, for one root and one component project with `hooks=python` and `is_service=true`, it checks that a fresh project passes its own gates: `uv sync`, `just check` (ruff, pyright, pytest with the coverage gate) and `pre-commit run --all-files` on a feature branch. This needs network access to PyPI and to github.com (pre-commit hook repos), and it is what catches drift when a new ruff or pyright release starts rejecting the generated code.

It also appends a stale answer to a rendered project's `.copier-answers.yml` and runs `copier update`, to make sure projects generated before a question was removed still update.

The script renders from a snapshot of `copier.yaml`, `template/` and `_shared/` as they are in the working tree — committed or not. Rendering the repo directly makes copier run `git add -A` on a dirty tree, which picks up (and can fail on) unrelated untracked files.

When a question or choice is added, extend the matrix in `scripts/test-render.sh`.

## Smoke-testing forge recipes

`--dry-run` only shows that a recipe resolves. A change to a forge recipe is tested for real against a scratch repo (see [operations.md](operations.md)):

1. Render a project for the platform, commit it, push it to the scratch repo as `main`.
2. Run each recipe: `issues`, `issue-new`, `comment`, `issue`, then from a feature branch `pr`, `prs`, `pr-diff`, `comment-pr`, then from `main` `release` and `releases`.
3. Use a title with `"quotes"` and `$HOME` at least once.
4. Check the four `release` guards: not on `main`, malformed version, dirty tree, `main` ahead of `origin/main`.
5. For fj, repeat a few recipes from a branch without upstream in a clone with a second remote — plain `fj` fails there (see [ADR 001](adr/001-just-is-the-forge-interface.md)).

Things that look like failures but are not:

- Forgejo's issue search lags a few seconds behind creation; `just issues <query>` right after `just issue-new` can come back empty.
- fj wraps names and numbers in invisible Unicode isolate characters when its output is piped.

## Tested versions

| Tool | Version | How |
|---|---|---|
| forgejo-cli (`fj`) | 0.7.0 | every recipe run against a scratch repo; flags identical in 0.6.0 |
| GitHub CLI (`gh`) | 2.46.0 | `--dry-run` and `--help` only — not run against GitHub |
| just | 1.40.0 | |
| detect-secrets | 1.5.0 | hook run over every rendered project; pinned in the generated pre-commit config |
| git-cliff | from the generated project's dev dependencies | release notes for root and component layout |

Update this table when a recipe is re-tested with a newer version.
