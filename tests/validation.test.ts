import { describe, expect, it } from "vitest";
import {
  appendProjectEventInputSchema,
  closeProjectInputSchema,
  configureProjectStageInputSchema,
  createProjectInputSchema,
  systemScopeInputSchema,
} from "@/lib/validation";

const id = "11111111-1111-4111-8111-111111111111";

describe("command validation", () => {
  it("rejects ambiguous System scope rows", () => {
    expect(
      systemScopeInputSchema.safeParse({
        systemId: id,
        entireSystem: true,
        moduleId: id,
      }).success,
    ).toBe(false);
    expect(
      systemScopeInputSchema.safeParse({ systemId: id, entireSystem: false })
        .success,
    ).toBe(false);
  });

  it("validates a complete create-project aggregate", () => {
    expect(
      createProjectInputSchema.safeParse({
        code: "PMO-101",
        name: "Command validation",
        priorityId: id,
        state: "Pipeline",
        pmoOfficerId: id,
        ballOwnerId: id,
        participants: [{ personId: id, group: "PMO" }],
        systemScopes: [],
        references: [],
      }).success,
    ).toBe(true);
  });

  it("requires event-specific Progress and Bump payloads", () => {
    const base = {
      projectId: id,
      version: 1,
      effectiveAt: "2026-08-14T09:00:00+08:00",
    };
    expect(
      appendProjectEventInputSchema.safeParse({
        ...base,
        eventType: "progress",
        stageId: id,
        payload: { summary: "" },
      }).success,
    ).toBe(false);
    expect(
      appendProjectEventInputSchema.safeParse({
        ...base,
        eventType: "bump",
        payload: { text: "Followed up with delivery." },
      }).success,
    ).toBe(true);
  });

  it("uses action-specific stage fields", () => {
    expect(
      configureProjectStageInputSchema.safeParse({
        projectId: id,
        version: 3,
        action: "reorder",
        stageIds: [],
      }).success,
    ).toBe(false);
  });

  it("bounds the closeout stakeholder rating", () => {
    expect(
      closeProjectInputSchema.safeParse({
        projectId: id,
        version: 5,
        effectiveAt: "2026-08-14T09:00:00+08:00",
        closeout: {
          dodMet: true,
          dodExplanation: "Accepted",
          methodologyCompliant: true,
          methodologyExplanation: "Reviewed",
          documentationComplete: true,
          documentationExplanation: "Published",
          stakeholderRating: 6,
        },
      }).success,
    ).toBe(false);
  });
});
