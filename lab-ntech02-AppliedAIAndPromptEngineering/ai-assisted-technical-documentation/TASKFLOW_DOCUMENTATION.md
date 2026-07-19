# TaskFlow Documentation

## Getting Started

TaskFlow is a web app for managing your personal to-do list. This guide
covers everything you need to start using it.

### Signing in

Go to the TaskFlow login page and enter your email and password. If
your details are correct you'll be signed in right away, there's no
separate email verification step.

### Understanding task status

Every task has a status:

- **To do**: not started yet. New tasks start here automatically.
- **In progress**: you're currently working on it.
- **Done**: finished.

You move a task between these as your work progresses.

### Creating a task

Click "New Task," give it a title (the only required field), and
optionally add a description and a due date. It's saved as "To do."

### Updating or deleting a task

Open any task to change its title, description, status, or due date.
Deleting a task removes it immediately and can't be undone.

### A note on platforms

TaskFlow is currently web-only. There's no mobile app.

---

## API Reference

All endpoints return JSON. Requests to any `/api/tasks` endpoint require
an `Authorization: Bearer <token>` header. Tokens come from
`POST /api/auth/login` and expire after 24 hours.

### POST /api/auth/login

Logs a user in and returns an access token.

**Request body**
```json
{ "email": "string", "password": "string" }
```

**Responses**

| Status | Meaning | Example body |
| --- | --- | --- |
| 200 | Success | `{ "token": "string", "user": { "id": "string", "name": "string", "email": "string" } }` |
| 400 | Missing email or password | `{ "error": "VALIDATION_ERROR", "message": "Email and password are required." }` |
| 401 | Wrong email or password | `{ "error": "INVALID_CREDENTIALS", "message": "Email or password is incorrect." }` |

### GET /api/tasks

Lists the current user's tasks. Optional `?status=` query parameter
filters by `todo`, `in_progress`, or `done`.

**Responses**

| Status | Meaning | Example body |
| --- | --- | --- |
| 200 | Success (empty array if no tasks) | `{ "tasks": [ { "id": "1", "title": "Write docs", "description": "", "status": "todo", "dueDate": null, "createdAt": "2026-07-01T00:00:00Z" } ] }` |
| 401 | Missing or invalid token | `{ "error": "UNAUTHORIZED", "message": "Missing or invalid authentication token." }` |

### POST /api/tasks

Creates a task. New tasks always start with `status: "todo"`.

**Request body**
```json
{ "title": "string (required)", "description": "string (optional)", "dueDate": "YYYY-MM-DD (optional)" }
```

**Responses**

| Status | Meaning | Example body |
| --- | --- | --- |
| 201 | Created | `{ "task": { "id": "2", "title": "Ship feature", "description": "", "status": "todo", "dueDate": null, "createdAt": "2026-07-01T00:00:00Z" } }` |
| 400 | Missing title | `{ "error": "VALIDATION_ERROR", "message": "Title is required." }` |
| 401 | Missing or invalid token | `{ "error": "UNAUTHORIZED", "message": "Missing or invalid authentication token." }` |

### PATCH /api/tasks/{id}

Updates any subset of `title`, `description`, `status`, `dueDate`.
`status` must be `todo`, `in_progress`, or `done`.

**Responses**

| Status | Meaning | Example body |
| --- | --- | --- |
| 200 | Updated | `{ "task": { "id": "2", "title": "Ship feature", "status": "in_progress", ... } }` |
| 400 | Invalid status value | `{ "error": "VALIDATION_ERROR", "message": "Status must be one of: todo, in_progress, done." }` |
| 404 | Task doesn't exist or isn't yours | `{ "error": "TASK_NOT_FOUND", "message": "No task with that ID exists for this user." }` |

### DELETE /api/tasks/{id}

Deletes a task.

**Responses**

| Status | Meaning | Example body |
| --- | --- | --- |
| 204 | Deleted (empty response body) | (none) |
| 404 | Task doesn't exist or isn't yours | `{ "error": "TASK_NOT_FOUND", "message": "No task with that ID exists for this user." }` |

