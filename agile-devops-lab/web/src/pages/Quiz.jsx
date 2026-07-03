import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import Logo from '../components/Logo';
import QuestionCard from '../components/QuestionCard';
import { getShuffledQuestions } from '../data/questions';

function Quiz() {
  const navigate = useNavigate();
  const [questions] = useState(() => getShuffledQuestions());
  const [currentIndex, setCurrentIndex] = useState(0);

  const currentQuestion = questions[currentIndex];

  function handleSubmit(selectedIndex) {
    console.log('Submitted index:', selectedIndex);
  }

  return (
    <div className="flex flex-col items-center gap-8 p-8 w-full">
      <Logo size="small" />
      <QuestionCard
        key={currentQuestion.id}
        question={currentQuestion}
        onSubmit={handleSubmit}
      />
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
