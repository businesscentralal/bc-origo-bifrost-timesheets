---
status: ready
source: message-type picker (Gunnar 16.10.2026), story drafted by Claude Code
prompt-version: story-v4
solution: Bifrost Timesheets
story-type: Feature
---

# Story: Timesheets.Absence.Register: absence lines linked to Employee Absence

> Origin: Gunnar picked **Add** for picker row 153 (`TimeSheet.Absence.Register`, rank M) on 16.10.2026.

# Part 1 - The Story

## Goal

Let a caller register absence on a time sheet with a cause of absence, so it becomes an Employee Absence when the line is posted, as BC does for absence lines.

## User story

As an integrator, automation or AI agent working through the Bifröst queue API, I want `Timesheets.Absence.Register` so that I can do this without the Business Central client and without raw `Data.Records.*` table choreography.

## Scope

- New message type(s) in Bifrost Timesheets: `Timesheets.Absence.Register`.
- Contract (`Msg Contract ori`), discovery and help (en-US and is-IS) for each type.
- Permission set extension changes on BIFROST Timeshts ori (and the Read extension) / BIFROST Timeshts ori (and the Full extension) as needed (no new assignable permission set).
- Write-restriction subscriber for what the type owns (see Binding Constraints).
- Tests in the test app (unit + MCP verification).

## Not in scope

Employee creation (Foundation row 65, parked).

# Part 2 - Implementation Contract

## Approved Scope

- `Timesheets.Absence.Register` (Inbound, writes)

## Microsoft BC object / action it mirrors

- Time Sheet Line Type Absence with Cause of Absence Code; posting creates Employee Absence (table 5207)

## Acceptance Criteria

| ID | Criterion | Proof |
|---|---|---|
| AC01 | `Timesheets.Absence.Register` takes a time sheet no. (or resource + date), causeOfAbsenceCode and hours per day and answers the absence line. | AL unit test (happy path) + MCP on bc28-w1 |
| AC02 | Refusal: when the resource is not linked to an employee, the type answers code `PreconditionFailed` with a `nextStep` that says: "Link the resource to an employee in BC." Nothing is written. | AL unit test (invalid input) |
| AC03 | Refusal: when cause of absence not found, the type answers code `RecordNotFound` with a `nextStep` that says: "Use a code from Causes of Absence." Nothing is written. | AL unit test (invalid input) |
| AC04 | Common refusals: a missing required key answers `MissingParameter`, a wrong-typed key `InvalidParameterFormat`, an unknown key `UnknownParameter`, an identifier that matches nothing `RecordNotFound`, and conflicting identifiers `ConflictingIdentifiers`; each with `nextStep`. | AL unit test (invalid input) |
| AC05 | Edge case: Hours on a non-working day are accepted and flagged with a warning. | AL unit test (edge) |
| AC06 | Permissions: IsEnabled and Execute check write permission on every table the type touches; a caller without it gets `PermissionDenied` with a `nextStep` naming the permission set. Grants live on BIFROST Timeshts ori (and the Full extension) (feature app: no assignable set, no `Setup ori` grants). Hot-path reads of base-app tables are granted or guarded with `ReadPermission()`. | AL unit test (no-permission path) |
| AC07 | Writes go through Validate and the BC codeunits/reports named above (never direct Insert/Modify of ledger or posted tables), inside the write-isolation `Codeunit.Run` pattern so a failure answers a clean error and not a raw runtime error. Post/Register types commit and the help says so (core#985). | AL unit test + code review |
| AC08 | Help: `Help.Implementation.Get` returns the help for each new type in en-US and is-IS (lcid 1039): purpose, parameters, response, every refusal code above with its nextStep, and an example. Help never names AL objects, codeunit numbers or internal procedures. | MCP on bc28-w1 and bc28-is |
| AC09 | Translations: every new label has an is-IS entry in `app/Translations/Bifrost Timesheets.is-IS.xlf`; the IcelandicXlfInSync, MixedLanguageLabels and HelpLinks guards pass. | CI guards |
| AC10 | Contract: each type implements `Msg Contract ori`; the ContractParameterKeys guard passes (declared keys = keys read). | CI guard |
| AC11 | The message type name has exactly three dot-separated parts (Gunnar 16.10 naming rule). | Review |
| AC12 | Tests: the test app has at least one happy-path, one invalid-input and one edge-case test per new type, and the no-permission test; the full suite is green. | CI |
| AC13 | Live verification: before merge, Claude Code verifies each type on bc28-w1 (and bc28-is for the Icelandic help) with self-created data and posts the receipt on the PR. | MCP receipt |

## Binding Constraints

- Namespace `Origo.Bifrost.Timesheets` on every file; object IDs taken from app/app.json and test/app.json; fit into gaps, never a new range.
- Follow bc-dev-standards and the repo AGENTS.md (one statement per line, SetLoadFields where it pays, XML docs, no WITH).
- Feature app: never read or grant Foundation's `Setup ori`; call Foundation entry points.

## Required Technical Facts

- BC object ids above are from the BC 28 base app as recalled when drafting; the coder confirms each id and procedure on the downloaded symbols before coding and notes any difference on the PR.
- Message type enum: `ClockifyMsgType` enum extension (app/src/MessageTypes/ClockifyMsgType.EnumExt.al) or a new Timesheets enum extension.

## Known Ambiguities

| ID | Question | Class | Default |
|---|---|---|---|
| AMB-0 | None known | - | - |

## Test layers

- AL unit tests in the test app (happy, invalid input, edge, no-permission, write-restriction).
- CI guards (contract keys, XLF, help links, mixed language).
- MCP live verification on bc28-w1 / bc28-is (Claude Code, pre-merge).
---
Source: message-type picker (Gunnar 16.10), row 153.