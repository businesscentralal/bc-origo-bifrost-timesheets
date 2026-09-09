# Origo BC — PR Gateway Report

```
╔══════════════════════════════════════════════════════════════════╗
║           Origo BC — PR Gateway Report                           ║
║           Extension : Bifrost Timesheets v29.0.0.0               ║
║           Customer  : Origo (AppSource, Bifröst portfolio)       ║
║           Date      : 2026-09-07 03:30                           ║
║           Tier      : Standard (AppSourceCop.json, no stories/)  ║
║           Branch    : feature/bifrost-clockify-migration → main  ║
║           PR        : #12                                        ║
╠══════════════════════════════════════════════════════════════════╣
║  LAYER 1 — Automated Script (23 checks)                          ║
║  Files scanned: 84     Passed: 12/23     Failed: 11              ║
║  After agent triage: 21 real findings fixed, 0 open,             ║
║                      431 dismissed as false positives            ║
╠══════════════════════════════════════════════════════════════════╣
║  LAYER 2 — Agent Deep Checks         Result                      ║
╠══════════════════════════════════════════════════════════════════╣
║  1.  AL Compiler                     ✅ Pass  (0 err / 0 warn)   ║
║  2.  Object Naming — Prefix          ✅ Pass  (84 objects)       ║
║  3.  Object ID Ranges                ✅ Pass                     ║
║  4.  SetLoadFields — Exceptions      ✅ Pass  (15 added)         ║
║  5.  Breaking Change Guard           ⏭ Skip (initial phase)     ║
║  6.  app.json — Semantic             ⚠️ Pass w/ 2 deviations     ║
║  7.  CHANGELOG & README Quality      ✅ Pass after rebuild       ║
║  8.  HTML Help Pages                 ✅ Deviation, slugs resolve ║
║  9.  Documentation Generation        📝 Done                     ║
║  10. Unit Tests                      ✅ Pass  (62/62 × 2)        ║
║  11. Story-Doc Consistency           ⏭ Skip (no stories/)       ║
║  12. Logic Review                    🔍 6 findings               ║
║  13. What I Couldn't Check           🔍 5 gaps noted             ║
║  14. Role Coverage                   ⚠️ 1 layering gap           ║
║  15. Platform Integration            ⏭ Skip (not standards repo)║
╠══════════════════════════════════════════════════════════════════╣
║  Overall : ✅ 9 passed  ❌ 0 failed  ⚠️ 3 warnings  ⏭ 3 skipped ║
╚══════════════════════════════════════════════════════════════════╝
```

Target branch `main` — from `.claude/CLAUDE.md` (`Default branch: main`) and confirmed against the
open PR #12.

Approved deviations, stated here once and never counted as failures: documentation lives in
`businesscentralal/bifrost` and this repository carries no `Help/` or `docs/` folder; help URLs use
`businesscentralal.github.io` until the `bifrost.origo.is` DNS record exists; test-app objects carry
no ` ori` affix; there is no AppSourceCop version baseline, so the breaking-change guard is skipped;
version 29.0.0.0 against sibling apps at 28.x is the documented in-place-successor numbering.

---

## Layer 1 — Automated scan, with agent triage

The script reports 11 failed checks and 452 raw findings. Every finding was read against the
source. 21 were real and are fixed; 431 are false positives, with the reason recorded.

