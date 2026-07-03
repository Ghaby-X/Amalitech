import { useNavigate } from 'react-router-dom';
import Logo from '../components/Logo';

function Quiz() {
  const navigate = useNavigate();

  return (
    <div className="flex flex-col items-center gap-8 p-8 w-full">
      <Logo size="small" />
      <div className="w-full max-w-xl min-h-80 bg-white border-3 border-black rounded-2xl shadow-[6px_6px_0px_#1a1a1a]">
        {/* Questions will be rendered here in the next story */}
      </div>
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
