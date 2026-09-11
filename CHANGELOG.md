# Changelog

All notable changes to **Bifrost Timesheets** are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[semantic versioning](https://semver.org/) aligned with the Business Central major version.

## [29.0.0.0] — 2026-09-06

### Fixed (2026-09-11) - install Insert on Retention Policy Setup

Deploy of Bifrost Timesheets to SaaS was rolling back on install: `Clockify Reten. Policy ori`
(`EnableDefaultPolicy`) inserts/modifies system table 3901 `Retention Policy Setup` without a
direct grant, so the tenant denied `TableData 3901 Retention Policy Setup: Insert`.

- Added `Permissions = tabledata "Retention Policy Setup" = RIM;` on codeunit **10036793
  `Clockify Reten. Policy ori`** (R for Get, I for Insert, M for Modify of `Enabled`). No `D`.
- **Choice**: keep the install-time default-policy enable (minimal RIM grant), matching Foundation's
  `ReqLog Retention ori` pattern — do **not** switch to register-allowed-only
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
- **Identity.** App renamed to `Bifrost Timesheets`, version 29.0.0.0, brief and description mention
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
