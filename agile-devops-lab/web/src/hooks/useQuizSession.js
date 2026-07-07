import { useState, useCallback } from 'react';
import { getShuffledQuestions } from '../data/questions';

const STORAGE_KEY = 'quizme_session';

/**
 * Reads the current session from localStorage.
 * Returns null if no session exists.
 */
function loadSession() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    return raw ? JSON.parse(raw) : null;
  } catch {
    console.error('[QuizMe] Failed to load session from localStorage');
    return null;
  }
}

/**
 * Persists the session object to localStorage.
 */
function saveSession(session) {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(session));
  } catch {
    console.error('[QuizMe] Failed to save session to localStorage');
  }
}

/**
 * Creates a fresh session object with shuffled questions.
 */
function createSession() {
  return {
    questions: getShuffledQuestions(),
    currentIndex: 0,
    answers: [],
    finished: false,
  };
}

/**
 * useQuizSession — manages the full quiz session lifecycle.
 *
 * Initialises from localStorage on mount so state survives page refresh.
 *
 * Returns:
 *   - session:       current session object
 *   - startNewQuiz:  wipes state and starts a fresh session
 *   - submitAnswer:  records an answer and advances internal state
 *   - nextQuestion:  advances to the next question index
 *   - finishQuiz:    marks the session as finished
 */
export function useQuizSession() {
  const [session, setSession] = useState(() => {
    const existing = loadSession();
    if (existing) {
      console.log(`[QuizMe] Session resumed — question ${existing.currentIndex + 1}/${existing.questions.length}`);
      return existing;
    }
    return null;
  });

  const startNewQuiz = useCallback(() => {
    const fresh = createSession();
    saveSession(fresh);
    setSession(fresh);
    console.log('[QuizMe] New quiz session started');
  }, []);

  const submitAnswer = useCallback((questionId, selectedIndex, isCorrect, categories) => {
    setSession((prev) => {
      const updated = {
        ...prev,
        answers: [
          ...prev.answers,
          { questionId, selectedIndex, isCorrect, categories },
        ],
      };
      saveSession(updated);
      console.log(`[QuizMe] Answer recorded — questionId: ${questionId}, correct: ${isCorrect}`);
      return updated;
    });
  }, []);

  const nextQuestion = useCallback(() => {
    setSession((prev) => {
      const updated = { ...prev, currentIndex: prev.currentIndex + 1 };
      saveSession(updated);
      console.log(`[QuizMe] Advancing to question ${updated.currentIndex + 1}`);
      return updated;
    });
  }, []);

  const finishQuiz = useCallback(() => {
    setSession((prev) => {
      const updated = { ...prev, finished: true };
      saveSession(updated);
      console.log('[QuizMe] Quiz finished');
      return updated;
    });
  }, []);

  return { session, startNewQuiz, submitAnswer, nextQuestion, finishQuiz };
}
