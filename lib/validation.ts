import { z } from "zod";
import { PROJECT_STATES } from "./domain";
export const projectSchema = z.object({
  code: z
    .string()
    .trim()
    .min(1)
    .max(40)
    .regex(/^[^/]+$/, "Project Code cannot contain a slash"),
  name: z.string().trim().min(1).max(160),
  priorityId: z.string().uuid(),
  state: z.enum(PROJECT_STATES),
  pmoOfficerId: z.string().uuid(),
  ballOwnerId: z.string().uuid(),
  scope: z.string().trim().max(10000).optional(),
  version: z.coerce.number().int().nonnegative(),
});
export const eventSchema = z.object({
  projectId: z.string().uuid(),
  effectiveAt: z.string().min(1),
  resultingBallOwnerId: z.string().uuid(),
  version: z.coerce.number().int().nonnegative(),
  summary: z.string().trim().min(1).max(4000),
});
export const referenceSchema = z.object({
  typeId: z.string().uuid(),
  label: z.string().trim().min(1).max(120),
  url: z
    .string()
    .url()
    .refine(
      (v) => ["http:", "https:"].includes(new URL(v).protocol),
      "Use an HTTP(S) URL",
    ),
});
