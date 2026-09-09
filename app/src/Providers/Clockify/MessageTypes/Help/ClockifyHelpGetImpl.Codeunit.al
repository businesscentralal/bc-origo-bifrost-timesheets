namespace Origo.Bifrost.Timesheets.Providers.Clockify;

using Origo.Bifrost;

/// <summary>
/// Implementation of the <c>Provider.Clockify.Help.Get</c> message type. Returns a Markdown
/// overview of the Clockify connector and every message type it exposes. No request
/// body is required.
/// </summary>
codeunit 10036802 "Clockify Help Get Impl ori" implements "Msg Interface ori"
{
    Access = Internal;

    procedure IsEnabled(): Boolean
    var
        ClockifyIntegration: Record "Clockify Integration ori";
        SecretMgt: Codeunit "Clockify Secret Mgt ori";
    begin
        if not ClockifyIntegration.WritePermission() then
            exit(false);
        exit(SecretMgt.HasCompanyApiKey());
    end;

    procedure GetFilterTableNo(): Integer
    begin
        exit(0);
    end;

    procedure GetDescription(): Text[250]
    begin
        exit('Returns a Markdown overview of the Clockify connector and all its message types. No request body is required.');
    end;

    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit(Enum::"Msg Direction ori"::Outbound);
    end;

    procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "Message Argument ori")
    begin
        Argument.SetResponseMarkdown(BuildOverview());
    end;

    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    var
        ResponseJson: JsonObject;
        ResultJson: JsonObject;
    begin
        Argument.AssertVersion1();

        ResultJson.Add('messageType', 'Provider.Clockify.Help.Get');
        ResultJson.Add('format', 'markdown');
        ResultJson.Add('markdown', BuildOverview());

        ResponseJson.Add('status', 'Success');
        ResponseJson.Add('result', ResultJson);
        Argument.SetResponseJson(ResponseJson);
        Argument."Content Type" := 'text/json';
    end;

    local procedure BuildOverview(): Text
    var
        Builder: TextBuilder;
    begin
        Builder.AppendLine('# Clockify Connector — Message Types');
        Builder.AppendLine('');
        Builder.AppendLine('The Clockify connector exposes the [Clockify](https://docs.developer.clockify.me) REST API as Bifrost message types.');
        Builder.AppendLine('Most message types are **outbound** (Business Central calls Clockify) and use `Content-Type: application/json`. The exceptions are `Timesheets.JobJournal.SyncFromClockify` (inbound BC-side operation that writes to the Job Journal and does not call Clockify) and `Timesheets.JobJournal.SyncRangeFromClockify` (inbound BC-side operation that reads entries from Clockify, then writes to the Job Journal).');
        Builder.AppendLine('');
        Builder.AppendLine('Authentication uses the workspace API key stored on Clockify Setup (`X-Api-Key`). Set `workspaceId` in the request, or configure a Default Workspace ID on Clockify Setup.');
        Builder.AppendLine('Create/update message types send the request''s `body` object verbatim to Clockify. List message types accept an optional `query` object whose properties become URL query parameters (for example `page-size`, `page`, `name`, `in-progress`).');
        Builder.AppendLine('For `Provider.Clockify.TimeEntry.List`, prefer `query.in-progress = false` when selecting entries for `Timesheets.JobJournal.SyncFromClockify`. In-progress entries (`end` = null) are intentionally rejected by sync and never written to Job Journal.');
        Builder.AppendLine('');
        Builder.AppendLine('Responses are wrapped as `{ "status", "statusCode", "data" }`. For the full request/response contract of any message type, request its per-type help.');
        Builder.AppendLine('');
        Builder.AppendLine('| Message type | Description |');
        Builder.AppendLine('|---|---|');
        Builder.AppendLine('| `Provider.Clockify.Workspace.List` | Lists the workspaces the API key can access. |');
        Builder.AppendLine('| `Provider.Clockify.User.GetCurrent` | Returns the currently authenticated user. |');
        Builder.AppendLine('| `Provider.Clockify.User.List` | Lists the users in a workspace. |');
        Builder.AppendLine('| `Provider.Clockify.Client.List` | Lists the clients in a workspace. |');
        Builder.AppendLine('| `Provider.Clockify.Client.Get` | Retrieves a single client by ID. |');
        Builder.AppendLine('| `Provider.Clockify.Client.Create` | Creates a client. |');
        Builder.AppendLine('| `Provider.Clockify.Client.Update` | Updates a client. |');
        Builder.AppendLine('| `Provider.Clockify.Client.Delete` | Deletes a client. |');
        Builder.AppendLine('| `Provider.Clockify.Project.List` | Lists the projects in a workspace. |');
        Builder.AppendLine('| `Provider.Clockify.Project.Get` | Retrieves a single project by ID. |');
        Builder.AppendLine('| `Provider.Clockify.Project.Create` | Creates a project. |');
        Builder.AppendLine('| `Provider.Clockify.Project.Update` | Updates a project. |');
        Builder.AppendLine('| `Provider.Clockify.Project.Delete` | Deletes a project. |');
        Builder.AppendLine('| `Provider.Clockify.Task.List` | Lists the tasks of a project. |');
        Builder.AppendLine('| `Provider.Clockify.Task.Create` | Creates a task. |');
        Builder.AppendLine('| `Provider.Clockify.Task.Update` | Updates a task. |');
        Builder.AppendLine('| `Provider.Clockify.Task.Delete` | Deletes a task. |');
        Builder.AppendLine('| `Provider.Clockify.Tag.List` | Lists the tags in a workspace. |');
        Builder.AppendLine('| `Provider.Clockify.Tag.Create` | Creates a tag. |');
        Builder.AppendLine('| `Provider.Clockify.Tag.Update` | Updates a tag. |');
        Builder.AppendLine('| `Provider.Clockify.Tag.Delete` | Deletes a tag. |');
        Builder.AppendLine('| `Provider.Clockify.TimeEntry.List` | Lists a user''s time entries in a workspace. |');
        Builder.AppendLine('| `Provider.Clockify.TimeEntry.Get` | Retrieves a single time entry by ID. |');
        Builder.AppendLine('| `Provider.Clockify.TimeEntry.Create` | Creates a time entry for a user. |');
        Builder.AppendLine('| `Provider.Clockify.TimeEntry.Update` | Updates a time entry. |');
        Builder.AppendLine('| `Provider.Clockify.TimeEntry.Delete` | Deletes a time entry. |');
        Builder.AppendLine('| `Timesheets.JobJournal.SyncFromClockify` | Syncs a time entry to a BC Job Journal Line with deduplication, update detection, and correction posting. |');
        Builder.AppendLine('| `Timesheets.JobJournal.SyncRangeFromClockify` | Syncs all of a user''s finished time entries in a date range to BC Job Journal Lines in a single call. |');
        Builder.AppendLine('| `Timesheets.TimeSheet.SyncFromClockify` | Syncs a time entry to the resource''s open BC Time Sheet (line + detail) instead of the Job Journal. |');
        Builder.AppendLine('| `Timesheets.TimeSheet.SyncRangeFromClockify` | Syncs all of a user''s finished time entries in a date range to their open BC Time Sheets in one call. |');
        Builder.AppendLine('| `Timesheets.SyncAllUsersFromClockify` | Syncs finished entries in a date range for **every mapped user** — to time sheets (default) or the Job Journal. |');
        Builder.AppendLine('| `Timesheets.TimeSheet.Create` | Creates upcoming weekly time sheets for every time-sheet resource (BC-side). |');
        Builder.AppendLine('| `Timesheets.TimeSheet.Approve` | Submits and approves open time-sheet lines up to a cut-off date (BC-side). |');
        Builder.AppendLine('| `Timesheets.TimeSheet.Reject` | Rejects submitted time-sheet lines up to a cut-off date (BC-side). |');
        Builder.AppendLine('| `Timesheets.TimeSheet.Reopen` | Reopens submitted or approved time-sheet lines back to Open (BC-side). |');
        Builder.AppendLine('| `Timesheets.TimeSheet.Post` | Transfers approved time-sheet detail to a Job Journal batch and posts it (BC-side). |');
        Builder.AppendLine('| `Timesheets.TimeSheet.Archive` | Archives fully posted time sheets and removes empty posted sheets (BC-side). |');
        Builder.AppendLine('| `Provider.Clockify.Currency.List` | Lists the currencies defined in a workspace. Returns the `currencyId` values that `Provider.Clockify.Client.Create` and `Provider.Clockify.Client.Update` need. |');
        Builder.AppendLine('| `Provider.Clockify.UserGroup.List` | Lists the user groups defined in a workspace. Returns the user-group IDs needed for `userGroupIds` on `Provider.Clockify.Project.Create` / `Provider.Clockify.Project.Update`. |');
        Builder.AppendLine('| `Provider.Clockify.CustomField.List` | Lists the workspace-level custom field definitions. Returns the `customFieldId` values needed when writing `customFields` on time entries and projects. |');
        Builder.AppendLine('');
        AppendCommonGotchasSection(Builder);
        AppendIntegrationTrackingSection(Builder);
        exit(Builder.ToText());
    end;

    local procedure AppendCommonGotchasSection(var Builder: TextBuilder)
    begin
        Builder.AppendLine('## Common Clockify quirks');
        Builder.AppendLine('');
        Builder.AppendLine('These behaviours are not obvious from the Clockify reference and have bitten integrations in production. Each per-type help repeats the relevant one in its **Notes** section.');
        Builder.AppendLine('');
        Builder.AppendLine('- **Clients use `currencyId`, not `currencyCode`.** The body of `Provider.Clockify.Client.Create` and `Provider.Clockify.Client.Update` must carry `currencyId` (an opaque Clockify ID). Passing `currencyCode` returns HTTP 200 but silently leaves the workspace default in place. Discover IDs with `Provider.Clockify.Currency.List`.');
        Builder.AppendLine('- **Clients must be archived before they can be deleted.** Clockify rejects `Provider.Clockify.Client.Delete` on active clients with HTTP 400 `Cannot delete an active client`. First send `Provider.Clockify.Client.Update` with body `{ "archived": true }`, then delete.');
        Builder.AppendLine('- **Clockify addresses are single-line.** The client (and similar) `address` field is one free-text value. When the source is a BC customer with `Address`, `Address 2`, `Post Code`, `City`, and `Country/Region Code`, concatenate them before sending.');
        Builder.AppendLine('- **Writes accept Clockify IDs, never names or BC keys.** `clientId`, `projectId`, `taskId`, `userId`, `tagIds`, `userGroupIds`, `customFieldId`, and `currencyId` are all opaque Clockify IDs. Passing display names or BC numbers returns HTTP 200 but the value is ignored. Resolve IDs first with the matching `*.List` message type.');
        Builder.AppendLine('- **Projects also archive before delete.** As with clients, `Provider.Clockify.Project.Delete` requires `archived = true` first; update the project, then delete.');
        Builder.AppendLine('');
    end;

    local procedure AppendIntegrationTrackingSection(var Builder: TextBuilder)
    begin
        Builder.AppendLine('## Integration tracking');
        Builder.AppendLine('');
        Builder.AppendLine('The connector keeps the links between Business Central records and Clockify objects (for example a BC **Customer** and a Clockify **Client**) in the **`Clockify Integration`** table. You manage it with the base **`Data.Records.Get`** and **`Data.Records.Set`** message types — the Clockify message types above never touch it.');
        Builder.AppendLine('');
        Builder.AppendLine('Each row holds:');
        Builder.AppendLine('');
        Builder.AppendLine('| Field | Meaning |');
        Builder.AppendLine('|---|---|');
        Builder.AppendLine('| `BC Table No.` | The BC table of the linked record (for example `18` for Customer). |');
        Builder.AppendLine('| `BC SystemId` | The SystemId of the linked BC record — the stable link target. |');
        Builder.AppendLine('| `BC Code` | The readable key of the BC record (for example the Customer No.). |');
        Builder.AppendLine('| `Clockify Type` | `CLIENT`, `PROJECT`, `TASK`, `TAG`, `TIME_ENTRY`, `USER` or `WORKSPACE`. |');
        Builder.AppendLine('| `Clockify Workspace Id` | The workspace the Clockify object lives in. |');
        Builder.AppendLine('| `Clockify Id` | The Clockify object identifier. |');
        Builder.AppendLine('| `Clockify Name` | The display name of the Clockify object. |');
        Builder.AppendLine('| `Reversed` | Set to `true` to break the link (rows cannot be deleted). |');
        Builder.AppendLine('| `Reversed At` | Stamped automatically when `Reversed` becomes `true`. |');
        Builder.AppendLine('');
        Builder.AppendLine('### Methods for storing integration information');
        Builder.AppendLine('');
        Builder.AppendLine('Use the following `Data.Records.Set` and `Data.Records.Get` patterns to manage the Clockify Integration table.');
        Builder.AppendLine('');
        Builder.AppendLine('#### Record a link (`Data.Records.Set`)');
        Builder.AppendLine('');
        Builder.AppendLine('After creating or syncing an object in Clockify, record the link:');
        Builder.AppendLine('');
        Builder.AppendLine('```json');
        Builder.AppendLine('{');
        Builder.AppendLine('  "type": "Data.Records.Set",');
        Builder.AppendLine('  "body": {');
        Builder.AppendLine('    "table": "Clockify Integration ori",');
        Builder.AppendLine('    "records": [');
        Builder.AppendLine('      {');
        Builder.AppendLine('        "primaryKey": { "Entry No.": <next entry no.> },');
        Builder.AppendLine('        "fields": {');
        Builder.AppendLine('          "BC Table No.": 18,');
        Builder.AppendLine('          "BC SystemId": "<SystemId of BC Customer>",');
        Builder.AppendLine('          "BC Code": "10000",');
        Builder.AppendLine('          "Clockify Type": "CLIENT",');
        Builder.AppendLine('          "Clockify Workspace Id": "<workspaceId>",');
        Builder.AppendLine('          "Clockify Id": "<clockify client id>",');
        Builder.AppendLine('          "Clockify Name": "Adatum Corporation",');
        Builder.AppendLine('          "Reversed": false');
        Builder.AppendLine('        }');
        Builder.AppendLine('      }');
        Builder.AppendLine('    ]');
        Builder.AppendLine('  }');
        Builder.AppendLine('}');
        Builder.AppendLine('```');
        Builder.AppendLine('');
        Builder.AppendLine('Common `Clockify Type` and `BC Table No.` pairings:');
        Builder.AppendLine('');
        Builder.AppendLine('| Clockify Type | BC Table No. | BC Table |');
        Builder.AppendLine('|---|---|---|');
        Builder.AppendLine('| `CLIENT` | 18 | Customer |');
        Builder.AppendLine('| `PROJECT` | 167 | Job |');
        Builder.AppendLine('| `TASK` | 1001 | Job Task |');
        Builder.AppendLine('| `USER` | 156 | Resource |');
        Builder.AppendLine('| `TIME_ENTRY` | 210 | Job Journal Line (or 169 = Job Ledger Entry after posting) |');
        Builder.AppendLine('| `TAG` | 200 | Work Type — optional; links a Clockify tag to a BC Work Type so synced time entries carry a Work Type Code (`BC Code` = the Work Type Code). |');
        Builder.AppendLine('');
        Builder.AppendLine('#### Resolve a link (`Data.Records.Get`)');
        Builder.AppendLine('');
        Builder.AppendLine('Look up the Clockify ID for a BC record (or vice versa):');
        Builder.AppendLine('');
        Builder.AppendLine('```json');
        Builder.AppendLine('{');
        Builder.AppendLine('  "type": "Data.Records.Get",');
        Builder.AppendLine('  "body": {');
        Builder.AppendLine('    "table": "Clockify Integration ori",');
        Builder.AppendLine('    "filter": "WHERE(Clockify Type=CONST(PROJECT),BC Table No.=CONST(167),Reversed=CONST(false))"');
        Builder.AppendLine('  }');
        Builder.AppendLine('}');
        Builder.AppendLine('```');
        Builder.AppendLine('');
        Builder.AppendLine('To find the BC record for a known Clockify ID:');
        Builder.AppendLine('');
        Builder.AppendLine('```json');
        Builder.AppendLine('{');
        Builder.AppendLine('  "type": "Data.Records.Get",');
        Builder.AppendLine('  "body": {');
        Builder.AppendLine('    "table": "Clockify Integration ori",');
        Builder.AppendLine('    "filter": "WHERE(Clockify Type=CONST(TIME_ENTRY),Clockify Id=CONST(<clockifyId>),Reversed=CONST(false))"');
        Builder.AppendLine('  }');
        Builder.AppendLine('}');
        Builder.AppendLine('```');
        Builder.AppendLine('');
        Builder.AppendLine('#### Break a link (`Data.Records.Set` with `Reversed`)');
        Builder.AppendLine('');
        Builder.AppendLine('Neither `Data.Records.Get` nor `Data.Records.Set` can delete rows. Set `Reversed` = `true` instead:');
        Builder.AppendLine('');
        Builder.AppendLine('```json');
        Builder.AppendLine('{');
        Builder.AppendLine('  "type": "Data.Records.Set",');
        Builder.AppendLine('  "body": {');
        Builder.AppendLine('    "table": "Clockify Integration ori",');
        Builder.AppendLine('    "records": [');
        Builder.AppendLine('      {');
        Builder.AppendLine('        "primaryKey": { "Entry No.": <existing entry no.> },');
        Builder.AppendLine('        "fields": { "Reversed": true }');
        Builder.AppendLine('      }');
        Builder.AppendLine('    ]');
        Builder.AppendLine('  }');
        Builder.AppendLine('}');
        Builder.AppendLine('```');
        Builder.AppendLine('');
        Builder.AppendLine('A retention policy automatically purges reversed rows about **one month** after `Reversed At`.');
        Builder.AppendLine('');
        Builder.AppendLine('#### Automated sync (`Timesheets.JobJournal.SyncFromClockify`)');
        Builder.AppendLine('');
        Builder.AppendLine('The `Timesheets.JobJournal.SyncFromClockify` message type handles integration tracking automatically:');
        Builder.AppendLine('');
        Builder.AppendLine('- **Created**: Creates a Job Journal Line and a new integration record linking the Clockify time entry ID to the journal line SystemId.');
        Builder.AppendLine('- **Skipped**: Time entry already synced and unchanged — no action.');
        Builder.AppendLine('- **Updated**: Time entry changed but journal line not yet posted — updates the line in place and updates the integration name.');
        Builder.AppendLine('- **Corrected**: Time entry changed but already posted to Job Ledger — reverses the old integration, creates a reversal journal line (negative qty) and a new correct line with new integration.');
        Builder.AppendLine('');
        Builder.AppendLine('##### How a synced line is built');
        Builder.AppendLine('');
        Builder.AppendLine('| Job Journal Line field | Source |');
        Builder.AppendLine('|---|---|');
        Builder.AppendLine('| Job No. | The `PROJECT` integration link for the entry''s Clockify project. |');
        Builder.AppendLine('| Job Task No. | The `TASK` integration link for the entry''s Clockify task. The Clockify task always maps to a BC Job Task. |');
        Builder.AppendLine('| No. (Resource) | The `USER` integration link for the entry''s Clockify user. People sync as BC **Resources** (not Employees). |');
        Builder.AppendLine('| Quantity | The entry duration in hours. |');
        Builder.AppendLine('| Line Type | `Both Budget and Billable` when the entry is billable, otherwise `Budget`. |');
        Builder.AppendLine('| Work Type Code | Resolved from the entry''s **tags** (see below). |');
        Builder.AppendLine('| Unit of Measure / Unit Price / Unit Cost | Defaulted by BC from the Resource and standard job/resource pricing. Clockify rates are not transferred. |');
        Builder.AppendLine('');
        Builder.AppendLine('**Work Type resolution (tags → Work Type).** A Clockify tag can be linked to a BC Work Type with a `TAG` integration row whose `BC Code` is the Work Type Code. When a time entry is synced, the connector takes the **first** of the entry''s tags that is linked to a Work Type and stamps it on the journal line. If the entry has no tags, or none of its tags is linked, the **`Clockify Default Work Type`** on Clockify Setup is used. If that is also blank, the line''s Work Type is left empty.');
        Builder.AppendLine('');
        Builder.AppendLine('**Journal target.** Lines are written to the **`Clockify Job Journal Template` / `Clockify Job Journal Batch`** configured on Clockify Setup (the `Timesheets.JobJournal.SyncFromClockify` request may override them per call with `journalTemplate` / `journalBatch`). The connector **creates** the journal line only — it never posts it; posting is left to a person.');
        Builder.AppendLine('');
        Builder.AppendLine('When the Job Journal is posted, the `Clockify Event Subscribers` codeunit automatically updates the integration record from `BC Table No. = 210` (Job Journal Line) to `BC Table No. = 169` (Job Ledger Entry).');
        Builder.AppendLine('');
        Builder.AppendLine('> Every Clockify message type except this help requires **write permission to the `Clockify Integration` table** (the `Clockify - Full` permission set grants it). Requests run by a user without it return an error.');
    end;
}
