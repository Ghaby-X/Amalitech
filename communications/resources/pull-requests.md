# Pull Request Guidelines

A pull request is more than a mechanism for merging code. It is one of the most important communication tools a team has. These guidelines cover how to write, size, review, and respond to PRs in a way that benefits the whole team.

---

### 1. Why PRs Matter

**Code review as a communication tool, not just a gate**

PRs are where the team shares context, catches mistakes, and learns from each other. A review is a conversation about the code, not a judgment on the person who wrote it.

**Impact on team velocity, code quality, and knowledge sharing**

- Well-written PRs get reviewed faster, unblocking work sooner.
- Reviewers catch bugs, edge cases, and design issues before they reach production.
- PRs serve as a living record of *why* changes were made, which helps future contributors understand the codebase.

---

### 2. Before Opening a PR

**Keep PRs small and focused - one logical change**

A PR should do one thing. Mixing unrelated changes makes it harder to review, harder to revert if something breaks, and harder to understand in the future.

**Self-review your diff first**

Before requesting review, read through your own diff. Look for debug code left in, typos, unintended changes, or anything you'd want a reviewer to flag. Catching these yourself saves everyone time.

**Run tests and linters locally before pushing**

Don't rely on CI to catch things you could have caught yourself. A green CI should be a confirmation, not a first check.

**Rebase or clean up commit history if needed**

A clean commit history makes it easier to review the PR incrementally and to understand the change history later. Squash WIP commits and write meaningful commit messages before opening for review.

---

### 3. Writing a Good PR Description

A clear description is the single most effective thing you can do to speed up your review.

**Clear title - what changed, not just "fix bug"**

| Avoid | Prefer |
|---|---|
| `fix bug` | `Fix null pointer when user has no profile photo` |
| `updates` | `Add pagination to the /users endpoint` |
| `wip` | `Draft: Refactor auth middleware to support OAuth` |

**Context - what problem this solves and why**

Explain the background. What was broken, missing, or needed? Why is this the right approach? Reviewers shouldn't have to dig through Slack or Jira to understand why a PR exists.

**What changed and how**

Give a brief, high-level summary of the approach. Not a line-by-line narration, just enough that the reviewer knows what to expect before reading the diff.

**How to test or verify it**

Tell the reviewer how to confirm the change works. Include steps, commands, or environments where relevant.

**Screenshots or GIFs for UI changes**

Before/after screenshots remove all ambiguity for visual changes and make reviews significantly faster.

**Link related issues or tickets**

Connect the PR to its source of truth. Use keywords like `Closes #123` or `Fixes #456` to automatically close issues on merge where supported.

---

### 4. Sizing and Scope

**Why small PRs get reviewed faster and more thoroughly**

The larger a PR, the harder it is to hold in your head at once. Reviewers are more likely to skim a 600-line diff than a 60-line one. Smaller PRs mean fewer missed issues and faster turnaround.

**How to split large features into a sequence of PRs**

- Start with the data model or schema change.
- Follow with backend logic, then API layer, then UI - each as its own PR.
- Use a tracking issue or project board to link the sequence together.
- If the feature isn't ready to expose yet, hide it behind a feature flag rather than holding the code in one giant branch.

---

### 5. Being Review-Friendly

**Descriptive commit messages**

Each commit should explain the intent of that specific change. `Fix tests` is less useful than `Fix test helper to handle empty response body`.

**Comment on your own PR to explain tricky parts**

If you made a non-obvious decision, leave a comment explaining it before a reviewer has to ask. This saves a round-trip and shows you've thought it through.

**Avoid mixing unrelated changes**

Don't bundle formatting-only diffs with logic changes. It buries the meaningful changes and makes it hard to review or revert selectively. If you want to clean up formatting, do it in a separate PR.

---

### 6. Responding to Review Feedback

**Don't take feedback personally - treat it as collaborative**

Feedback is about the code, not about you. The goal of every reviewer is to ship better software together.

**Respond to every comment**

Even a short "done" or "fixed in latest commit" signals that you've seen and addressed the feedback. If you disagree, explain your reasoning rather than silently not making the change.

**Re-request review after making changes**

Once you've addressed feedback, re-request review from the relevant reviewers. Don't leave them guessing whether the PR is ready for another look.

---

### 7. Common Anti-Patterns

| Anti-pattern | Why it's a problem |
|---|---|
| Giant PRs | Nobody reviews them carefully; high risk of important issues being missed |
| No description ("fixed stuff") | Reviewers have no context; makes the git history useless |
| Force-pushing over active review comments without warning | Destroys the review thread history and confuses reviewers |
| Ignoring CI failures | Signals low confidence in the change and wastes reviewers' time |

---

### 8. Reviewing Others' PRs Well

**Be kind but honest**

Phrase feedback as suggestions or questions, not commands or criticisms. Assume the author had a reason for their choice and ask about it if it's unclear.

**Distinguish blocking issues from nitpicks**

Be explicit about the weight of your comments. A blocking issue is something that must be addressed before the PR merges. A nitpick is a preference or style suggestion that the author can take or leave. Labelling them removes ambiguity.

```
// Blocking: this will cause a race condition under concurrent requests
// Nit: variable name could be more descriptive - up to you
```

**Approve with comments when appropriate**

If your only remaining feedback is stylistic or optional, approve the PR and leave the comments anyway. Blocking a merge on a nitpick delays the team without improving the code in any meaningful way.
