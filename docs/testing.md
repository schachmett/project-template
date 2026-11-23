# Testing

The template has no unit tests. It is tested by rendering it and checking the result.

## Render test

```bash
just test-render
```

Renders every platform × python × is_service combination with `uvx copier` — GitHub once per `github_owner_type` — and checks, for each:

- `just --list` parses the rendered justfile
- `just --dry-run` resolves every forge recipe; `issue-parent` and `forge-protect` exist on GitHub only, `issue-type` only for GitHub organisations, and `type/` labels everywhere else
- the justfile calls the CLI of its platform and not the other one
- no removed question (`workflow_style`) appears in the output
- `scripts/check_render.py`: the four skills exist with matching `name` and a `description` in their frontmatter; every relative markdown link resolves; no file mentions a removed doc; no raw `gh`/`fj` command appears in any markdown file
- `scripts/setup.sh` is executable and parses (`bash -n`)
- every file ends with exactly one newline and has no trailing whitespace
- `.pre-commit-config.yaml` loads (`pre-commit validate-config`)
- detect-secrets 1.5.0 reports nothing in the fresh project, apart from the excluded answers file (see [ADR 005](adr/005-detect-secrets-without-baseline.md))

The projects are rendered with `secrets=env-only`, so `.env.example` is part of what is checked.

After the matrix it renders every `agents` selection (none, claude, codex, both) on Forgejo and GitHub and checks that adapter files exist exactly for the selected agents, that `.claude/skills` is a symlink resolving to the skills, that the JSON files parse, and that the default reviewer in `just review` matches the selection.

Then, for one root and one component project with `hooks=python` and `is_service=true`, it checks that a fresh project passes its own gates: `uv sync`, `just check` (ruff, pyright, pytest with the coverage gate) and `pre-commit run --all-files` on a feature branch. This needs network access to PyPI and to github.com (pre-commit hook repos), and it is what catches drift when a new ruff or pyright release starts rejecting the generated code.

It also appends a stale answer to a rendered project's `.copier-answers.yml` and runs `copier update`, to make sure projects generated before a question was removed still update.

The script renders from a snapshot of `copier.yaml`, `template/` and `_shared/` as they are in the working tree — committed or not. Rendering the repo directly makes copier run `git add -A` on a dirty tree, which picks up (and can fail on) unrelated untracked files.

When a question or choice is added, extend the matrix in `scripts/test-render.sh`.

## Smoke-testing forge recipes

`--dry-run` only shows that a recipe resolves. A change to a forge recipe is tested for real against a scratch repo (see [operations.md](operations.md)):

1. Render a project for the platform, commit it, push it to the scratch repo as `main`.
2. Run each recipe: `labels-init` (twice — the second run must create nothing), `issues`, `issue-new` with and without labels, `issue-label`, `issue-unlabel`, `issue-blocked-by`, `issue`, `issue-unblock`, `comment`, `issue-close`, then from a feature branch `pr`, `prs`, `pr-view`, `pr-body`, `pr-diff`, `comment-pr`, then from `main` `release` and `releases`.
3. Use a title with `"quotes"` and `$HOME` at least once.
4. Check the four `release` guards: not on `main`, malformed version, dirty tree, `main` ahead of `origin/main`.
5. For fj, repeat a few recipes from a branch without upstream in a clone with a second remote — plain `fj` fails there (see [ADR 001](adr/001-just-is-the-forge-interface.md)).

`scripts/setup.sh` is tested by running it in the scratch clone with an empty `HOME` and `PATH=/usr/bin:/bin`: it must install the tools into `$HOME/.local/bin` and end with `just doctor` reporting only the missing login. `just doctor` is tested with a stub tool that reports an old version.

The Claude adapter is tested by hand in a rendered project with `claude -p`: the four skills are listed, `git push origin main` and `fj -H <host> pr merge N` are refused, the Stop hook reports a failing `just static` on a dirty tree, and `just review N` posts a review on a scratch PR. The Codex adapter has no test beyond the render checks.

The gh recipes cannot be run without a GitHub scratch repo. Check their argument handling with a stub `gh` on `PATH` that prints its arguments.

Things that look like failures but are not:

- Forgejo's issue search lags a few seconds behind creation; `just issues <query>` right after `just issue-new` can come back empty.
- `fj issue depend remove` (0.7.0) prints `unexpected status code 201 Created` and exits non-zero, but the dependency is removed. `issue-unblock` checks the result instead of the exit code.
- fj prints results such as `created issue #N` on stderr, and `repo labels view` prints exclusive labels as `scope  name` instead of `scope/name`. `issue-new` and `labels-init` parse both.
- fj wraps names and numbers in invisible Unicode isolate characters when its output is piped.

## Tested versions

| Tool | Version | How |
|---|---|---|
| forgejo-cli (`fj`) | 0.7.0 | every recipe run against a scratch repo |
| GitHub CLI (`gh`) | 2.105.0 | flags from `--help`, argument handling with a stub — not run against GitHub. Issue types, sub-issues and blocked-by do not exist in 2.46.0 (Debian's package) |
| just | 1.40.0 | |
| Claude Code | 2.1.327 | adapter checked by hand as described above |
| Codex | — | not installed; adapter written from the docs |
| detect-secrets | 1.5.0 | hook run over every rendered project; pinned in the generated pre-commit config |
| git-cliff | from the generated project's dev dependencies | release notes for root and component layout |

Update this table when a recipe is re-tested with a newer version.
