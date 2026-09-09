---
id: TS-30-01
title: Reorganize app to separate external providers from generic time sheet handling
type: feature
status: in-progress
version: 29.0.0.0
scope: folder + namespace + message-type wire rename (breaking change; object IDs frozen)
created: 2026-09-08
last-updated: 2026-09-09
created-by: Copilot
folded-into: PR #12 (branch feature/bifrost-clockify-migration)
---

> **Scope revision 2026-09-09:** Added message-type rename per user direction. Wire
> break is intentional — no compatibility shim. See "Message Type Rename" section
> below. Non-goal #1 no longer applies to message-type enum value names/captions;
> all other object IDs and names still frozen.

# TS-30-01 — Reorganize app to separate external providers from generic time sheet handling

## Goal
Reshape the source tree so the current Clockify implementation lives under a
`Providers/Clockify/` folder tree with its own sub-namespace, and the small
generic surface (Bifröst app registration + generic setup page + permission set)
lives under `Core/`. This is preparation for future providers (Azure DevOps,
Jira, Halo, Asana) — no provider stubs are added by this story.

## Non-Goals (explicitly out of scope)
1. **No object renames** except message-type enum values (see revision above).
   `Clockify Integration ori`, `Clockify Setup ori`, `Clockify Webhook ori`, all
   `Clockify* Impl` codeunits, pages, and the `Clockify Msg Type ori` enum extension
   itself all keep their current names and object IDs. **Message-type enum value
   names and captions are renamed** — see mapping table below.
2. **No table structure changes.** No new fields, no obsolete markings, no
   upgrade codeunit changes.
3. **No generic abstraction layer.** No new `Time Provider` interface. No
   generic integration/link table. The `Clockify API Client ori` interface
   stays exactly as it is.
4. **No provider stubs.** Do not scaffold Jira/ADO/Halo/Asana folders.
5. **No test object renames.** Test namespace and file names stay as-is where
   they still make sense; only relocate if needed for consistency.
6. **No translation source changes.** `Bifrost Timesheets.g.xlf` regenerates
   naturally on build; hand-edited `is-IS` XLF is preserved verbatim.

## Target Folder Layout

```
app/src/
  Core/                                          (generic, provider-agnostic)
    Registration/
      TimesheetsRegistration.Codeunit.al        (was Setup/)
      TimesheetsSetup.Page.al                   (was Setup/)
    Permissions/
      BIFROSTTimeshts.PermissionSet.al          (was Permissions/)

  Providers/
    Clockify/
      Api/                                       (transport contract + HTTP)
        ClockifyAPIClient.Interface.al          (was Integration/)
        ClockifyAPIVersion.Enum.al              (was Integration/)
        ClockifyClient.Codeunit.al              (was Integration/)
        ClockifyRequestMgt.Codeunit.al          (was Integration/)
      Integration/                               (link table + gate + list + events)
        ClockifyIntegration.Table.al            (was Integration/)
        ClockifyIntegrationList.Page.al         (was Integration/)
        ClockifyIntegrationGate.Codeunit.al     (was Integration/)
        ClockifyEventSubscribers.Codeunit.al    (was Integration/)
      Sync/                                      (batch sync engines)
        ClockifyArchiveSync.Codeunit.al         (was Integration/)
        ClockifyTimeEntrySync.Codeunit.al       (was Integration/)
        ClockifySyncResult.Enum.al              (was Integration/)
      Webhook/
        ClockifyWebhookHandler.Codeunit.al      (was Integration/)
        ClockifyWebhook.Table.al                (was Setup/)
        ClockifyWebhookMgt.Codeunit.al          (was Setup/)
        ClockifyWebhooks.Page.al                (was Setup/)
      Setup/
        ClockifySetup.Table.al                  (was Setup/)
        ClockifySetupExt.PageExt.al             (was Setup/)
        ClockifySetupMgt.Codeunit.al            (was Setup/)
        ClockifySecretMgt.Codeunit.al           (was Setup/)
        ClockifySetSecretDialog.Page.al         (was Setup/)
        ClockifyWorkspaceBuffer.Table.al        (was Setup/)
        ClockifyWorkspaceLookup.Page.al         (was Setup/)
        ClockifyWorkspaceMgt.Codeunit.al        (was Setup/)
      Lifecycle/
        ClockifyInstall.Codeunit.al             (was Lifecycle/)
        ClockifyRetenPolicy.Codeunit.al         (was Lifecycle/)
      RequestLog/
        ClockifyReqLogMasker.Codeunit.al        (was RequestLog/)
        ClockifyReqLogType.EnumExt.al           (was RequestLog/)
      MessageTypes/                              (unchanged sub-tree)
        Clients/          Currencies/     CustomFields/
        Help/             Projects/       Tags/
        Tasks/            TimeEntries/    TimeSheets/
        UserGroups/       Users/          Workspaces/
        ClockifyHelpBuilder.Codeunit.al
        ClockifyMsgType.EnumExt.al
```

