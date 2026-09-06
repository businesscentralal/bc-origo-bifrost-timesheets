# Bifröst Clockify — message type test report, 2026-09-06

Migration verification of **Bifrost Clockify 29.0.0.0** (successor of *Origo Cloud Events Clockify*
28.1.0.0) on Bifrost Foundation 28.0.0.0.

| | |
|---|---|
| App | Bifrost Clockify 29.0.0.0 (`d4560cf5-947d-42b5-b812-33ae8dd009af`) |
| Test app | Bifrost Clockify - Tests 29.0.0.1 (`553214e3-b742-4ccf-8ecc-1ee86fbc96f9`) |
| Dependency | Bifrost Foundation 28.0.0.0 (`7505e808-6e52-4b96-a328-82573391297a`) |
| Containers | `bc28-is` (CRONUS IS) and `bc28-w1` (CRONUS International Ltd.) |
| API route | `origo/bifrost/v1.0` |
| Company (bc28-is) | `b93c35e0-6a9d-f111-90df-7ced8d9d7f83` |

---

## 1. Build

| Step | Analyzers | Result |
|---|---|---|
| `app` | CodeCop + UICop + AppSourceCop | 0 errors, 0 warnings (84 objects, 84 files) |
| `test` | CodeCop + UICop | 0 errors, 0 warnings (6 objects) |

The `ori` affix was verified separately, because command-line `alc.exe` does not raise AS0011:
all 84 app objects end with ` ori`, none exceeds 30 characters, and the permission set name
`BIFROST Clockify ori` is exactly 20 characters. Test-app objects deliberately carry no affix.

## 2. Deployment

| Container | App | Test app |
|---|---|---|
| `bc28-is` | published (ForceSync), installed | published (Synchronize), installed |
| `bc28-w1` | published (ForceSync), installed | published (Synchronize), installed |

The legacy *Origo Cloud Events Clockify* was **not** installed on either container, so no uninstall
was needed. Publishing repeatedly returned HTTP 422 *"another service is currently modifying the
state of extensions"* while another session was publishing Bifrost Foundation; the documented
60-second retry loop cleared it (worst case 8 attempts).

## 3. Unit tests

Run with Microsoft's AL Test Runner against the dedicated `CLOCKIFY` suite.

| Container | Codeunits | Tests | Passed | Failed |
|---|---|---|---|---|
| `bc28-is` | 1 (`Clockify Connector Tests`) | 58 | 58 | 0 |
| `bc28-w1` | 1 (`Clockify Connector Tests`) | 58 | 58 | 0 |

Raw runner output (`clockify_is.xml`, `clockify_w1.xml`) is archived outside the repository — the AL
compiler flags stray `.xml` files inside a project folder with AL1025.

**Test-suite defect found and fixed during this run.** The legacy test app's install codeunit
deleted and rebuilt the shared `DEFAULT` AL Test Suite from range `50000..99999`. On a container
where several Bifröst and Cloud Events test apps live side by side that wipes every other app's
suite, and on a fresh install it does not even contain the app's own codeunits (they are not yet in
`AllObjWithCaption` when `OnInstallAppPerCompany` runs). Discovery through the runner's
`ExtensionId` control returned zero tests for every app on both containers. The test app now builds
its own `CLOCKIFY` suite from `95600..95699` and refreshes it from a new upgrade codeunit (95605),
so republishing picks up new test codeunits without an uninstall.

## 4. Message types over the queue API

87 calls, strictly serial, POST `.../companies({id})/tasks` with a CloudEvents 1.0 envelope
(`data` carries the payload as a JSON **string** — an object is rejected with HTTP 400), then GET
`.../responses({taskId})/data`.

| Result | Count |
|---|---|
| HTTP 200 | 87 / 87 |
| HTTP 5xx or unhandled exception | 0 |
| `Help.Implementation.Get` per message type | 41 / 41 returned Markdown |
| Invocations returning `status = Success` | 6 |
| Invocations returning a handled `status = Error` | 35 |

