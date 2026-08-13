export function BallIcon({ size = 24 }: { size?: number }) {
  return (
    <svg
      className="pixel-icon"
      width={size}
      height={size}
      viewBox="0 0 32 32"
      fill="none"
      aria-hidden="true"
      shapeRendering="crispEdges"
    >
      <path
        d="M10 3h12v3h5v5h3v10h-3v5h-5v3H10v-3H5v-5H2V11h3V6h5V3Z"
        fill="#ff9f43"
        stroke="#563d7c"
        strokeWidth="2"
      />
      <path
        d="M7 6c5 4 13 14 18 20M5 23c7-5 14-6 23-4M21 5c-3 7-3 15 1 22"
        stroke="#7b4774"
        strokeWidth="2"
      />
    </svg>
  );
}
export function BumpIcon({ size = 24 }: { size?: number }) {
  return (
    <svg
      className="pixel-icon"
      width={size}
      height={size}
      viewBox="0 0 32 32"
      fill="none"
      aria-hidden="true"
      shapeRendering="crispEdges"
    >
      <path
        d="M2 15h4v-4h4v3h4v4h4v-4h4v-3h4v4h4v8h-4v4H6v-4H2v-8Z"
        fill="#ffb5d8"
        stroke="#563d7c"
        strokeWidth="2"
      />
      <path
        d="M10 14v6m12-6v6m-9 3h6M16 8V3m-6 6L7 6m15 3 3-3"
        stroke="#563d7c"
        strokeWidth="2"
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
