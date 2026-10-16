# Changelog

## [Unreleased]

### Added (2026-10-16) - Native time sheet message types (#60, #61, #62, #63, #64, #65, #67)

- New message types on enumextension `Clockify Msg Type ori` (10036785): `Timesheets.TimeSheet.Submit` (10036872, codeunit `TS Sheet Submit Impl ori` 10036873), `Timesheets.TimeSheet.Create` (10036873, `TS Sheet Create Impl ori` 10036874), `Timesheets.PendingApproval.Get` (10036874, `TS Pending Appr Impl ori` 10036875), `Timesheets.TimeSheet.Approve` (10036875, `TS Sheet Approve Impl ori` 10036876), `Timesheets.TimeSheet.Reject` (10036876, `TS Sheet Reject Impl ori` 10036877), `Timesheets.TimeSheetLine.CopyFromPrevious` (10036877, `TS Line CopyPrev Impl ori` 10036878), `Timesheets.TimeSheetLine.CreateFromPlanning` (10036878, `TS Line FromPlan Impl ori` 10036879), `Timesheets.Absence.Register` (10036879, `TS Absence Reg Impl ori` 10036880), `Timesheets.TimeSheet.Reopen` (10036880, `TS Sheet Reopen Impl ori` 10036881), `Timesheets.TimeSheet.Post` (10036881, `TS Sheet Post Impl ori` 10036882) and `Timesheets.TimeSheet.Archive` (10036882, `TS Sheet Archive Impl ori` 10036883).
- Shared dispatch `TS Native Mgt ori` (10036868), contract chapters `TS Contract Parts ori` (10036869), write isolation `TS Native Context ori` (10036870) and `TS Native Runner ori` (10036871). `TS Sheet Restrict ori` (10036872) blocks generic writes of Time Sheet Header and of Time Sheet Line Status.
- The six existing `Clockify.TimeSheet.Create/Approve/Reject/Reopen/Post/Archive` names keep running. A successful call adds a `DeprecatedParameter` warning whose next step is `Use the native name.` Their help notes name the native replacement. Reopen, Post and Archive native names return the same success fields as the old names. Create, Approve and Reject native names are the new per-sheet operations, not aliases of the bulk Clockify operations.
- Permission set `BIFROST Timeshts ori` (10036785) grants the new codeunits and time sheet, resource, employee, cause of absence and number series data. No new assignable permission set and no Foundation `Setup ori` grant.
- `Timesheets.Absence.Register` warns when hours fall on Saturday or Sunday. The BC 28 Resource table in this compile has no Base Calendar Code, so closed base-calendar days are not detected.
- Object ids for the sixteen new codeunits moved by +12 to 10036868..10036883, and `TS Native Sheet Tests` moved from 95615 to 95616, so they stay clear of the phone role-center branch. Message enum values are unchanged. Behavior tests cover copy, planning, absence and the Clockify legacy-name warning.
- Issues #66, #59 and #58 stay out of this change.

### Added (2026-10-16) - Phone Role Center (#6)

- `Phone Role Center ori` (page 10036860) and profile `Phone Role Center Profile ori` show three lists: current customers from My Customers, customers worked today (including a running Clockify timer), and customers worked on the previous Monday-to-Friday date.
- `Phone Cust Bucket ori` (enum 10036856) marks each temporary row as Current, Today or Last workday. `Phone Cust Buffer ori` (table 10036857) holds those rows and stores no customer content.
- `Phone Current Cust Part ori` (page 10036861) lists the signed-in user's My Customers. `Phone Today Cust Part ori` (page 10036862) lists customers worked on the work date, including a running timer. `Phone LastDay Cust Part ori` (page 10036863) lists customers worked on the previous Monday-to-Friday date.
- `Phone Add Service Item ori` (page 10036864) asks for a My Items service item and a quantity.
- `Phone Cust Buffer Mgt ori` (codeunit 10036858) builds those lists. A missing resource, Clockify user mapping, workspace or company API key leaves the time lists empty and does not open an error dialog.
- `Clockify Mock State` (codeunit 95602) queues ordered Clockify responses and records the paths the phone tests call. `Clockify Mock Client` (codeunit 95603) returns the next queued response before the single armed response, so the tests do not call Clockify.
- `Phone Sales Quick Add ori` (10036859) adds a My Items service item to a sales invoice. A second add for the same customer appends a line to the still-open phone invoice, marked by `Phone RC Document ori` on `Sales Header` (table extension 10036865). The line carries Job No. and Job Task No. when the row has a job. There is no licence check.
- Permission set `BIFROST Timeshts ori` (10036785) includes the new objects. `Phone RC Full Ext ori` (10036866) extends `BIFROST Full ori`. `Phone RC Read Ext ori` (10036867) extends `BIFROST Read ori` with the lists only.
- September object 10036855 and test codeunit 95608 were already in use. The new objects start at 10036856. The tests are `Phone Role Center Tests` (95615), past the guard-branch test 95614.
- Gunnar's 30 September decisions are the ones implemented. The 11 September note that every item type is offered is not applied. The item must be a service item on My Items.
- `Phone Sales Quick Add ori` suppresses the standard validation confirm while it writes the customer, item, quantity, job and job task the page already collected.
- `Clockify Field Restrict Tests` (95612) expects Foundation 28.0.5 to keep the setup hint in `nextStep`. The same assertion is on the guard branch.

