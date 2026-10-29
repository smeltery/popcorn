export default (props) => {
  const e = (f) => {
    return (e) => {
      e.preventDefault();
      f(e);
    };
  };

  return (
    <div class="ap-overlay ap-overlay-start" onClick={e(props.onClick)}>
      <div class="ap-play-button">
        <div>
          <span>
            <svg viewBox="0 0 100 100" class="ap-icon" aria-hidden="true">
              <circle cx="50" cy="50" r="46" fill="var(--popcorn-midnight)" />
              <path
                d="M39 28Q35 26 35 31V69Q35 74 39 72L72 53Q77 50 72 47Z"
                fill="currentColor"
              />
            </svg>
          </span>
        </div>
      </div>
    </div>
  );
};
