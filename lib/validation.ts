import { z } from "zod";
import { GROUPS, PROJECT_STATES } from "./domain";

const uuid = z.string().uuid();
const version = z.coerce.number().int().nonnegative();
const effectiveAt = z.string().datetime({ offset: true });
const requiredText = (maximum: number) => z.string().trim().min(1).max(maximum);
const optionalUuid = uuid.nullish();

export const participantInputSchema = z.object({
  personId: uuid,
  group: z.enum(GROUPS),
});

export const systemScopeInputSchema = z
  .object({
    systemId: uuid,
    entireSystem: z.boolean(),
    moduleId: optionalUuid,
  })
  .superRefine((scope, context) => {
    if (!scope.entireSystem && !scope.moduleId) {
      context.addIssue({
        code: z.ZodIssueCode.custom,
        path: ["moduleId"],
        message: "Choose a Module or select the entire System.",
      });
    }
    if (scope.entireSystem && scope.moduleId) {
      context.addIssue({
        code: z.ZodIssueCode.custom,
        path: ["moduleId"],
        message: "An entire-System scope cannot also select a Module.",
      });
    }
  });

export const referenceSchema = z.object({
  id: optionalUuid,
  typeId: uuid,
  label: requiredText(120),
  url: z
    .string()
    .trim()
    .url()
    .max(2048)
    .refine(
      (value) => ["http:", "https:"].includes(new URL(value).protocol),
      "Use an HTTP(S) URL",
    ),
});

const projectAggregateFields = {
  name: requiredText(160),
  initiativeId: optionalUuid,
  priorityId: uuid,
  scope: z.string().trim().max(10000).nullish(),
  requestTypeId: optionalUuid,
  initiatorTypeId: optionalUuid,
  requesterId: optionalUuid,
  participants: z.array(participantInputSchema),
  systemScopes: z.array(systemScopeInputSchema),
  references: z.array(referenceSchema),
};

export const createProjectInputSchema = z.object({
  code: requiredText(40).regex(
    /^[^/]+$/,
    "Project Code cannot contain a slash",
  ),
  ...projectAggregateFields,
  state: z.enum(PROJECT_STATES),
  pmoOfficerId: uuid,
  ballOwnerId: uuid,
});

export const updateProjectInputSchema = z.object({
  projectId: uuid,
  version,
  name: projectAggregateFields.name.optional(),
  initiativeId: optionalUuid.optional(),
  priorityId: projectAggregateFields.priorityId.optional(),
  scope: projectAggregateFields.scope.optional(),
  requestTypeId: optionalUuid.optional(),
  initiatorTypeId: optionalUuid.optional(),
  requesterId: optionalUuid.optional(),
  participants: projectAggregateFields.participants.optional(),
  systemScopes: projectAggregateFields.systemScopes.optional(),
  references: projectAggregateFields.references.optional(),
});

export const reassignProjectPmoInputSchema = z.object({
  projectId: uuid,
  version,
  pmoOfficerId: uuid,
  reason: z.string().trim().max(4000).nullish(),
});

const stageBaseSchema = z.object({
  projectId: uuid,
  version,
});

export const configureProjectStageInputSchema = z.discriminatedUnion("action", [
  stageBaseSchema.extend({
    action: z.literal("add"),
    name: requiredText(120),
    sortOrder: z.coerce.number().int().positive(),
    detailLabel: z.string().trim().max(120).nullish(),
    detailHelp: z.string().trim().max(1000).nullish(),
    detailRequired: z.boolean().default(false),
    detailMultiline: z.boolean().default(false),
  }),
  stageBaseSchema.extend({
    action: z.literal("update"),
    stageId: uuid,
    name: requiredText(120).optional(),
    detailLabel: z.string().trim().max(120).nullish(),
    detailHelp: z.string().trim().max(1000).nullish(),
    detailRequired: z.boolean().optional(),
    detailMultiline: z.boolean().optional(),
  }),
  stageBaseSchema.extend({
    action: z.literal("reorder"),
    stageIds: z.array(uuid).min(1),
  }),
  stageBaseSchema.extend({
    action: z.literal("remove"),
    stageId: uuid,
  }),
]);

export const reviseStagePlanInputSchema = z.object({
  projectId: uuid,
  version,
  stageId: uuid,
  plannedDate: z.string().date(),
  effectiveAt,
  reason: requiredText(4000),
});

const eventBaseSchema = z.object({
  projectId: uuid,
  version,
  effectiveAt,
  resultingBallOwnerId: uuid.optional(),
});

export const appendProjectEventInputSchema = z.discriminatedUnion("eventType", [
  eventBaseSchema.extend({
    eventType: z.literal("progress"),
    stageId: uuid,
    payload: z.object({
      summary: requiredText(4000),
      stageDetail: z.string().trim().max(10000).optional(),
      transitionReason: z.string().trim().max(4000).optional(),
    }),
  }),
  eventBaseSchema.extend({
    eventType: z.literal("bump"),
    payload: z.object({ text: requiredText(4000) }),
  }),
  eventBaseSchema.extend({
    eventType: z.literal("state_changed"),
    resultingState: z.enum(PROJECT_STATES),
    payload: z.object({ reason: z.string().trim().max(4000).optional() }),
  }),
  eventBaseSchema.extend({
    eventType: z.literal("ball_transferred"),
    resultingBallOwnerId: uuid,
    payload: z.record(z.unknown()).default({}),
  }),
]);

export const closeProjectInputSchema = z.object({
  projectId: uuid,
  version,
  effectiveAt,
  closeout: z.object({
    dodMet: z.boolean(),
    dodExplanation: requiredText(10000),
    methodologyCompliant: z.boolean(),
    methodologyExplanation: requiredText(10000),
    documentationComplete: z.boolean(),
    documentationExplanation: requiredText(10000),
    stakeholderRating: z.coerce.number().int().min(1).max(5),
    stakeholderComment: z.string().trim().max(10000).nullish(),
  }),
});

export const setProjectArchivedInputSchema = z.object({
  projectId: uuid,
  version,
  archived: z.boolean(),
});

export const correctProjectEventInputSchema = z.object({
  eventId: uuid,
  version,
  reason: requiredText(4000),
  effectiveAt: effectiveAt.optional(),
  resultingState: z.enum(PROJECT_STATES).optional(),
  stageId: optionalUuid.optional(),
  resultingBallOwnerId: uuid.optional(),
  payload: z.record(z.unknown()).optional(),
});

// Kept for the current create form until Task 15 wires the full aggregate form.
export const projectSchema = z.object({
  code: createProjectInputSchema.shape.code,
  name: createProjectInputSchema.shape.name,
  priorityId: uuid,
  state: z.enum(PROJECT_STATES),
  pmoOfficerId: uuid,
  ballOwnerId: uuid,
  scope: z.string().trim().max(10000).optional(),
  version,
});

// Kept for existing event forms until Task 16 adopts the discriminated schema.
export const eventSchema = z.object({
  projectId: uuid,
  effectiveAt,
  resultingBallOwnerId: uuid,
  version,
  summary: requiredText(4000),
});

export type CreateProjectInput = z.infer<typeof createProjectInputSchema>;
export type UpdateProjectInput = z.infer<typeof updateProjectInputSchema>;
export type AppendProjectEventInput = z.infer<
  typeof appendProjectEventInputSchema
>;
