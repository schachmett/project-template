---
name: plan-issue
description: Turn an issue into an implementation plan, post it as a comment on the issue, and wait for the human's approval. Use at the start of any work on an issue, before editing any file.
---

# Plan an issue

1. **Find the issue.** `just issues` lists open issues, `just issue N` shows one with all its comments. Read the comments: an earlier plan or decision may already be there.

   If the task has no issue, write one first: body to `.ai/forge/issue.md`, then `just issue-new "Title" .ai/forge/issue.md`. Title conventions are in `docs/workflow.md`.
2. **Read what the task touches.** The docs listed in `AGENTS.md` that are relevant, the ADRs for the area, and the code you expect to change. Do not read everything.
3. **Write the plan** to `.ai/forge/plan-N.md`:
   - what changes, file by file, and why
   - what is deliberately out of scope
   - how it will be verified (tests, commands, manual checks)
   - decisions that need an ADR
   - open questions, each with your recommendation
4. **Post it:** `just comment N .ai/forge/plan-N.md`
5. **Stop.** Tell the human the plan is posted and repeat the open questions. Edit no file until the human explicitly says to go ahead. Answers to questions or agreement with one point are not approval; if unsure, ask.
6. **If the answers change the plan,** post the change as a further comment (`just comment N FILE`) so the issue stays the complete record, then wait again.

Once approved, continue with the `implement-issue` skill — in this session or a new one.

Body files for `just` go in `.ai/forge/` (create it if missing). The rest of `.ai/` may hold the human's own notes and scripts: leave it alone.
