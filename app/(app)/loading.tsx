export default function Loading() {
  return (
    <div aria-live="polite" aria-busy="true">
      <div className="notice">
        <strong>Loading the portfolio…</strong> Reconstructing the latest
        trustworthy view.
      </div>
    </div>
  );
}
