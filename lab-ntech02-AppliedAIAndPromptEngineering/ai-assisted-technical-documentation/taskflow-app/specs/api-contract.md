# TaskFlow API contract (internal spec, source of truth)

This is the authoritative contract for TaskFlow's REST API. It is
intentionally terse, the kind of thing that ends up half-buried in a
wiki page. Any generated documentation must match this exactly, not the
older Slack-thread terminology some team members still use (see
`feature-notes.md`).

## Auth

All endpoints under `/api/tasks` require `Authorization: Bearer <token>`.
Tokens are issued by `/api/auth/login` and expire after 24 hours.

Any `/api/tasks` request without a valid token gets one of two 401
responses:
| Status | Body | When |
| --- | --- | --- |
| 401 | `{ "error": "UNAUTHORIZED", "message": "Missing or invalid authentication token." }` | No token, or token is malformed/unrecognized |
| 401 | `{ "error": "TOKEN_EXPIRED", "message": "Your session has expired. Please log in again." }` | Token is well-formed but past its 24-hour expiry |

## Endpoints

### POST /api/auth/login

Request body:
```json
{ "email": "string", "password": "string" }
```

Responses:
| Status | Body | When |
| --- | --- | --- |
| 200 | `{ "token": "string", "user": { "id": "string", "name": "string", "email": "string" } }` | Credentials valid |
| 400 | `{ "error": "VALIDATION_ERROR", "message": "Email and password are required." }` | Missing email or password |
| 401 | `{ "error": "INVALID_CREDENTIALS", "message": "Email or password is incorrect." }` | Credentials invalid |

### GET /api/tasks

Query params: `status` (optional, one of `todo`, `in_progress`, `done`).

Responses:
| Status | Body | When |
| --- | --- | --- |
| 200 | `{ "tasks": [ { "id", "title", "description", "status", "dueDate", "createdAt" } ] }` | Always (empty array if no tasks) |
| 401 | `{ "error": "UNAUTHORIZED", "message": "Missing or invalid authentication token." }` | Missing/invalid token |

### POST /api/tasks

Request body:
```json
{ "title": "string (required)", "description": "string (optional)", "dueDate": "ISO date string (optional)" }
```

Responses:
| Status | Body | When |
| --- | --- | --- |
| 201 | `{ "task": { "id", "title", "description", "status", "dueDate", "createdAt" } }` | Created. New tasks always start with `status: "todo"` |
| 400 | `{ "error": "VALIDATION_ERROR", "message": "Title is required." }` | Missing title |
| 401 | `{ "error": "UNAUTHORIZED", "message": "Missing or invalid authentication token." }` | Missing/invalid token |

### PATCH /api/tasks/{id}

Request body: any subset of `{ "title", "description", "status", "dueDate" }`.
`status` must be one of `todo`, `in_progress`, `done`.

Responses:
| Status | Body | When |
| --- | --- | --- |
| 200 | `{ "task": { ...updated fields } }` | Updated |
| 400 | `{ "error": "VALIDATION_ERROR", "message": "Status must be one of: todo, in_progress, done." }` | Invalid status value |
| 404 | `{ "error": "TASK_NOT_FOUND", "message": "No task with that ID exists for this user." }` | Task doesn't exist or belongs to another user |

### DELETE /api/tasks/{id}

Responses:
| Status | Body | When |
| --- | --- | --- |
| 204 | (empty) | Deleted |
| 404 | `{ "error": "TASK_NOT_FOUND", "message": "No task with that ID exists for this user." }` | Task doesn't exist or belongs to another user |

## Rate limiting

`/api/auth/login` is limited to 10 requests per 15 minutes per IP address.

Responses:
| Status | Body | When |
| --- | --- | --- |
| 429 | `{ "error": "RATE_LIMITED", "message": "Too many login attempts. Try again later." }` | Limit exceeded |
