import { render, screen } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import Logo from '../components/Logo';

describe('Logo', () => {
  it('renders "Quiz" in black and "Me!!" in purple', () => {
    render(<Logo />);
    expect(screen.getByText('Quiz')).toBeInTheDocument();
    expect(screen.getByText('Me!!')).toBeInTheDocument();
  });

  it('applies large size class by default', () => {
    render(<Logo />);
    const heading = screen.getByRole('heading');
    expect(heading).toHaveClass('text-8xl');
  });

  it('applies small size class when size="small"', () => {
    render(<Logo size="small" />);
    const heading = screen.getByRole('heading');
    expect(heading).toHaveClass('text-4xl');
  });
});
