import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, it, expect, vi } from 'vitest';
import { MemoryRouter } from 'react-router-dom';
import Home from '../pages/Home';

// Mock useNavigate
const mockNavigate = vi.fn();
vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual('react-router-dom');
  return { ...actual, useNavigate: () => mockNavigate };
});

describe('Home page', () => {
  it('renders the QuizMe logo', () => {
    render(<MemoryRouter><Home /></MemoryRouter>);
    expect(screen.getByText('Quiz')).toBeInTheDocument();
    expect(screen.getByText('Me!!')).toBeInTheDocument();
  });

  it('renders the description text', () => {
    render(<MemoryRouter><Home /></MemoryRouter>);
    expect(
      screen.getByText(/test your general knowledge/i)
    ).toBeInTheDocument();
  });

  it('renders the Quick Start button', () => {
    render(<MemoryRouter><Home /></MemoryRouter>);
    expect(screen.getByRole('button', { name: /quick start/i })).toBeInTheDocument();
  });

  it('navigates to /quiz when Quick Start is clicked', async () => {
    const user = userEvent.setup();
    render(<MemoryRouter><Home /></MemoryRouter>);
    await user.click(screen.getByRole('button', { name: /quick start/i }));
    expect(mockNavigate).toHaveBeenCalledWith('/quiz');
  });
});
