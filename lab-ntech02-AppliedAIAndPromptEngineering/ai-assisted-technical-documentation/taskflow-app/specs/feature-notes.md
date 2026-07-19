# Scattered TaskFlow notes (raw, unedited)

Pasted together from developer notes, old Slack threads, and a wiki page
nobody has touched since last year. This is the messy input the
scenario describes, not a source of truth. Where this conflicts with
`api-contract.md`, the contract wins.

- status values are `todo` / `in_progress` / `done`. NOTE: we renamed
  `pending` to `todo` back in March. The old onboarding slide deck and
  at least one wiki page still say `pending`, that's stale, ignore it.
- task priority field (`low`/`medium`/`high`) was designed but never
  shipped. Don't document it as if it exists.
- due dates are optional, `YYYY-MM-DD`, no time component.
- QA flagged that DELETE seemed to "return the deleted task" in one
  test run. Checked with backend: it doesn't, response body is empty
  (204). QA's test script was reading a stale cached response.
- login rate limit: someone's notes say 20 requests per 15 minutes,
  that was the original number before the security review. It's been
  10 per 15 minutes since then.
- email verification before creating a task: this existed briefly in a
  feature branch, never shipped, was fully removed. If you see it
  mentioned anywhere, it's wrong.
- there is no mobile app. A slide deck from a planning meeting said
  "iOS app coming soon", that was aspirational, not a commitment, and
  isn't on the roadmap. Web only for now.
- tasks are private to the user who created them, no sharing or teams
  feature yet (frequently requested, not built).
