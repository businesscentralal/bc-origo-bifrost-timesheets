# Changelog

All notable changes to **Bifrost Clockify** are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[semantic versioning](https://semver.org/) aligned with the Business Central major version.

## [29.0.0.0] — 2026-09-06

Migration of *Origo Cloud Events Clockify* 28.1.0.0 to **Bifrost Clockify** on Bifrost Foundation.
This is an **in-place successor**: the app id, the object id range (70009200–70009299) and the test
range (95600–95699) are unchanged, so an installed tenant upgrades rather than installing a second
app. The 41 message-type keys and every help document are unchanged — they are the published API
contract.

### Changed (2026-09-06)

- **Documentation moved to the site.** All public documentation and in-product help now live in the
  [businesscentralal/bifrost](https://github.com/businesscentralal/bifrost) repository and are
  published at <https://businesscentralal.github.io/bifrost> — product documentation at `/en-us/clockify/`, help at
  `/en-us/help/clockify/` and `/is-is/help/clockify/`. This repository keeps no `docs/` or `Help/`
  folder, and `README.md` was trimmed to header facts, links, layout, dependencies and development
  notes.
- **Context-sensitive help slugs.** `ContextSensitiveHelpPage` was added to the five pages, using
  the Docusaurus slugs of the new help pages: `clockify-setup` (`Clockify Setup ori`),
  `clockify-integration-list` (`Clockify Integration List ori`), `clockify-webhooks`
  (`Clockify Webhooks ori`), `clockify-workspace-lookup` (`Clockify Workspace Lookup ori`) and
  `clockify-set-secret-dialog` (`Clockify Set Secret Dialog ori`). `Clockify Setup Ext ori` adds no
  slug of its own — the Bifröst Setup page belongs to Foundation.
- **Test reports moved.** The migration test report and the raw queue-API call log moved from
  `app/docs/` to `test/reports/`. They are internal and are deliberately not published to the
  documentation site. The tracked AL test result XML files under `TestResults/` were dropped from
  the repository — a stray `.xml` inside an AL project folder raises AL1025.

### Changed

- **Platform.** Dependency moved from *Origo Cloud Events Core* (`a629b897-…`) to **Bifrost
  Foundation** `7505e808-6e52-4b96-a328-82573391297a` 28.0.0.0. The API route is now
  `origo/bifrost/v1.0`.
- **Identity.** App renamed to `Bifrost Clockify`, version 29.0.0.0, brief and description mention
  Bifröst. Namespace `Origo.PTE.CloudEvents.Clockify` → `Origo.Bifrost.Clockify`; the test app moved
  to `Origo.Bifrost.Clockify.Test`. New Clockify logo.
- **Interface.** `ExecuteCloudEventTask` → `ExecuteBifrostTask` on all 41 implementations.
- **Object names.** Every object now carries the mandatory ` ori` suffix within 30 characters, and
  the words "Cloud Event(s)" are gone. Renames beyond the plain suffix:

  | Legacy | Bifröst |
  |---|---|
  | `Clockify Cloud Event Msg Type` (enumext) | `Clockify Msg Type ori` |
  | `Clockify Full` (permission set) | `BIFROST Clockify ori` |
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
  `Clockify Setup ori` table and card (70009268), and the page extension adds exactly one action in
  Foundation's `Apps` group plus its promoted reference — the footprint every dependent Bifröst app
  is allowed. Field names lost their redundant `Clockify ` prefix (`Clockify API Version` →
  `API Version`, and so on).
- **Help consolidated per domain.** The Markdown that used to sit inline in each implementation now
  lives in six domain codeunits — `Clockify Workspace Help ori`, `Clockify Client Help ori`,
  `Clockify Project Help ori`, `Clockify Task Help ori`, `Clockify Tag Help ori`,
  `Clockify TimeEntry Help ori` (70009262–70009267) — each with a `case` on `Message Type ori`.
  `Clockify TimeSheet Help ori` became a `case` dispatcher too. The help text itself is unchanged.
- **Repository layout.** `Cloud Events Clockify/` → `app/`, `Cloud Events Clockify - Tests/` →
  `test/` (`test/src` for mocks, `test/test` for the test codeunits), AL-Go settings, workspace file,
  `.gitignore` and `app/.vscode/launch.json` aligned with the other Bifröst repositories. Tracked
  build artefacts removed.
- **Help URLs.** `help` and `contextSensitiveHelpUrl` now point at `bifrost.origo.is`, matching the
  portfolio convention adopted on 2026-09-06. The pages still have to be written in the
  `businesscentralal/bifrost` site repository.

### Added

- Message types for Projects and Time Sheets from the open pull request
  *#5 Message Types for Projects* (`feature-#5_MessageTypes_Projects`), merged into this migration:
  `Clockify.TimeSheet.Create`, `.Approve`, `.Post`, `.Archive`, `.Reject`, `.Reopen`,
  `Clockify.TimeEntry.SyncToTimeSheet`, `.SyncRangeToTimeSheet` and `.SyncAllUsers`, together with
  `Clockify TimeSheet Mgt ori`, `Clockify TimeSheet Sync ori`, `Clockify TimeEntry Fetch ori`,
  `Clockify TimeEntry Parse ori` and 430 lines of new tests.
- `Bifrost Clockify.is-IS.xlf` with all 130 translation units translated. The legacy app shipped no
  Icelandic translation file at all.
- `is-IS=` comments on the 18 labels, enum captions and search terms that had none.
- A dedicated `CLOCKIFY` AL Test Suite built by the test app, refreshed by a new upgrade codeunit
  (95605) so republishing picks up new test codeunits.

### Fixed

- The test app no longer deletes and rebuilds the container-wide `DEFAULT` AL Test Suite, which used
  to wipe the suite of every other test app installed beside it and never contained Clockify's own
  codeunits on a fresh install.
- Three Icelandic messages still directed the user to *Bifrost stillingar*; they now name the
  Clockify Setup card, matching the English text.

### Removed

- `tableextension 70009200 "Clockify Setup Ext"` on `Cloud Events Setup ori`. Its seven fields moved
  to `Clockify Setup ori`. **There is no upgrade codeunit to carry the values across**: the fields
  belonged to a table owned by a dependency that this version no longer references, so the values
  cannot be read after the dependency swap. The app was never published, so no tenant is affected;
  re-enter the Clockify settings on the new card after upgrading a development environment.

### Notes

- The Clockify API key still lives in this app's own `Clockify Secret Mgt ori` (IsolatedStorage,
  Company scope) with its own masked dialog. Bifrost Foundation now owns a unified secret store
  (`Secret Store ori`); **the API key will move there in a later pass**, at which point the key has
  to be re-entered once — an install take-over cannot copy another extension's IsolatedStorage.
- Verification: CodeCop + UICop + AppSourceCop clean, 58/58 unit tests green on `bc28-is` and
  `bc28-w1`, and all 41 message types exercised over the queue API on `bc28-is` (87 calls, no
  HTTP 5xx). See [test/reports/Bifrost_Clockify_TestReport_2026-09-06.md](test/reports/Bifrost_Clockify_TestReport_2026-09-06.md).

---

## [28.1.0.0] and earlier — Origo Cloud Events Clockify

Released as *Origo Cloud Events Clockify* on Origo Cloud Events Core. See the repository history
before 2026-09-06.
