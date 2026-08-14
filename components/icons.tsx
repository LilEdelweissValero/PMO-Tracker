export function BallIcon({ size = 24 }: { size?: number }) {
  return (
    <svg
      className="ball-icon"
      width={size}
      height={size}
      viewBox="0 0 32 32"
      fill="none"
      aria-hidden="true"
    >
      <circle cx="16" cy="16" r="13" fill="currentColor" opacity=".16" />
      <circle cx="16" cy="16" r="11.5" stroke="currentColor" strokeWidth="2" />
      <path
        d="M8 7.5c4.5 3.5 12.5 12 16 17M5.5 21.5c6.5-4 14-5 21-2.5M20.5 5.5c-3 6.5-2.5 14 1.5 20"
        stroke="currentColor"
        strokeWidth="1.7"
        strokeLinecap="round"
      />
    </svg>
  );
}
export function BumpIcon({ size = 24 }: { size?: number }) {
  return (
    <svg
      className="bump-icon"
      width={size}
      height={size}
      viewBox="0 0 32 32"
      fill="none"
      aria-hidden="true"
    >
      <path
        d="M3.5 16.5 8 12l5.5 1 2.5 3 2.5-3L24 12l4.5 4.5v6L25 26h-7l-2-2-2 2H7l-3.5-3.5v-6Z"
        fill="currentColor"
        opacity=".18"
      />
      <path
        d="M4.5 17 8 13.5l5 1 3 3 3-3 5-1 3.5 3.5v5L24.5 25H19l-3-2.5-3 2.5H7.5l-3-3v-5ZM16 9V4m-6.5 6L6 6.5m16.5 3.5L26 6.5"
        stroke="currentColor"
        strokeWidth="1.8"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}
export function SparkIcon() {
  return (
    <svg
      width="18"
      height="18"
      viewBox="0 0 20 20"
      fill="none"
      aria-hidden="true"
    >
      <path
        d="M10 1c.6 5.5 3.5 8.4 9 9-5.5.6-8.4 3.5-9 9-.6-5.5-3.5-8.4-9-9 5.5-.6 8.4-3.5 9-9Z"
        fill="currentColor"
      />
    </svg>
  );
}