| Check | Raw | Real | Disposition |
| --- | ---: | ---: | --- |
| `xml_doc_comments` | 254 | 3 | 251 are the `Msg Interface ori` / `Request Log Masker ori` / `Clockify API Client ori` implementations — the contract is documented on the interface, and every object itself is documented. This is the pattern the whole Bifröst portfolio uses. The 3 real ones were `ResolveProjectMapping`, `ResolveTaskMapping` and `ResolveUserMapping` on `Clockify Time Entry Sync ori` — `internal` procedures called from another codeunit with no `///` at all. Documented. |
| `set_load_fields` | 82 | 15 | 15 added (see Check 4). Of the 67 dismissed: ~50 are not record reads at all (`JsonObject.Get`, `JsonToken.Get`, `Dictionary.Get`, `List.Get`, `IsolatedStorage.Get`), 42 hits are `Record.WritePermission()` handles that never fetch a row, 7 are temporary records, 6 are singleton `Get()` on a setup table with a clustered primary key, and the rest are variables that are `Init`/`Insert`/`Modify`-ed or whole-record-assigned right after the read, where a partial load is a correctness trap rather than an optimisation. |
| `read_isolation` | 41 | 8 | 8 added. The rest are update paths (`FindSet(true)`, `FindLast` before an insert — which would want `UpdLock`, not `ReadCommitted`), rows that are modified or deleted immediately after the read, temporary records (AP-023), and `IsEmpty()` existence probes on 1–3 row tables where the statement would be noise. The sibling app `bc-origo-bifrost-attachments` carries 3 such statements in total; 8 is the right order of magnitude, 41 is not. |
| `caption_translation` | 42 | 0 | All 42 are `Locked = true` captions on `Clockify Msg Type ori` (41 message-type keys) and `Clockify Req Log Type ori`. They are the published wire contract and must not be translated. |
| `one_statement_per_line` | 43 | 0 | Every hit is a procedure signature with several parameters; the scanner counts the parameter separator `;` as a statement separator. |
| `modernization` | 12 | 0 | All substring matches inside longer words or inside help prose: `NAS` matched in `ValueToke**nAs**Text`, `Timer` in the help sentence "returns running timers", and `UserGroup.` in the message-type key `Clockify.UserGroup.List`. |
| `try_prefix_convention` | 4 | 0 | `TryGetWorkspaceCurrencies`, `TryFetchUserEntries`, `TryGetApiKey`, `TryGetJobJournal` are `Boolean`-returning "try to get" procedures without `[TryFunction]`. This is the established portfolio convention, not a defect: Bifröst Foundation itself ships `TryGetSecret`, `TryGetRemaining`, `TryAddQuotaWarning` and `TryGetStoredJsonSnapshot` in exactly this shape. Renaming here would make this app the odd one out. |
| `page_code_minimal` | 4 | 0 | The four action triggers on `Timesheets Setup ori` are a `var` block, one call and `CurrPage.Update(false)`. The scanner counts the `var` line as logic. |
| `reserved_var_names` | 2 | 2 | `Action` was used as a `Text` variable and parameter name in `Clockify Help Builder ori`, shadowing the AL built-in. Renamed to `ActionName` throughout (11 occurrences). |
| `format_guid` | 1 | 1 | Real, and wider than the scanner saw — see Check 12, finding 2. |
| `global_variables` | 1 | 0 | `Clockify Help Builder ori` holds 20 globals because it *is* the builder that assembles one help document; the alternative is passing 20 parameters. |

---

## Check 1 — AL compiler

| Project | Analyzers | Result |
| --- | --- | --- |
| `app` (84 files) | CodeCop + UICop + AppSourceCop | **0 errors, 0 warnings** |
| `test` (6 files) | CodeCop + UICop | **0 errors, 0 warnings** |

`alc.exe` 17.0.34.45391, symbols from `app/.alpackages` and `test/.alpackages` with the current
`Origo_Bifrost Foundation_28.0.0.0.app`. Command-line `alc` does not raise AS0011 (mandatory affix),
so the ` ori` suffix was verified separately across all 84 objects — see Check 2.

**Fixed on the way:** `test/.vscode/settings.json` listed `${AppSourceCop}` for the test project, but
the test app cannot pass AppSourceCop and is not meant to — it has no `AppSourceCop.json`, no
`TranslationFile` feature flag, and its objects deliberately carry no affix. Running the analyzer
there produced `AS0015`, `AS0054` and `AS0092`. The test project now declares CodeCop + UICop, which
is how it is actually built and what the Origo rule says. `test/ruleset.json` existed only to
suppress `AS0084` for that analyzer, was referenced by nothing, and still carried the pre-rename name
"Cloud Events Clockify Tests Ruleset"; it is deleted.

---

## Check 2 — Object naming and affix

84 objects in `app/src`: 68 codeunits, 5 pages, 4 tables, 2 enums, 2 enum extensions, 1 page
extension, 1 permission set, 1 interface.

- **Affix:** 84 of 84 end in ` ori`. None missing.
- **Length:** none over 30 characters. 13 names sit at exactly 30 (`Clockify ClientCreate Impl ori`,
  `Clockify Set Secret Dialog ori`, …) — no headroom left for a rename.
