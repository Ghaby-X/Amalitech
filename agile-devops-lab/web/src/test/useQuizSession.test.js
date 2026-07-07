import { renderHook, act } from '@testing-library/react';
import { describe, it, expect, beforeEach } from 'vitest';
import { useQuizSession } from '../hooks/useQuizSession';

beforeEach(() => {
  localStorage.clear();
});

describe('useQuizSession', () => {
  it('returns null session when no session exists', () => {
    const { result } = renderHook(() => useQuizSession());
    expect(result.current.session).toBeNull();
  });

  it('startNewQuiz creates a session with shuffled questions', () => {
    const { result } = renderHook(() => useQuizSession());
    act(() => result.current.startNewQuiz());

    const { session } = result.current;
    expect(session).not.toBeNull();
    expect(session.questions.length).toBeGreaterThan(0);
    expect(session.currentIndex).toBe(0);
    expect(session.answers).toHaveLength(0);
    expect(session.finished).toBe(false);
  });

  it('startNewQuiz persists session to localStorage', () => {
    const { result } = renderHook(() => useQuizSession());
    act(() => result.current.startNewQuiz());

    const stored = JSON.parse(localStorage.getItem('quizme_session'));
    expect(stored).not.toBeNull();
    expect(stored.currentIndex).toBe(0);
  });

  it('submitAnswer records the answer in session', () => {
    const { result } = renderHook(() => useQuizSession());
    act(() => result.current.startNewQuiz());
    act(() => result.current.submitAnswer(1, 2, true, ['history']));

    const { answers } = result.current.session;
    expect(answers).toHaveLength(1);
    expect(answers[0]).toEqual({ questionId: 1, selectedIndex: 2, isCorrect: true, categories: ['history'] });
  });

  it('nextQuestion increments currentIndex', () => {
    const { result } = renderHook(() => useQuizSession());
    act(() => result.current.startNewQuiz());
    act(() => result.current.nextQuestion());

    expect(result.current.session.currentIndex).toBe(1);
  });

  it('nextQuestion persists updated index to localStorage', () => {
    const { result } = renderHook(() => useQuizSession());
    act(() => result.current.startNewQuiz());
    act(() => result.current.nextQuestion());

    const stored = JSON.parse(localStorage.getItem('quizme_session'));
    expect(stored.currentIndex).toBe(1);
  });

  it('finishQuiz sets finished to true', () => {
    const { result } = renderHook(() => useQuizSession());
    act(() => result.current.startNewQuiz());
    act(() => result.current.finishQuiz());

    expect(result.current.session.finished).toBe(true);
  });

  it('finishQuiz does not clear the session', () => {
    const { result } = renderHook(() => useQuizSession());
    act(() => result.current.startNewQuiz());
    act(() => result.current.submitAnswer(1, 0, false, ['science']));
    act(() => result.current.finishQuiz());

    expect(result.current.session.answers).toHaveLength(1);
    expect(localStorage.getItem('quizme_session')).not.toBeNull();
  });

  it('resumes existing session from localStorage on mount', () => {
    const existingSession = {
      questions: [{ id: 99, type: 'true-false', categories: ['science'], question: 'Test?', options: ['True', 'False'], correctIndex: 0 }],
      currentIndex: 0,
      answers: [{ questionId: 99, selectedIndex: 0, isCorrect: true, categories: ['science'] }],
      finished: false,
    };
    localStorage.setItem('quizme_session', JSON.stringify(existingSession));

    const { result } = renderHook(() => useQuizSession());
    expect(result.current.session.currentIndex).toBe(0);
    expect(result.current.session.answers).toHaveLength(1);
  });
});
