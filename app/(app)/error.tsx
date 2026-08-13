"use client";
export default function ErrorPage({ reset }: { reset: () => void }) {
  return (
    <div className="empty" role="alert">
      <h1>That view hit a snag</h1>
      <p>Your data was not changed. Try loading the view again.</p>
      <button onClick={reset}>Try again</button>
    </div>
  );
}
