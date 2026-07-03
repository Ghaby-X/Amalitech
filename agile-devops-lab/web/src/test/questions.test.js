import { describe, it, expect } from 'vitest';
import { questions, getShuffledQuestions, isCorrectAnswer } from '../data/questions';

describe('questions data', () => {
  it('contains at least 15 questions', () => {
    expect(questions.length).toBeGreaterThanOrEqual(15);
  });

  it('every question has required fields', () => {
    questions.forEach((q) => {
      expect(q).toHaveProperty('id');
      expect(q).toHaveProperty('type');
      expect(q).toHaveProperty('categories');
      expect(q).toHaveProperty('question');
      expect(q).toHaveProperty('options');
      expect(q).toHaveProperty('correctIndex');
    });
  });

  it('multiple-choice questions have exactly 4 options', () => {
    const mc = questions.filter((q) => q.type === 'multiple-choice');
    mc.forEach((q) => expect(q.options).toHaveLength(4));
  });

  it('true-false questions have exactly 2 options', () => {
    const tf = questions.filter((q) => q.type === 'true-false');
    tf.forEach((q) => expect(q.options).toHaveLength(2));
  });

  it('correctIndex is within bounds of options array', () => {
    questions.forEach((q) => {
      expect(q.correctIndex).toBeGreaterThanOrEqual(0);
      expect(q.correctIndex).toBeLessThan(q.options.length);
    });
  });

  it('categories is an array with at least one entry', () => {
    questions.forEach((q) => {
      expect(Array.isArray(q.categories)).toBe(true);
      expect(q.categories.length).toBeGreaterThanOrEqual(1);
    });
  });
});

describe('getShuffledQuestions', () => {
  it('returns the same number of questions', () => {
    expect(getShuffledQuestions()).toHaveLength(questions.length);
  });

  it('returns a new array, not the original', () => {
    expect(getShuffledQuestions()).not.toBe(questions);
  });
});

describe('isCorrectAnswer', () => {
  const mockQuestion = { correctIndex: 2 };

  it('returns true when selected index matches correctIndex', () => {
    expect(isCorrectAnswer(mockQuestion, 2)).toBe(true);
  });

  it('returns false when selected index does not match', () => {
    expect(isCorrectAnswer(mockQuestion, 0)).toBe(false);
    expect(isCorrectAnswer(mockQuestion, 1)).toBe(false);
    expect(isCorrectAnswer(mockQuestion, 3)).toBe(false);
  });
});
