import { PageHeader } from "@/components/page-header";
export default function Lists() {
  return (
    <>
      <PageHeader
        title="Configurable lists"
        description="Referenced choices retire instead of disappearing from historical Projects."
        actions={<button>Add choice</button>}
      />
      {[
        ["Priorities", "Critical, High, Medium, Low"],
        ["Request Types", "Enhancement, New System, New Module"],
        ["Reference Types", "GDocs, OneDrive, ELS, Jira"],
        ["Initiator Types", "System Owner, PMO, Developer, Higher Authority"],
      ].map(([h, v]) => (
        <section className="section" key={h}>
          <h2>{h}</h2>
          <p>{v}</p>
        </section>
      ))}
    </>
  );
}
