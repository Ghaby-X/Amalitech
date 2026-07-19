# Prompt history

Full log of the prompts used to produce `TASKFLOW_DOCUMENTATION.md`,
in order. Outputs are abbreviated to the parts that matter (what was
wrong, what changed), not pasted in full, the full corrected text lives
in the final document.

## Phase 2: first-pass prompts (one per section)

These were written before looking at the project files, deliberately,
to see what a context-free prompt produces.

1. "Write a Getting Started guide for TaskFlow, a task management web
   app."
2. "Write an API reference for TaskFlow's API."
3. "Write a troubleshooting section for TaskFlow covering common errors
   and FAQs."

## Phase 3: first pass, review, refine, chain

### 1. Getting Started

**First pass output (abbreviated):** a generic onboarding guide that
mentioned "verify your email before creating your first task" and
"available on web and iOS, with more platforms coming soon."

**Review against project files:** both claims are wrong.
`taskflow-app/specs/feature-notes.md` says email verification was
removed, and there is no iOS app or roadmap commitment to one, that was
an aspirational line in a planning slide deck. Also missing entirely:
what a task's `status` values are and mean to an end user, since the
first pass never mentioned status at all.

**Refined prompt:**
> Act as a technical writer. Here are TaskFlow's actual facts, from our
> internal spec: tasks have a status of `todo`, `in_progress`, or
> `done` (new tasks start as `todo`); there is no email verification
> step; the product is web-only, no mobile app exists or is planned.
> Rewrite the Getting Started guide for end users using only these
> facts, plain English, no jargon, and don't mention anything not
> listed here.

**Result:** corrected guide with no invented features, includes the
real status values in plain language.

### 2. API Reference

**First pass output (abbreviated):** invented an `/api/v1/tasks`
prefix (the real API has no version prefix), described auth as "API
key in the header," used a task status enum of `pending / in-progress
/ completed` (wrong casing and wrong terms), returned generic
`{ "success": false, "error": "message" }` error bodies, and never
mentioned rate limiting.

**Review against project files:** every one of those is wrong per
`taskflow-app/specs/api-contract.md`: no version prefix, auth is a
Bearer JWT (not an API key), status values are exactly `todo` /
`in_progress` / `done`, errors are `{ "error": "CODE", "message":
"..." }`, and `/api/auth/login` is rate-limited (10 requests per 15
minutes) with a 429 response the first pass never mentioned.

**Refined prompt (following the lab's own bad-prompt/good-prompt
pattern):**
> Act as a technical writer. Here is the internal API contract for
> TaskFlow's `/api/tasks` and `/api/auth/login` endpoints: [pasted the
> full contents of `taskflow-app/specs/api-contract.md`]. Write an API
> reference from this, one subsection per endpoint, each with path,
> method, auth requirement, request body, and every documented
> response status with an example body. Don't add endpoints, fields,
> or status codes that aren't in the contract I gave you.

**Result:** matches the contract exactly, including the rate limit
section the generic pass omitted.

### 3. Troubleshooting

**First pass output (abbreviated):** generic entries like "Error 500:
Server Error, try refreshing the page" and an invented "Task limit
reached" error that doesn't exist anywhere in the project files.

**Review against project files:** the real error surface is the five
error codes in the API contract (`VALIDATION_ERROR`,
`INVALID_CREDENTIALS`, `UNAUTHORIZED`, `TOKEN_EXPIRED`,
`TASK_NOT_FOUND`, `RATE_LIMITED`), plus one real point of confusion
from `feature-notes.md`: QA once believed DELETE returns the deleted
task in its response body, it doesn't (204, empty body), that was a
stale-cache issue on their end. That's a genuinely useful thing to
document since it's a real question a new developer would otherwise
ask in Slack.

**Refined prompt:**
> Act as a technical writer. Here are TaskFlow's actual error codes and
> when each one happens: [pasted the responses tables from
> `api-contract.md`]. Also document this known point of confusion: some
> people expect DELETE /api/tasks/{id} to return the deleted task, it
> returns an empty 204 response instead. Write a troubleshooting
> section as a list of symptom to cause to fix, using only these facts.

**Result:** every entry traces to a real status code or a documented
gotcha, no invented errors.

### 4. Chain: unify style across sections

Ran once all three sections were individually fact-checked, per the
lab's chaining example:

> Take the Getting Started guide, API Reference, and Troubleshooting
> section I've written and rewrite them to have the same professional,
> clear, and simple tone. Ensure all main headings are H2 and
> sub-headings are H3. Do not change any technical fact, status code,
> field name, or example, only tone and heading structure.

**Result:** consistent voice and heading levels across all three
sections without altering any technical content, verified by
re-diffing the technical facts against `api-contract.md` after the
rewrite.

### 5. Assemble

Combined the three chained, fact-checked sections into
`TASKFLOW_DOCUMENTATION.md` in the order: Getting Started, API
Reference, Troubleshooting, followed by this prompt history and the
reflection.
