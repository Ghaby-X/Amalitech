# AI-Assisted Technical Documentation

Uses AI to generate documentation for a fictional task management app,
"TaskFlow," then fact-checks and refines it against a source-of-truth
spec through iterative prompting.

## Files

| File | Purpose |
| --- | --- |
| [`TASKFLOW_DOCUMENTATION.md`](TASKFLOW_DOCUMENTATION.md) | The submission: Getting Started guide, API Reference, Troubleshooting section, prompt history summary, and reflection, in one document. |
| [`prompt-history.md`](prompt-history.md) | Full log of every prompt used: first pass, review notes on what was wrong, refined prompts, and the style-chaining prompt. |
| [`taskflow-app/`](taskflow-app/) | Fixture only, not part of the submission. The "TaskFlow project files and specs" the scenario describes: an API contract (source of truth) and messy, sometimes-contradictory developer notes. |

## Method

Followed the lab's four-phase process: ran context-free "first pass"
prompts for each section, reviewed the output against
`taskflow-app/specs/api-contract.md` and `feature-notes.md`, refined by
pasting the real spec directly into the prompt, then ran one chaining
prompt to standardize tone and heading levels across all three sections
without altering any technical fact. Details and before/after notes are
in `prompt-history.md`.

## Where accuracy actually mattered

The first-pass output was fluent and wrong in specific, checkable ways:
a fabricated API version prefix, wrong task-status values, an invented
error, a claimed iOS app, and a missing rate-limit section. The messy
notes fixture adds a second layer on top of that: a couple of its own
entries are themselves outdated (an old status name, an aspirational
feature that was never shipped), so cross-checking against the notes
alone wasn't enough either, only the API contract could be trusted as
ground truth. That gap between "sounds right" and "is right" is the
point of the exercise.

One gap surfaced during verification of the assembled document itself:
`TASKFLOW_DOCUMENTATION.md` documented a `TOKEN_EXPIRED` error that
wasn't actually defined in `api-contract.md` at the time, only the fact
that tokens expire after 24 hours was. Rather than delete the detail
from the docs, the contract was fixed to properly define that response,
since it's a real, expected case any client would hit. That's the same
fact-checking discipline the exercise asks for, applied one level up.
