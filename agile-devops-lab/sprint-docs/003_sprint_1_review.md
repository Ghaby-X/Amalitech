## Sprint 1 Review

**Sprint Goal**: Deliver a working quiz flow where a user can start a quiz, answer multiple choice and true/false questions, and receive instant feedback on their answers.

**Total Planned Story Points**: 7 (SP-1 + SP-3 + SP-3)

**Total Delivered Story Points**: 7

---

### Stories Delivered

#### Story 1 — Quick Start (SP-1)
*As a user, I want to start a quiz with one tap so I can begin answering questions quickly.*

**Acceptance Criteria Met**:
- A Quick Start button is present on the home page
- Clicking Quick Start navigates immediately to the `/quiz` route

**What was built**:
- Home page with QuizMe!! branding — "Quiz" in black, "Me!!" in purple
- Large Quick Start button with hover/active press interaction
- React Router navigation from `/` to `/quiz`
- Global yellow dot-grid background, Fredoka font, violet theme applied across the app

---

#### Story 2 — Multiple Choice / True-False Questions (SP-3)
*As a user, I want to be able to answer either multiple choice or True/False questions so that I can test my knowledge.*

**Acceptance Criteria Met**:
- Each question has either 4 options (multiple choice) or 2 options (True/False)
- Only one option can be selected at a time
- User submits after making a selection

**What was built**:
- `QuestionCard` component supporting both question types
- 20 Africa-focused questions (12 multiple choice, 8 true/false) across Geography, History, Culture, and Science categories
- Single-selection logic — selecting a new option deselects the previous one
- Submit button disabled until an option is selected
- Questions are shuffled on quiz start

---

#### Story 3 — Instant Feedback (SP-3)
*As a user, I want to get instant feedback so that I can know whether my answers are correct or not.*

**Acceptance Criteria Met**:
- Correct answer is highlighted in green
- Wrong selection is highlighted in red

**What was built**:
- On submit: correct option turns green, wrong selection turns red, remaining options fade out
- Submit button disappears after submission — no re-submission possible
- Options are locked after submission — no changing answer after the fact

---

### DevOps Delivery

| Task | Status |
|------|--------|
| React + Vite project scaffolded | ✅ |
| Tailwind CSS v4 configured | ✅ |
| Vitest + Testing Library set up | ✅ |
| 32 unit tests written and passing | ✅ |
| GitHub Actions CI pipeline configured | ✅ |
| CI runs on push/PR to `lab-agile-devops` | ✅ |
| Docker + Docker Compose setup | ✅ |
| Production build passing | ✅ |

---

### Test Summary

| Test File | Tests |
|---|---|
| `Logo.test.jsx` | 3 |
| `Home.test.jsx` | 4 |
| `QuestionCard.test.jsx` | 15 |
| `questions.test.js` | 10 |
| **Total** | **32** |

---

### Demo

- **Home** (`/`): QuizMe!! logo, description, Quick Start button
- **Quiz** (`/quiz`): Shuffled questions rendered one at a time — multiple choice with A/B/C/D labels, true/false in a two-column layout
- **Feedback**: Correct answer highlights green, wrong selection highlights red immediately on submit
- **Navigation**: Back to Home link on the quiz page

---

### Notes

All 3 Sprint 1 stories delivered and all acceptance criteria met. The sprint also established the full DevOps foundation — CI pipeline, test suite, Docker setup, and production build — which will carry forward into Sprint 2 without additional setup cost.
