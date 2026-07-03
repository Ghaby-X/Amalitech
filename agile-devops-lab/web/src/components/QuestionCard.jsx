import { useState } from 'react';
import { isCorrectAnswer } from '../data/questions';

/**
 * Renders a single question with its options and instant feedback.
 * Supports 'multiple-choice' (4 options) and 'true-false' (2 options).
 *
 * Props:
 *   - question:   question object from the question bank
 *   - onSubmit:   called with (selectedIndex, isCorrect) when user submits
 */
function QuestionCard({ question, onSubmit }) {
  const [selectedIndex, setSelectedIndex] = useState(null);
  const [submitted, setSubmitted] = useState(false);

  const isTrueFalse = question.type === 'true-false';

  function handleSubmit() {
    if (selectedIndex === null || submitted) return;
    setSubmitted(true);
    onSubmit(selectedIndex, isCorrectAnswer(question, selectedIndex));
  }

  function getOptionStyle(index) {
    // Before submission — normal selection styling
    if (!submitted) {
      const isSelected = selectedIndex === index;
      return isSelected
        ? 'border-purple bg-purple-light text-purple shadow-[3px_3px_0px_#7c3aed] cursor-pointer'
        : 'border-black bg-white text-black hover:border-purple hover:text-purple cursor-pointer';
    }

    // After submission — feedback colours
    const isCorrect = index === question.correctIndex;
    const isWrongSelection = index === selectedIndex && !isCorrect;

    if (isCorrect) {
      return 'border-green-600 bg-green-100 text-green-800 shadow-[3px_3px_0px_#16a34a] cursor-default';
    }
    if (isWrongSelection) {
      return 'border-red-500 bg-red-100 text-red-700 shadow-[3px_3px_0px_#ef4444] cursor-default';
    }
    return 'border-black bg-white text-black opacity-40 cursor-default';
  }

  return (
    <div className="w-full max-w-xl bg-white border-3 border-black rounded-2xl shadow-[6px_6px_0px_#1a1a1a] p-6 flex flex-col gap-6">

      {/* Question type badge + text */}
      <div className="flex flex-col gap-2">
        <span className="text-xs font-semibold uppercase tracking-widest text-purple opacity-70">
          {isTrueFalse ? 'True / False' : 'Multiple Choice'}
        </span>
        <p className="text-xl font-semibold text-black leading-snug">
          {question.question}
        </p>
      </div>

      {/* Options */}
      <div className={`grid gap-3 ${isTrueFalse ? 'grid-cols-2' : 'grid-cols-1'}`}>
        {question.options.map((option, index) => (
          <button
            key={index}
            onClick={() => !submitted && setSelectedIndex(index)}
            disabled={submitted}
            className={`
              w-full px-4 py-3 rounded-xl border-2 text-left font-medium text-base
              transition-all duration-150
              ${getOptionStyle(index)}
            `}
          >
            {!isTrueFalse && (
              <span className="mr-2 font-bold opacity-50">
                {String.fromCharCode(65 + index)}.
              </span>
            )}
            {option}
          </button>
        ))}
      </div>

      {/* Submit button — hidden after submission */}
      {!submitted && (
        <button
          onClick={handleSubmit}
          disabled={selectedIndex === null}
          className="w-full py-3 rounded-xl font-semibold text-lg text-white
                     transition-all duration-100
                     disabled:cursor-not-allowed
                     shadow-[3px_3px_0px_#3b0764]
                     hover:enabled:shadow-[5px_5px_0px_#3b0764] hover:enabled:-translate-y-0.5
                     active:enabled:shadow-[1px_1px_0px_#3b0764] active:enabled:translate-y-0.5"
          style={{ backgroundColor: '#7c3aed', opacity: selectedIndex === null ? 0.45 : 0.85 }}
        >
          Submit
        </button>
      )}
    </div>
  );
}

export default QuestionCard;
