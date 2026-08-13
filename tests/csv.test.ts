import { describe, it, expect } from "vitest";
import { csv } from "@/lib/csv";
describe("CSV", () => {
  it("quotes delimiters, quotes, and lines", () => {
    expect(csv([{ name: 'A, "B"', note: "one\ntwo" }])).toBe(
      '"name","note"\r\n"A, ""B""","one\ntwo"',
    );
  });
});
