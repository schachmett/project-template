# 010: Small changes skip the plan gate

**Status**: accepted
**Date**: 2026-11-23

## Context

Every change needed a plan posted on the issue and a wait for approval, then a PR and a second wait. For a typo, a dependency bump or a one-line fix the first wait buys nothing: the issue already says everything a plan would.

## Decision

A change is *small* when it changes no behaviour beyond what the issue states, adds no dependency, changes no interface, schema or stored format, and needs no ADR. A small change goes issue → PR without a plan comment. The issue is still required and the merge gate is untouched.

- The PR body carries the line `No plan — small change`, so the reviewer sees which lane was used.
- In doubt, it is not small.
- The human's word on the issue overrides the definition both ways: "plan first" or "no plan needed".
- If the work turns out bigger than expected, the agent stops and plans.

The definition lives once, in the generated `docs/workflow.md`; AGENTS.md rule 1 and the `plan-issue` and `implement-issue` skills refer to it.

## Consequences

- One human wait instead of two for trivial work.
- The classification is the agent's call. A misjudged "small" change is caught at the merge gate, later and more expensively than a plan would have caught it.
- "Adds no dependency" makes a version bump small but a new package not; that is intended.