- **Permission set:** `BIFROST Timeshts ori` is exactly 20 characters, the `Code[20]` ceiling.
- **Test app:** 6 objects, 95600–95605, deliberately without the affix (approved deviation).

---

## Check 3 — Object ID ranges

Every id in `app/src` falls inside `10036785–10036884`, matching `app.json` `idRanges` and
`.claude/CLAUDE.md`. Lowest 10036785, highest **10036853**; 10036854–10036884 (31 ids) free. Both
enum extensions place their value ordinals inside the same block: 41 values on `Clockify Msg Type ori`
(10036785–10036825) and 1 on `Clockify Req Log Type ori` (10036785). Test objects 95600–95605 are
inside 95600–95699.

The MCP tool `check_app_range` was not reachable from this session, so the range was verified against
`app.json`, `.claude/CLAUDE.md` and a full scan of the source rather than against the registry
service. The workbook entry itself was not re-read — see Check 13.

---

## Check 4 — SetLoadFields and ReadIsolation

15 `SetLoadFields` and 8 `ReadIsolation` statements added. The ones that matter:

| File | What | Why |
| --- | --- | --- |
| `ClockifyTimeSheetMgt` `FillApprovedLineBuffer` | `SetLoadFields("No.")` + `ReadCommitted` on `Time Sheet Header` | An **unfiltered full-table scan** of every time sheet in the company that only ever uses `"No."`. Biggest single win in the app. |
| `ClockifyTimeSheetSync` `FindOpenTimeSheet` | `SetLoadFields("No.", "Starting Date", "Resource No.")` + `ReadCommitted` | Runs once per synced time entry against the wide `Time Sheet Header`; the header is never modified. |
| `ClockifyTimeSheetMgt` Approve/Reject/Reopen | `SetLoadFields("No.")` on the three header scans | Only `TimeSheet."No."` is handed to `TimeSheetMgt.SetTimeSheetNo`. |
| `ClockifyArchiveSync` (2 sites) | `"BC Code"` added to the existing load set | A real partial-load bug: the loop reaches `BuildTaskPath`, which reads `"BC Code"`, so every `TASK` row triggered a JIT re-fetch. |
| `ClockifyTimeEntrySync` Resolve\* (4) | `ReadCommitted` | Read-only mapping lookups, one per synced entry, running before `LockTable()`. |
| `ClockifyTimeSheetSync` `FindActiveIntegration` | `SetLoadFields(…)` | The twin procedure in `ClockifyTimeEntrySync` already had one; this one was missed. |

Deliberately **not** narrowed: `Time Sheet Line` records handed to base-app
`Time Sheet Approval Management`, `TimeSheetDetail` records passed to `GetMaxQtyToPost()`, the
`TimeSheet` record passed whole to `MoveTimeSheetToArchive`, and the `TempTimeSheetLine :=
TimeSheetLine` whole-record assignment in `FillApprovedLineBuffer` — a partial load there would
silently blank the unloaded fields in the buffer.

---

## Check 5 — Breaking change guard

⏭ **Skipped.** Profile is `appsource` (`AppSourceCop.json` carries `supportedCountries`), but the
phase is `initial`: `AppSourceCop.json` declares no `version`, and this app has never been published.
There is no baseline to break against. The object-id renumbering earlier in this PR
(70009200–70009268 → 10036785–10036853) would be a hard break against a published app and is only
safe because of that.

Ruleset health: `app/AppSourceCop.json` sets `mandatoryAffixes`, `mandatorySuffix`, `publisher` and
14 `supportedCountries`. There is no ruleset file, so AppSourceCop runs with default actions —
nothing is silenced, and no never-suppress rule is hidden. ℹ️ Add a `version` to `AppSourceCop.json`
matching the first published build before the second release, or the guard stays blind.

---

## Check 6 — app.json: two deviations

Everything mandatory is present and semantically correct: `id` matches `.claude/CLAUDE.md`, publisher
`Origo`, version `29.0.0.0`, `target: Cloud`, application/platform `28.0.0.0`, runtime `17.0`,
`idRanges` `10036785–10036884` matching both the registry entry and every object in the app, logo,
brief, description, url, privacyStatement, and `applicationInsightsConnectionString` set (the modern
replacement for `applicationInsightsKey`). `supportedLocales` lists `en-US` and `is-IS`, and
`features` carries `TranslationFile`.

