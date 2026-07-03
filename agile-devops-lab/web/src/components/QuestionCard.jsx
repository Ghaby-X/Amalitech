import { useState } from 'react';

/**
 * Renders a single question with its options.
 * Supports 'multiple-choice' (4 options) and 'true-false' (2 options).
 *
 * Props:
 *   - question:   question object from the question bank
 *   - onSubmit:   called with selectedIndex when user submits
 */
function QuestionCard({ question, onSubmit }) {
  const [selectedIndex, setSelectedIndex] = useState(null);

  const isTrueFalse = question.type === 'true-false';

  function handleSubmit() {
    if (selectedIndex === null) return;
    onSubmit(selectedIndex);
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
        {question.options.map((option, index) => {
          const isSelected = selectedIndex === index;
          return (
            <button
              key={index}
              onClick={() => setSelectedIndex(index)}
              className={`
                w-full px-4 py-3 rounded-xl border-2 text-left font-medium text-base
                cursor-pointer transition-all duration-100
                ${isSelected
                  ? 'border-purple bg-purple-light text-purple shadow-[3px_3px_0px_#7c3aed]'
                  : 'border-black bg-white text-black hover:border-purple hover:text-purple'
                }
              `}
            >
              {!isTrueFalse && (
                <span className="mr-2 font-bold opacity-50">
                  {String.fromCharCode(65 + index)}.
                </span>
              )}
              {option}
            </button>
          );
        })}
      </div>

      {/* Submit button */}
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
    </div>
  );
}

export default QuestionCard;
