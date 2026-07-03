import { useNavigate } from 'react-router-dom';
import Logo from '../components/Logo';

function Home() {
  const navigate = useNavigate();

  return (
    <div className="flex flex-col items-center gap-6 p-8">
      <Logo size="large" />
      <p className="text-xl text-black/70 max-w-sm leading-relaxed">
        Test your general knowledge with quick, fun quizzes.
      </p>
      <button
        onClick={() => navigate('/quiz')}
        className="mt-2 px-16 py-4 text-2xl font-semibold text-white rounded-full cursor-pointer
                   shadow-[4px_4px_0px_#5b21b6]
                   hover:-translate-x-0.5 hover:-translate-y-0.5 hover:shadow-[6px_6px_0px_#5b21b6]
                   active:translate-x-0.5 active:translate-y-0.5 active:shadow-[2px_2px_0px_#5b21b6]
                   transition-all duration-100"
        style={{ backgroundColor: '#7c3aed', opacity: 0.85 }}
      >
        Quick Start
      </button>
    </div>
  );
}

export default Home;
