import "server-only";

import { dataClient, type DataClient } from "./client";
import { listResult } from "./result";

export async function listPriorities(client?: DataClient) {
  const supabase = await dataClient(client);
  const { data, error } = await supabase
    .from("priorities")
    .select("*")
    .order("sort_order");
  return listResult(data, error);
}

export async function listRequestTypes(client?: DataClient) {
  const supabase = await dataClient(client);
  const { data, error } = await supabase
    .from("request_types")
    .select("*")
    .order("name");
  return listResult(data, error);
}

export async function listReferenceTypes(client?: DataClient) {
  const supabase = await dataClient(client);
  const { data, error } = await supabase
    .from("reference_types")
    .select("*")
    .order("name");
  return listResult(data, error);
}

export async function listInitiatorTypes(client?: DataClient) {
  const supabase = await dataClient(client);
  const { data, error } = await supabase
    .from("initiator_types")
    .select("*")
    .order("name");
  return listResult(data, error);
}

export async function listInitiatives(client?: DataClient) {
  const supabase = await dataClient(client);
  const { data, error } = await supabase
    .from("initiatives")
    .select("*")
    .order("name");
  return listResult(data, error);
}

export async function listWorkflowTemplateStages(client?: DataClient) {
  const supabase = await dataClient(client);
  const { data, error } = await supabase
    .from("workflow_template_stages")
    .select("*")
    .order("sort_order");
  return listResult(data, error);
}
