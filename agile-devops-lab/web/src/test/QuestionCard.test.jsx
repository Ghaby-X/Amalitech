import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, it, expect, vi } from 'vitest';
import QuestionCard from '../components/QuestionCard';

const mcQuestion = {
  id: 1,
  type: 'multiple-choice',
  categories: ['history'],
  question: 'Who was the first President of Ghana?',
  options: ['Kofi Annan', 'Jerry Rawlings', 'Kwame Nkrumah', 'John Kufuor'],
  correctIndex: 2,
};

const tfQuestion = {
  id: 2,
  type: 'true-false',
  categories: ['history'],
  question: 'Nelson Mandela served 27 years in prison.',
  options: ['True', 'False'],
  correctIndex: 0,
};

describe('QuestionCard — multiple choice', () => {
  it('renders the question text', () => {
    render(<QuestionCard question={mcQuestion} onSubmit={vi.fn()} />);
    expect(screen.getByText(mcQuestion.question)).toBeInTheDocument();
  });

  it('renders all 4 options', () => {
    render(<QuestionCard question={mcQuestion} onSubmit={vi.fn()} />);
    mcQuestion.options.forEach((opt) => {
      expect(screen.getByText(opt, { exact: false })).toBeInTheDocument();
    });
  });

  it('shows "Multiple Choice" badge', () => {
    render(<QuestionCard question={mcQuestion} onSubmit={vi.fn()} />);
    expect(screen.getByText(/multiple choice/i)).toBeInTheDocument();
  });

  it('submit button is disabled before selection', () => {
    render(<QuestionCard question={mcQuestion} onSubmit={vi.fn()} />);
    expect(screen.getByRole('button', { name: /submit/i })).toBeDisabled();
  });

  it('submit button enables after selecting an option', async () => {
    const user = userEvent.setup();
    render(<QuestionCard question={mcQuestion} onSubmit={vi.fn()} />);
    await user.click(screen.getByText('Kwame Nkrumah', { exact: false }));
    expect(screen.getByRole('button', { name: /submit/i })).not.toBeDisabled();
  });

  it('calls onSubmit with the selected index', async () => {
    const user = userEvent.setup();
    const onSubmit = vi.fn();
    render(<QuestionCard question={mcQuestion} onSubmit={onSubmit} />);
    await user.click(screen.getByText('Kwame Nkrumah', { exact: false }));
    await user.click(screen.getByRole('button', { name: /submit/i }));
    expect(onSubmit).toHaveBeenCalledWith(2, true);
  });

  it('only allows one option to be selected at a time', async () => {
    const user = userEvent.setup();
    const onSubmit = vi.fn();
    render(<QuestionCard question={mcQuestion} onSubmit={onSubmit} />);
    await user.click(screen.getByText('Kofi Annan', { exact: false }));
    await user.click(screen.getByText('Kwame Nkrumah', { exact: false }));
    await user.click(screen.getByRole('button', { name: /submit/i }));
    // Last selection wins — should submit index 2 (correct)
    expect(onSubmit).toHaveBeenCalledWith(2, true);
    expect(onSubmit).toHaveBeenCalledTimes(1);
  });
});

describe('QuestionCard — true/false', () => {
  it('renders the question text', () => {
    render(<QuestionCard question={tfQuestion} onSubmit={vi.fn()} />);
    expect(screen.getByText(tfQuestion.question)).toBeInTheDocument();
  });

  it('renders True and False options', () => {
    render(<QuestionCard question={tfQuestion} onSubmit={vi.fn()} />);
    expect(screen.getByText('True')).toBeInTheDocument();
    expect(screen.getByText('False')).toBeInTheDocument();
  });

  it('shows "True / False" badge', () => {
    render(<QuestionCard question={tfQuestion} onSubmit={vi.fn()} />);
    expect(screen.getByText(/true \/ false/i)).toBeInTheDocument();
  });

  it('calls onSubmit with correct index for true/false', async () => {
    const user = userEvent.setup();
    const onSubmit = vi.fn();
    render(<QuestionCard question={tfQuestion} onSubmit={onSubmit} />);
    await user.click(screen.getByText('True'));
    await user.click(screen.getByRole('button', { name: /submit/i }));
    expect(onSubmit).toHaveBeenCalledWith(0, true);
  });
});

describe('QuestionCard — instant feedback', () => {
  it('hides submit button after submission', async () => {
    const user = userEvent.setup();
    render(<QuestionCard question={mcQuestion} onSubmit={vi.fn()} />);
    await user.click(screen.getByText('Kwame Nkrumah', { exact: false }));
    await user.click(screen.getByRole('button', { name: /submit/i }));
    expect(screen.queryByRole('button', { name: /submit/i })).not.toBeInTheDocument();
  });

  it('calls onSubmit with true when correct answer is selected', async () => {
    const user = userEvent.setup();
    const onSubmit = vi.fn();
    render(<QuestionCard question={mcQuestion} onSubmit={onSubmit} />);
    await user.click(screen.getByText('Kwame Nkrumah', { exact: false }));
    await user.click(screen.getByRole('button', { name: /submit/i }));
    expect(onSubmit).toHaveBeenCalledWith(2, true);
  });

  it('calls onSubmit with false when wrong answer is selected', async () => {
    const user = userEvent.setup();
    const onSubmit = vi.fn();
    render(<QuestionCard question={mcQuestion} onSubmit={onSubmit} />);
    await user.click(screen.getByText('Kofi Annan', { exact: false }));
    await user.click(screen.getByRole('button', { name: /submit/i }));
    expect(onSubmit).toHaveBeenCalledWith(0, false);
  });

  it('does not allow changing selection after submission', async () => {
    const user = userEvent.setup();
    const onSubmit = vi.fn();
    render(<QuestionCard question={mcQuestion} onSubmit={onSubmit} />);
    await user.click(screen.getByText('Kofi Annan', { exact: false }));
    await user.click(screen.getByRole('button', { name: /submit/i }));
    // Try clicking another option after submit — onSubmit should still only be called once
    await user.click(screen.getByText('Kwame Nkrumah', { exact: false }));
    expect(onSubmit).toHaveBeenCalledTimes(1);
  });
});
