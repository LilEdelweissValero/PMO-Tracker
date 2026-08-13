# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Stack

Next.js deployed to Vercel with Supabase as the database and authentication backend.

## Users

- Administrators manage the directory, configuration, access, and corrections.
- PMO Officers maintain the official records of their assigned Projects.
- Leadership Viewers inspect portfolio status, history, and reports without modifying data.
- Developers and System Owners are directory records and Project Participants, not application users.

The expected scale is fewer than 100 Projects, fewer than 50 People, and three signed-in users.

## Product Purpose

The tracker gives the Project Management Office one trustworthy record of Project progress, responsibility, timing, and governance. It succeeds when leadership can answer what every Project was doing at a chosen time, who held responsibility, how long work remained with each person or group, and what changed without reconstructing the answer from scattered messages and links.

## Positioning

The product joins a freely editable Project-specific Stage list with immutable event history and exactly one Ball Owner for every non-terminal Project. It preserves PMO flexibility without losing accountability or point-in-time truth.

## Operating Context

- The PMO tracks Pipeline, Planned, Active, On Hold, Cancelled, and Closed Projects.
- Each Project starts with suggested Stages that PMO Officers may tailor independently.
- Progress Updates change Stage; Bumps capture conversational updates; either may transfer the Ball.
- Project events have both Effective and Recorded timestamps in Philippine time.
- Systems contain Modules; Developers belong to Systems and one current System Owner belongs to each Module.
- External working material remains in tools such as GDocs, OneDrive, ELS, and Jira and is linked through configurable References.

## Capabilities and Constraints

- Simple username and password login; no Microsoft Entra ID or enterprise SSO.
- Exactly one Ball Owner for each non-terminal Project, with ownership and hold durations retained historically.
- Project and directory assignment changes are logged rather than overwritten.
- Closed and Cancelled Projects cannot be reopened.
- Configurable Priorities, Request Types, Reference Types, Initiator Types, default Stages, and per-Stage Detail prompts.
- KRA/KPI definitions and targets are shown in the first release, but automated KPI calculation is deferred.
- No Excel import, notifications, file uploads, or PDF generation in the first release.
- CSV export remains available for reports and Project history.
- The product is a small responsive website, not a mobile application or enterprise platform.

## Evidence on Hand

- The source requirements and complete decision interview live in `pmospec.md` and the current conversation.
- Canonical domain language lives in `CONTEXT.md`.
- Durable decisions live in `docs/adr/`.
- No logo, brand system, production screenshots, or real Project dataset has been provided; future work must not fabricate organizational claims or production data.

## Product Principles

- Keep the workflow flexible and the history trustworthy.
- Make current responsibility impossible to miss.
- Prefer a small explicit feature over a generalized enterprise subsystem.
- Preserve facts through logs, effective dates, and non-destructive corrections.
- Optimize daily PMO operation before analytical sophistication.
