# 011: Setup script, `just doctor`, and branch protection as after-copy steps

**Status**: accepted
**Date**: 2026-11-23

## Context

Generated projects assumed `just`, `uv`, `pre-commit` and a logged-in forge CLI of the right version. On a fresh machine or in a cloud agent's sandbox the first recipe failed with an unrelated-looking error. And the merge gate was described in `workflow.md` but nothing set it up or reminded the human to.

## Decision

- **`scripts/setup.sh`** (rendered per platform) installs uv, just, pre-commit and the forge CLI into `~/.local/bin` without root, syncs the Python environment, installs the hooks and ends with `just doctor`. The forge CLI is a pinned release binary (fj 0.7.0 from Codeberg, gh 2.105.0 from GitHub). Tools that are already installed are kept.
- **Tokens come from the environment.** gh reads `GH_TOKEN` itself. fj has no such variable, so the script pipes `FORGEJO_TOKEN` to `fj auth add-token` on stdin; fj then stores it in its own configuration.
- **`just doctor`** prints one line per problem and exits non-zero: tool missing, forge CLI too old, hooks not installed, forge CLI not logged in for the host of `origin`. AGENTS.md mentions it only for the case that a recipe fails on a tool.
- **Branch protection:** on GitHub `just forge-protect` applies it through `gh api` (gh has no command for it — the one API call in the justfile): pull requests only, one approving review, not enforced for admins. fj 0.7.0 cannot manage branch protection, so on Forgejo the manual steps are printed after `copier copy` and described in `workflow.md`.
- **The agent account stays manual** and is an after-copy step on both forges.
- Protection is not enforced for admins because a human working alone could otherwise not merge their own PRs. The gate therefore holds only against a non-admin agent account.

## Consequences

- A cloud agent environment needs one setup command and one secret.
- `just doctor` proves that a token is stored for fj, not that it is valid; fj accepts any string.
- The minimum versions exist in three places: the setup script, `doctor`, and the docs.
- Nothing checks whether `main` is actually protected.
- Not run: `forge-protect` against GitHub, the gh half of the setup script, the `uv tool install rust-just` path (just was already present on the test machine), and the Forgejo protection steps.
