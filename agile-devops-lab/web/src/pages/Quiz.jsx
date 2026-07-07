import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import Logo from '../components/Logo';
import QuestionCard from '../components/QuestionCard';
import ScoreBoard from '../components/ScoreBoard';
import { useQuizSession } from '../hooks/useQuizSession';

function Quiz() {
  const navigate = useNavigate();
  const { session, startNewQuiz, submitAnswer, nextQuestion, finishQuiz } = useQuizSession();
  const [answered, setAnswered] = useState(false);

  if (!session) {
    return (
      <div className="flex flex-col items-center gap-6 p-8">
        <Logo size="small" />
        <p className="text-lg text-black/60">No active quiz session.</p>
        <button
          onClick={() => navigate('/')}
          className="text-purple font-medium underline underline-offset-4 cursor-pointer"
        >
          ← Back to Home
        </button>
      </div>
    );
  }

  const { questions, currentIndex, answers } = session;
  const currentQuestion = questions[currentIndex];
  const isLastQuestion = currentIndex === questions.length - 1;

  function handleSubmit(selectedIndex, isCorrect) {
    submitAnswer(currentQuestion.id, selectedIndex, isCorrect, currentQuestion.categories);
    setAnswered(true);
  }

  function handleNext() {
    nextQuestion();
    setAnswered(false);
  }

  return (
    <div className="flex flex-col items-center gap-8 p-8 w-full">
      <Logo size="small" />

      <ScoreBoard answers={answers} />

      <QuestionCard
        key={currentQuestion.id}
        question={currentQuestion}
        onSubmit={handleSubmit}
      />

      {/* Next / Finish — only visible after answering */}
      {answered && (
        isLastQuestion ? (
          <button
            onClick={handleFinish}
            className="px-10 py-3 rounded-full font-semibold text-lg text-white
                       shadow-[4px_4px_0px_#3b0764] cursor-pointer
                       hover:-translate-y-0.5 hover:shadow-[6px_6px_0px_#3b0764]
                       active:translate-y-0.5 active:shadow-[2px_2px_0px_#3b0764]
                       transition-all duration-100"
            style={{ backgroundColor: '#7c3aed', opacity: 0.85 }}
          >
            Finish Quiz
          </button>
        ) : (
          <button
            onClick={handleNext}
            className="px-10 py-3 rounded-full font-semibold text-lg text-white
                       shadow-[4px_4px_0px_#3b0764] cursor-pointer
                       hover:-translate-y-0.5 hover:shadow-[6px_6px_0px_#3b0764]
                       active:translate-y-0.5 active:shadow-[2px_2px_0px_#3b0764]
                       transition-all duration-100"
            style={{ backgroundColor: '#7c3aed', opacity: 0.85 }}
          >
            Next Question →
          </button>
        )
      )}

      <button
        onClick={() => navigate('/')}
        className="text-purple font-medium underline underline-offset-4 cursor-pointer hover:text-purple-dark transition-colors"
      >
        ← Back to Home
      </button>
    </div>
  );
}

export default Quiz;
