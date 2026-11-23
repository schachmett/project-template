---
name: review-pr
description: Review a pull request against its issue, the approved plan and the definition of done, and post the findings as a PR comment. Use when asked to review a PR; never approves or merges.
---

# Review a pull request

You review; you do not fix, approve or merge.

1. **Read the PR:** `just pr-view N` (body, comments, CI status) and `just pr-diff N`.
2. **Read what it claims to implement:** the issue named in the body (`just issue M`), including the plan and later decisions.
3. **Check, in this order:**
   - **Scope** — does the diff do what the plan says, and nothing else?
   - **Correctness** — follow the changed code paths; look for the inputs and states the author did not test.
   - **Tests** — does new behaviour have tests that would fail without the change?
   - **Conventions** — `docs/codestyle.md`, existing patterns in the touched files.
   - **Docs and ADRs** — updated where the change makes them wrong; a non-obvious decision has an ADR.
   - **Handoff** — does the body say how it was verified and what was not?
   - **Definition of done** in `docs/workflow.md`, including CI.
4. **Write the review** to `.ai/forge/review-N.md`:
   - verdict first: *ready to merge*, *ready after small fixes*, or *needs rework*
   - findings, most severe first, each with file and line, what happens, and why it matters
   - questions for the author
   - what you did not check
   Report only what you verified in the code. No style remarks that `just fix` would settle.
5. **Post it:** `just comment-pr N .ai/forge/review-N.md`
6. **Stop.** The human decides what happens next.

When started through `just review N`, the PR text and diff are already in the prompt and the recipe posts the result: skip steps 1 and 5 and print the review.
