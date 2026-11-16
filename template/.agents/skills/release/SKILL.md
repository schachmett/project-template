---
name: release
description: Cut a release from main with generated release notes. Use only when the human explicitly asks for a release.
---

# Release

A release creates a tag, publishes notes and triggers the CD workflow. Do it only on an explicit request from the human, and confirm the version with them before running the recipe.

1. **Be on a clean, current `main`:** `git checkout main && git pull`. The recipe refuses otherwise.
2. **Check `main` is green** — the last CI run on `main` passed. If you cannot see that, ask.
3. **Pick the version** (`vMAJOR.MINOR.PATCH`, semver) from the commits since the last release (`just releases`, `git log <last-tag>..HEAD --oneline`):
   - a breaking change (`!` or `BREAKING CHANGE`) → major
   - any `feat` → minor
   - otherwise → patch
   Tell the human which version you propose and why; wait for their confirmation.
4. **Release:** `just release vX.Y.Z`
   The notes are generated from the conventional commits. There is no `CHANGELOG.md` and nothing to commit.
5. **Confirm:** `just releases` shows the new version. Report it, and that CD was triggered by the tag.

If the recipe fails after the tag was created, do not retry blindly: report what exists (`just releases`, `git ls-remote --tags origin`) and let the human decide.