## Namespace Strategy

| Folder | Namespace |
|--------|-----------|
| `Core/**` | `Origo.Bifrost.Timesheets` |
| `Providers/Clockify/**` | `Origo.Bifrost.Timesheets.Providers.Clockify` |
| `test/**` | `Origo.Bifrost.Timesheets.Test` (unchanged) |

Cross-namespace references get `using` lines added:
- `Core/Registration/TimesheetsSetup.Page.al` references `Codeunit "Timesheets Registration ori"` only — stays inside `Core`.
- `Providers/Clockify/**` files that reference generic Core types (none currently — nothing under Core references Clockify) need no new `using`.
- Test files need `using Origo.Bifrost.Timesheets.Providers.Clockify;` added where they reference Clockify types.

## Acceptance Criteria

| AC | Title | Verification |
|----|-------|--------------|
| AC-01 | Every file listed above physically exists at the target path | `Get-ChildItem app/src -Recurse -Filter *.al` matches target layout; old paths are gone |
| AC-02 | Every relocated file has the correct namespace | Grep: files under `Providers/Clockify/**` start with `namespace Origo.Bifrost.Timesheets.Providers.Clockify;`; files under `Core/**` start with `namespace Origo.Bifrost.Timesheets;` |
| AC-03 | App compiles with zero errors | `al_build` (or VS Code AL build) succeeds; `get_errors` returns none |
| AC-04 | Test app compiles with zero errors | Test build succeeds after `using Origo.Bifrost.Timesheets.Providers.Clockify;` added to each test source file that references Clockify types |
| AC-05 | No object ID or object name changed **except message-type enum values** | `git diff` shows no `field(` / `procedure` / `Caption =` diffs on tables/pages/codeunits; message-type enum value IDs (`10036785`–`10036825`) unchanged, only value names and captions differ per rename table |
| AC-06 | `app.json` version stays at `29.0.0.0` (reorg folded into PR #12) | `app.json` version field unchanged in diff |
| AC-07 | Existing tests still pass unmodified in behavior | `TimesheetsRegistrationTests` + `ClockifyConnectorTests` all green after test-side references are updated to the new message-type names |
| AC-08 | Bifrost Foundation still lists this app on its setup page | Manual smoke: open Bifröst Setup → Timesheets app is visible → click opens `Timesheets Setup ori` |
| AC-09 | Existing customer with rows in `Clockify Integration ori` continues to work after upgrade | Deploy over v29.0.0.0 to a container with seeded data; `Clockify Integration List ori` still shows all rows; no upgrade errors in event log |
| AC-10 | Translation build produces same `.g.xlf` unit IDs as v29 (byte-diff of unit `id=` attributes only) | Compare `Bifrost Timesheets.g.xlf` from v29 build vs new build; unit IDs unchanged for objects that aren't renamed. Message-type Captions are `Locked = true` so they don't emit XLF trans-units — no XLF change expected from rename |
| AC-11 | Every old message-type name is removed from source | `Select-String -Path 'app/src/**/*.al','test/**/*.al' -Pattern '(Clockify\.\|Help\.Clockify\.)' -CaseSensitive` returns no enum-value references (narrative text mentioning the word "Clockify" is fine) |
| AC-12 | All 41 new message-type names appear exactly once in the enum extension and every dispatch site uses one of them | Manual: count of `value(` in `ClockifyMsgType.EnumExt.al` = 41; every `MessageType::` reference in source uses a value from the new set |
| AC-13 | Wire break is documented in PR description | PR description lists the old→new mapping and warns downstream consumers |

## Implementation Contract

**Contract Status: Ready for implementation: Yes**
**Open Blockers: None (dependent on PR #12 merged)**

### Files created
None. This is a move-only story.

### Files moved (84 app + 0 test)
Use `git mv` for every relocation so history follows. Batch by folder to keep the
diff reviewable.

### Files modified in place
1. Every moved `.al` file: change `namespace Origo.Bifrost.Timesheets;` to
   `namespace Origo.Bifrost.Timesheets.Providers.Clockify;` (only for files under
   `Providers/Clockify/**`). `Core/**` files keep the existing namespace.
2. Test source files under `test/src/` and `test/test/`: add
   `using Origo.Bifrost.Timesheets.Providers.Clockify;` after the existing
   `namespace Origo.Bifrost.Timesheets.Test;` line.
3. `app.json` version bump.

### Execution order
1. Create `stories/backlog/` and this story file. **Done.**
2. `git mv` files into new folders on `feature/bifrost-clockify-migration`. **Done.**
3. Update namespaces in `Providers/Clockify/**`. **Done.**
4. Add `using` lines in test app. **Done.**
5. Rename all 41 message-type enum values + captions + call sites (see mapping below). **In progress.**
6. Build both apps locally; fix any missing `using` errors.
7. Push to PR #12.

## Message Type Rename

**Scheme:** Split into `Provider.Clockify.*` (pure Clockify API pass-throughs) and
`Timesheets.*` (generic BC-side operations). **Value IDs stay the same** — only the
enum value identifier and its `Caption` change. **Wire break:** old names removed;
no compatibility shim. Downstream consumers (Azure Function webhook receiver,
any external Bifröst caller, tests) must update in lockstep.

### Provider-scoped (30 values — pure Clockify API)

| ID | Old | New |
|---|---|---|
| 10036785 | `Help.Clockify.Get` | `Provider.Clockify.Help.Get` |
| 10036786 | `Clockify.Workspace.List` | `Provider.Clockify.Workspace.List` |
| 10036787 | `Clockify.User.GetCurrent` | `Provider.Clockify.User.GetCurrent` |
| 10036788 | `Clockify.User.List` | `Provider.Clockify.User.List` |
| 10036789 | `Clockify.Client.List` | `Provider.Clockify.Client.List` |
| 10036790 | `Clockify.Client.Get` | `Provider.Clockify.Client.Get` |
| 10036791 | `Clockify.Client.Create` | `Provider.Clockify.Client.Create` |
| 10036792 | `Clockify.Client.Update` | `Provider.Clockify.Client.Update` |
| 10036793 | `Clockify.Client.Delete` | `Provider.Clockify.Client.Delete` |
| 10036794 | `Clockify.Project.List` | `Provider.Clockify.Project.List` |
| 10036795 | `Clockify.Project.Get` | `Provider.Clockify.Project.Get` |
| 10036796 | `Clockify.Project.Create` | `Provider.Clockify.Project.Create` |
| 10036797 | `Clockify.Project.Update` | `Provider.Clockify.Project.Update` |
| 10036798 | `Clockify.Project.Delete` | `Provider.Clockify.Project.Delete` |
| 10036799 | `Clockify.Task.List` | `Provider.Clockify.Task.List` |
| 10036800 | `Clockify.Task.Create` | `Provider.Clockify.Task.Create` |
| 10036801 | `Clockify.Task.Update` | `Provider.Clockify.Task.Update` |
| 10036802 | `Clockify.Task.Delete` | `Provider.Clockify.Task.Delete` |
| 10036803 | `Clockify.Tag.List` | `Provider.Clockify.Tag.List` |
| 10036804 | `Clockify.Tag.Create` | `Provider.Clockify.Tag.Create` |
| 10036805 | `Clockify.Tag.Update` | `Provider.Clockify.Tag.Update` |
| 10036806 | `Clockify.Tag.Delete` | `Provider.Clockify.Tag.Delete` |
| 10036807 | `Clockify.TimeEntry.List` | `Provider.Clockify.TimeEntry.List` |
| 10036808 | `Clockify.TimeEntry.Get` | `Provider.Clockify.TimeEntry.Get` |
| 10036809 | `Clockify.TimeEntry.Create` | `Provider.Clockify.TimeEntry.Create` |
| 10036810 | `Clockify.TimeEntry.Update` | `Provider.Clockify.TimeEntry.Update` |
| 10036811 | `Clockify.TimeEntry.Delete` | `Provider.Clockify.TimeEntry.Delete` |
| 10036812 | `Clockify.Currency.List` | `Provider.Clockify.Currency.List` |
| 10036813 | `Clockify.UserGroup.List` | `Provider.Clockify.UserGroup.List` |
| 10036814 | `Clockify.CustomField.List` | `Provider.Clockify.CustomField.List` |

### Generic BC-side (11 values — no Clockify API calls, but sync ops read from Clockify)

| ID | Old | New | Notes |
|---|---|---|---|
| 10036815 | `Clockify.TimeEntry.Sync` | `Timesheets.JobJournal.SyncFromClockify` | Reads Clockify → writes BC Job Journal Line |
| 10036816 | `Clockify.TimeEntry.SyncRange` | `Timesheets.JobJournal.SyncRangeFromClockify` | Batch variant |
| 10036817 | `Clockify.TimeSheet.Create` | `Timesheets.TimeSheet.Create` | Pure BC — no provider code |
| 10036818 | `Clockify.TimeSheet.Approve` | `Timesheets.TimeSheet.Approve` | Pure BC |
| 10036819 | `Clockify.TimeSheet.Post` | `Timesheets.TimeSheet.Post` | Pure BC |
| 10036820 | `Clockify.TimeSheet.Archive` | `Timesheets.TimeSheet.Archive` | Pure BC |
| 10036821 | `Clockify.TimeEntry.SyncToTimeSheet` | `Timesheets.TimeSheet.SyncFromClockify` | Reads Clockify → writes BC Time Sheet |
| 10036822 | `Clockify.TimeEntry.SyncRangeToTimeSheet` | `Timesheets.TimeSheet.SyncRangeFromClockify` | Batch variant |
| 10036823 | `Clockify.TimeSheet.Reject` | `Timesheets.TimeSheet.Reject` | Pure BC |
| 10036824 | `Clockify.TimeSheet.Reopen` | `Timesheets.TimeSheet.Reopen` | Pure BC |
| 10036825 | `Clockify.TimeEntry.SyncAllUsers` | `Timesheets.SyncAllUsersFromClockify` | Cross-user batch orchestrator |

### Replacement ordering (critical)
Longer strings must be replaced before shorter prefixes to avoid partial matches:
1. `Clockify.TimeEntry.SyncRangeToTimeSheet` → `Timesheets.TimeSheet.SyncRangeFromClockify`
2. `Clockify.TimeEntry.SyncToTimeSheet` → `Timesheets.TimeSheet.SyncFromClockify`
3. `Clockify.TimeEntry.SyncAllUsers` → `Timesheets.SyncAllUsersFromClockify`
4. `Clockify.TimeEntry.SyncRange` → `Timesheets.JobJournal.SyncRangeFromClockify`
5. `Clockify.TimeEntry.Sync` → `Timesheets.JobJournal.SyncFromClockify`
6. All remaining `Clockify.*` and `Help.Clockify.Get` → `Provider.Clockify.*`

## Known Ambiguities
| ID | Question | Impact | Disposition |
|----|----------|--------|-------------|
| A1 | Version number | app.json | **Resolved 2026-09-08**: stay at `29.0.0.0`, fold reorg into PR #12 |
| A2 | Add `Providers/Clockify/README.md` explaining the boundary? | Documentation only | Deferred |
| A3 | Folder name `Providers/` vs `Connectors/`? | Cosmetic | **Resolved**: use `Providers/` |

## Regression Test Requirements
- Existing test codeunits (`ClockifyConnectorTests`, `TimesheetsRegistrationTests`) must pass without behavioral edits.
- Smoke test: install over v29.0.0.0 with seeded `Clockify Integration ori` rows → verify no upgrade errors, list page still opens with rows visible.

## Risk Assessment
- **Level:** Low. Pure reorganization within one app boundary.
- **Side effects:** Any external app that references a Clockify type by `Codeunit "Clockify X ori"` (name-only) continues to work — AL binds by object name, not namespace. Only source references in the same repo need the `using` update.
- **Rollback plan:** `git revert` the reorg PR. Zero data or config change.
