function Logo({ size = 'large' }) {
  const sizeClass = size === 'large' ? 'text-8xl' : 'text-4xl';

  return (
    <h1 className={`${sizeClass} font-bold tracking-wide leading-none`}>
      <span className="text-black">Quiz</span>
      <span className="text-purple">Me!!</span>
    </h1>
  );
}

export default Logo;
