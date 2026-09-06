# Bifrost Clockify

**Publisher:** Origo &nbsp;|&nbsp; **Version:** 29.0.0.0 &nbsp;|&nbsp; **Object ID range:** 70009200-70009299 &nbsp;|&nbsp; **Namespace:** `Origo.Bifrost.Clockify`

Bifrost Clockify exposes the [Clockify](https://docs.developer.clockify.me) time-tracking REST API as
Bifröst message types on top of [Bifrost Foundation](https://github.com/OrigoSoftwareSolutions/bc-origo-bifrost-core).
Workspaces, users, user groups, clients, projects, tasks, tags, currencies, custom fields and time
entries are readable and writable over the Bifröst queue API (`origo/bifrost/v1.0`), so an external
system or an AI agent can drive Clockify from Business Central the same way a user would.

On top of the pass-through API the connector synchronises finished Clockify time entries into
Business Central — either into a Job Journal (with deduplication, update detection and correction
posting) or into the resource's open Time Sheet — and manages the Time Sheet lifecycle (create,
approve, reject, reopen, post, archive). A webhook receiver keeps the sync real-time.

This app is the successor of *Origo Cloud Events Clockify*; it keeps the same app id and object ids,
so an installed environment upgrades in place. See [CHANGELOG.md](CHANGELOG.md) for the migration
record.

## Documentation

Public documentation lives in the [businesscentralal/bifrost](https://github.com/businesscentralal/bifrost)
site repository — there is no `Help/` folder here.

- Product documentation: https://bifrost.origo.is/en-us/clockify/
- In-product help (context-sensitive help pages): https://bifrost.origo.is/en-us/help/clockify/

Every message type also documents itself at runtime: `Help.Clockify.Get` returns the connector
overview, and `Help.Implementation.Get` with the message type as subject returns that type's full
request/response contract. The source of those documents is the per-domain help codeunits under
`app/src/MessageTypes/`.

The internal migration test report is in
[app/docs/Bifrost_Clockify_TestReport_2026-09-06.md](app/docs/Bifrost_Clockify_TestReport_2026-09-06.md).

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

## Setup

All settings live on the **Clockify Setup** card, reachable from one action in the `Apps` group of
the Bifröst Setup page. Nothing is added to Foundation's own setup fields.

| Setting | Purpose |
| --- | --- |
| Clockify API Version | Which API implementation the connector uses (default `Version 1`) |
| Default Workspace / Workspace Name | Workspace used when a request omits `workspaceId`; picked from a live lookup |
| Company API Key | Stored in IsolatedStorage (Company scope), never in a table field |
| Job Journal Template / Batch | Where synced time entries are written |
| Default Work Type | Fallback Work Type when a time entry has no Work-Type-linked tag |
| Webhook Receiver URL | The endpoint that forwards Clockify events into Business Central |

Use the card's actions to set or clear the API key, register or remove the real-time time-entry
webhooks, show the webhook signing tokens, and open the integration links between BC records and
Clockify objects.

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
| `test/` | Test app (`Bifrost Clockify - Tests`, range 95600-95699) |
| `.AL-Go/`, `.github/` | AL-Go for GitHub / COSMO Alpaca pipeline configuration |

## Development

- Open `al.code-workspace` in VS Code.
- Development containers: COSMO Alpaca `launch: bc28-is` (CRONUS IS) and `launch: bc28-w1` (W1),
  both in `app/.vscode/launch.json` (git-ignored).
- Build locally with `alc.exe` from the AL extension, using `app/.alpackages` as the package cache
  and the CodeCop, UICop and AppSourceCop analyzers. Zero errors and zero warnings is the bar.
- Publish and run the tests with `Publish-BifrostApp.ps1` / `Run-BifrostTests.ps1` from
  `bc-origo-bifrost-core/tools`. The test app registers its own `CLOCKIFY` AL Test Suite — run
  against that suite, not `DEFAULT`.
- Standards: [Origo BC Development Standards](https://github.com/OrigoSoftwareSolutions/bc-dev-standards).
  Project rules are in `.claude/CLAUDE.md`.
- Every object carries the mandatory `ori` suffix; the brand name is carried by the namespace, the
  app name and the captions, never by object names.

<!-- AUTO-UPDATE-START -->
# COSMO Alpaca AL-Go AppSource App Template

[![Use this template](https://github.com/microsoft/AL-Go/assets/10775043/ca1ecc85-2fd3-4ab5-a866-bd2e7e80259d)](https://github.com/new?template_name=Alpaca-AppSource-Template&template_owner=cosmoconsult)

This template repository can be used for managing AppSource Apps for Business Central.

It is a customized version of the [AL-Go-AppSource](https://github.com/microsoft/AL-Go-AppSource) template and is designed to be used with [COSMO Alpaca](https://cosmoconsult.com/cosmo-alpaca).

> [!NOTE]
> If you created this repository using the GitHub web UI (for example by clicking **Use this template** on GitHub.com) instead of creating it from the COSMO Alpaca VS Code extension, you must initialize it using the [COSMO Alpaca VS Code extension](https://marketplace.visualstudio.com/items?itemName=cosmoconsult.cosmo-alpaca). To do this, simply right-click on the repository in VS Code and select _Initialize_.

Please go to https://aka.ms/AL-Go and [COSMO Docs](https://docs.cosmoconsult.com/en-us/cloud-service/alpaca) to learn more.
<!-- AUTO-UPDATE-END -->
