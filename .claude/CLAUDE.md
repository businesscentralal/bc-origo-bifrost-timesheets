# Extension: Bifrost Clockify

## Prefix
(none - objects use raw names with the mandatory `ori` suffix inside the `Origo.Bifrost.Clockify`
namespace; the third-party product name `Clockify` stays in object names because it identifies the
domain and keeps the names unique across the tenant)

## Namespace
Origo.Bifrost.Clockify (tests: Origo.Bifrost.Clockify.Test)

## Object ID Range
App:   70009200-70009299 (unchanged from Origo Cloud Events Clockify - this is an in-place
  successor with the same app id, so the ids must not move). Highest id in use: 70009268.
Tests: 95600-95699 (unchanged). Highest id in use: 95605.

## App ID
`d4560cf5-947d-42b5-b812-33ae8dd009af` (app) / `553214e3-b742-4ccf-8ecc-1ee86fbc96f9` (tests) -
both kept from the legacy app on purpose.

## Target BC Version
28.x (application/platform 28.0.0.0, runtime 17.0)

## Source Control
Platform: GitHub
Organization: businesscentralal
Repository: origo-bc-cloudevents-clockify (rename to `bc-origo-bifrost-clockify` is pending - the
  name is currently taken by an empty AppSource-template repository created 2026-09-05)
Default branch: main

## Dependencies
- Bifrost Foundation (`7505e808-6e52-4b96-a328-82573391297a`, 28.0.0.0) - the only AL dependency.

## Naming Rules
- Every object carries the `ori` suffix (AppSource mandatory affix), max 30 characters;
  permission sets max 20 (`BIFROST Clockify ori` is exactly 20).
- "Cloud Event(s)" and the `CE` prefix are gone. The brand name lives in the namespace, the app
  name, the permission set and the captions - never as an object-name prefix.
- Implementation codeunits are `Clockify <Entity><Verb> Impl ori`; where `<Entity><Verb>` would push
  the name past 26 characters the entity is abbreviated (`TEntry`, `TSheet`, `Proj`, `Wrkspace`,
  `UserGrp`, `CustFld`). See the rename table in CHANGELOG 29.0.0.0.
- Icelandic captions use "Bifröst".

## Platform Rules Inherited from Foundation
- **Bifröst Setup page**: this app adds **one action only**, in `group(Apps)` with its `actionref` in
  `addlast(Category_Apps)`. No fields, no table extension of `Setup ori`, no action group. All
  Clockify settings live on `Clockify Setup ori` (table + page 70009268).
- **Secrets**: the Clockify API key is still held by this app's own `Clockify Secret Mgt ori` in
  IsolatedStorage (Company scope) with `Clockify Set Secret Dialog ori`. Foundation now owns a
  unified `Secret Store ori`; migrating the key to it is a planned follow-up, and the key will have
  to be re-entered once because IsolatedStorage cannot be copied between extensions.

## Message Type Conventions
- Enum extension `Clockify Msg Type ori` (70009200) extends Foundation's `Message Type ori` with 41
  values. The keys (`Clockify.<Entity>.<Verb>`, plus `Help.Clockify.Get`) are the published external
  API contract and must never be renamed or removed.
- Each type has a `Clockify <Name> Impl ori` codeunit implementing `Msg Interface ori`
  (`ExecuteBifrostTask`), and gets its Markdown help from a per-domain help codeunit:
  `Clockify Workspace Help ori`, `Clockify Client Help ori`, `Clockify Project Help ori`,
  `Clockify Task Help ori`, `Clockify Tag Help ori`, `Clockify TimeEntry Help ori`,
  `Clockify TimeSheet Help ori`. Each exposes
  `GetHelp(MessageType: Enum "Message Type ori"; Description: Text): Text` with a `case` on the type.
  `Clockify Help Builder ori` renders the shared Markdown skeleton.
- `Clockify Help Overview Sub ori` adds the `Help.Clockify.Get` line to Foundation's
  `Help.Bifrost.Get` directory.
- Errors must be returned as `status = Error` with a helpful message through
  `Argument.RespondWithError`; never let an unhandled exception reach the API.

## Connector Conventions
- `Clockify Client ori` is the only HTTP path to Clockify; it authenticates with the `X-Api-Key`
  header read from IsolatedStorage and logs through Foundation's request log
  (`Clockify ReqLog Masker ori` passes bodies through unmasked - the key is never in a body).
- `Clockify Integration ori` maps BC records to Clockify objects; rows are never deleted, they are
  marked `Reversed` and purged by the retention policy about a month later.
- Time entries sync either to a Job Journal (`Clockify Time Entry Sync ori`) or to the resource's
  open Time Sheet (`Clockify TimeSheet Sync ori`). In-progress entries (no `end`) are rejected by
  both on purpose.

## Development Environment
- Two COSMO Alpaca containers, both defined in `app/.vscode/launch.json` (git-ignored, the authority
  for instance ids): `launch: bc28-is` (Icelandic CRONUS IS, used for the queue-API message-type
  tests) and `launch: bc28-w1` (W1). Publish and run the unit tests on **both**.