- ⚠️ **`EULA` still points at the Cloud Events terms** (`https://www.origo.is/skilmalar-og-oryggismal`),
  carried over from the source app. **Needs a decision before AppSource submission** — publish a
  Bifröst EULA, or reuse this one deliberately.
- ✅ **`help` and `contextSensitiveHelpUrl` use `businesscentralal.github.io`** instead of
  `bifrost.origo.is`. Approved: the DNS record does not exist yet, and the URLs move with it.

`suppressWarnings` carries `AA0215` and `AS0081` — both pre-existing and unchanged by this PR.

---

## Check 8 — Help pages: approved deviation, all slugs resolve

The repository holds no `Help/` or `docs/` folder — approved deviation, all public documentation
lives in `businesscentralal/bifrost`. Every `ContextSensitiveHelpPage` slug was resolved against that
repository's **`main`** branch, checking front matter rather than filenames, and checking the
Docusaurus plugin routing rather than assuming it:

| Slug | AL page | en-US on main | is-IS on main |
| --- | --- | :---: | :---: |
| `clockify-setup` | `Timesheets Setup ori` | ✅ | ✅ |
| `clockify-integration-list` | `Clockify Integration List ori` | ✅ | ✅ |
| `clockify-webhooks` | `Clockify Webhooks ori` | ✅ | ✅ |
| `clockify-workspace-lookup` | `Clockify Workspace Lookup ori` | ✅ | ✅ |
| `clockify-set-secret-dialog` | `Clockify Set Secret Dialog ori` | ✅ | ✅ |

Routing verified end to end: `docusaurus.config.ts` registers the `help-clockify` docs instance at
`help/clockify`, `apps.ts` contains the `clockify` app entry, the Icelandic pages sit under
`i18n/is-IS/docusaurus-plugin-content-docs-help-clockify/current/`, and the composed route matches
`app.json`'s `contextSensitiveHelpUrl` of `.../{0}/help/clockify/`. The Icelandic pages are real
translations, not stubs. Nothing is missing, and no Help button 404s.

ℹ️ One stale reference in the **site** repository, not this one: `apps.ts` still names the app
"Bifrost Clockify" after the rename to Bifrost Timesheets. Fix it in `businesscentralal/bifrost`.

---

## Check 12 — Logic review

```
╭──────────────────────────────────────────────────────────────╮
│  What this PR does:                                          │
│  Migrates Origo Cloud Events Clockify 28.1.0.0 to Bifrost    │
│  Timesheets 29.0.0.0 in place — new platform dependency,     │
│  new namespace, mandatory affix, per-domain help codeunits,  │
│  own setup card, Icelandic translation, and a renumbered     │
│  object-id block. 41 message-type keys are unchanged.        │
╰──────────────────────────────────────────────────────────────╯
```

Because there is no story, the acceptance criteria below are inferred from the diff, the PR
description and the message-type help documents. They are a reading of the code, not a specification.

| AC | Criterion | Result |
| --- | --- | --- |
| 1 | Every message-type key and help document survives the migration unchanged | ✅ |
| 2 | Every object carries the ` ori` affix inside 30 characters and the new id block | ✅ |
| 3 | The API response payload does not depend on the caller's language | ⚠️ Bug — fixed |
| 4 | Values written to and read back from the integration table round-trip regardless of locale | ⚠️ Bug — fixed |
| 5 | Every failure inside `ExecuteBifrostTask` returns `status = Error`, never an exception | ⚠️ Partly — 2 fixed, 2 open |
| 6 | The time-sheet batch operations act only on the lines they claim to act on | ⚠️ Bug — fixed |
| 7 | Counts returned by the batch operations reflect what actually happened | ⚠️ Bug — fixed |
| 8 | No credential reaches the request log | ⚠️ Bug — fixed |

### Findings

