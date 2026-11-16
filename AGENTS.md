# project-template

Agent entry point for the template repo itself. `template/AGENTS.md.jinja` is the file rendered into generated projects — it does not describe this repo.

## Rules

- Work happens in issues and PRs on Forgejo (`origin`). GitHub is a mirror.
- Post the plan as an issue comment and wait for the human's go before editing. Open the PR and stop; the human merges.
- Run `just test-render` before opening a PR.
- Check `fj <cmd> --help` before using an fj subcommand you have not verified; do not guess flags.
- This repo has two remotes: pass the host to fj (`fj -H git.pw13.eu …`), or it cannot resolve the repo on a branch without upstream.

## Documentation map

- [README.md](README.md) — parameters, generated output, rolling out template changes
- [docs/testing.md](docs/testing.md) — render test, smoke-testing forge recipes, tested tool versions
- [docs/operations.md](docs/operations.md) — what a forge needs so generated projects work (CI secret, scratch repo)
- [docs/adr/README.md](docs/adr/README.md) — ADR index and format guide

## Layout

- `copier.yaml` — questions and excludes
- `template/` — rendered into generated projects
- `_shared/` — Jinja partials included by several template files
- `scripts/`, `justfile` — tooling for this repo, not rendered