No Clockify API key is configured on `bc28-is`, so every type that calls the Clockify REST API is
expected to answer with a handled error. That is exactly what happened — never an HTTP 5xx.

### 4.1 Per message type

| # | Message type | Help | Invoke | Response |
|---|---|---|---|---|
| 1 | `Help.Clockify.Get` | OK | Success | Markdown overview, Bifröst-branded |
| 2 | `Clockify.Workspace.List` | OK | Error | No Clockify API key is stored |
| 3 | `Clockify.User.GetCurrent` | OK | Error | No Clockify API key is stored |
| 4 | `Clockify.User.List` | OK | Error | No Clockify API key is stored |
| 5 | `Clockify.Client.List` | OK | Error | No Clockify API key is stored |
| 6 | `Clockify.Client.Get` | OK | Error | No Clockify API key is stored |
| 7 | `Clockify.Client.Create` | OK | Error | No Clockify API key is stored |
| 8 | `Clockify.Client.Update` | OK | Error | No Clockify API key is stored |
| 9 | `Clockify.Client.Delete` | OK | Error | No Clockify API key is stored |
| 10 | `Clockify.Project.List` | OK | Error | No Clockify API key is stored |
| 11 | `Clockify.Project.Get` | OK | Error | No Clockify API key is stored |
| 12 | `Clockify.Project.Create` | OK | Error | No Clockify API key is stored |
| 13 | `Clockify.Project.Update` | OK | Error | No Clockify API key is stored |
| 14 | `Clockify.Project.Delete` | OK | Error | No Clockify API key is stored |
| 15 | `Clockify.Task.List` | OK | Error | No Clockify API key is stored |
| 16 | `Clockify.Task.Create` | OK | Error | No Clockify API key is stored |
| 17 | `Clockify.Task.Update` | OK | Error | No Clockify API key is stored |
| 18 | `Clockify.Task.Delete` | OK | Error | No Clockify API key is stored |
| 19 | `Clockify.Tag.List` | OK | Error | No Clockify API key is stored |
| 20 | `Clockify.Tag.Create` | OK | Error | No Clockify API key is stored |
| 21 | `Clockify.Tag.Update` | OK | Error | No Clockify API key is stored |
| 22 | `Clockify.Tag.Delete` | OK | Error | No Clockify API key is stored |
| 23 | `Clockify.TimeEntry.List` | OK | Error | No Clockify API key is stored |
| 24 | `Clockify.TimeEntry.Get` | OK | Error | No Clockify API key is stored |
| 25 | `Clockify.TimeEntry.Create` | OK | Error | No Clockify API key is stored |
| 26 | `Clockify.TimeEntry.Update` | OK | Error | No Clockify API key is stored |
| 27 | `Clockify.TimeEntry.Delete` | OK | Error | No Clockify API key is stored |
| 28 | `Clockify.Currency.List` | OK | Error | No Clockify API key is stored |
| 29 | `Clockify.UserGroup.List` | OK | Error | No Clockify API key is stored |
| 30 | `Clockify.CustomField.List` | OK | Error | No Clockify API key is stored |
| 31 | `Clockify.TimeEntry.Sync` | OK | Error | Missing `workspaceId` (bad payload); with a full payload: in-progress entries are not synced to the Job Journal |
| 32 | `Clockify.TimeEntry.SyncRange` | OK | Error | Missing `start` (bad payload); with a full payload: no Job Journal target configured |
| 33 | `Clockify.TimeSheet.Create` | OK | **Success** | BC-side; created 0 sheets (no time-sheet resources in CRONUS IS) |
| 34 | `Clockify.TimeSheet.Approve` | OK | **Success** | BC-side; 0 lines approved |
| 35 | `Clockify.TimeSheet.Post` | OK | Error | No Job Journal target configured |
| 36 | `Clockify.TimeSheet.Archive` | OK | **Success** | BC-side; 0 sheets archived |
| 37 | `Clockify.TimeEntry.SyncToTimeSheet` | OK | Error | With a full payload: in-progress entries are not synced |
| 38 | `Clockify.TimeEntry.SyncRangeToTimeSheet` | OK | Error | With a full payload: no Clockify API key is stored |
| 39 | `Clockify.TimeSheet.Reject` | OK | **Success** | BC-side; 0 lines rejected |
| 40 | `Clockify.TimeSheet.Reopen` | OK | **Success** | BC-side; 0 lines reopened |
| 41 | `Clockify.TimeEntry.SyncAllUsers` | OK | Error | `target=journal` requires a Job Journal |