**1. ⚠️ Logic — `Format()` on an enum changed the API response for non-English sessions.** *(fixed)*
Five call sites built the `result` field of the message-type response with `Format(SyncResult)`:
`ClockifyTEntrySyncImpl`, `ClockifyTSheetSyncImpl`, `ClockifyTEntryRangeImpl`, `ClockifyTSheetRangeImpl`
and `ClockifySyncAllUsersImpl` (the last one keying the `counts` dictionary). `Clockify Sync Result ori`
carries translated captions (`is-IS=Stofnað`, `Sleppt`, `Leiðrétt`, `Uppfært`, `Villa`), and `Format`
on an enum returns the **caption**, not the value name. An Icelandic session would therefore answer
`"result": "Stofnað"` where the published help document promises `Created|Updated|Skipped|Error` — a
silent break of the wire contract, and a direct violation of Origo core principle 10. Layer 1's
`format_evaluate_enum` check did not catch it. Fixed by adding
`Clockify TimeEntry Parse ori.SyncResultName()`, which resolves the value name through
`Names()`/`Ordinals()`/`AsInteger()`, and routing all five sites through it.

**2. ⚠️ Logic — locale-dependent parsing and serialisation of API payloads and stored keys.** *(fixed)*
Thirteen `Evaluate` calls parsed ISO-8601 datetimes from the Clockify API without format 9
(`ClockifyTimeEntryParse`, `ClockifyTEntryRangeImpl`, `ClockifyTEntrySyncImpl`, `ClockifyWebhookHandler`),
so hours and posting dates depended on the session culture. Worse, `Clockify Integration ori`
`"Clockify Name"` is written with `Format(Hours)` and parsed back by `ExtractHoursFromName` with a
bare `Evaluate` — a round trip that silently returns 0 hours if the write and the read happen under
different languages, which then posts a **zero-hour reversal** against a real ledger entry. The
persisted correlation key `"BC Code"` was likewise built with `Format(LineNo)`. All of these now use
format 9 on both sides. *(This subsumes the single Layer 1 `format_guid` finding.)*

**3. ⚠️ Robustness — two unhandled errors escaping `ExecuteBifrostTask`.** *(1 fixed, 1 open)*
- *Fixed:* `ClockifyTimeSheetSync.SyncTimeEntryToTimeSheet` called `JobTask.Get(JobNo, JobTaskNo)`
  unguarded. Every other failure in that procedure returns a `Clockify Sync Result ori::Error`; an
  integration row pointing at a since-deleted job task raised an exception instead. Now guarded, with
  a message naming the job task, the job and the Clockify task id. *(Copilot remark on PR #11, still
  live in the code.)*
- *Fixed:* the same procedure passed an unbounded Clockify `description` into a `Text[250]` parameter
  in two places in `ClockifyTimeEntrySync.CreateIntegrationRecord`. A description over ~245
  characters raised a length-overflow error out of the task and out of the webhook subscriber. Both
  call sites now `CopyStr`.
- *Open, needs a decision:* `Clockify API Client ori.Send` raises `Error(SendFailedErr, …)` when the
  HTTP send fails (DNS, TLS, timeout) and when the API key was deleted between `IsEnabled()` and
  execution. A transient Clockify outage therefore produces an HTTP 5xx instead of the required
  `status = Error` envelope. The fix — return `false` and let `Clockify Request Mgt` build the
  envelope — changes the contract of the only HTTP path in the app and would touch every caller, so
  it is flagged rather than made inside a gateway run.

**4. ⚠️ Logic — `ApprovePendingTimeSheets` filtered on the field its own loop body changes.** *(fixed)*
The Copilot remark on PR #11 ("iterates all lines including Submitted/Approved/Rejected") had been
addressed by adding `TimeSheetLine.SetRange(Status, Status::Open)` before `FindSet(true)` — but
`Submit` and `Approve` both change `Status`, so each processed line dropped out of the filtered
recordset mid-iteration and `Next()` could skip records. The sibling procedures
`RejectPendingTimeSheets` and `ReopenTimeSheets` carry an explicit comment saying exactly why they
test the status in code instead. `ApprovePendingTimeSheets` now does the same.

**5. ⚠️ Logic — `Clockify.TimeSheet.Post` reported lines it had not posted.** *(fixed)*
`PostApprovedTimeSheets` discarded the Boolean result of
`Codeunit.Run(Codeunit::"Job Jnl.-Post Line", JobJnlLine)` and incremented `PostedLineCount`
unconditionally, so a line whose posting failed and rolled back was still counted. The count is now
truthful. **Open decision:** a failed post is still swallowed — the caller sees a smaller number and
no reason. Deciding between "report a `failedLines` count" and "fail the whole batch" is a product
call, not a gateway call.

