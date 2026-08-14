import "server-only";

import type { Enums, Tables } from "@/lib/database.types";
import { dataClient, type DataClient } from "./client";
import { listResult } from "./result";

export type BallQueueItem = Tables<"project_ball_queue">;

export type BallQueueFilters = {
  group?: Enums<"participant_group">;
  ownerId?: string;
  limit?: number;
};

export async function listBallQueue(
  filters: BallQueueFilters = {},
  client?: DataClient,
) {
  const supabase = await dataClient(client);
  let query = supabase
    .from("project_ball_queue")
    .select("*")
    .order("held_seconds", { ascending: false })
    .limit(filters.limit ?? 100);
  if (filters.group) query = query.eq("ball_owner_group", filters.group);
  if (filters.ownerId) query = query.eq("ball_owner_id", filters.ownerId);
  const { data, error } = await query;
  return listResult(data, error);
}