### Changed (2026-10-14) - Version reset to 28.0.0.0

- Owner decision (Gunnar, 2026-10-14): `app/app.json` and `test/app.json` go from 29.0.0.0 to 28.0.0.0, so the first AppSource version aligns with the other Bifröst apps on Business Central 28. The test app's dependency on the app moves to 28.0.0.0 as well.
- The v29 builds were never published outside test environments. Gunnar removed both v29 apps from the UAT environment and cleaned their data.
- Upgrade caveat: a tenant that still has the legacy *Origo Cloud Events Clockify* 28.x (same app id) installed must uninstall it before installing this version, because Business Central cannot downgrade an installed app.
- The earlier "version 29" rationale further down this file (the first-release section, formerly headed 29.0.0.0) is kept as history and is superseded by this entry.

### Changed (2026-10-12) - Clockify Create/Update/Delete direction is Inbound (#32)

- Callers that filter on direction now see these fifteen types as Inbound, not Outbound. `GetMessageDirection` returns `Inbound` on `Clockify ClientCreate Impl ori` (10036794), `Clockify ClientUpdate Impl ori` (10036798), `Clockify ClientDelete Impl ori` (10036795), `Clockify ProjCreate Impl ori` (10036804), `Clockify ProjUpdate Impl ori` (10036808), `Clockify ProjDelete Impl ori` (10036805), `Clockify Task Create Impl ori` (10036813), `Clockify Task Update Impl ori` (10036816), `Clockify Task Delete Impl ori` (10036814), `Clockify Tag Create Impl ori` (10036809), `Clockify Tag Update Impl ori` (10036812), `Clockify Tag Delete Impl ori` (10036810), `Clockify TEntryCreate Impl ori` (10036817), `Clockify TEntryUpdate Impl ori` (10036822) and `Clockify TEntryDelete Impl ori` (10036818). The eleven BC-side sync and time sheet types stay Inbound. Read types stay Outbound.

### Fixed (2026-10-12) - Clockify help text fixes (#32)

- `Help.Clockify.Get` (`Clockify Help Get Impl ori`, 10036802) defines direction by mutation instead of "who calls whom": Outbound = read, Inbound = write or mutating (Clockify writes and the eleven BC-side types, now all listed), and says the Sync/SyncToTimeSheet types read the mapping rows and create, update or reverse the `TIME_ENTRY` rows they sync themselves (the "never touch it" sentence is gone).
- `Clockify Contract Parts ori` (10036855) documents the wrong-workspace response as HTTP 400 "<entity> doesn't belong to Workspace" for every single-ID type (live verify shows Clockify answering 400, not 404), and `Clockify.CustomField.List` documents the 403 Access Denied (Clockify code 501) on plans without custom fields.
- `Clockify.TimeEntry.Sync` and `Clockify.TimeEntry.SyncToTimeSheet` contract parameters mark `start`/`end` (both) and `taskId` (SyncToTimeSheet) optional, matching the `RequireParam`/`GetOptionalParam`/`GetText` usage in the Impl codeunits.
- `Clockify Help Builder ori` (10036799) direction doc comment restates the platform convention instead of the stale BC-side/Clockify split.
- New `Clockify Help Fixes Tests` (95613) asserts the direction of 40 Clockify types, the optional sync parameters, the 400/403 error rows, and the rewritten overview (run through the public dispatcher with the mock API client).

### Changed (2026-10-11) - Current build pins BC 28.5

- `.AL-Go/settings.json` sets `artifact` to `/sandbox/28.5.54151.55751/w1/latest`, so pull request builds and CI/CD compile against Business Central 28.5. AL-Go reads that value as storage/type/version/country/select; the single leading slash keeps country `w1` and select `latest`.
- `.github/Test Current.settings.json` sets the same artifact, `/sandbox/28.5.54151.55751/w1/latest`, so the Test Current workflow no longer overrides the pin with `////latest`. `.github/Test Next Minor.settings.json` and `.github/Test Next Major.settings.json` stay on `////nextminor` and `////nextmajor`. `.github/AL-Go-Settings.json` does not set `artifact`.
- `app/app.json` and `test/app.json` already set runtime `17.0` and application/platform `28.0.0.0`. No app version change, and no AL symbols needed a 28.5 correction.