### Rate limiting

`POST /api/auth/login` allows 10 requests per 15 minutes per IP address.

| Status | Meaning | Example body |
| --- | --- | --- |
| 429 | Too many login attempts | `{ "error": "RATE_LIMITED", "message": "Too many login attempts. Try again later." }` |

---

## Troubleshooting

### "Missing or invalid authentication token" (401, UNAUTHORIZED)

**Cause:** the `Authorization: Bearer <token>` header is missing or the
token is malformed.
**Fix:** log in again via `POST /api/auth/login` and use the returned
token exactly as given.

### "Your session has expired" (401, TOKEN_EXPIRED)

**Cause:** tokens expire 24 hours after login.
**Fix:** log in again to get a new token.

### "Email or password is incorrect" (401, INVALID_CREDENTIALS)

**Cause:** the email/password combination doesn't match an account.
**Fix:** double-check for typos. This response is intentionally the
same for "wrong password" and "no such account," so it doesn't reveal
which one it was.

### "Too many login attempts" (429, RATE_LIMITED)

**Cause:** more than 10 login attempts from the same IP address within
15 minutes.
**Fix:** wait 15 minutes before trying again.

### "Title is required" / validation errors (400, VALIDATION_ERROR)

**Cause:** a required field is missing, or `status` was set to
something other than `todo`, `in_progress`, or `done`.
**Fix:** check the request body against the API Reference above. Note
that `pending` is not a valid status, it was renamed to `todo`.

### "No task with that ID exists for this user" (404, TASK_NOT_FOUND)

**Cause:** the task ID doesn't exist, or it belongs to a different
user. Tasks are private, there's no sharing yet.
**Fix:** confirm the ID came from a `GET /api/tasks` response for the
currently logged-in user.

### "I deleted a task but the response body was empty, is that a bug?"

No. `DELETE /api/tasks/{id}` returns `204` with an empty body by
design, it does not return the deleted task. If you're seeing task data
after a delete, you're reading a cached response, not the actual
`DELETE` response.

---

## Prompt History

The full prompt-by-prompt log, including first-pass generic output and
what was wrong with it, lives in
[`prompt-history.md`](prompt-history.md). Summary:

1. **First pass:** ran context-free prompts for each of the three
   sections above. Output was fluent but wrong in specific,
   checkable ways: an invented `/api/v1/` prefix, wrong status values
   (`pending`/`in-progress`/`completed` instead of the real
   `todo`/`in_progress`/`done`), a made-up "Task limit reached" error,
   a claimed iOS app, and a missing rate-limit section.
2. **Review:** compared every claim against
   `taskflow-app/specs/api-contract.md` and `feature-notes.md`, and
   listed each mismatch.
3. **Refine:** re-prompted with the actual contract and notes pasted in
   directly, and an explicit instruction not to add anything beyond
   what was given.
4. **Chain:** ran one more prompt across all three refined sections to
   unify tone and heading levels (H2 sections, H3 subsections) without
   touching any technical fact, then re-checked the facts again after
   that rewrite to make sure nothing drifted.
5. **Assemble:** combined the three sections into this document.

---

## Reflection

The hardest part was fact-checking, not writing. The AI's first-pass
output was confident and readable, but wrong in ways that wouldn't be
obvious without cross-checking every field name, status code, and claim
against the actual spec. The scattered notes made this harder still,
since some of them were themselves outdated (the old `pending` status
name, an aspirational iOS app that was never real), so "matching the
notes" wasn't enough. Only the API contract file could be trusted fully.

Iterative prompting made a large difference. The first pass, with no
context, produced a plausible-looking but partly fabricated reference.
Pasting the real contract directly into the prompt, rather than
describing it, eliminated almost all fabrication. The chaining step
mattered less for accuracy and more for consistency: without it, the
three sections read like they were written by different people.
