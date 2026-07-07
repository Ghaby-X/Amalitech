import { render, screen } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import ScoreBoard from '../components/ScoreBoard';

describe('ScoreBoard', () => {
  it('shows all zeros when no questions have been attempted', () => {
    render(<ScoreBoard answers={[]} />);
    expect(screen.getAllByText('0')).toHaveLength(3); // attempted, correct, wrong
    expect(screen.getByText('0%')).toBeInTheDocument();
  });

  it('counts attempted, correct, and wrong answers', () => {
    const answers = [
      { isCorrect: true },
      { isCorrect: false },
      { isCorrect: true },
    ];
    render(<ScoreBoard answers={answers} />);

    expect(screen.getByText('3')).toBeInTheDocument(); // attempted
    expect(screen.getAllByText('2')).toHaveLength(1); // correct
    expect(screen.getByText('1')).toBeInTheDocument(); // wrong
  });

  it('calculates the correct percentage, rounded to the nearest whole number', () => {
    const answers = [
      { isCorrect: true },
      { isCorrect: true },
      { isCorrect: false },
    ];
    render(<ScoreBoard answers={answers} />);

    expect(screen.getByText('67%')).toBeInTheDocument();
  });

  it('updates correctly when every answer is wrong', () => {
    const answers = [{ isCorrect: false }, { isCorrect: false }];
    render(<ScoreBoard answers={answers} />);

    expect(screen.getByText('0%')).toBeInTheDocument();
  });
});
