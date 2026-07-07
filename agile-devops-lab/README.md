# QuizMe

A simple flashcard-style quiz app for learning general knowledge and cultural
awareness through quick, interactive quizzes.

## Features

- One-tap quick start — no sign-up, jump straight into a quiz
- Multiple-choice and true/false questions
- Instant feedback on each answer (correct/incorrect highlighting)
- Live score tracking (attempted, correct, wrong, percentage) as you go
- Finish the quiz at any point and get a final score summary
- Session persists to `localStorage`, so a page refresh resumes where you left off

## Tech stack

- [React 19](https://react.dev/) + [React Router](https://reactrouter.com/)
- [Vite](https://vitejs.dev/) for dev server and builds
- [Tailwind CSS 4](https://tailwindcss.com/)
- [Vitest](https://vitest.dev/) + [Testing Library](https://testing-library.com/) for unit tests
- [oxlint](https://oxc.rs/docs/guide/usage/linter.html) for linting

## Getting started

The app lives in [`web/`](web).

```bash
cd web
npm install
npm run dev
```

The app runs at `http://localhost:5173`.

## Scripts

Run these from the `web/` directory.

| Command                 | Description                         |
| ------------------------ | ------------------------------------ |
| `npm run dev`            | Start the Vite dev server            |
| `npm run build`          | Build for production                 |
| `npm run preview`        | Preview the production build locally |
| `npm run lint`           | Lint the codebase with oxlint        |
| `npm test`               | Run the test suite once              |
| `npm run test:watch`     | Run tests in watch mode              |
| `npm run test:coverage`  | Run tests with coverage report       |

## Project structure

```
web/
  src/
    components/   Reusable UI pieces (QuestionCard, ScoreBoard, Logo)
    pages/        Route-level pages (Home, Quiz)
    hooks/        Quiz session state management (useQuizSession)
    data/         Question bank and helpers
    test/         Unit tests
  Dockerfile

sprint-docs/       Sprint planning, backlog, and retrospectives
docker-compose.yml
```

## Running with Docker

A production build can be served via Docker/nginx from the repo root:

```bash
docker compose up --build
```

This builds the app and serves it at `http://localhost:5173` (mapped to
container port 80).

## Project docs

Sprint planning, backlog, and retrospectives live in [`sprint-docs/`](sprint-docs).
