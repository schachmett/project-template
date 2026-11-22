---
name: implement-issue
description: Implement an approved plan on a branch, pass the quality gates, open a pull request with a handoff body, and stop for human review. Use once the plan on the issue has been approved.
---

# Implement an issue

Precondition, one of:

- the issue carries a plan and the human approved it, or
- the change is small by the definition in `docs/workflow.md` ("Small changes"), or the human said "no plan needed". Then the issue body is the scope, and the PR body starts with `No plan — small change`. If the work turns out not to be small after all, stop and use `plan-issue`.

Otherwise use `plan-issue` first.

1. **Know the scope.** The plan on the issue and every later comment are the scope.
   - *New session:* read them with `just issue N`. That is the only context you have — do not rely on files in `.ai/`.
   - *Same session that wrote the plan:* no need to re-read it. Do run `just issue N` if the human answered on the issue instead of in the conversation.
2. **Branch from an up-to-date `main`:**

   `git checkout main && git pull && git checkout -b <type>/<short-description>`

   If a branch or PR for the issue already exists (`just prs`, `just pr-view N`), continue there instead.
3. **Implement the plan.** Stay inside the agreed scope. Something else is broken? Note it for the PR body or open an issue; do not fix it in passing.
4. **Tests come with the change.** A bug fix includes the test that would have caught it.
5. **Run the gates:** `just fix`, then `just check`. Fix failures; never skip or silence a check to get through.
6. **Update the docs** the change makes wrong, and write an ADR for any non-obvious decision (`docs/adr/README.md`).
7. **Commit** in conventional-commit format (`docs/codestyle.md`), one logical change per commit.
8. **Open the PR.** Write the body to `.ai/forge/pr-N.md` using the template below, then

   `just pr "<type>: <summary>" .ai/forge/pr-N.md`
9. **Stop.** Report the PR number. The human reviews and merges; you never merge.

## PR body

The PR body is the handoff: the next session, the reviewer and the human read it instead of any chat history.

```markdown
Closes #N            <!-- or: Part of #N -->
<!-- small change without a posted plan: add the line "No plan — small change" -->

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

Address review comments with further commits on the same branch and push. If the changes make the body wrong, rewrite it and run `just pr-body N .ai/forge/pr-N.md`. Answer comments with `just comment-pr N FILE`.

If a review comment states a rule that applies beyond this PR ("we never do X here"), make it permanent in the same PR: add it to the doc or skill it belongs to (`docs/codestyle.md`, `docs/workflow.md`, a skill), so the next session does not repeat the mistake.

## If the session ends before there is a PR

Push the branch and leave a comment on the issue (`just comment N FILE`): branch name, what is done, what is left, anything surprising.