**6. ⚠️ Security — the webhook signing token was written to the request log in cleartext.** *(fixed)*
`Clockify ReqLog Masker ori` returned every response body unchanged, documented as safe because "the
`X-Api-Key` header is never present in a body". That is true of the API key — verified: the key is a
`SecretText` set only as a request header, and Foundation's request logger takes no header parameter
at all. It is not true of the **webhook signing token**: `POST /workspaces/{id}/webhooks` and the
webhook list answer with `authToken`, and that token is the only credential authenticating an inbound
Clockify webhook. Anyone able to read `Request Log ori` could read it. `MaskResponseBody` now walks
the JSON and redacts every `authToken` value at any depth, in objects and arrays, and returns
non-JSON or token-free bodies untouched. Four tests cover it (see Check 10).

### Blindspot questions

- 👁 **Trust — inbound webhooks are not authenticated.** `Clockify Webhook Handler ori` receives
  `HeadersJson` (which carries `clockify-signature`) and discards it, branching on `EventType` alone;
  the only check is `EventSource.StartsWith('clockify/')`. The signing token is never stored in BC, so
  BC could not verify it even if it wanted to. Anyone able to post a `Webhook.Inbound.Receive` task can
  forge time entries straight into Job Journal Lines and Time Sheet Details. The Azure Function in
  front is a control BC neither enforces nor can confirm is configured. **Decision needed:** store the
  `authToken` at registration and compare it in the handler, or document the Function as the trust
  boundary. Fixing it also removes the reason finding 6 exists.
- 👁 **Impact Radius — `TIME_ENTRY_DELETED` never removes time-sheet hours.**
  `ClockifyWebhookHandler.ReverseFromWebhook` calls `TimeEntrySync.ReverseTimeEntry` first, whose
  `FindActiveIntegration` does **not** filter on `"BC Table No."` — unlike its twin in
  `ClockifyTimeSheetSync`, which filters on `Database::"Time Sheet Detail"`. For a time-sheet-synced
  entry it therefore matches the Time Sheet Detail row, marks it `Reversed`, and the following
  `TimeSheetSync.ReverseFromTimeSheet` finds no active link and returns `Skipped`. The hours stay on
  the sheet. One-line fix (`SetRange("BC Table No.", Database::"Job Journal Line")`), but it changes
  what a delete webhook does and no test covers the path — **left for the owner to confirm.**
