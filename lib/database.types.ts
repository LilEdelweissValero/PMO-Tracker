export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[];

export type Database = {
  public: {
    Tables: {
      audit_log: {
        Row: {
          action: string;
          actor_id: string;
          after_data: Json | null;
          before_data: Json | null;
          entity_id: string;
          entity_type: string;
          id: string;
          recorded_at: string;
        };
        Insert: {
          action: string;
          actor_id: string;
          after_data?: Json | null;
          before_data?: Json | null;
          entity_id: string;
          entity_type: string;
          id?: string;
          recorded_at?: string;
        };
        Update: {
          action?: string;
          actor_id?: string;
          after_data?: Json | null;
          before_data?: Json | null;
          entity_id?: string;
          entity_type?: string;
          id?: string;
          recorded_at?: string;
        };
        Relationships: [
          {
            foreignKeyName: "audit_log_actor_id_fkey";
            columns: ["actor_id"];
            isOneToOne: false;
            referencedRelation: "profiles";
            referencedColumns: ["id"];
          },
        ];
      };
      closeout_assessments: {
        Row: {
          actor_id: string;
          documentation_complete: boolean;
          documentation_explanation: string;
          dod_explanation: string;
          dod_met: boolean;
          id: string;
          methodology_compliant: boolean;
          methodology_explanation: string;
          project_id: string;
          recorded_at: string;
          stakeholder_comment: string | null;
          stakeholder_rating: number | null;
        };
        Insert: {
          actor_id: string;
          documentation_complete: boolean;
          documentation_explanation: string;
          dod_explanation: string;
          dod_met: boolean;
          id?: string;
          methodology_compliant: boolean;
          methodology_explanation: string;
          project_id: string;
          recorded_at?: string;
          stakeholder_comment?: string | null;
          stakeholder_rating?: number | null;
        };
        Update: {
          actor_id?: string;
          documentation_complete?: boolean;
          documentation_explanation?: string;
          dod_explanation?: string;
          dod_met?: boolean;
          id?: string;
          methodology_compliant?: boolean;
          methodology_explanation?: string;
          project_id?: string;
          recorded_at?: string;
          stakeholder_comment?: string | null;
          stakeholder_rating?: number | null;
        };
        Relationships: [
          {
            foreignKeyName: "closeout_assessments_actor_id_fkey";
            columns: ["actor_id"];
            isOneToOne: false;
            referencedRelation: "profiles";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "closeout_assessments_project_id_fkey";
            columns: ["project_id"];
            isOneToOne: true;
            referencedRelation: "project_ball_queue";
            referencedColumns: ["project_id"];
          },
          {
            foreignKeyName: "closeout_assessments_project_id_fkey";
            columns: ["project_id"];
            isOneToOne: true;
            referencedRelation: "project_dashboard_queue";
            referencedColumns: ["project_id"];
          },
          {
            foreignKeyName: "closeout_assessments_project_id_fkey";
            columns: ["project_id"];
            isOneToOne: true;
            referencedRelation: "projects";
            referencedColumns: ["id"];
          },
        ];
      };
      departments: {
        Row: {
          active: boolean;
          created_at: string;
          id: string;
          name: string;
        };
        Insert: {
          active?: boolean;
          created_at?: string;
          id?: string;
          name: string;
        };
        Update: {
          active?: boolean;
          created_at?: string;
          id?: string;
          name?: string;
        };
        Relationships: [];
      };
      initiatives: {
        Row: {
          active: boolean;
          id: string;
          name: string;
        };
        Insert: {
          active?: boolean;
          id?: string;
          name: string;
        };
        Update: {
          active?: boolean;
          id?: string;
          name?: string;
        };
        Relationships: [];
      };
      initiator_types: {
        Row: {
          active: boolean;
          id: string;
          name: string;
        };
        Insert: {
          active?: boolean;
          id?: string;
          name: string;
        };
        Update: {
          active?: boolean;
          id?: string;
          name?: string;
        };
        Relationships: [];
      };
      module_owner_assignments: {
        Row: {
          effective_from: string;
          effective_to: string | null;
          id: string;
          module_id: string;
          person_id: string;
        };
        Insert: {
          effective_from: string;
          effective_to?: string | null;
          id?: string;
          module_id: string;
          person_id: string;
        };
        Update: {
          effective_from?: string;
          effective_to?: string | null;
          id?: string;
          module_id?: string;
          person_id?: string;
        };
        Relationships: [
          {
            foreignKeyName: "module_owner_assignments_module_id_fkey";
            columns: ["module_id"];
            isOneToOne: false;
            referencedRelation: "modules";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "module_owner_assignments_person_id_fkey";
            columns: ["person_id"];
            isOneToOne: false;
            referencedRelation: "people";
            referencedColumns: ["id"];
          },
        ];
      };
      modules: {
        Row: {
          active: boolean;
          id: string;
          name: string;
          system_id: string;
        };
        Insert: {
          active?: boolean;
          id?: string;
          name: string;
          system_id: string;
        };
        Update: {
          active?: boolean;
          id?: string;
          name?: string;
          system_id?: string;
        };
        Relationships: [
          {
            foreignKeyName: "modules_system_id_fkey";
            columns: ["system_id"];
            isOneToOne: false;
            referencedRelation: "systems";
            referencedColumns: ["id"];
          },
        ];
      };
      people: {
        Row: {
          active: boolean;
          created_at: string;
          department_id: string;
          id: string;
          name: string;
          position: string;
          updated_at: string;
          username: string;
        };
        Insert: {
          active?: boolean;
          created_at?: string;
          department_id: string;
          id?: string;
          name: string;
          position: string;
          updated_at?: string;
          username: string;
        };
        Update: {
          active?: boolean;
          created_at?: string;
          department_id?: string;
          id?: string;
          name?: string;
          position?: string;
          updated_at?: string;
          username?: string;
        };
        Relationships: [
          {
            foreignKeyName: "people_department_id_fkey";
            columns: ["department_id"];
            isOneToOne: false;
            referencedRelation: "departments";
            referencedColumns: ["id"];
          },
        ];
      };
      priorities: {
        Row: {
          active: boolean;
          id: string;
          name: string;
          sort_order: number;
        };
        Insert: {
          active?: boolean;
          id?: string;
          name: string;
          sort_order: number;
        };
        Update: {
          active?: boolean;
          id?: string;
          name?: string;
          sort_order?: number;
        };
        Relationships: [];
      };
      profile_roles: {
        Row: {
          profile_id: string;
          role: Database["public"]["Enums"]["app_role"];
        };
        Insert: {
          profile_id: string;
          role: Database["public"]["Enums"]["app_role"];
        };
        Update: {
          profile_id?: string;
          role?: Database["public"]["Enums"]["app_role"];
        };
        Relationships: [
          {
            foreignKeyName: "profile_roles_profile_id_fkey";
            columns: ["profile_id"];
            isOneToOne: false;
            referencedRelation: "profiles";
            referencedColumns: ["id"];
          },
        ];
      };
      profiles: {
        Row: {
          active: boolean;
          created_at: string;
          email: string | null;
          id: string;
          person_id: string;
        };
        Insert: {
          active?: boolean;
          created_at?: string;
          email?: string | null;
          id: string;
          person_id: string;
        };
        Update: {
          active?: boolean;
          created_at?: string;
          email?: string | null;
          id?: string;
          person_id?: string;
        };
        Relationships: [
          {
            foreignKeyName: "profiles_person_id_fkey";
            columns: ["person_id"];
            isOneToOne: true;
            referencedRelation: "people";
            referencedColumns: ["id"];
          },
        ];
      };
      project_events: {
        Row: {
          actor_id: string;
          correction_reason: string | null;
          created_transaction_id: number;
          effective_at: string;
          event_type: Database["public"]["Enums"]["project_event_type"];
          id: string;
          payload: Json;
          project_id: string;
          recorded_at: string;
          resulting_ball_owner_id: string | null;
          resulting_ball_owner_name: string | null;
          resulting_stage_id: string | null;
          resulting_stage_label: string | null;
          resulting_state: Database["public"]["Enums"]["project_state"] | null;
          supersedes_event_id: string | null;
        };
        Insert: {
          actor_id: string;
          correction_reason?: string | null;
          created_transaction_id?: number;
          effective_at: string;
          event_type: Database["public"]["Enums"]["project_event_type"];
          id?: string;
          payload?: Json;
          project_id: string;
          recorded_at?: string;
          resulting_ball_owner_id?: string | null;
          resulting_ball_owner_name?: string | null;
          resulting_stage_id?: string | null;
          resulting_stage_label?: string | null;
          resulting_state?: Database["public"]["Enums"]["project_state"] | null;
          supersedes_event_id?: string | null;
        };
        Update: {
          actor_id?: string;
          correction_reason?: string | null;
          created_transaction_id?: number;
          effective_at?: string;
          event_type?: Database["public"]["Enums"]["project_event_type"];
          id?: string;
          payload?: Json;
          project_id?: string;
          recorded_at?: string;
          resulting_ball_owner_id?: string | null;
          resulting_ball_owner_name?: string | null;
          resulting_stage_id?: string | null;
          resulting_stage_label?: string | null;
          resulting_state?: Database["public"]["Enums"]["project_state"] | null;
          supersedes_event_id?: string | null;
        };
        Relationships: [
          {
            foreignKeyName: "correction_event_belongs_to_project";
            columns: ["supersedes_event_id", "project_id"];
            isOneToOne: false;
            referencedRelation: "effective_project_events";
            referencedColumns: ["id", "project_id"];
          },
          {
            foreignKeyName: "correction_event_belongs_to_project";
            columns: ["supersedes_event_id", "project_id"];
            isOneToOne: false;
            referencedRelation: "project_events";
            referencedColumns: ["id", "project_id"];
          },
          {
            foreignKeyName: "correction_event_belongs_to_project";
            columns: ["supersedes_event_id", "project_id"];
            isOneToOne: false;
            referencedRelation: "project_timeline_intervals";
            referencedColumns: ["event_id", "project_id"];
          },
          {
            foreignKeyName: "event_stage_belongs_to_project";
            columns: ["resulting_stage_id", "project_id"];
            isOneToOne: false;
            referencedRelation: "project_stages";
            referencedColumns: ["id", "project_id"];
          },
          {
            foreignKeyName: "project_events_actor_id_fkey";
            columns: ["actor_id"];
            isOneToOne: false;
            referencedRelation: "profiles";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "project_events_project_id_fkey";
            columns: ["project_id"];
            isOneToOne: false;
            referencedRelation: "project_ball_queue";
            referencedColumns: ["project_id"];
          },
          {
            foreignKeyName: "project_events_project_id_fkey";
            columns: ["project_id"];
            isOneToOne: false;
            referencedRelation: "project_dashboard_queue";
            referencedColumns: ["project_id"];
          },
          {
            foreignKeyName: "project_events_project_id_fkey";
            columns: ["project_id"];
            isOneToOne: false;
            referencedRelation: "projects";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "project_events_resulting_ball_owner_id_fkey";
            columns: ["resulting_ball_owner_id"];
            isOneToOne: false;
            referencedRelation: "people";
            referencedColumns: ["id"];
          },
        ];
      };
      project_participant_assignments: {
        Row: {
          effective_from: string;
          effective_to: string | null;
          id: string;
          participant_group: Database["public"]["Enums"]["participant_group"];
          person_id: string;
          project_id: string;
        };
        Insert: {
          effective_from: string;
          effective_to?: string | null;
          id?: string;
          participant_group: Database["public"]["Enums"]["participant_group"];
          person_id: string;
          project_id: string;
        };
        Update: {
          effective_from?: string;
          effective_to?: string | null;
          id?: string;
          participant_group?: Database["public"]["Enums"]["participant_group"];
          person_id?: string;
          project_id?: string;
        };
        Relationships: [
          {
            foreignKeyName: "project_participant_assignments_person_id_fkey";
            columns: ["person_id"];
            isOneToOne: false;
            referencedRelation: "people";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "project_participant_assignments_project_id_fkey";
            columns: ["project_id"];
            isOneToOne: false;
            referencedRelation: "project_ball_queue";
            referencedColumns: ["project_id"];
          },
          {
            foreignKeyName: "project_participant_assignments_project_id_fkey";
            columns: ["project_id"];
            isOneToOne: false;
            referencedRelation: "project_dashboard_queue";
            referencedColumns: ["project_id"];
          },
          {
            foreignKeyName: "project_participant_assignments_project_id_fkey";
            columns: ["project_id"];
            isOneToOne: false;
            referencedRelation: "projects";
            referencedColumns: ["id"];
          },
        ];
      };
      project_pmo_assignments: {
        Row: {
          effective_from: string;
          effective_to: string | null;
          id: string;
          person_id: string;
          project_id: string;
        };
        Insert: {
          effective_from: string;
          effective_to?: string | null;
          id?: string;
          person_id: string;
          project_id: string;
        };
        Update: {
          effective_from?: string;
          effective_to?: string | null;
          id?: string;
          person_id?: string;
          project_id?: string;
        };
        Relationships: [
          {
            foreignKeyName: "project_pmo_assignments_person_id_fkey";
            columns: ["person_id"];
            isOneToOne: false;
            referencedRelation: "people";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "project_pmo_assignments_project_id_fkey";
            columns: ["project_id"];
            isOneToOne: false;
            referencedRelation: "project_ball_queue";
            referencedColumns: ["project_id"];
          },
          {
            foreignKeyName: "project_pmo_assignments_project_id_fkey";
            columns: ["project_id"];
            isOneToOne: false;
            referencedRelation: "project_dashboard_queue";
            referencedColumns: ["project_id"];
          },
          {
            foreignKeyName: "project_pmo_assignments_project_id_fkey";
            columns: ["project_id"];
            isOneToOne: false;
            referencedRelation: "projects";
            referencedColumns: ["id"];
          },
        ];
      };
      project_references: {
        Row: {
          active: boolean;
          id: string;
          label: string;
          project_id: string;
          reference_type_id: string;
          url: string;
        };
        Insert: {
          active?: boolean;
          id?: string;
          label: string;
          project_id: string;
          reference_type_id: string;
          url: string;
        };
        Update: {
          active?: boolean;
          id?: string;
          label?: string;
          project_id?: string;
          reference_type_id?: string;
          url?: string;
        };
        Relationships: [
          {
            foreignKeyName: "project_references_project_id_fkey";
            columns: ["project_id"];
            isOneToOne: false;
            referencedRelation: "project_ball_queue";
            referencedColumns: ["project_id"];
          },
          {
            foreignKeyName: "project_references_project_id_fkey";
            columns: ["project_id"];
            isOneToOne: false;
            referencedRelation: "project_dashboard_queue";
            referencedColumns: ["project_id"];
          },
          {
            foreignKeyName: "project_references_project_id_fkey";
            columns: ["project_id"];
            isOneToOne: false;
            referencedRelation: "projects";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "project_references_reference_type_id_fkey";
            columns: ["reference_type_id"];
            isOneToOne: false;
            referencedRelation: "reference_types";
            referencedColumns: ["id"];
          },
        ];
      };
      project_stages: {
        Row: {
          active: boolean;
          detail_help: string | null;
          detail_label: string | null;
          detail_multiline: boolean;
          detail_required: boolean;
          id: string;
          name: string;
          project_id: string;
          sort_order: number;
          template_stage_id: string | null;
          visited: boolean;
        };
        Insert: {
          active?: boolean;
          detail_help?: string | null;
          detail_label?: string | null;
          detail_multiline?: boolean;
          detail_required?: boolean;
          id?: string;
          name: string;
          project_id: string;
          sort_order: number;
          template_stage_id?: string | null;
          visited?: boolean;
        };
        Update: {
          active?: boolean;
          detail_help?: string | null;
          detail_label?: string | null;
          detail_multiline?: boolean;
          detail_required?: boolean;
          id?: string;
          name?: string;
          project_id?: string;
          sort_order?: number;
          template_stage_id?: string | null;
          visited?: boolean;
        };
        Relationships: [
          {
            foreignKeyName: "project_stages_project_id_fkey";
            columns: ["project_id"];
            isOneToOne: false;
            referencedRelation: "project_ball_queue";
            referencedColumns: ["project_id"];
          },
          {
            foreignKeyName: "project_stages_project_id_fkey";
            columns: ["project_id"];
            isOneToOne: false;
            referencedRelation: "project_dashboard_queue";
            referencedColumns: ["project_id"];
          },
          {
            foreignKeyName: "project_stages_project_id_fkey";
            columns: ["project_id"];
            isOneToOne: false;
            referencedRelation: "projects";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "project_stages_template_stage_id_fkey";
            columns: ["template_stage_id"];
            isOneToOne: false;
            referencedRelation: "workflow_template_stages";
            referencedColumns: ["id"];
          },
        ];
      };
      project_system_scopes: {
        Row: {
          entire_system: boolean;
          id: string;
          module_id: string | null;
          project_id: string;
          system_id: string;
        };
        Insert: {
          entire_system?: boolean;
          id?: string;
          module_id?: string | null;
          project_id: string;
          system_id: string;
        };
        Update: {
          entire_system?: boolean;
          id?: string;
          module_id?: string | null;
          project_id?: string;
          system_id?: string;
        };
        Relationships: [
          {
            foreignKeyName: "project_scope_module_belongs_to_system";
            columns: ["module_id", "system_id"];
            isOneToOne: false;
            referencedRelation: "modules";
            referencedColumns: ["id", "system_id"];
          },
          {
            foreignKeyName: "project_system_scopes_project_id_fkey";
            columns: ["project_id"];
            isOneToOne: false;
            referencedRelation: "project_ball_queue";
            referencedColumns: ["project_id"];
          },
          {
            foreignKeyName: "project_system_scopes_project_id_fkey";
            columns: ["project_id"];
            isOneToOne: false;
            referencedRelation: "project_dashboard_queue";
            referencedColumns: ["project_id"];
          },
          {
            foreignKeyName: "project_system_scopes_project_id_fkey";
            columns: ["project_id"];
            isOneToOne: false;
            referencedRelation: "projects";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "project_system_scopes_system_id_fkey";
            columns: ["system_id"];
            isOneToOne: false;
            referencedRelation: "systems";
            referencedColumns: ["id"];
          },
        ];
      };
      projects: {
        Row: {
          archived_at: string | null;
          ball_owner_id: string | null;
          code: string;
          created_at: string;
          current_stage_id: string | null;
          id: string;
          initiative_id: string | null;
          initiator_type_id: string | null;
          name: string;
          pmo_officer_id: string;
          priority_id: string;
          request_type_id: string | null;
          requester_department_name: string | null;
          requester_id: string | null;
          scope: string | null;
          state: Database["public"]["Enums"]["project_state"];
          updated_at: string;
          version: number;
        };
        Insert: {
          archived_at?: string | null;
          ball_owner_id?: string | null;
          code: string;
          created_at?: string;
          current_stage_id?: string | null;
          id?: string;
          initiative_id?: string | null;
          initiator_type_id?: string | null;
          name: string;
          pmo_officer_id: string;
          priority_id: string;
          request_type_id?: string | null;
          requester_department_name?: string | null;
          requester_id?: string | null;
          scope?: string | null;
          state: Database["public"]["Enums"]["project_state"];
          updated_at?: string;
          version?: number;
        };
        Update: {
          archived_at?: string | null;
          ball_owner_id?: string | null;
          code?: string;
          created_at?: string;
          current_stage_id?: string | null;
          id?: string;
          initiative_id?: string | null;
          initiator_type_id?: string | null;
          name?: string;
          pmo_officer_id?: string;
          priority_id?: string;
          request_type_id?: string | null;
          requester_department_name?: string | null;
          requester_id?: string | null;
          scope?: string | null;
          state?: Database["public"]["Enums"]["project_state"];
          updated_at?: string;
          version?: number;
        };
        Relationships: [
          {
            foreignKeyName: "projects_ball_owner_id_fkey";
            columns: ["ball_owner_id"];
            isOneToOne: false;
            referencedRelation: "people";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "projects_current_stage_fk";
            columns: ["current_stage_id", "id"];
            isOneToOne: false;
            referencedRelation: "project_stages";
            referencedColumns: ["id", "project_id"];
          },
          {
            foreignKeyName: "projects_initiative_id_fkey";
            columns: ["initiative_id"];
            isOneToOne: false;
            referencedRelation: "initiatives";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "projects_initiator_type_id_fkey";
            columns: ["initiator_type_id"];
            isOneToOne: false;
            referencedRelation: "initiator_types";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "projects_pmo_officer_id_fkey";
            columns: ["pmo_officer_id"];
            isOneToOne: false;
            referencedRelation: "people";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "projects_priority_id_fkey";
            columns: ["priority_id"];
            isOneToOne: false;
            referencedRelation: "priorities";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "projects_request_type_id_fkey";
            columns: ["request_type_id"];
            isOneToOne: false;
            referencedRelation: "request_types";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "projects_requester_id_fkey";
            columns: ["requester_id"];
            isOneToOne: false;
            referencedRelation: "people";
            referencedColumns: ["id"];
          },
        ];
      };
      reference_types: {
        Row: {
          active: boolean;
          id: string;
          name: string;
        };
        Insert: {
          active?: boolean;
          id?: string;
          name: string;
        };
        Update: {
          active?: boolean;
          id?: string;
          name?: string;
        };
        Relationships: [];
      };
      request_types: {
        Row: {
          active: boolean;
          id: string;
          name: string;
        };
        Insert: {
          active?: boolean;
          id?: string;
          name: string;
        };
        Update: {
          active?: boolean;
          id?: string;
          name?: string;
        };
        Relationships: [];
      };
      stage_plan_revisions: {
        Row: {
          actor_id: string;
          effective_at: string;
          id: string;
          planned_date: string | null;
          project_id: string;
          project_stage_id: string;
          reason: string;
          recorded_at: string;
        };
        Insert: {
          actor_id: string;
          effective_at: string;
          id?: string;
          planned_date?: string | null;
          project_id: string;
          project_stage_id: string;
          reason: string;
          recorded_at?: string;
        };
        Update: {
          actor_id?: string;
          effective_at?: string;
          id?: string;
          planned_date?: string | null;
          project_id?: string;
          project_stage_id?: string;
          reason?: string;
          recorded_at?: string;
        };
        Relationships: [
          {
            foreignKeyName: "stage_plan_revisions_actor_id_fkey";
            columns: ["actor_id"];
            isOneToOne: false;
            referencedRelation: "profiles";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "stage_plan_revisions_project_id_fkey";
            columns: ["project_id"];
            isOneToOne: false;
            referencedRelation: "project_ball_queue";
            referencedColumns: ["project_id"];
          },
          {
            foreignKeyName: "stage_plan_revisions_project_id_fkey";
            columns: ["project_id"];
            isOneToOne: false;
            referencedRelation: "project_dashboard_queue";
            referencedColumns: ["project_id"];
          },
          {
            foreignKeyName: "stage_plan_revisions_project_id_fkey";
            columns: ["project_id"];
            isOneToOne: false;
            referencedRelation: "projects";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "stage_plan_stage_belongs_to_project";
            columns: ["project_stage_id", "project_id"];
            isOneToOne: false;
            referencedRelation: "project_stages";
            referencedColumns: ["id", "project_id"];
          },
        ];
      };
      system_developer_assignments: {
        Row: {
          effective_from: string;
          effective_to: string | null;
          id: string;
          person_id: string;
          system_id: string;
        };
        Insert: {
          effective_from: string;
          effective_to?: string | null;
          id?: string;
          person_id: string;
          system_id: string;
        };
        Update: {
          effective_from?: string;
          effective_to?: string | null;
          id?: string;
          person_id?: string;
          system_id?: string;
        };
        Relationships: [
          {
            foreignKeyName: "system_developer_assignments_person_id_fkey";
            columns: ["person_id"];
            isOneToOne: false;
            referencedRelation: "people";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "system_developer_assignments_system_id_fkey";
            columns: ["system_id"];
            isOneToOne: false;
            referencedRelation: "systems";
            referencedColumns: ["id"];
          },
        ];
      };
      systems: {
        Row: {
          active: boolean;
          created_at: string;
          id: string;
          name: string;
        };
        Insert: {
          active?: boolean;
          created_at?: string;
          id?: string;
          name: string;
        };
        Update: {
          active?: boolean;
          created_at?: string;
          id?: string;
          name?: string;
        };
        Relationships: [];
      };
      workflow_template_stages: {
        Row: {
          active: boolean;
          detail_help: string | null;
          detail_label: string | null;
          detail_multiline: boolean;
          detail_required: boolean;
          id: string;
          name: string;
          sort_order: number;
        };
        Insert: {
          active?: boolean;
          detail_help?: string | null;
          detail_label?: string | null;
          detail_multiline?: boolean;
          detail_required?: boolean;
          id?: string;
          name: string;
          sort_order: number;
        };
        Update: {
          active?: boolean;
          detail_help?: string | null;
          detail_label?: string | null;
          detail_multiline?: boolean;
          detail_required?: boolean;
          id?: string;
          name?: string;
          sort_order?: number;
        };
        Relationships: [];
      };
    };
    Views: {
      effective_project_events: {
        Row: {
          actor_id: string | null;
          correction_reason: string | null;
          effective_at: string | null;
          effective_event_type:
            | Database["public"]["Enums"]["project_event_type"]
            | null;
          fact_id: string | null;
          id: string | null;
          is_correction: boolean | null;
          payload: Json | null;
          project_id: string | null;
          recorded_at: string | null;
          recorded_event_type:
            | Database["public"]["Enums"]["project_event_type"]
            | null;
          resulting_ball_owner_id: string | null;
          resulting_ball_owner_name: string | null;
          resulting_stage_id: string | null;
          resulting_stage_label: string | null;
          resulting_state: Database["public"]["Enums"]["project_state"] | null;
          supersedes_event_id: string | null;
        };
        Insert: {
          actor_id?: string | null;
          correction_reason?: string | null;
          effective_at?: string | null;
          effective_event_type?: never;
          fact_id?: never;
          id?: string | null;
          is_correction?: never;
          payload?: Json | null;
          project_id?: string | null;
          recorded_at?: string | null;
          recorded_event_type?:
            | Database["public"]["Enums"]["project_event_type"]
            | null;
          resulting_ball_owner_id?: string | null;
          resulting_ball_owner_name?: string | null;
          resulting_stage_id?: string | null;
          resulting_stage_label?: string | null;
          resulting_state?: Database["public"]["Enums"]["project_state"] | null;
          supersedes_event_id?: string | null;
        };
        Update: {
          actor_id?: string | null;
          correction_reason?: string | null;
          effective_at?: string | null;
          effective_event_type?: never;
          fact_id?: never;
          id?: string | null;
          is_correction?: never;
          payload?: Json | null;
          project_id?: string | null;
          recorded_at?: string | null;
          recorded_event_type?:
            | Database["public"]["Enums"]["project_event_type"]
            | null;
          resulting_ball_owner_id?: string | null;
          resulting_ball_owner_name?: string | null;
          resulting_stage_id?: string | null;
          resulting_stage_label?: string | null;
          resulting_state?: Database["public"]["Enums"]["project_state"] | null;
          supersedes_event_id?: string | null;
        };
        Relationships: [
          {
            foreignKeyName: "correction_event_belongs_to_project";
            columns: ["supersedes_event_id", "project_id"];
            isOneToOne: false;
            referencedRelation: "effective_project_events";
            referencedColumns: ["id", "project_id"];
          },
          {
            foreignKeyName: "correction_event_belongs_to_project";
            columns: ["supersedes_event_id", "project_id"];
            isOneToOne: false;
            referencedRelation: "project_events";
            referencedColumns: ["id", "project_id"];
          },
          {
            foreignKeyName: "correction_event_belongs_to_project";
            columns: ["supersedes_event_id", "project_id"];
            isOneToOne: false;
            referencedRelation: "project_timeline_intervals";
            referencedColumns: ["event_id", "project_id"];
          },
          {
            foreignKeyName: "event_stage_belongs_to_project";
            columns: ["resulting_stage_id", "project_id"];
            isOneToOne: false;
            referencedRelation: "project_stages";
            referencedColumns: ["id", "project_id"];
          },
          {
            foreignKeyName: "project_events_actor_id_fkey";
            columns: ["actor_id"];
            isOneToOne: false;
            referencedRelation: "profiles";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "project_events_project_id_fkey";
            columns: ["project_id"];
            isOneToOne: false;
            referencedRelation: "project_ball_queue";
            referencedColumns: ["project_id"];
          },
          {
            foreignKeyName: "project_events_project_id_fkey";
            columns: ["project_id"];
            isOneToOne: false;
            referencedRelation: "project_dashboard_queue";
            referencedColumns: ["project_id"];
          },
          {
            foreignKeyName: "project_events_project_id_fkey";
            columns: ["project_id"];
            isOneToOne: false;
            referencedRelation: "projects";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "project_events_resulting_ball_owner_id_fkey";
            columns: ["resulting_ball_owner_id"];
            isOneToOne: false;
            referencedRelation: "people";
            referencedColumns: ["id"];
          },
        ];
      };
      project_ball_queue: {
        Row: {
          ball_owner_group:
            | Database["public"]["Enums"]["participant_group"]
            | null;
          ball_owner_id: string | null;
          ball_owner_name: string | null;
          current_stage_id: string | null;
          current_stage_name: string | null;
          held_seconds: number | null;
          last_effective_activity_at: string | null;
          owner_since: string | null;
          pmo_officer_id: string | null;
          pmo_officer_name: string | null;
          priority_id: string | null;
          priority_name: string | null;
          project_code: string | null;
          project_id: string | null;
          project_name: string | null;
          state: Database["public"]["Enums"]["project_state"] | null;
          version: number | null;
          waiting_seconds: number | null;
        };
        Relationships: [
          {
            foreignKeyName: "projects_ball_owner_id_fkey";
            columns: ["ball_owner_id"];
            isOneToOne: false;
            referencedRelation: "people";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "projects_current_stage_fk";
            columns: ["current_stage_id", "project_id"];
            isOneToOne: false;
            referencedRelation: "project_stages";
            referencedColumns: ["id", "project_id"];
          },
          {
            foreignKeyName: "projects_pmo_officer_id_fkey";
            columns: ["pmo_officer_id"];
            isOneToOne: false;
            referencedRelation: "people";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "projects_priority_id_fkey";
            columns: ["priority_id"];
            isOneToOne: false;
            referencedRelation: "priorities";
            referencedColumns: ["id"];
          },
        ];
      };
      project_dashboard_queue: {
        Row: {
          ball_owner_group:
            | Database["public"]["Enums"]["participant_group"]
            | null;
          ball_owner_id: string | null;
          ball_owner_name: string | null;
          current_stage_id: string | null;
          current_stage_name: string | null;
          last_effective_activity_at: string | null;
          pmo_officer_id: string | null;
          pmo_officer_name: string | null;
          priority_id: string | null;
          priority_name: string | null;
          project_code: string | null;
          project_id: string | null;
          project_name: string | null;
          state: Database["public"]["Enums"]["project_state"] | null;
          version: number | null;
          waiting_seconds: number | null;
        };
        Relationships: [
          {
            foreignKeyName: "projects_ball_owner_id_fkey";
            columns: ["ball_owner_id"];
            isOneToOne: false;
            referencedRelation: "people";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "projects_current_stage_fk";
            columns: ["current_stage_id", "project_id"];
            isOneToOne: false;
            referencedRelation: "project_stages";
            referencedColumns: ["id", "project_id"];
          },
          {
            foreignKeyName: "projects_pmo_officer_id_fkey";
            columns: ["pmo_officer_id"];
            isOneToOne: false;
            referencedRelation: "people";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "projects_priority_id_fkey";
            columns: ["priority_id"];
            isOneToOne: false;
            referencedRelation: "priorities";
            referencedColumns: ["id"];
          },
        ];
      };
      project_hold_spans: {
        Row: {
          project_id: string | null;
          span_end: string | null;
          span_start: string | null;
        };
        Relationships: [
          {
            foreignKeyName: "project_events_project_id_fkey";
            columns: ["project_id"];
            isOneToOne: false;
            referencedRelation: "project_ball_queue";
            referencedColumns: ["project_id"];
          },
          {
            foreignKeyName: "project_events_project_id_fkey";
            columns: ["project_id"];
            isOneToOne: false;
            referencedRelation: "project_dashboard_queue";
            referencedColumns: ["project_id"];
          },
          {
            foreignKeyName: "project_events_project_id_fkey";
            columns: ["project_id"];
            isOneToOne: false;
            referencedRelation: "projects";
            referencedColumns: ["id"];
          },
        ];
      };
      project_ownership_spans: {
        Row: {
          owner_id: string | null;
          owner_name: string | null;
          project_id: string | null;
          span_end: string | null;
          span_start: string | null;
        };
        Relationships: [
          {
            foreignKeyName: "project_events_project_id_fkey";
            columns: ["project_id"];
            isOneToOne: false;
            referencedRelation: "project_ball_queue";
            referencedColumns: ["project_id"];
          },
          {
            foreignKeyName: "project_events_project_id_fkey";
            columns: ["project_id"];
            isOneToOne: false;
            referencedRelation: "project_dashboard_queue";
            referencedColumns: ["project_id"];
          },
          {
            foreignKeyName: "project_events_project_id_fkey";
            columns: ["project_id"];
            isOneToOne: false;
            referencedRelation: "projects";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "project_events_resulting_ball_owner_id_fkey";
            columns: ["owner_id"];
            isOneToOne: false;
            referencedRelation: "people";
            referencedColumns: ["id"];
          },
        ];
      };
      project_timeline_intervals: {
        Row: {
          effective_event_type:
            | Database["public"]["Enums"]["project_event_type"]
            | null;
          event_id: string | null;
          interval_end: string | null;
          interval_start: string | null;
          project_id: string | null;
          resulting_ball_owner_id: string | null;
          resulting_ball_owner_name: string | null;
          resulting_stage_id: string | null;
          resulting_stage_label: string | null;
          resulting_state: Database["public"]["Enums"]["project_state"] | null;
        };
        Relationships: [
          {
            foreignKeyName: "event_stage_belongs_to_project";
            columns: ["resulting_stage_id", "project_id"];
            isOneToOne: false;
            referencedRelation: "project_stages";
            referencedColumns: ["id", "project_id"];
          },
          {
            foreignKeyName: "project_events_project_id_fkey";
            columns: ["project_id"];
            isOneToOne: false;
            referencedRelation: "project_ball_queue";
            referencedColumns: ["project_id"];
          },
          {
            foreignKeyName: "project_events_project_id_fkey";
            columns: ["project_id"];
            isOneToOne: false;
            referencedRelation: "project_dashboard_queue";
            referencedColumns: ["project_id"];
          },
          {
            foreignKeyName: "project_events_project_id_fkey";
            columns: ["project_id"];
            isOneToOne: false;
            referencedRelation: "projects";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "project_events_resulting_ball_owner_id_fkey";
            columns: ["resulting_ball_owner_id"];
            isOneToOne: false;
            referencedRelation: "people";
            referencedColumns: ["id"];
          },
        ];
      };
      project_turnaround_report: {
        Row: {
          current_state: Database["public"]["Enums"]["project_state"] | null;
          gross_seconds: number | null;
          hold_seconds: number | null;
          net_seconds: number | null;
          owner_group: Database["public"]["Enums"]["participant_group"] | null;
          owner_id: string | null;
          owner_name: string | null;
          project_code: string | null;
          project_id: string | null;
          project_name: string | null;
          span_end: string | null;
          span_start: string | null;
        };
        Relationships: [
          {
            foreignKeyName: "project_events_project_id_fkey";
            columns: ["project_id"];
            isOneToOne: false;
            referencedRelation: "project_ball_queue";
            referencedColumns: ["project_id"];
          },
          {
            foreignKeyName: "project_events_project_id_fkey";
            columns: ["project_id"];
            isOneToOne: false;
            referencedRelation: "project_dashboard_queue";
            referencedColumns: ["project_id"];
          },
          {
            foreignKeyName: "project_events_project_id_fkey";
            columns: ["project_id"];
            isOneToOne: false;
            referencedRelation: "projects";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "project_events_resulting_ball_owner_id_fkey";
            columns: ["owner_id"];
            isOneToOne: false;
            referencedRelation: "people";
            referencedColumns: ["id"];
          },
        ];
      };
    };
    Functions: {
      append_project_event: { Args: { input: Json }; Returns: string };
      assert_ball_owner: {
        Args: {
          target_effective_at: string;
          target_person_id: string;
          target_project_id: string;
        };
        Returns: undefined;
      };
      assert_project_complete: {
        Args: { target_project_id: string };
        Returns: undefined;
      };
      can_edit_project: {
        Args: { target_project_id: string };
        Returns: boolean;
      };
      close_project: { Args: { input: Json }; Returns: string };
      configure_project_stage: { Args: { input: Json }; Returns: string };
      correct_project_event: { Args: { input: Json }; Returns: string };
      create_project: { Args: { input: Json }; Returns: string };
      current_roles: {
        Args: never;
        Returns: Database["public"]["Enums"]["app_role"][];
      };
      has_active_profile: { Args: never; Returns: boolean };
      is_admin: { Args: never; Returns: boolean };
      manage_profile_access: { Args: { input: Json }; Returns: string };
      provision_profile: { Args: { input: Json }; Returns: string };
      reassign_project_pmo: { Args: { input: Json }; Returns: undefined };
      record_project_audit: {
        Args: {
          target_action: string;
          target_after: Json;
          target_before: Json;
          target_project_id: string;
        };
        Returns: undefined;
      };
      replay_project_projection: {
        Args: { target_project_id: string };
        Returns: undefined;
      };
      report_project_audit: {
        Args: { target_project_id?: string };
        Returns: {
          action: string;
          actor_id: string;
          after_data: Json;
          audit_id: string;
          before_data: Json;
          project_id: string;
          recorded_at: string;
        }[];
      };
      report_project_history: {
        Args: { target_project_id: string };
        Returns: {
          actor_id: string;
          correction_reason: string;
          effective_at: string;
          effective_event_type: Database["public"]["Enums"]["project_event_type"];
          event_id: string;
          is_effective: boolean;
          payload: Json;
          recorded_at: string;
          recorded_event_type: Database["public"]["Enums"]["project_event_type"];
          resulting_ball_owner_id: string;
          resulting_ball_owner_name: string;
          resulting_stage_id: string;
          resulting_stage_label: string;
          resulting_state: Database["public"]["Enums"]["project_state"];
          supersedes_event_id: string;
        }[];
      };
      report_projects_as_of: {
        Args: { as_of_time: string; target_project_id?: string };
        Returns: {
          archived: boolean;
          ball_owner_group: Database["public"]["Enums"]["participant_group"];
          ball_owner_id: string;
          ball_owner_name: string;
          effective_at: string;
          pmo_officer_id: string;
          pmo_officer_name: string;
          project_code: string;
          project_id: string;
          project_name: string;
          stage_id: string;
          stage_name: string;
          state: Database["public"]["Enums"]["project_state"];
        }[];
      };
      revise_stage_plan: { Args: { input: Json }; Returns: string };
      set_project_archived: { Args: { input: Json }; Returns: string };
      update_project: { Args: { input: Json }; Returns: undefined };
    };
    Enums: {
      app_role: "administrator" | "pmo_officer" | "leadership_viewer";
      participant_group: "PMO" | "Developer" | "System Owner";
      project_event_type:
        | "project_created"
        | "project_changed"
        | "progress"
        | "bump"
        | "state_changed"
        | "ball_transferred"
        | "workflow_changed"
        | "participant_changed"
        | "pmo_reassigned"
        | "plan_revised"
        | "corrected"
        | "archived";
      project_state:
        | "Pipeline"
        | "Planned"
        | "Active"
        | "On Hold"
        | "Cancelled"
        | "Closed";
    };
    CompositeTypes: {
      [_ in never]: never;
    };
  };
};

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">;

type DefaultSchema = DatabaseWithoutInternals[Extract<
  keyof Database,
  "public"
>];

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals;
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R;
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R;
      }
      ? R
      : never
    : never;

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals;
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I;
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I;
      }
      ? I
      : never
    : never;

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals;
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U;
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U;
      }
      ? U
      : never
    : never;

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals;
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never;

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals;
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never;

export const Constants = {
  public: {
    Enums: {
      app_role: ["administrator", "pmo_officer", "leadership_viewer"],
      participant_group: ["PMO", "Developer", "System Owner"],
      project_event_type: [
        "project_created",
        "project_changed",
        "progress",
        "bump",
        "state_changed",
        "ball_transferred",
        "workflow_changed",
        "participant_changed",
        "pmo_reassigned",
        "plan_revised",
        "corrected",
        "archived",
      ],
      project_state: [
        "Pipeline",
        "Planned",
        "Active",
        "On Hold",
        "Cancelled",
        "Closed",
      ],
    },
  },
} as const;
