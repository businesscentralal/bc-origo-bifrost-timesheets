# Bifrost Timesheets

**App name:** Bifrost Timesheets  
**App ID:** `d4560cf5-947d-42b5-b812-33ae8dd009af`  
**App ID Range:** 10036785–10036884 (highest id in use: 10036853). Test app `553214e3-b742-4ccf-8ecc-1ee86fbc96f9`, range 95600–95699.  
**Publisher:** Origo — **Version:** 29.0.0.0 — **Namespace:** `Origo.Bifrost.Timesheets`  
**Target:** Cloud (AppSource) — application/platform 28.0.0.0, runtime 17.0

**Environments**

| Environment | Purpose |
| --- | --- |
| AppSource (production, SaaS) | The shipping target. `"target": "Cloud"`, AppSourceCop clean, mandatory ` ori` affix on every object. |
| `launch: bc28-is` (COSMO Alpaca) | Development and test container, CRONUS IS. Used for the end-to-end message-type runs over the Bifröst queue API. |
| `launch: bc28-w1` (COSMO Alpaca) | Development and test container, CRONUS International Ltd. (W1). Unit tests run here as well. |

Both containers are defined in `app/.vscode/launch.json`, which is git-ignored and is the authority for the instance ids.

---

## Overview

Bifrost Timesheets exposes the [Clockify](https://docs.developer.clockify.me) time-tracking REST API as 41 Bifröst message types on top of Bifrost Foundation, and synchronises finished Clockify time entries into Business Central Job Journals or Time Sheets. Workspaces, users, user groups, clients, projects, tasks, tags, currencies, custom fields and time entries are readable and writable over the Bifröst queue API (`origo/bifrost/v1.0`), so an external system or an AI agent can drive Clockify from Business Central the same way a user would.

On the BC side the connector writes time entries either into a Job Journal — with deduplication, update detection and correction posting — or into the resource's open Time Sheet, and it manages the Time Sheet lifecycle (create, approve, reject, reopen, post, archive). A webhook receiver keeps the sync real-time. Links between BC records and Clockify objects are held in the `Clockify Integration ori` table; rows are never deleted, only marked `Reversed` and purged later by a retention policy.

This is the in-place successor of *Origo Cloud Events Clockify* 28.1.0.0: same app id, version bumped to 29.0.0.0. It was never published, so there is no data take-over codeunit. The app was migrated under the name *Bifrost Clockify* and renamed to **Bifrost Timesheets** before its first release (repository `origo-bc-cloudevents-clockify` -> `bc-origo-bifrost-timesheets`). Object names keep the `Clockify` domain word, and the 41 message-type keys never changed. The documentation slug is still `clockify` until the folders in the site repository are renamed.

---

## Functional Flow

1. An administrator opens **Bifrost Timesheets Setup** (page `Timesheets Setup ori`), reached from the Bifröst Setup page or by searching for it.
2. The administrator enters the Clockify API key through **Set Company API Key**. The key is written to IsolatedStorage (Company scope) by `Clockify Secret Mgt ori`; the dialog `Clockify Set Secret Dialog ori` does not echo the keystrokes and the key never lands in a table field.
3. The administrator picks a default workspace from **Clockify Workspace Lookup ori**, which lists the workspaces the key can reach, and fills in the Job Journal template, batch and default work type.
4. **Register Webhooks** creates the Clockify webhooks that push time-entry changes back to BC. Registered webhooks are listed on `Clockify Webhooks ori`.
5. BC records are linked to Clockify objects. A link is one row in `Clockify Integration ori` — BC table no. plus SystemId or code on one side, Clockify type, workspace id and object id on the other. `Clockify Integration List ori` shows them.
6. A caller (external system, AI agent, or the Job Queue) sends a Bifröst message over the queue API: `POST .../tasks` with a CloudEvents 1.0 envelope naming one of the 41 message types, then reads the answer from `.../responses({taskId})/data`.
7. Read types (`*.List`, `*.Get`) return the Clockify data as JSON. Write types (`*.Create`, `*.Update`, `*.Delete`) change Clockify and record the resulting link. Sync types pull finished time entries into BC.
8. `Clockify.TimeEntry.Sync` / `.SyncRange` / `.SyncAllUsers` create Job Journal lines. `Clockify.TimeEntry.SyncToTimeSheet` / `.SyncRangeToTimeSheet` write Time Sheet lines and details instead.
9. `Clockify.TimeSheet.Create` / `.Approve` / `.Reject` / `.Reopen` / `.Post` / `.Archive` drive the Time Sheet through its lifecycle.
10. A user reviews the resulting Job Journal or Time Sheet in Business Central and posts it as usual.
11. When a BC record is deleted, blocked or completed, `Clockify Event Subscribers ori` reacts and `Clockify Archive Sync ori` archives the corresponding Clockify client, project or task.

---

## Benefits

- **One API surface for Clockify from BC** — 41 message types cover workspaces, users, user groups, clients, projects, tasks, tags, currencies, custom fields, time entries and time sheets. Callers use the Bifröst queue API and never talk to Clockify directly.
- **No duplicate journal lines** — `Clockify Time Entry Sync ori` checks `Clockify Integration ori` before writing, so re-running a sync skips entries that are already in the journal.
- **Corrections instead of silent overwrites** — when a synced entry changes in Clockify (hours, project, task or work type), the connector writes a reversal line plus a new line rather than editing the existing one.
- **Real-time sync without polling** — registered Clockify webhooks call `Clockify Webhook Handler ori`, which routes the change straight to the sync engine.
- **Two sync targets** — the same time entry can go to a Job Journal or to the resource's open Time Sheet, chosen by the message type.
- **Auditable links that survive deletion** — integration rows are marked `Reversed` rather than deleted, and `Clockify Reten. Policy ori` removes them later through the BC retention-policy framework.
- **API key out of the database** — the key lives in this app's IsolatedStorage (Company scope), and `Clockify ReqLog Masker ori` governs what the request log stores.
- **Self-documenting at runtime** — `Help.Clockify.Get` returns the connector directory and every message type answers its own Markdown contract, so a caller can discover the API without reading the source.
- **Bilingual** — every caption, label and enum value carries an `is-IS` comment, and `Bifrost Timesheets.is-IS.xlf` ships all 130 translation units translated.

---

## Logic Flow

**Message dispatch**

1. Bifrost Foundation receives the CloudEvents envelope, creates a `Message ori` record and resolves the `type` against the `Message Type ori` enum. `Clockify Msg Type ori` (10036785) contributes the 41 Clockify values.
2. Foundation instantiates the `Msg Interface ori` implementation registered for the value and calls `ExecuteBifrostTask(var Argument)`.
3. The `Clockify <Name> Impl ori` codeunit reads its parameters from the argument, calls `Clockify Request Mgt ori` for the shared plumbing, and writes the answer back through the argument.
4. Failures are returned as `status = Error` with a message through `Argument.RespondWithError`. An unhandled exception never reaches the API.

**Outbound HTTP**

5. `Clockify Integration Gate ori` checks that the connector is configured and enabled before any call leaves BC.
6. `Clockify Client ori` is the only HTTP path to Clockify. It is the `Version 1` implementation of the `Clockify API Client ori` interface; the implementation is chosen from the `API Version` enum field on `Clockify Setup ori`, so a test extension can register a mock without changing this app.
7. It reads the API key from IsolatedStorage, sets the `X-Api-Key` header, and logs request and response through Foundation's request log under the `Clockify Req Log Type ori` service type.

**Time-entry sync to a Job Journal**

8. `Clockify TimeEntry Fetch ori` pulls the user's finished entries for the date range from Clockify, following pagination. Entries with no `end` (still running) are rejected on purpose.
9. `Clockify TimeEntry Parse ori` parses the workspace, user and entry parameters, the tag array, and derives hours and dates from the ISO-8601 values.
10. `Clockify Time Entry Sync ori` resolves the Job Task from the Clockify task's `TASK` integration link, and the Work Type from the first tag that has a `TAG` link to a Work Type code — falling back to **Default Work Type** on setup.
11. It then looks the entry up in `Clockify Integration ori` and returns one of `Created`, `Skipped`, `Updated`, `Corrected` or `Error` (`Clockify Sync Result ori`). `Corrected` means a reversal line and a new line were written. If the original line was already posted, the link is reversed and the caller is told to post a manual correction for the ledger entry.

**Time-entry sync to a Time Sheet**

12. `Clockify TimeSheet Sync ori` writes the entry to the resource's open Time Sheet as a line plus a detail record instead of a journal line.
13. `Clockify TimeSheet Mgt ori` is the automation engine behind the `Clockify.TimeSheet.*` types and performs create, approve, reject, reopen, post and archive.

**Webhooks**

14. Clockify posts the change to the URL in **Webhook Receiver URL**. `Clockify Webhook Handler ori` routes it to the sync engine; `Clockify Webhook Mgt ori` registers and removes the webhooks and holds their signing tokens.

**Housekeeping**

15. `Clockify Install ori` runs on install. `Clockify Reten. Policy ori` registers `Clockify Integration ori` with the retention-policy framework and enables a default policy that removes reversed links.
16. `Clockify Help Builder ori` renders the shared Markdown skeleton; the seven per-domain help codeunits fill it with a `case` on the message type. `Clockify Help Overview Sub ori` adds the `Help.Clockify.Get` line to Foundation's `Help.Bifrost.Get` directory.

---

## Setup & Configuration

**Setup table:** `Clockify Setup ori` (10036853) — a single company-level record.

**Setup page:** `Timesheets Setup ori` (10036853), captioned *Bifrost Timesheets Setup* / *Uppsetning Bifröst tímaskýrslna*. `Clockify Setup Ext ori` adds exactly one action to the Bifröst Setup page's `Apps` group; the connector does not extend Foundation's `Setup ori` table.

| Field | Type | Caption (en-US / is-IS) | Purpose |
| --- | --- | --- | --- |
| `Primary Key` | Code[10] | Primary Key / Aðallykill | Singleton key. Always blank. |
| `API Version` | Enum `Clockify API Version ori` | Clockify API Version / Clockify API útgáfa | Selects the `Clockify API Client ori` implementation. `Version 1` is the default and is fixed on `https://api.clockify.me/api/v1`. It replaced the former free-text base-URL field. |
| `Default Workspace` | Text[50] | Default Workspace ID / Kenni sjálfgefins vinnusvæðis | The Clockify workspace id used when a caller does not name one. Filled by the workspace picker. |
| `Workspace Name` | Text[250] | Default Workspace / Sjálfgefið vinnusvæði | Display name of that workspace. |
| `Webhook Receiver URL` | Text[250] | Webhook Receiver URL / Móttökuslóð vefkróka | The URL Clockify posts time-entry changes to. |
| `Job Jnl. Template` | Code[10] | Job Journal Template / Verkbókarlýsing | Target Job Journal template for the journal sync. |
| `Job Jnl. Batch` | Code[10] | Job Journal Batch / Verkbókarflokkur | Target batch within that template. |
| `Default Work Type` | Code[10] | Default Work Type / Sjálfgefin vinnutegund | Work Type used when no Clockify tag resolves to one. |

**API key.** Not a field. `Clockify Secret Mgt ori` stores it in this app's IsolatedStorage (Company scope). Enter it with the **Set Company API Key** action, which opens `Clockify Set Secret Dialog ori`; remove it with **Clear Company API Key**. The page shows a read-only **Company API Key Stored** indicator. Bifrost Foundation now owns a unified `Secret Store ori`; moving the key there is a planned follow-up and will require entering the key once more, because IsolatedStorage cannot be copied between extensions.

**Actions on the setup page**

| Action | What it does |
| --- | --- |
| Set Company API Key | Prompts for the key without echoing it and writes it to IsolatedStorage. |
| Clear Company API Key | Removes the stored key. |
| Register Webhooks | Creates the Clockify webhooks for real-time time-entry sync. |
| Remove Webhooks | Deletes them again. |
| Show Signing Tokens | Displays the webhook signing tokens. |
| Integration Links | Opens `Clockify Integration List ori`. |
| Registered Webhooks | Opens `Clockify Webhooks ori`. |

**Prerequisites**

- Bifrost Foundation 28.0.0.0 installed.
- A Clockify account and an API key with access to the workspace.
- A Job Journal template and batch for the journal sync, or resources with open Time Sheets for the time-sheet sync.
- Work Types set up if Clockify tags should map to them.

**Permissions.** `BIFROST Timeshts ori` (*Bifrost Timesheets* / *Bifröst tímaskýrslur*) is the app's single assignable permission set and grants everything the app owns: the setup, integration, webhook and buffer tables, every message-type implementation and help codeunit, and the five pages. Combine it with a Bifröst Foundation permission set (`BIFROST Full ori` or `BIFROST Read ori`) — the message loop, the request log and `User Setup ori` live in Foundation — and with the base-application permissions for the targets the sync writes to: Job Journal, Time Sheets and Resources.

---

## Example Scenario

A consultancy tracks hours in Clockify and invoices them from BC projects.

1. An administrator opens **Bifrost Timesheets Setup**, runs **Set Company API Key** and pastes the Clockify API key.
2. The administrator opens the **Default Workspace** lookup, picks *Acme Consulting*, then sets Job Journal Template `JOB`, Batch `DEFAULT` and Default Work Type `CONSULT`.
3. The administrator clicks **Register Webhooks**. The registered webhooks appear on `Clockify Webhooks ori`.
4. A caller creates the Clockify side of an existing BC project:

   ```json
   {
     "type": "Clockify.Project.Create",
     "subject": "J-00040",
     "data": "{\"name\":\"Acme Rollout\",\"clientId\":\"64a1...\"}"
   }
   ```

   The response carries the new Clockify project id, and a `PROJECT` row is written to `Clockify Integration ori` linking BC job `J-00040` to it.
5. A consultant logs 6.5 hours in Clockify against *Acme Rollout*, task *Data migration*, tag *Consulting*, and stops the timer.
6. Clockify posts the change to the webhook receiver. `Clockify Webhook Handler ori` hands the entry to `Clockify Time Entry Sync ori`.
7. The sync resolves the Job Task from the `TASK` link and the Work Type `CONSULT` from the *Consulting* tag, then writes one Job Journal line for 6.5 hours. The result is `Created` and a new `TIMEENTRY` row appears in `Clockify Integration ori`.
8. The consultant later corrects the entry to 7 hours. The webhook fires again; the sync finds the existing link and returns `Corrected` — a reversal line for the original 6.5 hours and a new line for 7 hours.
9. A project manager reviews the Job Journal in BC and posts it. The hours reach the Job Ledger.
10. The project is closed in BC. `Clockify Event Subscribers ori` fires and `Clockify Archive Sync ori` sends `{ "archived": true }` for the Clockify project. The call is non-blocking: if it fails, a telemetry warning is logged and the BC operation still completes.
11. Later the retention policy removes the reversed integration rows.

---

## Objects

84 objects in `app/src`: 68 codeunits, 5 pages, 4 tables, 2 enums, 2 enum extensions, 1 page extension, 1 permission set and 1 interface. Interfaces carry no object id.

| Object Type | Object ID | Name | Purpose |
| --- | --- | --- | --- |
| Table | 10036785 | Clockify Integration ori | Links between BC records and the Clockify objects they correspond to. Rows are marked `Reversed`, never deleted. |
| Table | 10036786 | Clockify Webhook ori | The Clockify webhooks the connector has registered for real-time time-entry sync. |
| Table | 10036787 | Clockify Workspace Buffer ori | In-memory buffer carrying the workspaces from `GET /workspaces` into the workspace picker. |
| Table | 10036853 | Clockify Setup ori | Company-level setup for the connector. |
| Page | 10036785 | Clockify Integration List ori | Administrative view of the integration links. |
| Page | 10036786 | Clockify Set Secret Dialog ori | Modal dialog that prompts for the API key without echoing keystrokes. |
| Page | 10036787 | Clockify Webhooks ori | Administrative view of the registered webhooks. |
| Page | 10036788 | Clockify Workspace Lookup ori | Read-only lookup over the workspaces the company API key can reach. |
| Page | 10036853 | Timesheets Setup ori | Setup card for the connector. |
| PageExtension | 10036785 | Clockify Setup Ext ori | Adds the Bifrost Timesheets setup action to the Bifröst Setup page. |
| Enum | 10036785 | Clockify API Version ori | Selects which Clockify API implementation the connector talks to. Extensible. |
| Enum | 10036786 | Clockify Sync Result ori | Outcome of synchronising a time entry: Created, Skipped, Corrected, Updated, Error. |
| EnumExtension | 10036785 | Clockify Msg Type ori | Extends Foundation's `Message Type ori` with the 41 Clockify message types. |
| EnumExtension | 10036786 | Clockify Req Log Type ori | Extends `Request Log Type ori` with the Clockify service type. |
| Interface | — | Clockify API Client ori | Transport contract for talking to the Clockify REST API. |
| PermissionSet | 10036785 | BIFROST Timeshts ori | Full permission set for the connector. Assignable. |
| Codeunit | 10036785 | Clockify Archive Sync ori | Archives Clockify clients, projects and tasks when the BC record is deleted, blocked or completed. Non-blocking. |
| Codeunit | 10036786 | Clockify Client ori | `Version 1` implementation of `Clockify API Client ori`: the HTTP client for the public Clockify REST API. |
| Codeunit | 10036787 | Clockify Event Subscribers ori | Event subscribers that keep integration records in sync with BC lifecycle events. |
| Codeunit | 10036788 | Clockify Integration Gate ori | Access gate for the connector; checks that it is configured before a call leaves BC. |
| Codeunit | 10036789 | Clockify Request Mgt ori | Shared helper for the message-type implementations. |
| Codeunit | 10036790 | Clockify Time Entry Sync ori | Syncs a time entry to a Job Journal Line with deduplication, update detection and correction posting. |
| Codeunit | 10036791 | Clockify Webhook Handler ori | Routes inbound webhooks to the time-entry sync engine. |
| Codeunit | 10036792 | Clockify Install ori | Install codeunit for the connector. |
| Codeunit | 10036793 | Clockify Reten. Policy ori | Registers `Clockify Integration ori` with the retention-policy framework and enables the default policy. |
| Codeunit | 10036794 | Clockify ClientCreate Impl ori | Implements `Clockify.Client.Create`. |
| Codeunit | 10036795 | Clockify ClientDelete Impl ori | Implements `Clockify.Client.Delete`. |
| Codeunit | 10036796 | Clockify Client Get Impl ori | Implements `Clockify.Client.Get`. |
| Codeunit | 10036797 | Clockify Client List Impl ori | Implements `Clockify.Client.List`. |
| Codeunit | 10036798 | Clockify ClientUpdate Impl ori | Implements `Clockify.Client.Update`. |
| Codeunit | 10036799 | Clockify Help Builder ori | Renders the shared Markdown skeleton for the connector's help documents. |
| Codeunit | 10036800 | Clockify CurrencyList Impl ori | Implements `Clockify.Currency.List`. |
| Codeunit | 10036801 | Clockify CustFldList Impl ori | Implements `Clockify.CustomField.List`. |
| Codeunit | 10036802 | Clockify Help Get Impl ori | Implements `Help.Clockify.Get`. |
| Codeunit | 10036803 | Clockify Help Overview Sub ori | Adds the `Help.Clockify.Get` entry to Foundation's `Help.Bifrost.Get` directory. |
| Codeunit | 10036804 | Clockify ProjCreate Impl ori | Implements `Clockify.Project.Create`. |
| Codeunit | 10036805 | Clockify ProjDelete Impl ori | Implements `Clockify.Project.Delete`. |
| Codeunit | 10036806 | Clockify Project Get Impl ori | Implements `Clockify.Project.Get`. |
| Codeunit | 10036807 | Clockify Project List Impl ori | Implements `Clockify.Project.List`. |
| Codeunit | 10036808 | Clockify ProjUpdate Impl ori | Implements `Clockify.Project.Update`. |
| Codeunit | 10036809 | Clockify Tag Create Impl ori | Implements `Clockify.Tag.Create`. |
| Codeunit | 10036810 | Clockify Tag Delete Impl ori | Implements `Clockify.Tag.Delete`. |
| Codeunit | 10036811 | Clockify Tag List Impl ori | Implements `Clockify.Tag.List`. |
| Codeunit | 10036812 | Clockify Tag Update Impl ori | Implements `Clockify.Tag.Update`. |
| Codeunit | 10036813 | Clockify Task Create Impl ori | Implements `Clockify.Task.Create`. |
| Codeunit | 10036814 | Clockify Task Delete Impl ori | Implements `Clockify.Task.Delete`. |
| Codeunit | 10036815 | Clockify Task List Impl ori | Implements `Clockify.Task.List`. |
| Codeunit | 10036816 | Clockify Task Update Impl ori | Implements `Clockify.Task.Update`. |
| Codeunit | 10036817 | Clockify TEntryCreate Impl ori | Implements `Clockify.TimeEntry.Create`. |
| Codeunit | 10036818 | Clockify TEntryDelete Impl ori | Implements `Clockify.TimeEntry.Delete`. |
| Codeunit | 10036819 | Clockify TEntryGet Impl ori | Implements `Clockify.TimeEntry.Get`. |
| Codeunit | 10036820 | Clockify TEntryList Impl ori | Implements `Clockify.TimeEntry.List`. |
| Codeunit | 10036821 | Clockify TEntrySync Impl ori | Implements `Clockify.TimeEntry.Sync`. |
| Codeunit | 10036822 | Clockify TEntryUpdate Impl ori | Implements `Clockify.TimeEntry.Update`. |
| Codeunit | 10036823 | Clockify UserGrpList Impl ori | Implements `Clockify.UserGroup.List`. |
| Codeunit | 10036824 | Clockify User Current Impl ori | Implements `Clockify.User.GetCurrent`. |
| Codeunit | 10036825 | Clockify User List Impl ori | Implements `Clockify.User.List`. |
| Codeunit | 10036826 | Clockify WrkspaceList Impl ori | Implements `Clockify.Workspace.List`. |
| Codeunit | 10036827 | Clockify ReqLog Masker ori | Masker implementation for Clockify request log entries. |
| Codeunit | 10036828 | Clockify Secret Mgt ori | Stores and retrieves the company API key in IsolatedStorage (Company scope). |
| Codeunit | 10036829 | Clockify Setup Mgt ori | Drives the actions on the Clockify Setup card. |
| Codeunit | 10036830 | Clockify Webhook Mgt ori | Registers and removes the webhooks that drive real-time sync. |
| Codeunit | 10036831 | Clockify Workspace Mgt ori | Backs the default-workspace picker on the Clockify Setup card. |
| Codeunit | 10036832 | Clockify TEntryRange Impl ori | Implements `Clockify.TimeEntry.SyncRange`. |
| Codeunit | 10036833 | Clockify TimeSheet Mgt ori | Time-sheet automation engine behind the `Clockify.TimeSheet.*` message types. |
| Codeunit | 10036834 | Clockify TSheetCreate Impl ori | Implements `Clockify.TimeSheet.Create`. |
| Codeunit | 10036835 | Clockify TSheetApprv Impl ori | Implements `Clockify.TimeSheet.Approve`. |
| Codeunit | 10036836 | Clockify TSheetPost Impl ori | Implements `Clockify.TimeSheet.Post`. |
| Codeunit | 10036837 | Clockify TSheetArch Impl ori | Implements `Clockify.TimeSheet.Archive`. |
| Codeunit | 10036838 | Clockify TimeSheet Help ori | Markdown help for the `Clockify.TimeSheet.*` message types. |
| Codeunit | 10036839 | Clockify TimeSheet Sync ori | Syncs a time entry into a BC Time Sheet (line plus detail) instead of the Job Journal. |
| Codeunit | 10036840 | Clockify TSheetSync Impl ori | Implements `Clockify.TimeEntry.SyncToTimeSheet`. |
| Codeunit | 10036841 | Clockify TSheetRange Impl ori | Implements `Clockify.TimeEntry.SyncRangeToTimeSheet`. |
| Codeunit | 10036842 | Clockify TimeEntry Parse ori | Shared JSON parsing helpers for the time-entry sync types (parameters, tag arrays, ISO-8601 hours and dates). |
| Codeunit | 10036843 | Clockify TSheetReject Impl ori | Implements `Clockify.TimeSheet.Reject`. |
| Codeunit | 10036844 | Clockify TSheetReopen Impl ori | Implements `Clockify.TimeSheet.Reopen`. |
| Codeunit | 10036845 | Clockify TimeEntry Fetch ori | Fetches a user's finished time entries for a date range, following pagination. |
| Codeunit | 10036846 | Clockify SyncAllUsers Impl ori | Implements `Clockify.TimeEntry.SyncAllUsers`. |
| Codeunit | 10036847 | Clockify Workspace Help ori | Markdown help for the workspace-scoped reference lists (workspaces, users, user groups, currencies, custom fields). |
| Codeunit | 10036848 | Clockify Client Help ori | Markdown help for the client message types. |
| Codeunit | 10036849 | Clockify Project Help ori | Markdown help for the project message types. |
| Codeunit | 10036850 | Clockify Task Help ori | Markdown help for the task message types. |
| Codeunit | 10036851 | Clockify Tag Help ori | Markdown help for the tag message types. |
| Codeunit | 10036852 | Clockify TimeEntry Help ori | Markdown help for the time-entry message types, including the Job Journal sync types. |

The test app (`Bifrost Timesheets - Tests`, `553214e3-b742-4ccf-8ecc-1ee86fbc96f9`) holds 6 objects in range 95600–95699 (95600–95605), including the upgrade codeunit that refreshes the `TIMESHEETS` AL Test Suite.

---

## Dependencies

| App | ID | Purpose |
| --- | --- | --- |
| Bifrost Foundation | `7505e808-6e52-4b96-a328-82573391297a` | Origo, 28.0.0.0. The message loop and queue API (`origo/bifrost/v1.0`), the `Message Type ori` enum this app extends, `Msg Interface ori` and `Message Argument ori`, the request log and its masker contract, `User Setup ori`, the shared `Setup ori` page, and the `Help.Bifrost.Get` directory. |

That is the only AL dependency. The test app additionally depends on Bifrost Timesheets itself and on Microsoft's test libraries.

At runtime a Clockify account with an API key is required. The key is stored in IsolatedStorage (Company scope) by this app, never in a table field.

---

## Documentation

All public documentation lives in the [businesscentralal/bifrost](https://github.com/businesscentralal/bifrost) site repository and is published at <https://businesscentralal.github.io/bifrost>.

| What | Where |
| --- | --- |
| Product documentation (overview, message types, requirements) | <https://businesscentralal.github.io/bifrost/en-us/clockify/> |
| In-product help (context-sensitive help pages, en-US and is-IS) | <https://businesscentralal.github.io/bifrost/en-us/help/clockify/> |
| Building on Bifröst (extensibility guide) | <https://businesscentralal.github.io/bifrost/en-us/extensibility/> |
| Release notes | [CHANGELOG.md](CHANGELOG.md) |
| Project rules for this repository | [.claude/CLAUDE.md](.claude/CLAUDE.md) |
| End-to-end message-type test reports (internal, not published) | `test/reports/` |

**This repository deliberately has no `Help/` or `docs/` folder.** Documentation for every Bifröst app is centralised in the site repository instead. This is an approved deviation from PR gateway check 8 (HTML Help Pages), which otherwise expects `Help/en-US/` and `Help/is-IS/` folders inside the app repository.

### Context-Sensitive Help

Help pages are addressed by Docusaurus slug rather than by HTML file name, resolved against `"contextSensitiveHelpUrl": "https://businesscentralal.github.io/bifrost/{0}/help/clockify/"` in `app/app.json`. `{0}` is the locale; `"supportedLocales"` lists `en-US` and `is-IS`, and all five pages exist in both languages on the site.

| Page | `ContextSensitiveHelpPage` slug |
| --- | --- |
| `Timesheets Setup ori` | `clockify-setup` |
| `Clockify Integration List ori` | `clockify-integration-list` |
| `Clockify Webhooks ori` | `clockify-webhooks` |
| `Clockify Workspace Lookup ori` | `clockify-workspace-lookup` |
| `Clockify Set Secret Dialog ori` | `clockify-set-secret-dialog` |

`Clockify Setup Ext ori` carries no slug of its own — the Bifröst Setup page it extends belongs to Foundation.

### Runtime help

Message-type contracts are also served by the app itself at runtime. `Help.Clockify.Get` returns the connector directory, and every message type answers its own Markdown help through `get_message_type_help` / `Help.Implementation.Get`. The source of those documents is the per-domain help codeunits under `app/src/MessageTypes/`.

---

## Message types

| Domain | Message types |
| --- | --- |
| Directory | `Help.Clockify.Get` |
| Workspace | `Clockify.Workspace.List`, `Clockify.User.GetCurrent`, `Clockify.User.List`, `Clockify.UserGroup.List`, `Clockify.Currency.List`, `Clockify.CustomField.List` |
| Clients | `Clockify.Client.List` / `.Get` / `.Create` / `.Update` / `.Delete` |
| Projects | `Clockify.Project.List` / `.Get` / `.Create` / `.Update` / `.Delete` |
| Tasks | `Clockify.Task.List` / `.Create` / `.Update` / `.Delete` |
| Tags | `Clockify.Tag.List` / `.Create` / `.Update` / `.Delete` |
| Time entries | `Clockify.TimeEntry.List` / `.Get` / `.Create` / `.Update` / `.Delete` |
| Journal sync | `Clockify.TimeEntry.Sync`, `Clockify.TimeEntry.SyncRange`, `Clockify.TimeEntry.SyncAllUsers` |
| Time sheet sync | `Clockify.TimeEntry.SyncToTimeSheet`, `Clockify.TimeEntry.SyncRangeToTimeSheet` |
| Time sheets | `Clockify.TimeSheet.Create` / `.Approve` / `.Reject` / `.Reopen` / `.Post` / `.Archive` |

The keys are the published API contract and never change.

---

## Repository layout

| Folder | Content |
| --- | --- |
| `app/` | The AppSource app (`Bifrost Timesheets`) |
| `app/src/Integration/` | HTTP client, request management, integration table and gate, webhook handler, archive and time-entry sync engines |
| `app/src/Setup/` | Clockify Setup table and card, Bifröst Setup extension, secret, webhook and workspace management |
| `app/src/MessageTypes/` | Message type enum extension, implementations and per-domain help codeunits |
| `app/src/Lifecycle/` | Install codeunit and retention policy |
| `app/src/Permissions/` | `BIFROST Timeshts ori` |
| `app/src/RequestLog/` | Request-log type extension and masker |
| `test/` | Test app (`Bifrost Timesheets - Tests`, range 95600–95699) |
| `test/reports/` | End-to-end message-type test reports and raw test results (internal, not published) |
| `.AL-Go/`, `.github/` | AL-Go for GitHub / COSMO Alpaca pipeline configuration |

---

## Development

- Open `al.code-workspace` in VS Code.
- Development containers: COSMO Alpaca `launch: bc28-is` (CRONUS IS) and `launch: bc28-w1` (W1 CRONUS International Ltd.), both defined in `app/.vscode/launch.json` — git-ignored and the authority for the instance ids. Publish and run the unit tests on **both**.
- Compile locally with `alc.exe`: the app with CodeCop, UICop and AppSourceCop, the test project with CodeCop and UICop only (a test app is never submitted to AppSource, has no `AppSourceCop.json`, and its objects deliberately carry no ` ori` affix). Symbols live in `app/.alpackages`; test symbols in `test/.alpackages`, including the Bifrost Foundation and Bifrost Timesheets `.app` files.

  ```
  alc.exe /project:app /packagecachepath:app/.alpackages /out:app/output/timesheets.app ^
          /analyzer:<CodeCop.dll> /analyzer:<UICop.dll> /analyzer:<AppSourceCop.dll>
  ```

- Publish and run tests without VS Code (pwsh 7, credential from the user-level env vars `BC28IS_USER` / `BC28IS_PASSWORD`, never from files): `bc-origo-bifrost-core/tools/Publish-BifrostApp.ps1 -AppFile <.app>` and `bc-origo-bifrost-core/tools/Run-BifrostTests.ps1`. The test app registers its own `TIMESHEETS` AL Test Suite — run against that suite, not `DEFAULT`.
- Command-line `alc` does not raise AS0011 (mandatory affix); AL-Go CI is the gate, so check the ` ori` suffix yourself before pushing.
- Standards: [Origo BC Development Standards](https://github.com/OrigoSoftwareSolutions/bc-dev-standards). Project rules are in `.claude/CLAUDE.md`.
- Every object carries the mandatory ` ori` suffix; the brand name is carried by the namespace, the app name and the captions, never by an object-name prefix.

---

© 2026 Origo ehf.

<!-- AUTO-UPDATE-START -->
# COSMO Alpaca AL-Go AppSource App Template

[![Use this template](https://github.com/microsoft/AL-Go/assets/10775043/ca1ecc85-2fd3-4ab5-a866-bd2e7e80259d)](https://github.com/new?template_name=Alpaca-AppSource-Template&template_owner=cosmoconsult)

This template repository can be used for managing AppSource Apps for Business Central.

It is a customized version of the [AL-Go-AppSource](https://github.com/microsoft/AL-Go-AppSource) template and is designed to be used with [COSMO Alpaca](https://cosmoconsult.com/cosmo-alpaca).

> [!NOTE]
> If you created this repository using the GitHub web UI (for example by clicking **Use this template** on GitHub.com) instead of creating it from the COSMO Alpaca VS Code extension, you must initialize it using the [COSMO Alpaca VS Code extension](https://marketplace.visualstudio.com/items?itemName=cosmoconsult.cosmo-alpaca). To do this, simply right-click on the repository in VS Code and select _Initialize_.

Please go to https://aka.ms/AL-Go and [COSMO Docs](https://docs.cosmoconsult.com/en-us/cloud-service/alpaca) to learn more.
<!-- AUTO-UPDATE-END -->
