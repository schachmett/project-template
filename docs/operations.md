# Operations

What has to exist outside a generated project for it to work, and the infrastructure this repo uses for testing.

## Forgejo CI needs a GitHub token (`GH_PAT`)

The `setup-just` and `setup-uv` actions ask the GitHub API for their tool's releases. On a Forgejo runner the default token is a Forgejo token, which GitHub rejects — the first CI run of a new project fails within seconds:

```
GET /repos/casey/just/releases - 401
::error::Bad credentials - https://docs.github.com/rest
```

The Forgejo workflows therefore pass `secrets.GH_PAT` to both actions.

- **What token:** it only reads public repositories. A fine-grained token with repository access "Public repositories (read-only)" and no permissions is enough; so is a classic token with no scopes.
- **Expiry:** the token grants nothing an anonymous user lacks apart from the owner's rate limit, so no expiry is defensible. With an expiry, CI of every project fails on the day it runs out.
- **Where:** set it once as a **user-level or organisation-level** Actions secret in Forgejo (Settings → Actions → Secrets). Every repo of that owner then has it, and new projects need no per-repo step. This is how it is set up on git.pw13.eu.

CD needs no extra secret: it logs in to the container registry with the built-in token and `packages: write`.

## Scratch repo

`simon/test-repo` on git.pw13.eu is the scratch repo for smoke-testing forge recipes (see [testing.md](testing.md)). It holds a rendered project plus test issues, PRs and releases; nothing in it needs to be kept.

## Mirrors

`origin` is Forgejo (git.pw13.eu) and carries issues, PRs and releases. `github` is a mirror for `copier copy gh:…`.
