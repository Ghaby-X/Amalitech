import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { MemoryRouter } from 'react-router-dom';
import Quiz from '../pages/Quiz';

const mockNavigate = vi.fn();
const mockStartNewQuiz = vi.fn();
const mockSubmitAnswer = vi.fn();
const mockNextQuestion = vi.fn();
const mockFinishQuiz = vi.fn();

let mockSession;

vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual('react-router-dom');
  return { ...actual, useNavigate: () => mockNavigate };
});

vi.mock('../hooks/useQuizSession', () => ({
  useQuizSession: () => ({
    session: mockSession,
    startNewQuiz: mockStartNewQuiz,
    submitAnswer: mockSubmitAnswer,
    nextQuestion: mockNextQuestion,
    finishQuiz: mockFinishQuiz,
  }),
}));

const question = {
  id: 1,
  type: 'true-false',
  categories: ['history'],
  question: 'Nelson Mandela served 27 years in prison.',
  options: ['True', 'False'],
  correctIndex: 0,
};

beforeEach(() => {
  vi.clearAllMocks();
  mockSession = {
    questions: [question],
    currentIndex: 0,
    answers: [{ questionId: 1, selectedIndex: 0, isCorrect: true, categories: ['history'] }],
    finished: false,
  };
});

describe('Quiz page — in progress', () => {
  it('renders the live ScoreBoard reflecting current answers', () => {
    render(<MemoryRouter><Quiz /></MemoryRouter>);
    expect(screen.getAllByText('1')).toHaveLength(2); // attempted + correct
    expect(screen.getByText('100%')).toBeInTheDocument();
  });

  it('shows the Finish Quiz button before any answer is submitted', () => {
    render(<MemoryRouter><Quiz /></MemoryRouter>);
    expect(screen.getByRole('button', { name: /finish quiz/i })).toBeInTheDocument();
  });

  it('calls finishQuiz when the Finish Quiz button is clicked', async () => {
    const user = userEvent.setup();
    render(<MemoryRouter><Quiz /></MemoryRouter>);
    await user.click(screen.getByRole('button', { name: /finish quiz/i }));
    expect(mockFinishQuiz).toHaveBeenCalled();
  });

  it('shows the Next Question button after answering a non-final question', async () => {
    const user = userEvent.setup();
    mockSession.questions = [question, { ...question, id: 2 }];
    render(<MemoryRouter><Quiz /></MemoryRouter>);

    await user.click(screen.getByText('True'));
    await user.click(screen.getByRole('button', { name: /submit/i }));

    expect(screen.getByRole('button', { name: /next question/i })).toBeInTheDocument();
  });
});

describe('Quiz page — finished', () => {
  beforeEach(() => {
    mockSession.finished = true;
  });

  it('shows the Quiz Complete message and final ScoreBoard', () => {
    render(<MemoryRouter><Quiz /></MemoryRouter>);
    expect(screen.getByText('Quiz Complete!')).toBeInTheDocument();
    expect(screen.getByText('100%')).toBeInTheDocument();
  });

  it('starts a new quiz when "Start New Quiz" is clicked', async () => {
    const user = userEvent.setup();
    render(<MemoryRouter><Quiz /></MemoryRouter>);
    await user.click(screen.getByRole('button', { name: /start new quiz/i }));
    expect(mockStartNewQuiz).toHaveBeenCalled();
  });
});