### Fixed (2026-10-10) - UAT dependency installation

- UAT feature-app deployment uses the Foundation app already deployed by its own pipeline in Dev scope, avoiding an unauthorized AppSource Foundation installation. `.github/AL-Go-Settings.json`: `DeployToBifrost.DependencyInstallMode = "ignore"`. AppSource delivery is unchanged; no AL objects or IDs change.

### Changed (2026-10-04) - CI/CD builds only main; every pull request gets a Pull Request Build

- Build policy only, no app change. `CI/CD` runs on pushes to `main` only, and `Pull Request Build` runs for pull requests into any branch. `.github/AL-Go-Settings.json` sets `CICDPushBranches` to `main` and `CICDPullRequestBranches` to `**`, so Update AL-Go System Files keeps the triggers.

### Changed (2026-10-05) - align with Bifrost Foundation 28.0.1

- The Foundation dependency floor is **28.0.1.0** in `app/app.json` and `test/app.json`, the same floor as Bifrost Language Models and Bifrost Attachments.
- The nine tables and pages this alignment had closed stay extensible. They shipped extensible in the first release (developed as 29.0.0.0), and closing them is an AppSource breaking change.
- `tools/` carries Foundation's source guards. The Source Guards workflow runs the checks that already pass on Attachments: no call stack in answers, validated table views, no obsolete, permission coverage, and Icelandic keyword counts. Contract-parameter and mixed-language guards are copied but not wired in.
- Help Links is not wired in until `businesscentralal/bifrost` main has `help/timesheets/`.

### Security (2026-10-01) - generic data API field restrictions (core#344)

- `Data.Records.Set` refuses the `Webhook Receiver URL` (field 13) on `Clockify Setup ori` (10036853). That URL is where Clockify is told to deliver real-time time-entry webhooks, so a generic-write caller could otherwise redirect time-entry data. `Clockify Field Restrict ori` (10036838) subscribes to Foundation's `OnAfterIsFieldWriteRestrictedForDataRecords` and `OnGetDedicatedMessageTypeHintForField`. The hint is locked machine-facing text, `the Timesheets setup page (Clockify Setup)`, which Foundation composes into the refusal. Reading the field stays allowed. The Timesheets setup page and the Clockify message types / webhook handler are unchanged (#41).
- `Clockify Field Restrict Tests` (95612) cover the restriction through public `Help.Fields.Get`, and public `Data.Records.Set` refusal and allowed writes.
- Paired builds treat warnings as failures, run CodeCop and UICop, and apply AppSourceCop to the product app only. Test-app changes trigger a full paired Default/Test build.

### Changed (2026-10-01) - Clockify writes and time sheet posting declare effect irreversible (#39)

- `Clockify.Client/Project/Task/Tag/TimeEntry.Create` and `.Update` write to Clockify outside the Business Central transaction, and `Clockify.TimeSheet.Post` posts job ledger entries; all eleven now declare effect `irreversible`, so the Orchestrator's Omit Commit guard refuses them in a rollback chain.
- The effect `changes` text and the overview now say per type what changes: a Clockify write, a Clockify delete, a posting, or Business Central records only.
- New `Message Contract Effect Tests` (95611) assert the effect of every writing type and that syncs and the time sheet lifecycle stay `write`.

### Removed (2026-10-01) - markdown help procedure (#37)