### 4.2 Contract checks

- All 41 message-type keys are unchanged from the legacy app — the published API contract holds.
- `Help.Clockify.Get` still appears in Foundation's `Help.Bifrost.Get` directory, through the
  rebranded `Clockify Help Overview Sub ori` subscriber.
- All 41 help documents are byte-identical to the legacy text apart from the brand words: they were
  moved verbatim out of the `*Impl ori` codeunits into the per-domain `<Domain> Help ori` codeunits.
- Error responses name **Clockify Setup** (the connector's own card) rather than the old
  Cloud Events Setup card, in both English and Icelandic.

## 5. Defects and observations

| # | Severity | Item |
|---|---|---|
| 1 | Fixed | Test app clobbered the container-wide `DEFAULT` AL Test Suite and never registered its own codeunits (see §3). |
| 2 | Fixed | Three Icelandic label texts still told the user to open *Bifrost stillingar*; the settings now live on the Clockify Setup card. |
| 3 | Fixed | The legacy app shipped **no** `is-IS.xlf` at all and 18 labels, enum captions and search terms carried no `is-IS=` comment. All 130 translation units are now `state="translated"`. |
| 4 | Open | `Clockify.TimeEntry.Sync` reports *"No workspace was supplied"* before it reports the missing `entryId`/`projectId`. Parameter validation order makes the first error message misleading when several parameters are missing. Pre-existing behaviour, not introduced by the migration. |
| 5 | Open | The Clockify API key still lives in this app's own `Clockify Secret Mgt ori` + `Clockify Set Secret Dialog ori`. Foundation now owns a unified secret store (`Secret Store ori`); moving the key there is a follow-up, agreed for a later pass. |
| 6 | Open | No live Clockify workspace is configured on `bc28-is`, so the 30 outbound message types were only exercised down to the HTTP client boundary. A run against a real Clockify workspace is still required before release. |
| 7 | Open | `app.json` now points `help` at `https://businesscentralal.github.io/bifrost/en-us/clockify/` and context-sensitive help at `https://businesscentralal.github.io/bifrost/{0}/help/clockify/`, matching the portfolio convention adopted 2026-09-06. The pages themselves still have to be written in the `businesscentralal/bifrost` site repository. |

## 6. How to reproduce

```powershell
# build
alc.exe /project:app /packagecachepath:app/.alpackages /out:"app/output/Origo_Bifrost Clockify_29.0.0.0.app" `
        /analyzer:...CodeCop.dll /analyzer:...UICop.dll /analyzer:...AppSourceCop.dll

# publish (repo root; app/.vscode/launch.json holds both containers)
pwsh -File ..\..\OrigoSoftwareSolutions\bc-origo-bifrost-core\tools\Publish-BifrostApp.ps1 `
     -AppFile '.\app\output\Origo_Bifrost Clockify_29.0.0.0.app' -LaunchConfiguration 'launch: bc28-is'

# unit tests - use the app's own suite, not DEFAULT
Run-AlTests -ServiceUrl 'https://.../f068155f0c39/cs/?tenant=default' -Credential $cred `
            -AutorizationType NavUserPassword -TestSuite 'CLOCKIFY' -TestIsolation Codeunit
```
