## Sprint 1 Retrospective

---

### What Went Well

- **All 3 stories delivered**: The sprint goal was fully met; 7/7 story points delivered
- **Strong test coverage from the start**: 32 unit tests written alongside features, not bolted on at the end. Tests cover data validation, component rendering, interaction logic, and routing
- **DevOps foundation**: CI pipeline, Docker setup, and production build are all working; Sprint 2 can focus purely on features
- **Question bank is meaningful**: 20 questions across Geography, History, Culture, and Science give the app a clear identity and purpose
- **Component design is clean**: `QuestionCard` handles both question types with a single component, making it easy to extend for Sprint 2 features

---

### What Didn't Go Well

- **Tooling decisions slowed early progress**: Switching from CSS modules to Tailwind mid-sprint and resolving Tailwind v4 compatibility issues (custom color utilities, preflight conflicts) consumed time that could have gone into features
- **CI pipeline debugging was costly**: Multiple iterations were needed to resolve Node version deprecation, cache path errors, and branch checkout behaviour before the pipeline ran cleanly
- **Button styling required many iterations**: Small visual adjustments (brightness, sizing, spacing) went back and forth several times; clearer design direction upfront would have avoided this
- **No "end of quiz" state handled**: Reaching the last question leaves the user in a dead end. This was a known gap deferred to Sprint 2 but should have been flagged as a risk earlier

---

### Improvements for Sprint 2

1. **Agree on visual design decisions before implementation**: Button colours, spacing, and component appearance should be decided once and applied; not adjusted iteratively during development. A quick sketch or description upfront saves multiple back-and-forth cycles.

2. **Identify edge cases before starting a story**: The end-of-quiz state was only noticed after Story 2 was already built. In Sprint 2, each story will be reviewed for edge cases (empty states, boundary conditions) before coding starts, so nothing gets deferred unexpectedly.

---

### Sprint 2 Priorities

- Story 4: Next question navigation (show next button after feedback, advance to next question)
- Story 5: Score tracking (attempted, correct, wrong, percentage — updates after each submission)
- Story 7: Finish quiz (end session, prompt to restart)
- Story 8: Results screen (general stats + category breakdown)
