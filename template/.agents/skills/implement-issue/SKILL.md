---
name: implement-issue
description: Implement an approved plan on a branch, pass the quality gates, open a pull request with a handoff body, and stop for human review. Use once the plan on the issue has been approved.
---

# Implement an issue

Precondition: the issue carries a plan and the human approved it. If not, use `plan-issue` first.

1. **Re-read the record:** `just issue N`. The plan and every later comment are the scope. In a new session this is the only context you have — do not rely on files in `.ai/`.
2. **Branch from an up-to-date `main`:**
   `git checkout main && git pull && git checkout -b <type>/<short-description>`
   If a branch or PR for the issue already exists (`just prs`, `just pr-view N`), continue there instead.
3. **Implement the plan.** Stay inside the agreed scope. Something else is broken? Note it for the PR body or open an issue; do not fix it in passing.
4. **Tests come with the change.** A bug fix includes the test that would have caught it.
5. **Run the gates:** `just fix`, then `just check`. Fix failures; never skip or silence a check to get through.
6. **Update the docs** the change makes wrong, and write an ADR for any non-obvious decision (`docs/adr/README.md`).
7. **Commit** in conventional-commit format (`docs/codestyle.md`), one logical change per commit.
8. **Open the PR.** Write the body to `.ai/pr-N.md` using the template below, then
   `just pr "<type>: <summary>" .ai/pr-N.md`
9. **Stop.** Report the PR number. The human reviews and merges; you never merge.

## PR body

The PR body is the handoff: the next session, the reviewer and the human read it instead of any chat history.

```markdown
Closes #N            <!-- or: Part of #N -->

## What changed
## How it was verified
<!-- commands run and their result; say what was NOT verified -->
## Assumptions
## Open questions
## ADRs
<!-- written, or deferred and why -->
```

Check CI with `just pr-view N` once it has run and say in your report whether it is green.

## After review

Address review comments with further commits on the same branch and push. If the changes make the body wrong, rewrite it and run `just pr-body N .ai/pr-N.md`. Answer comments with `just comment-pr N FILE`.

## If the session ends before there is a PR

Push the branch and leave a comment on the issue (`just comment N FILE`): branch name, what is done, what is left, anything surprising.
