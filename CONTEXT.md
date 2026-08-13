# PMO Project Tracking

This context describes the language used to govern and review the Project Management Office's portfolio of delivery work.

## Portfolio

**Project**:
One independently governed delivery effort with one accountable PMO Officer. A Project may affect multiple Systems and involve multiple Developers, System Owners, requesters, and departments.

**Project Code**:
A unique identifier entered when a Project is created and immutable thereafter. Its format is determined outside the tracker.

**Priority**:
An Administrator-managed classification of a Project's urgency, initially Critical, High, Medium, or Low. Retired values remain attached to existing Projects but are unavailable for new selection.

**Request Type**:
An Administrator-managed classification of the requested delivery, initially Enhancement, New System, or New Module. Retired values remain attached to existing Projects but are unavailable for new selection.

**Scope/Description**:
The editable definition of what a Project intends to deliver. Changes are retained in Project history.
_Avoid_: Project Summary Note, Remarks

**Reference**:
A labeled external URL associated with a Project and classified by a configurable Reference Type. A Project may have any number of References of the same type.

**Initiative**:
A shared business request or objective that may produce one or more independently tracked Projects.

## Workflow

**Workflow Template**:
The PMO's suggested ordered set of Stages, copied into each new Project. Editing a Project's copied Stage list does not change the template or other Projects.
_Avoid_: Status list

**Stage**:
A suggested position in a Project's delivery workflow, such as Dev Start, Dev End, or Deployed. Upcoming Stages may be added, removed, renamed, or reordered for that Project, and a Stage may define one configurable Stage Detail.
_Avoid_: Status, state

**Stage Transition**:
A Project's movement into a Stage. Transitions may move freely through the Project's current Stage list, while prior transitions retain their original identity and sequence; every transition confirms or changes the Ball Owner.
_Avoid_: Status change

**Stage Detail**:
A single configurable text value recorded with a Stage Transition. Its Stage supplies the label, help text, required setting, and single-line or multiline presentation.
_Avoid_: Custom form, document checklist

**Planned Completion**:
The optional Philippine date by which a Stage is expected to be completed. Every revision is retained, allowing completion variance to be shown against both the original and latest plans.

**Stage Variance**:
The number of calendar days a Stage was completed early or late relative to a Planned Completion.

**Project State**:
The operational condition of a Project: Pipeline, Planned, Active, On Hold, Cancelled, or Closed. Pipeline means under discussion; Planned means approved but not yet started; Cancelled and Closed are irreversible terminal states.
_Avoid_: Stage, status

**Health**:
A Project's Green, Yellow, or Red performance classification, derived from its schedule and cost performance.
_Avoid_: State, stage

## Activity and History

**Progress Update**:
A recorded transition from one Stage to another.
_Avoid_: Bump

**Bump**:
A conversational Project update that does not itself change the Project's Stage.
_Avoid_: Progress Update

**Ball Owner**:
The one individual accountable for progressing a non-terminal Project at a given time. A terminal Project retains its final Ball Owner historically but has no active ownership clock.
_Avoid_: Assignee, responsible group

**Ball Ownership Period**:
The uninterrupted interval during which one individual is the Ball Owner of a Project. Consecutive periods provide the basis for measuring individual and group turnaround time, excluding time when the Project is On Hold.

**Hold Period**:
The interval during which a Project is On Hold. Hold duration is measured separately and excluded from Ball Owner turnaround duration; the Ball may be transferred when the Hold Period begins.

**Deployment Version**:
The free-form release identifier required whenever a Project transitions into the Deployed Stage. A Project may have multiple deployments and therefore multiple Deployment Versions.

**Effective Date**:
The Philippine date and time at which a recorded Project event occurred in the real world. It may be backdated without changing its Recorded Date.

**Recorded Date**:
The date on which a Project event was entered into the tracker.

**As-of View**:
A reconstruction of the portfolio at a specified Effective Date. An audit perspective may instead reconstruct what had been recorded by a specified Recorded Date.
_Avoid_: Snapshot

**Closeout Assessment**:
The record completed when a Project is Closed, stating whether its Definition of Done, methodology, and documentation obligations were met and optionally recording a stakeholder rating and comment.

**Initiator Type**:
An Administrator-managed category of party that originated a Project request, initially System Owner, PMO, Developer, or Higher Authority. Retired values remain on existing Projects.

**Requester**:
The Person who asked for a Project. The Requester's Department at the time of the request is preserved with the Project.

## People

**Person**:
An individual in the shared directory, identified by name, Department, username, position, and Active or Inactive state. Username is stored for external use and is not an application login identifier; inactive people remain in history but cannot receive new assignments or the Ball.

**Administrator**:
A person responsible for managing tracker access and organization-wide configuration.

**PMO Officer**:
The person accountable for maintaining the official governance record of an assigned Project.

**Leadership Viewer**:
A person with read-only access to portfolio and historical reporting.

**Developer**:
A person who performs delivery work for a Project but does not directly maintain its official tracker record.

**System Owner**:
A person accountable for one or more Modules but does not directly maintain a Project's official tracker record.

## Systems

**System**:
A managed technology product that may be affected by Projects, contains Modules, and has one or more assigned Developers.

**Module**:
A defined functional area belonging to one System. Each Module has exactly one current System Owner, while prior ownership is retained historically.

**Developer Assignment**:
The association of a Developer with a System in the shared directory.

**Ownership Assignment**:
The association of a System Owner with a Module in the shared directory.

**Project Participant**:
A Person assigned to a Project under the PMO, Developer, or System Owner group. A Developer or System Owner normally comes from an affected System's assignments, but an exceptional cross-system assignment is permitted.

**Assignment Period**:
The effective interval during which a Person is assigned to a System, Module, or Project in a particular capacity. Changing an assignment closes the prior period rather than overwriting it, and directory changes do not alter existing Project assignments automatically.
