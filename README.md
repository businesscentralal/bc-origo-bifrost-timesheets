# Bifröst Clockify

**App name:** Bifrost Clockify  
**Publisher:** Origo — **Version:** 29.0.0.0 — **Target:** Cloud (BC 28, runtime 17.0)  
**App ID:** `d4560cf5-947d-42b5-b812-33ae8dd009af` — **Test app ID:** `553214e3-b742-4ccf-8ecc-1ee86fbc96f9`  
**Object ID range:** 70009200–70009299 (tests 95600–95699) — **Namespace:** `Origo.Bifrost.Clockify`

Bifröst Clockify exposes the [Clockify](https://docs.developer.clockify.me) time-tracking REST API
as 41 Bifröst message types on top of Bifrost Foundation. Workspaces, users, user groups, clients,
projects, tasks, tags, currencies, custom fields and time entries are readable and writable over the
Bifröst queue API (`origo/bifrost/v1.0`), so an external system or an AI agent can drive Clockify
from Business Central the same way a user would.

On top of the pass-through API the connector synchronises finished Clockify time entries into
Business Central — either into a Job Journal (with deduplication, update detection and correction
posting) or into the resource's open Time Sheet — and manages the Time Sheet lifecycle (create,
approve, reject, reopen, post, archive). A webhook receiver keeps the sync real-time. It is the
in-place successor of *Origo Cloud Events Clockify*: same app id, same object ids, so an installed
environment upgrades rather than installing a second app.

---

## Documentation

All public documentation lives in the [businesscentralal/bifrost](https://github.com/businesscentralal/bifrost)
site repository and is published at <https://businesscentralal.github.io/bifrost>. There are no `docs/` or `Help/`
folders in this repository.

| What | Where |
| --- | --- |
| Product documentation (overview, message types, requirements) | <https://businesscentralal.github.io/bifrost/en-us/clockify/> |
| In-product help (context-sensitive help pages, en-US and is-IS) | <https://businesscentralal.github.io/bifrost/en-us/help/clockify/> |
| Building on Bifröst (extensibility guide) | <https://businesscentralal.github.io/bifrost/en-us/extensibility/> |
| Release notes | [CHANGELOG.md](CHANGELOG.md) |

Message-type contracts are also served by the app itself at runtime: `Help.Clockify.Get` returns the
connector directory, and every message type answers its own Markdown help through
`get_message_type_help` / `Help.Implementation.Get`. The source of those documents is the per-domain
help codeunits under `app/src/MessageTypes/`.

Context-sensitive help pages are addressed by Docusaurus slug (`clockify-setup`,
`clockify-integration-list`, `clockify-webhooks`, `clockify-workspace-lookup`,
`clockify-set-secret-dialog`), resolved against the `contextSensitiveHelpUrl` in `app/app.json`.

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
| `app/` | The AppSource app (`Bifrost Clockify`) |
| `app/src/Integration/` | HTTP client, request management, integration table and gate, webhook handler, archive and time-entry sync engines |
| `app/src/Setup/` | Clockify Setup table and card, Bifröst Setup extension, secret, webhook and workspace management |
| `app/src/MessageTypes/` | Message type enum extension, implementations and per-domain help codeunits |
| `app/src/Lifecycle/` | Install codeunit and retention policy |
| `app/src/Permissions/` | `BIFROST Clockify ori` |
| `app/src/RequestLog/` | Request-log type extension and masker |
| `test/` | Test app (`Bifrost Clockify - Tests`, range 95600–95699) |
| `test/reports/` | End-to-end message-type test reports and raw test results (internal, not published) |
| `.AL-Go/`, `.github/` | AL-Go for GitHub / COSMO Alpaca pipeline configuration |

---

## Dependencies

| App | ID | Publisher | Version |
| --- | --- | --- | --- |
| Bifrost Foundation | `7505e808-6e52-4b96-a328-82573391297a` | Origo | 28.0.0.0 |

That is the only AL dependency. The test app additionally depends on Bifrost Clockify itself and on
Microsoft's test libraries.

At runtime a Clockify account with an API key is required; the key is stored in IsolatedStorage
(Company scope) by this app, never in a table field.

---

## Development

- Open `al.code-workspace` in VS Code.
- Development containers: COSMO Alpaca `launch: bc28-is` (CRONUS IS) and `launch: bc28-w1` (W1
  CRONUS International Ltd.), both defined in `app/.vscode/launch.json` — git-ignored and the
  authority for the instance ids. Publish and run the unit tests on **both**.
- Compile locally with `alc.exe` plus CodeCop, UICop and AppSourceCop. Symbols live in
  `app/.alpackages`; test symbols in `test/.alpackages`, including the Bifrost Foundation and
  Bifrost Clockify `.app` files.

  ```
  alc.exe /project:app /packagecachepath:app/.alpackages /out:app/output/clockify.app ^
          /analyzer:<CodeCop.dll> /analyzer:<UICop.dll> /analyzer:<AppSourceCop.dll>
  ```

- Publish and run tests without VS Code (pwsh 7, credential from the user-level env vars
  `BC28IS_USER` / `BC28IS_PASSWORD`, never from files):
  `bc-origo-bifrost-core/tools/Publish-BifrostApp.ps1 -AppFile <.app>` and
  `bc-origo-bifrost-core/tools/Run-BifrostTests.ps1`. The test app registers its own `CLOCKIFY` AL
  Test Suite — run against that suite, not `DEFAULT`.
- Command-line `alc` does not raise AS0011 (mandatory affix); AL-Go CI is the gate, so check the
  ` ori` suffix yourself before pushing.
- Standards: [Origo BC Development Standards](https://github.com/OrigoSoftwareSolutions/bc-dev-standards).
  Project rules are in `.claude/CLAUDE.md`.
- Every object carries the mandatory ` ori` suffix; the brand name is carried by the namespace, the
  app name and the captions, never by an object-name prefix.

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