- 👁 **Scale — `Clockify.TimeSheet.Create` stops creating sheets after four weeks of history.**
  `CreateUpcomingTimeSheets` loops `while ExistingTimeSheet.Count() < TargetAhead`, and the only filter
  is `"Owner User ID"` — it counts *every sheet the resource has ever had*, not upcoming ones. Once a
  resource has four historical sheets the condition is permanently false and the message type silently
  creates nothing, contradicting its own summary ("ensures every time-sheet resource has upcoming
  weekly time sheets"). It also re-issues a `COUNT` on every iteration. The fix needs a decision about
  what "upcoming" counts from, so it is reported rather than guessed — a wrong guess here creates
  duplicate time sheets.
- 👁 **Scale — the time-sheet batch queries have no lower bound.**
  `Approve`/`Reject`/`Reopen`/`Archive` filter only `"Ending Date" <= WorkDate()` and lean on the
  `"Open Exists"` / `"Submitted Exists"` FlowFields, which force a correlated `EXISTS` per header row;
  `ReopenTimeSheets` has no status filter at all. These degrade linearly for the life of the tenant.
- 👁 **Failure State — synchronous HTTP inside base-table triggers.** `Clockify Archive Sync ori` makes
  one `ApiClient.Send` per linked record from `OnBeforeDeleteEvent` / `OnAfterModifyEvent` on Customer,
  Job and Job Task, with no `Client.Timeout` set anywhere in the app. Deleting a customer blocks the
  user on N round trips to api.clockify.me inside the delete transaction.
- 👁 **Scale — unbounded pagination.** The three `FetchEntries` variants loop
  `repeat … until PageArray.Count() < PageSize` with `PageSize = 200` and no maximum page, accumulating
  every page into one in-memory `JsonArray`. A wide date range, or a server that ignores `page`, loops
  until the session times out.

The full security and performance audits behind these questions are summarised below.

---

## Security and performance audits

Run phase by phase against `workflows/security-audit.yaml` and `workflows/performance-audit.yaml`.
Findings already fixed above are not repeated. Everything below is **open**.

**Clean phases:** event and API exposure (the app publishes no integration, business or external
business event and defines no API page), temporary-table safety (one temporary table, all five
base-table subscribers guard with `Rec.IsTemporary()`), filter injection (every `SetFilter` uses a
`%1` placeholder — no concatenated input anywhere), `Commit()` inside a loop (none), `CalcFields`
inside a loop (none), and data classification completeness (no `ToBeClassified`).

| # | Sev | Finding | Fix |
| --- | --- | --- | --- |
| S11 | High | Inbound webhooks are not authenticated (see blindspot above) | Store `authToken` at registration; compare against `clockify-signature` |
| S9 | High | `Clockify API Client ori.Send` raises `Error` on transport failure | Return `false` and let `Clockify Request Mgt` build the error envelope |
| S7b | High | `ExtractHoursFromName` re-parses hours out of a display string | Store the original hours in a dedicated Decimal field |
| S2 | Medium | The API key passes through plain `Text` on the input path (`Clockify Set Secret Dialog ori` → `Clockify Setup Mgt ori`) before becoming `SecretText`, contradicting the codeunit's own "SecretText end to end" comment | Return `SecretText` from `GetSecret()`, `Clear` the page variable |
| S4 | Medium | `Clockify Integration Gate ori` says the access gate "is enforced centrally … so it cannot be forgotten", but it is called from one place; the six `Clockify.TimeSheet.*` types and five direct `ApiClient.Send` callers bypass it | Call the gate at the top of each `ExecuteBifrostTask` that does not route through `Execute` |
| S6 | Medium | `Clockify Integration ori` is classified `CustomerContent`, but `TIME_ENTRY` rows hold a person's work description and hours and `USER` rows map a Clockify user to a named resource — that is EUII | Classify `Clockify Name`, `BC Code`, `Clockify Id` as `EndUserIdentifiableInformation` |
| S8 | Medium | `AsInteger()`/`AsBoolean()` on caller-supplied JSON are guarded by `IsValue()` but not by a type test, and array elements are cast with `AsObject()` with no `IsObject()` check — `{"weeksAhead":"abc"}` throws instead of answering `status = Error` | Add the matching type test and `RespondWithError` on mismatch |
| S12 | Medium | Raw Clockify response bodies are echoed verbatim into user-facing errors in three places | Return the extracted `message` only, as `ExtractErrorMessage` already does |
| S5 | Low | One `Assignable` set granting `RIMD` on all three tables, with no read-only variant | Split a read-only set |
| S3 | Low | `Clockify Webhook ori` documents the signing token as "held in IsolatedStorage by ClockifySecretMgt" — that storage does not exist | Correct the comment, or actually store the token (which also fixes S11) |
| P2 | High | Synchronous per-record HTTP from inside Customer/Job/Job Task delete and modify triggers | Enqueue the archive calls to a job queue |
| P8 | High | `FillApprovedLineBuffer` walks every time-sheet header in the company, then queries lines per header | Query `Time Sheet Line` once on `Type`/`Status`/`Posted` and drop the header loop |
| P7 | High | FlowField-driven whole-history scans in the four time-sheet batch operations | Add a lower `"Ending Date"` bound; filter `Time Sheet Line.Status` directly |
| P1 | High | Unbounded pagination with no page or entry cap, in three places | Cap the page number and answer with an error envelope at the cap |
| P3 | High | `SyncAllUsers` fans out users × pages of HTTP with interleaved writes in one transaction | Validate a maximum date range; process per user as a queued sub-task |
| P9 | Medium | `Clockify Integration ori` has no key for the `Clockify Type` + `BC Code` and `Clockify Type` + `Reversed` lookups, so both seek on `Clockify Type` alone and scan the whole `TIME_ENTRY` population — from inside a delete trigger | Add `("Clockify Type","BC Code","Reversed")` and `("Clockify Type","Reversed")` |
| P5 | Medium | `CreateUpcomingTimeSheets` re-evaluates an unfiltered `Count()` as its loop condition (see blindspot above) | Filter to upcoming sheets; compute the count once |
| P4 | Medium | `TimeSheetHeader.Get` re-reads the same header once per approved line | Cache the last-read `"Time Sheet No."` |
| P6 | Medium | Journal line numbering re-scanned per synced entry, on top of a `LockTable()` | Resolve the starting line number once per batch |
| P10 | Medium | The per-entry `Time Sheet Line` lookup matches on the free-text `Description`, so a re-worded Clockify description creates a duplicate line | Match on job/task/work type only and update the description |
| P11 | Medium | Per-row validated `Modify` setting the same value in a loop, inside a delete trigger | `ModifyAll("Reversed", true)` |
| P12 | Medium | HTTP DELETE per row in a loop with no failure isolation — the "best-effort" comment is wrong while `Send` raises `Error` (S9) | Wrap each call, or fix S9 |

**AppSource impact:** S11 and the request-log leak fixed in finding 6 are the two a Microsoft security
review would be most likely to raise. **GDPR impact:** S6, and indirectly the request log, which
retains unmasked time-entry bodies containing per-person work descriptions.

---

## Check 14 — Role coverage

`BIFROST Timeshts ori` (10036785) is `Assignable`, captioned `Bifrost Timesheets` /
`is-IS=Bifröst tímaskýrslur` at `MaxLength = 30`, and its coverage is exact: **68 of 68 codeunits, 5
of 5 pages, 3 of 3 grantable tables**, with no grant naming an object that does not exist. The only
table absent is `Clockify Workspace Buffer ori`, which is `TableType = Temporary` and needs no grant.

⚠️ **Layering gap.** The app ships an assignable set but **no `PermissionSetExtension` extending
Bifröst Foundation's `BIFROST Full ori`**. The sibling app `bc-origo-bifrost-attachments` ships both:
the assignable `BIFROST Attach ori` *and* `Storage Full ori`, a `permissionsetextension` that folds
its objects into Foundation's role set. As it stands, a user granted Foundation's `BIFROST Full ori`
gets no Timesheets access. Id 10036854 is free if this is an oversight. **Decision needed** — it may
also be deliberate, if Timesheets is meant to be opt-in rather than part of the Foundation role.

Users additionally need a Bifröst Foundation permission set and the base-app permissions for Job
Journal, Time Sheets and Resources; the README states this.

---

## Check 13 — What I couldn't check

- **Skipped:** Check 5 (no published baseline — `AppSourceCop.json` has no `version`, the app has
  never been released), Check 11 (no `stories/` folder), Check 15 (not the standards repository).
- **Limited:** the MCP tool `check_app_range` was not reachable from this session, so Check 3 was
  verified against `app.json`, `.claude/CLAUDE.md` and a full source scan rather than against the
  range registry. The object-ranges workbook was not re-opened.
- **Limited:** command-line `alc` does not raise AS0011 (mandatory affix), so the ` ori` suffix was
  verified by scanning all 84 object declarations. AL-Go CI remains the real gate.
- **Not exercised:** every outbound Clockify path. No Clockify API key and no workspace are configured
  on either container, so the 30 outbound message types were only ever driven down to the HTTP client
  boundary. The webhook receiver, the Azure Function in front of it, and the whole archive-on-delete
  path have never run against a live workspace. Most of the open High findings above live on exactly
  those paths.
- **Needs a human:** the six open decisions listed in the verdict.

---

## Verdict

```
✅  No blocking failures. 0 errors / 0 warnings on both projects, 62/62 tests on both
    containers, and the 21 real Layer 1 findings are fixed.

    Six decisions before this can be called release-ready:
    1. Webhook authentication (S11) — the inbound path is unauthenticated today.
    2. app.json EULA still points at the Cloud Events terms of use.
    3. Whether `Clockify API Client ori.Send` should stop raising Error (S9).
    4. Whether a failed Job Journal post should be reported or should fail the batch.
    5. Whether `Clockify.TimeSheet.Create` should count only upcoming sheets.
    6. Whether Timesheets belongs in Foundation's `BIFROST Full ori` role set.
```

*AI-assisted review. It cannot catch domain rules that are not written down anywhere, and the
acceptance criteria in Check 12 are a reading of the code, not a specification.*