- Compile locally with alc.exe + CodeCop/UICop/AppSourceCop (symbols in `app/.alpackages`, test
  symbols in `test/.alpackages` including the freshly built Bifrost Foundation and Clockify .app).
  Command-line alc does not raise AS0011 (mandatory affix) - check affixes yourself; AL-Go CI is the
  real gate.
- Publish and test without VS Code (pwsh 7, credential from the user-level env vars `BC28IS_USER` /
  `BC28IS_PASSWORD`, never from files, commands or chat), using the shared tooling in the Foundation
  repo: `..\..\..\OrigoSoftwareSolutions\bc-origo-bifrost-core\tools\Publish-BifrostApp.ps1` and
  `Run-BifrostTests.ps1`.
- Publishing returns HTTP 422 *"another service is currently modifying the state of extensions"*
  while another session publishes to the same container - wait 60 s and retry, up to 10 times.

## Testing
- The test app registers its **own** `CLOCKIFY` AL Test Suite (range 95600..95699) on install and on
  upgrade (`Clockify Test Upgrade`, 95605). Run against that suite:
  `Run-AlTests ... -TestSuite 'CLOCKIFY' -TestIsolation Codeunit`. Do **not** rebuild the shared
  `DEFAULT` suite - several test apps live side by side on these containers.
- The runner's `-ExtensionId` discovery path returned zero tests for every app on both containers on
  2026-09-06; the named-suite route is the reliable one.
- Message types are verified over the queue API on bc28-is: POST
  `.../companies({id})/tasks?tenant=default` with a CloudEvents 1.0 envelope where **`data` is a
  JSON string** (an object is rejected with HTTP 400) and a non-blank `subject`, then GET
  `.../responses({taskId})/data?tenant=default`. Keep calls strictly serial. Test data uses the
  `BIFT-` prefix.
- With no Clockify API key on the container every outbound type answers with a handled
  `status = Error`; that is the expected negative path, never an HTTP 5xx.

## Migration Notes
- Migrated 2026-09-06 from `Origo Cloud Events Clockify` 28.1.0.0, using the union of `main` and the
  open pull request #5 `feature-#5_MessageTypes_Projects` (Time Sheet message types).
- In-place successor: same app id, same object ids, version bumped to 29.0.0.0. No data take-over
  install codeunit is needed. The dropped `Clockify Setup Ext` table extension is the one exception -
  its seven fields moved to `Clockify Setup ori` and their values cannot be carried across, because
  the table they lived on belongs to a dependency this version no longer references.
- See [CHANGELOG.md](../CHANGELOG.md) and
  [test/reports/Bifrost_Clockify_TestReport_2026-09-06.md](../test/reports/Bifrost_Clockify_TestReport_2026-09-06.md).

## Documentation

Documentation lives in businesscentralal/bifrost (site bifrost.origo.is); there is no `Help/` or
`docs/` folder in this repository.

- Product docs: https://businesscentralal.github.io/bifrost/en-us/clockify/
- In-product help: https://businesscentralal.github.io/bifrost/en-us/help/clockify/
- Extensibility guide: https://businesscentralal.github.io/bifrost/en-us/extensibility/

Context-sensitive help pages are addressed by Docusaurus slug, not by HTML file name:
`clockify-setup`, `clockify-integration-list`, `clockify-webhooks`, `clockify-workspace-lookup`,
`clockify-set-secret-dialog`. `Clockify Setup Ext ori` carries no slug - the shared `Setup ori`
page belongs to Bifröst Foundation.

Internal test reports and raw AL test results live in `test/reports/` and are never published.

## Development Standards

This project follows the **Origo BC Development Standards**
(https://github.com/OrigoSoftwareSolutions/bc-dev-standards).

Before writing any AL code, load the relevant skills:
- **`origo-bc-al-coding-standards`** - namespaces, XML docs, naming, formatting, performance, enums,
  Format/Evaluate, events, error handling, JSON, security
- **`origo-bc-test-writer`** - test structure, AAA pattern, coverage checklists, mock patterns
- **`origo-bc-documentation-writer`** - XML doc comments, markdown reference docs, help codeunits

Key rules always in effect:
- Namespace `Origo.Bifrost.Clockify` at the top of every file
- XML documentation on every object and non-local procedure
- Bilingual captions (en-US + is-IS) on all user-facing text; `Bifrost Clockify.is-IS.xlf` is
  regenerated from the `is-IS=` comments after every compile
- `SetLoadFields` on all record reads
- `Format(guid, 0, 4)` for GUIDs, `Format(value, 0, 9)` / `Evaluate(var, text, 9)` for
  culture-invariant serialization
- Never use `Format()` / `Evaluate()` on enum values - use `.Names()`, `.Ordinals()`,
  `.AsInteger()`, `.FromInteger()`
- Implementation = code + tests + documentation
