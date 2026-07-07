/**
 * Displays live quiz progress: attempted, correct, wrong, and percentage.
 *
 * Props:
 *   - answers: array of { isCorrect } objects from the current session
 */
function ScoreBoard({ answers }) {
  const attempted = answers.length;
  const correct = answers.filter((answer) => answer.isCorrect).length;
  const wrong = attempted - correct;
  const percentage = attempted > 0 ? Math.round((correct / attempted) * 100) : 0;

  return (
    <div className="flex items-center gap-5 px-6 py-3 rounded-2xl border-2 border-black bg-white shadow-[3px_3px_0px_#1a1a1a] text-sm font-semibold">
      <span className="text-black">
        Attempted: <span className="font-bold">{attempted}</span>
      </span>
      <span className="text-green-700">
        Correct: <span className="font-bold">{correct}</span>
      </span>
      <span className="text-red-600">
        Wrong: <span className="font-bold">{wrong}</span>
      </span>
      <span className="text-purple">
        <span className="font-bold">{percentage}%</span>
      </span>
    </div>
  );
}

export default ScoreBoard;