- Every Clockify message type codeunit drops `GetMessageHelpAsMarkdownDocument`. Foundation removed it from `Msg Interface ori` (core#198); help is the contract chapters that `Help.Implementation.Get` returns. No chapter changed.
- Deleted `Clockify Contract Help 1/2/3 ori` (10036856-10036858), which only returned empty text, and their permission entries.
- Bifrost Foundation dependency raised to 28.0.0.186, the first Foundation build without the procedure, in `app/app.json` and `test/app.json`.
- `.claude/CLAUDE.md` id ledger brought up to date (contract parts, contract test codeunits, freed help ids).

### Changed (2026-09-29) - Message contracts batch 1

- Added bilingual discovery keywords and selection descriptions plus structured contract chapters for help, workspace-level reads, and client message types.
- Added batch 1 contract conformance coverage and pinned Bifrost Foundation to 28.0.0.166.

### Changed (2026-09-29) - Message contracts batch 2

- Added bilingual discovery metadata and structured contract chapters for project, task, and tag message types.
- Added batch 2 contract conformance coverage.

### Changed (2026-09-29) - Message contracts batch 3

- Added bilingual discovery metadata and structured contract chapters for time-entry and time-sheet message types.
- Added batch 3 contract conformance coverage.

### Fixed (2026-09-30) - Clockify message-type interface bindings (#38)

- Bind `Msg Interface ori`, `Msg Contract ori`, and `Msg Discovery ori` on one `Implementation` property for every Clockify message type, matching the Foundation enum.
- Remove the stale `Clockify TimeSheet Help ori` permission. That codeunit was replaced by `Clockify Contract Help 3 ori`, which is already granted.
- Import `System.TestLibraries.Utilities` in the contract batch tests so `Library Assert` resolves.
- Name message types with `Names().Get(Ordinals().IndexOf(...))` instead of `Format` on the enum, and use `JsonObject.WriteTo` for contract text.
- Include a `related` chapter on `Help.Clockify.Get` so the help contract points at `Clockify.Workspace.List`.
- Pin Bifrost Foundation to 28.0.0.166 in the app and the test app (approved). This is the first green build that contains `Msg Contract ori`.
- Add is-IS translations for the discovery labels, list only error texts the app sends, and move the former help facts into the contract chapters.

### Changed (2026-09-25) - Foundation latest CI build, floor 28.0.0.0

- The app builds against the latest Foundation CI build with a Foundation floor of 28.0.0.0.
- AL-Go `appDependencyProbingPaths` for bc-origo-bifrost-core: `release_status: latestBuild`, `version: latest`.
- AL-Go `fullBuildPatterns` includes `.AL-Go/settings.json` so a probe-only settings change triggers a full build under the `modifiedApps` incremental strategy.
- Webhook sync test calls `Webhook Inbound Events ori.OnWebhookReceived` directly. `Dispatcher ori.Execute` is the Foundation EULA gate and does not reach the handler in CI.

- App.json URL fields (`help`, `privacyStatement`, `EULA`, `contextSensitiveHelpUrl`) now point at the published Bifröst timesheets docs and Foundation privacy/EULA pages, and Application Insights telemetry uses the shared connection string.
- Page help links (`ContextSensitiveHelpPage`) now use the renamed docs routes (`clockify-*` slugs renamed to `timesheets-*`).

### Security

- Default (release) builds no longer ship the test app's internalsVisibleTo grant; the strip moved to PipelineInitialize.ps1 because Alpaca never ran PreCompileApp.ps1 (core#129).

### Changed (2026-09-17) - Bifrost Foundation Exact pin 28.0.0.100 (no float)

- App/test Bifrost Foundation dependency set to Exact `28.0.0.100`.
- AL-Go `appDependencyProbingPaths` for bc-origo-bifrost-core: `release_status: latestBuild`, `version: 1.0.0.100`.
- `nuGetFeedSelectMode: Exact` so NuGet does not resolve `[28.0.0.100,)` upward to colliding `.107`.

### Changed (2026-09-21) - Bifröst logo refresh

- App logo: new Bifröst wordmark with "Powered by origo." tagline; app-name line unchanged.

All notable changes to **Bifrost Timesheets** are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[semantic versioning](https://semver.org/) aligned with the Business Central major version.

## [28.0.0.0] — unreleased (first AppSource version; developed as 29.0.0.0 until 2026-10-14)

### Fixed (2026-09-11) - Retention Policy Setup Insert without Modify

Follow-up after PR #17: Deploy of 29.0.0.22 still failed at `EnableDefaultPolicy` line 12 with
**IndirectModify** on TableData 3901. Insert succeeded under the RIM grant, but the app has no
Modify entitlement on that System-app table, and the `Permissions` property cannot invent one.

- Populate every field including `Enabled := true` **before** `Insert(true)`; remove `Modify(true)`.
- If a Retention Policy Setup row already exists (even disabled), leave it alone — customer enables it.
- Reduce codeunit grant to `tabledata "Retention Policy Setup" = RI` (no `M`, no `D`).
- Still no system-table grant on assignable permission set `BIFROST Timeshts ori` (10036785).
- Update **95607 `Clockify Reten. Policy Tests`** TC001 to assert Enabled after a single Insert;
  TC002 still locks idempotent re-run (exit, no second row).

### Fixed (2026-09-11) - install Insert on Retention Policy Setup (superseded by RI follow-up)

Deploy of Bifrost Timesheets to SaaS was rolling back on install: `Clockify Reten. Policy ori`
(`EnableDefaultPolicy`) inserts into system table 3901 `Retention Policy Setup` without a
direct grant, so the tenant denied `TableData 3901 Retention Policy Setup: Insert`.

- Initially added `Permissions = tabledata "Retention Policy Setup" = RIM;` on codeunit **10036793
  `Clockify Reten. Policy ori`** (PR #17). Insert then succeeded; subsequent Modify failed with
  IndirectModify — see follow-up Fixed entry above (RI + Enabled before Insert).
- **Choice**: keep the install-time default-policy enable (minimal RI grant), matching Foundation's
  pattern — do **not** switch to register-allowed-only
  (`RetenPolAllowedTables.AddAllowedTable` only) like Orchestrator/Attachments.
- Did **not** add any system-table grant to assignable permission set `BIFROST Timeshts ori`
  (10036785).
- Tests **95607 `Clockify Reten. Policy Tests`** TC001–TC002 lock insert/idempotent re-run behaviour
  (SUPER cannot prove the Permissions grant; green Deploy to Bifrost is the install proof).

### Setup notifications and wizard (2026-09-07)

Across the Bifröst family, setup notifications now live **only** on Bifröst Foundation's `Setup ori`
page ("Bifrost Setup"), and their single action is *Start setup wizard*. No app raises setup
notifications of its own any more.

- Added codeunit **10036854 `Timesheets Registration ori`** (`Access = Internal`), which subscribes to
  Foundation's `App Registry ori.OnRegisterApps` and registers this app with its module id, its module
  name and its setup page `Timesheets Setup ori` (10036853). That is the only thing the codeunit does —
  Foundation aggregates the registrations and decides which notifications to show.
- Granted the new codeunit in permission set `BIFROST Timeshts ori`.
- Bifrost Timesheets raised **no** setup notification before this change, so nothing had to be removed;
  a scan of `app/src` confirms the app creates no `Notification` at all.
- Test **95606 `Timesheets Registration Tests`** asserts that the app appears in
  `App Registry ori.GetApps` with the right app id and setup page id.

### Added (2026-09-07) - Setup Wizard action on Timesheets Setup

- Added action **Setup Wizard** to page `Timesheets Setup ori` (10036853), promoted into the
  existing Process group. It opens Bifröst Foundation's `Setup Wizard ori` page directly from this
  app's own setup card, alongside the existing API key and webhook actions.

### Changed (2026-09-07) - tests run on Foundation's public API

- The test app no longer depends on Bifröst Foundation's internals: Bifrost Timesheets - Tests has been removed
  from Foundation's `internalsVisibleTo`, and the test suite compiles and runs against a Foundation
  package that does not grant it. No test code had to change - the suite never touched a Foundation internal.

Migration of *Origo Cloud Events Clockify* 28.1.0.0 to **Bifrost Timesheets** on Bifrost Foundation.
This is an **in-place successor**: the app id and the test range (95600–95699) are unchanged, so an
installed tenant upgrades rather than installing a second app. The object id range moved before
first release — see "Object ID range moved" below. The 41 message-type keys and every help document
are unchanged — they are the published API contract.

### Object ID range moved: 70009200-70009249 -> 10036785-10036884 (2026-09-06, before first release)

The block originally assigned to this app (70009200-70009249, 50 ids) could not hold it: the app
grew to 83 objects, including 68 codeunits, up to id 70009268 — 19 ids past the end of the assigned
block (`app/app.json` had wrongly declared 70009200-70009299, covering the overrun by accident).
Assigned blocks are never extended once given out, so every object id moved to the free tail of
Public Range 2: **10036785-10036884**. Object ids moved from 70009200-70009268 to
10036785-10036853 (offset -59972415); the assigned 50-id block could not hold the app and ranges
are never extended; no upgrade path needed - never published. This includes the `Clockify Msg Type
ori` and `Clockify Req Log Type ori` enum-extension value ordinals, which share the app's object-id
block by convention. The 41 message-type keys (`Clockify.*`, `Help.Clockify.Get`) and their
enum-extension **value names** are unchanged — only the underlying ordinal numbers moved. The test
app's own range (95600-95699) is untouched.

### App name: Bifrost Clockify -> Bifrost Timesheets (2026-09-06, before first release)

Bifröst apps are named after the business capability, not after the connected service. The app
ships as **Bifrost Timesheets**; Clockify stays visible everywhere it identifies the service.

- `app.json` name `Bifrost Clockify` -> **Bifrost Timesheets**; test app
  **Bifrost Timesheets - Tests**. Icelandic brand form: **Bifröst tímaskýrslur**.
- Namespace `Origo.Bifrost.Clockify` -> `Origo.Bifrost.Timesheets` (tests `.Test`).
- Permission set `BIFROST Clockify ori` -> `BIFROST Timeshts ori` (permission-set object names are
  `Code[20]`; `BIFROST Timesheets ori` would be 22). Its caption is now
  *Bifrost Timesheets* / *Bifröst tímaskýrslur* instead of the untranslated *Clockify - Full*.
- Setup page `Clockify Setup ori` (10036853) -> `Timesheets Setup ori`, captioned
  *Bifrost Timesheets Setup* / *Uppsetning Bifröst tímaskýrslna*. The setup **table** keeps the name
  `Clockify Setup ori` - it holds Clockify connection settings. The single action this app adds to
  Bifröst Setup is captioned the same way instead of just *Clockify*.
- **Object names, the 41 message-type keys (`Clockify.*`, `Help.Clockify.Get`), the help documents
  and the help slugs are unchanged.** Clockify is the connected service and the domain word.
- Repository renamed `origo-bc-cloudevents-clockify` -> `bc-origo-bifrost-timesheets`; the
  documentation slug stays `clockify` until the site folders are renamed.
- The test app's AL Test Suite is renamed `CLOCKIFY` -> `TIMESHEETS`, matching the name
  `tools/Run-BifrostTests.ps1` derives from the test app name.

### Added

- Message types for Projects and Time Sheets from the open pull request
  *#5 Message Types for Projects* (`feature-#5_MessageTypes_Projects`), merged into this migration:
  `Clockify.TimeSheet.Create`, `.Approve`, `.Post`, `.Archive`, `.Reject`, `.Reopen`,
  `Clockify.TimeEntry.SyncToTimeSheet`, `.SyncRangeToTimeSheet` and `.SyncAllUsers`, together with
  `Clockify TimeSheet Mgt ori`, `Clockify TimeSheet Sync ori`, `Clockify TimeEntry Fetch ori`,
  `Clockify TimeEntry Parse ori` and 430 lines of new tests.
- `Bifrost Timesheets.is-IS.xlf` with all 130 translation units translated. The legacy app shipped no
  Icelandic translation file at all.
- `is-IS=` comments on the 18 labels, enum captions and search terms that had none.
- A dedicated `CLOCKIFY` AL Test Suite built by the test app, refreshed by a new upgrade codeunit
  (95605) so republishing picks up new test codeunits.

### Changed

- **Documentation moved to the site.** All public documentation and in-product help now live in the
  [businesscentralal/bifrost](https://github.com/businesscentralal/bifrost) repository and are
  published at <https://businesscentralal.github.io/bifrost> — product documentation at `/en-us/clockify/`, help at
  `/en-us/help/clockify/` and `/is-is/help/clockify/`. This repository keeps no `docs/` or `Help/`
  folder, and `README.md` was trimmed to header facts, links, layout, dependencies and development
  notes.
- **Context-sensitive help slugs.** `ContextSensitiveHelpPage` was added to the five pages, using
  the Docusaurus slugs of the new help pages: `clockify-setup` (`Timesheets Setup ori`),
  `clockify-integration-list` (`Clockify Integration List ori`), `clockify-webhooks`
  (`Clockify Webhooks ori`), `clockify-workspace-lookup` (`Clockify Workspace Lookup ori`) and
  `clockify-set-secret-dialog` (`Clockify Set Secret Dialog ori`). `Clockify Setup Ext ori` adds no
  slug of its own — the Bifröst Setup page belongs to Foundation.
- **Test reports moved.** The migration test report and the raw queue-API call log moved from
  `app/docs/` to `test/reports/`. They are internal and are deliberately not published to the
  documentation site. The tracked AL test result XML files under `TestResults/` were dropped from
  the repository — a stray `.xml` inside an AL project folder raises AL1025.

- **Platform.** Dependency moved from *Origo Cloud Events Core* (`a629b897-…`) to **Bifrost
  Foundation** `7505e808-6e52-4b96-a328-82573391297a` 28.0.0.0. The API route is now
  `origo/bifrost/v1.0`.
- **Identity.** App renamed to `Bifrost Timesheets`, version 29.0.0.0 (reset to 28.0.0.0 on 2026-10-14, see the Unreleased entry), brief and description mention
  Bifröst. Namespace `Origo.PTE.CloudEvents.Clockify` → `Origo.Bifrost.Timesheets`; the test app moved
  to `Origo.Bifrost.Timesheets.Test`. New Clockify logo.
- **Interface.** `ExecuteCloudEventTask` → `ExecuteBifrostTask` on all 41 implementations.
- **Object names.** Every object now carries the mandatory ` ori` suffix within 30 characters, and
  the words "Cloud Event(s)" are gone. Renames beyond the plain suffix:

  | Legacy | Bifröst |
  |---|---|
  | `Clockify Cloud Event Msg Type` (enumext) | `Clockify Msg Type ori` |
  | `Clockify Full` (permission set) | `BIFROST Timeshts ori` |
  | `Clockify Workspace List Impl` | `Clockify WrkspaceList Impl ori` |
  | `Clockify Client Create Impl` | `Clockify ClientCreate Impl ori` |
  | `Clockify Client Update Impl` | `Clockify ClientUpdate Impl ori` |
  | `Clockify Client Delete Impl` | `Clockify ClientDelete Impl ori` |
  | `Clockify Project Create Impl` | `Clockify ProjCreate Impl ori` |
  | `Clockify Project Update Impl` | `Clockify ProjUpdate Impl ori` |
  | `Clockify Project Delete Impl` | `Clockify ProjDelete Impl ori` |
  | `Clockify Currency List Impl` | `Clockify CurrencyList Impl ori` |
  | `Clockify UserGroup List Impl` | `Clockify UserGrpList Impl ori` |
  | `Clockify CustomField List Impl` | `Clockify CustFldList Impl ori` |
  | `Clockify TimeEntry List Impl` | `Clockify TEntryList Impl ori` |
  | `Clockify TimeEntry Get Impl` | `Clockify TEntryGet Impl ori` |
  | `Clockify TimeEntry Create Impl` | `Clockify TEntryCreate Impl ori` |
  | `Clockify TimeEntry Update Impl` | `Clockify TEntryUpdate Impl ori` |
  | `Clockify TimeEntry Delete Impl` | `Clockify TEntryDelete Impl ori` |
  | `Clockify TimeEntry Sync Impl` | `Clockify TEntrySync Impl ori` |
  | `Clockify TimeEntrySyncRng Impl` | `Clockify TEntryRange Impl ori` |
  | `Clockify TimeSheetCreate Impl` | `Clockify TSheetCreate Impl ori` |
  | `Clockify TimeSheetApprove Impl` | `Clockify TSheetApprv Impl ori` |
  | `Clockify TimeSheetPost Impl` | `Clockify TSheetPost Impl ori` |
  | `Clockify TimeSheetArchive Impl` | `Clockify TSheetArch Impl ori` |
  | `Clockify TimeSheetReject Impl` | `Clockify TSheetReject Impl ori` |
  | `Clockify TimeSheetReopen Impl` | `Clockify TSheetReopen Impl ori` |
  | `Clockify TimeSheetSync Impl` | `Clockify TSheetSync Impl ori` |
  | `Clockify TimeSheetSyncRng Impl` | `Clockify TSheetRange Impl ori` |

  Foundation objects are referenced by their Bifröst names: `Message Argument ori`,
  `Msg Interface ori`, `Msg Direction ori`, `Message Type ori`, `Request Log Type ori`,
  `Request Log Masker ori`, `Message Events ori`.
- **Setup moved off the Foundation card.** The connector no longer extends Foundation's `Setup ori`
  table or fills its page with a Clockify pane. The seven settings live on a new
  `Clockify Setup ori` table and card (10036853), and the page extension adds exactly one action in
  Foundation's `Apps` group plus its promoted reference — the footprint every dependent Bifröst app
  is allowed. Field names lost their redundant `Clockify ` prefix (`Clockify API Version` →
  `API Version`, and so on).
- **Help consolidated per domain.** The Markdown that used to sit inline in each implementation now
  lives in six domain codeunits — `Clockify Workspace Help ori`, `Clockify Client Help ori`,
  `Clockify Project Help ori`, `Clockify Task Help ori`, `Clockify Tag Help ori`,
  `Clockify TimeEntry Help ori` (10036847–10036852) — each with a `case` on `Message Type ori`.
  `Clockify TimeSheet Help ori` became a `case` dispatcher too. The help text itself is unchanged.
- **Repository layout.** `Cloud Events Clockify/` → `app/`, `Cloud Events Clockify - Tests/` →
  `test/` (`test/src` for mocks, `test/test` for the test codeunits), AL-Go settings, workspace file,
  `.gitignore` and `app/.vscode/launch.json` aligned with the other Bifröst repositories. Tracked
  build artefacts removed.
- **Help URLs.** `help` and `contextSensitiveHelpUrl` point at
  <https://businesscentralal.github.io/bifrost> (`/en-us/clockify/` and `/{0}/help/clockify/`),
  where the site is actually published. They move to `bifrost.origo.is` once that DNS record
  exists. The pages still have to be written in the `businesscentralal/bifrost` site repository.

- **PR gateway 2026-09-07 — narrowed database reads.** 15 `SetLoadFields` and 8 `ReadIsolation`
  statements were added on the hot read paths: the unfiltered `Time Sheet Header` scan behind
  `Clockify.TimeSheet.Post`, the open-time-sheet lookup that runs once per synced entry, the three
  time-sheet batch scans, the four Clockify-to-BC mapping lookups, and the webhook list. Two existing
  `SetLoadFields` in `Clockify Archive Sync ori` were missing `"BC Code"`, which the loop reads, so
  every `TASK` row triggered a just-in-time re-fetch.
- **PR gateway 2026-09-07 — the test project no longer runs AppSourceCop.** The test app has no
  `AppSourceCop.json`, no `TranslationFile` feature flag, and its objects deliberately carry no ` ori`
  affix, so the analyzer only ever produced noise (`AS0015`, `AS0054`, `AS0092`). `test/.vscode/settings.json`
  now declares CodeCop + UICop, matching how the test app is actually built.

### Removed

- `tableextension 70009200 "Clockify Setup Ext"` on `Cloud Events Setup ori`. Its seven fields moved
  to `Clockify Setup ori`. **There is no upgrade codeunit to carry the values across**: the fields
  belonged to a table owned by a dependency that this version no longer references, so the values
  cannot be read after the dependency swap. The app was never published, so no tenant is affected;
  re-enter the Clockify settings on the new card after upgrading a development environment.
- `test/ruleset.json`. It existed only to suppress `AS0084` for the test project's AppSourceCop run,
  was referenced by no settings file, and still carried the pre-rename name
  "Cloud Events Clockify Tests Ruleset".

### Fixed

- Icelandic caption collision on `Clockify Setup ori`: fields *Default Workspace ID* and
  *Default Workspace* both translated to `Sjálfgefið vinnusvæði`. The id field is now
  `Kenni sjálfgefins vinnusvæðis`.

- The test app no longer deletes and rebuilds the container-wide `DEFAULT` AL Test Suite, which used
  to wipe the suite of every other test app installed beside it and never contained Clockify's own
  codeunits on a fresh install.
- Three Icelandic messages still directed the user to *Bifrost stillingar*; they now name the
  Clockify Setup card, matching the English text.

The following were found by the PR gateway run on 2026-09-07.

- **The `result` field of a sync response no longer depends on the caller's language.** Five message
  types built it with `Format()` applied to `Clockify Sync Result ori`, which returns the translated
  caption — an Icelandic session answered `"result": "Stofnað"` where the help document promises
  `Created|Updated|Skipped|Error`. The value name is now resolved culture-independently.
- **Time-entry payloads and stored correlation keys are parsed and written culture-independently.**
  Thirteen `Evaluate` calls read ISO-8601 datetimes from the Clockify API without format 9, and
  `Clockify Integration ori."Clockify Name"` was written with `Format(Hours)` and parsed back with a
  bare `Evaluate`. A write and a read under different session languages returned zero hours, which
  posted a zero-hour reversal against a real ledger entry.
- **`Clockify.TimeEntry.SyncToTimeSheet` answers `status = Error` instead of throwing** when the
  mapped job task no longer exists, and when a Clockify description is longer than the 250-character
  integration name field. Both previously raised an exception out of the task and out of the webhook
  subscriber.
- **`Clockify.TimeSheet.Approve` no longer skips lines.** It filtered the recordset on `Status = Open`
  and then changed `Status` inside the loop, so each processed line dropped out of the filter and
  `Next()` could step over the following one. It now tests the status in code, the way
  `Clockify.TimeSheet.Reject` and `Clockify.TimeSheet.Reopen` already did.
- **`Clockify.TimeSheet.Post` reports only the lines that actually posted.** The result of
  `Codeunit.Run` on the posting codeunit was discarded, so a line whose posting failed and rolled back
  was still counted.
- `Clockify.TimeEntry.SyncRange` said an entry with no finished interval was "skipped" while counting
  it as an error; the wording now matches the result. Both messages became `Locked` labels.
- `Action`, a reserved AL name, was used as a `Text` variable and parameter in
  `Clockify Help Builder ori`; renamed to `ActionName`.
- Three `internal` procedures on `Clockify Time Entry Sync ori` that are called from another codeunit
  had no XML documentation.

### Security

- **The Clockify webhook signing token no longer reaches the request log.** `Clockify ReqLog Masker ori`
  returned every response body unchanged, documented as safe because the API key travels only in the
  `X-Api-Key` header. That holds for the key, but the webhook endpoints answer with `authToken` — the
  only credential that authenticates an inbound Clockify webhook — and it was persisted in
  `Request Log ori` in cleartext. Response bodies are now scanned and every `authToken` value is
  redacted at any depth, in objects and in arrays; bodies that are not JSON or carry no token are
  returned untouched. Four regression tests cover it.

### Notes

- The Clockify API key still lives in this app's own `Clockify Secret Mgt ori` (IsolatedStorage,
  Company scope) with its own masked dialog. Bifrost Foundation now owns a unified secret store
  (`Secret Store ori`); **the API key will move there in a later pass**, at which point the key has
  to be re-entered once — an install take-over cannot copy another extension's IsolatedStorage.
- Verification: CodeCop + UICop + AppSourceCop clean, **62/62** unit tests green on `bc28-is` and
  `bc28-w1`, and all 41 message types exercised over the queue API on `bc28-is` (87 calls, no
  HTTP 5xx). See [test/reports/Bifrost_Timesheets_TestReport_2026-09-06.md](test/reports/Bifrost_Timesheets_TestReport_2026-09-06.md).
- The PR gateway run of 2026-09-07 is recorded in
  [test/reports/PR_Gateway_2026-09-07.md](test/reports/PR_Gateway_2026-09-07.md). It closes the
  findings listed above and leaves six open decisions, the largest being that inbound Clockify
  webhooks are not authenticated in Business Central.

---

## [28.1.0.0] and earlier — Origo Cloud Events Clockify

Released as *Origo Cloud Events Clockify* on Origo Cloud Events Core. See the repository history
before 2026-09-06.
