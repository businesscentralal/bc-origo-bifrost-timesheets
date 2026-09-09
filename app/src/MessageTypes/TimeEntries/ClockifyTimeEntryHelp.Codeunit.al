namespace Origo.Bifrost.Timesheets;

using Origo.Bifrost;

/// <summary>
/// Builds the Markdown help documents for the Clockify time-entry message types, including the Job Journal synchronisation types,
/// keeping the help text out of the individual <c>*Impl ori</c> codeunits. Every
/// implementation of the domain calls <see cref="GetHelp"/> from
/// <c>GetMessageHelpAsMarkdownDocument</c>, so <c>Help.Implementation.Get</c> still
/// answers per message type.
/// </summary>
codeunit 10036852 "Clockify TimeEntry Help ori"
{
    Access = Internal;

    /// <summary>Returns the Markdown help document for one message type of this domain.</summary>
    /// <param name="MessageType">The message type to document.</param>
    /// <param name="Description">The message type description shown in the help header.</param>
    /// <returns>The rendered Markdown document, or an empty string for a message type this codeunit does not own.</returns>
    procedure GetHelp(MessageType: Enum "Message Type ori"; Description: Text): Text
    begin
        case MessageType of
            MessageType::"Clockify.TimeEntry.List":
                exit(GetTimeEntryListHelp(Description));
            MessageType::"Clockify.TimeEntry.Get":
                exit(GetTimeEntryGetHelp(Description));
            MessageType::"Clockify.TimeEntry.Create":
                exit(GetTimeEntryCreateHelp(Description));
            MessageType::"Clockify.TimeEntry.Update":
                exit(GetTimeEntryUpdateHelp(Description));
            MessageType::"Clockify.TimeEntry.Delete":
                exit(GetTimeEntryDeleteHelp(Description));
            MessageType::"Clockify.TimeEntry.Sync":
                exit(GetTimeEntrySyncHelp(Description));
            MessageType::"Clockify.TimeEntry.SyncRange":
                exit(GetTimeEntrySyncRangeHelp(Description));
        end;
        exit('');
    end;

    /// <summary>Returns the help document for <c>Clockify.TimeEntry.List</c>.</summary>
    /// <param name="Description">The message type description shown in the help header.</param>
    local procedure GetTimeEntryListHelp(Description: Text): Text
    var
        HelpBuilder: Codeunit "Clockify Help Builder ori";
    begin
        HelpBuilder.Init('Clockify.TimeEntry.List', Description, 'GET', '/workspaces/{workspaceId}/user/{userId}/time-entries');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Clockify.Workspace.List → id');
        HelpBuilder.AddParam('userId', true, 'string', 'Clockify user ID whose entries to list', 'Clockify.User.GetCurrent → id or Clockify.User.List → id');
        HelpBuilder.AddParam('query.page-size', false, 'integer', 'Results per page (default 50, max 5000)', '');
        HelpBuilder.AddParam('query.page', false, 'integer', 'Page number (1-based)', '');
        HelpBuilder.AddParam('query.start', false, 'string', 'Filter: entries starting at or after this ISO-8601 UTC timestamp', '');
        HelpBuilder.AddParam('query.end', false, 'string', 'Filter: entries ending at or before this ISO-8601 UTC timestamp', '');
        HelpBuilder.AddParam('query.project', false, 'string', 'Filter: Clockify project ID', 'Clockify.Project.List → id');
        HelpBuilder.AddParam('query.task', false, 'string', 'Filter: Clockify task ID', 'Clockify.Task.List → id');
        HelpBuilder.AddParam('query.in-progress', false, 'boolean', 'Filter: true returns running timers only (`end` = null), false returns finished entries only (`end` is set).', '');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "userId": "63...", "query": { "start": "2026-06-01T00:00:00Z", "end": "2026-06-30T23:59:59Z", "in-progress": false, "page-size": 50, "page": 1 } }');
        HelpBuilder.SetResponseNote('an array of time-entry objects (each with `id`, `start`, `end`, `duration`, `projectId`, `taskId`, `tagIds`)');
        HelpBuilder.SetAfterSuccess('No tracking action required — this is a read operation. Use `id` values for Get/Update/Delete/Sync.');
        HelpBuilder.AddError(404, 'User not found', 'Verify userId via `Clockify.User.GetCurrent` or `Clockify.User.List`');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Clockify Setup');
        HelpBuilder.SetNotes('- Time entries are **per-user** — you must specify whose entries to list.\' +
            '- Use `start` and `end` filters to scope to a date range (ISO-8601 UTC).\' +
                '- `query.in-progress = true` returns only running timers (`end` = null).\' +
                '- `query.in-progress = false` returns only finished entries (`end` has a value).\' +
                '- For `Clockify.TimeEntry.Sync`, prefer finished entries only (set `query.in-progress = false`).');
        HelpBuilder.SetRelated('- **Resolve userId:** `Clockify.User.GetCurrent` (API key owner) or `Clockify.User.List`\' +
            '- **Get single entry:** `Clockify.TimeEntry.Get`\' +
            '- **Sync entries to BC:** `Clockify.TimeEntry.Sync`');
        exit(HelpBuilder.Render());
    end;

    /// <summary>Returns the help document for <c>Clockify.TimeEntry.Get</c>.</summary>
    /// <param name="Description">The message type description shown in the help header.</param>
    local procedure GetTimeEntryGetHelp(Description: Text): Text
    var
        HelpBuilder: Codeunit "Clockify Help Builder ori";
    begin
        HelpBuilder.Init('Clockify.TimeEntry.Get', Description, 'GET', '/workspaces/{workspaceId}/time-entries/{timeEntryId}');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Clockify.Workspace.List → id');
        HelpBuilder.AddParam('timeEntryId', true, 'string', 'The time entry ID to retrieve', 'Clockify.TimeEntry.List → id');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "timeEntryId": "64..." }');
        HelpBuilder.SetResponseNote('the time-entry object (includes `id`, `start`, `end`, `duration`, `projectId`, `taskId`, `tagIds`, `billable`)');
        HelpBuilder.SetAfterSuccess('No tracking action required — this is a read operation.');
        HelpBuilder.AddError(404, 'Time entry not found', 'Verify timeEntryId via `Clockify.TimeEntry.List`');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Clockify Setup');
        HelpBuilder.SetRelated('- **Find timeEntryId:** `Clockify.TimeEntry.List` (requires userId)\' +
            '- **Update this entry:** `Clockify.TimeEntry.Update`\' +
            '- **Sync to BC:** `Clockify.TimeEntry.Sync`');
        exit(HelpBuilder.Render());
    end;

    /// <summary>Returns the help document for <c>Clockify.TimeEntry.Create</c>.</summary>
    /// <param name="Description">The message type description shown in the help header.</param>
    local procedure GetTimeEntryCreateHelp(Description: Text): Text
    var
        HelpBuilder: Codeunit "Clockify Help Builder ori";
    begin
        HelpBuilder.Init('Clockify.TimeEntry.Create', Description, 'POST', '/workspaces/{workspaceId}/user/{userId}/time-entries');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Clockify.Workspace.List → id');
        HelpBuilder.AddParam('userId', true, 'string', 'Clockify user ID (NOT the BC user name)', 'Clockify.User.GetCurrent → id or Clockify.User.List → id');
        HelpBuilder.AddParam('body.start', true, 'string', 'Start time in ISO-8601 UTC (e.g. 2026-06-09T08:00:00Z)', '');
        HelpBuilder.AddParam('body.end', false, 'string', 'End time in ISO-8601 UTC. Omit to start a running timer.', '');
        HelpBuilder.AddParam('body.description', false, 'string', 'Free-text description of the work performed', '');
        HelpBuilder.AddParam('body.projectId', false, 'string', 'Clockify project ID (NOT the BC project number)', 'Clockify.Project.List → id');
        HelpBuilder.AddParam('body.taskId', false, 'string', 'Clockify task ID', 'Clockify.Task.List → id');
        HelpBuilder.AddParam('body.tagIds', false, 'array', 'Array of Clockify tag IDs', 'Clockify.Tag.List → id');
        HelpBuilder.AddParam('body.billable', false, 'boolean', 'true = billable (overrides project default)', '');
        HelpBuilder.AddParam('body.type', false, 'string', 'REGULAR (default) or BREAK', '');
        HelpBuilder.AddParam('body.customFields', false, 'array', 'Array of { customFieldId, value }', 'Clockify.CustomField.List → id');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "userId": "63...", "body": { "start": "2026-06-09T08:00:00Z", "end": "2026-06-09T10:00:00Z", "description": "Consulting", "projectId": "60...", "taskId": "61...", "tagIds": [ "62..." ], "billable": true, "customFields": [ { "customFieldId": "64...", "value": "PO-1234" } ] } }');
        HelpBuilder.SetResponseNote('the created time-entry object (includes `id`, `start`, `end`, `duration`, `projectId`, `taskId`)');
        HelpBuilder.AddError(400, 'Overlapping time entry', 'Check existing entries for the same period via `Clockify.TimeEntry.List`');
        HelpBuilder.AddError(404, 'User or workspace not found', 'Verify userId via `Clockify.User.GetCurrent` or `Clockify.User.List`');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Clockify Setup');
        HelpBuilder.SetNotes('- `start` must be ISO-8601 UTC. Clockify rejects local-time strings without offset.\' +
            '- Omit `end` to start a **running timer**; send a later `Clockify.TimeEntry.Update` with `end` to stop it.\' +
            '- `projectId`, `taskId`, and `tagIds` entries are Clockify internal IDs — names are silently ignored.\' +
            '- `customFields` format: `{ "customFieldId": "...", "value": ... }`. Get IDs from `Clockify.CustomField.List`.\' +
            '- `userId` in the URL is the Clockify user ID, NOT the BC user name.');
        HelpBuilder.SetRelated('- **Resolve userId:** `Clockify.User.GetCurrent` (API key owner) or `Clockify.User.List`\' +
            '- **Resolve projectId:** `Clockify.Project.List` or Clockify Integration (type=project)\' +
            '- **Resolve taskId:** `Clockify.Task.List` (requires projectId)\' +
            '- **Resolve tagIds:** `Clockify.Tag.List`\' +
            '- **Stop running timer:** `Clockify.TimeEntry.Update` with `end` field\' +
            '- **Sync to BC:** `Clockify.TimeEntry.Sync` (posts to Job Journal)');
        exit(HelpBuilder.Render());
    end;

    /// <summary>Returns the help document for <c>Clockify.TimeEntry.Update</c>.</summary>
    /// <param name="Description">The message type description shown in the help header.</param>
    local procedure GetTimeEntryUpdateHelp(Description: Text): Text
    var
        HelpBuilder: Codeunit "Clockify Help Builder ori";
    begin
        HelpBuilder.Init('Clockify.TimeEntry.Update', Description, 'PUT', '/workspaces/{workspaceId}/time-entries/{timeEntryId}');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Clockify.Workspace.List → id');
        HelpBuilder.AddParam('timeEntryId', true, 'string', 'The time entry ID to update', 'Clockify.TimeEntry.List → id');
        HelpBuilder.AddParam('body.start', false, 'string', 'Start time (ISO-8601 UTC)', '');
        HelpBuilder.AddParam('body.end', false, 'string', 'End time (ISO-8601 UTC). Setting this on an open entry **stops the timer**.', '');
        HelpBuilder.AddParam('body.description', false, 'string', 'Free-text description', '');
        HelpBuilder.AddParam('body.projectId', false, 'string', 'Clockify project ID', 'Clockify.Project.List → id');
        HelpBuilder.AddParam('body.taskId', false, 'string', 'Clockify task ID', 'Clockify.Task.List → id');
        HelpBuilder.AddParam('body.tagIds', false, 'array', 'Array of tag IDs. **Empty array clears all tags**; omit to keep current.', 'Clockify.Tag.List → id');
        HelpBuilder.AddParam('body.billable', false, 'boolean', 'Override billable status', '');
        HelpBuilder.AddParam('body.customFields', false, 'array', 'Array of { customFieldId, value }', 'Clockify.CustomField.List → id');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "timeEntryId": "64...", "body": { "start": "2026-06-09T08:00:00Z", "end": "2026-06-09T11:00:00Z", "description": "Consulting (revised)", "billable": true, "customFields": [ { "customFieldId": "65...", "value": "PO-1234" } ] } }');
        HelpBuilder.SetResponseNote('the updated time-entry object');
        HelpBuilder.AddError(400, 'Overlapping time entry', 'Adjust start/end to avoid overlap with existing entries');
        HelpBuilder.AddError(404, 'Time entry not found', 'Verify timeEntryId via `Clockify.TimeEntry.List`');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Clockify Setup');
        HelpBuilder.SetNotes('- Setting `end` on an entry with no end **stops the running timer**.\' +
            '- `tagIds: []` (empty array) **clears all tags**; omitting `tagIds` entirely leaves existing tags unchanged.\' +
            '- Send only fields you want to change; omitted fields retain current values.\' +
            '- `customFields` format: `{ "customFieldId": "...", "value": ... }`. Get IDs from `Clockify.CustomField.List`.');
        HelpBuilder.SetRelated('- **Stop running timer:** Send `{ "end": "<ISO-8601 UTC>" }`\' +
            '- **Delete instead:** `Clockify.TimeEntry.Delete`\' +
            '- **Sync updated entry to BC:** `Clockify.TimeEntry.Sync`');
        exit(HelpBuilder.Render());
    end;

    /// <summary>Returns the help document for <c>Clockify.TimeEntry.Delete</c>.</summary>
    /// <param name="Description">The message type description shown in the help header.</param>
    local procedure GetTimeEntryDeleteHelp(Description: Text): Text
    var
        HelpBuilder: Codeunit "Clockify Help Builder ori";
    begin
        HelpBuilder.Init('Clockify.TimeEntry.Delete', Description, 'DELETE', '/workspaces/{workspaceId}/time-entries/{timeEntryId}');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Clockify.Workspace.List → id');
        HelpBuilder.AddParam('timeEntryId', true, 'string', 'The time entry ID to delete', 'Clockify.TimeEntry.List → id');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "timeEntryId": "64..." }');
        HelpBuilder.SetResponseNote('empty body (HTTP 204 No Content on success)');
        HelpBuilder.AddError(404, 'Time entry not found', 'Verify timeEntryId via `Clockify.TimeEntry.List`');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Clockify Setup');
        HelpBuilder.SetNotes('- No archive step required — time entries can be deleted directly.\' +
            '- If the entry was already synced to BC, consider reversing the Job Journal Line in BC as well.');
        HelpBuilder.SetRelated('- **Alternative:** Update with corrected times instead of deleting (`Clockify.TimeEntry.Update`)\' +
            '- **After delete in BC context:** Reverse or delete the corresponding Job Journal Line');
        exit(HelpBuilder.Render());
    end;

    /// <summary>Returns the help document for <c>Clockify.TimeEntry.Sync</c>.</summary>
    /// <param name="Description">The message type description shown in the help header.</param>
    local procedure GetTimeEntrySyncHelp(Description: Text): Text
    var
        HelpBuilder: Codeunit "Clockify Help Builder ori";
    begin
        HelpBuilder.Init('Clockify.TimeEntry.Sync', Description, 'POST (BC-side)', '/internal/sync-time-entry');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Source workspace ID', 'Clockify.Workspace.List → id');
        HelpBuilder.AddParam('userId', true, 'string', 'Clockify user ID', 'Clockify.User.GetCurrent → id');
        HelpBuilder.AddParam('entryId', true, 'string', 'Clockify time entry ID to sync', 'Clockify.TimeEntry.List → id');
        HelpBuilder.AddParam('projectId', true, 'string', 'Clockify project ID (mapped to BC Job No.)', 'Clockify.Project.List → id');
        HelpBuilder.AddParam('taskId', false, 'string', 'Clockify task ID (mapped to BC Job Task No.)', 'Clockify.Task.List → id');
        HelpBuilder.AddParam('description', false, 'string', 'Work description (becomes Journal Line Description)', '');
        HelpBuilder.AddParam('start', true, 'string', 'Start time in ISO-8601 UTC', '');
        HelpBuilder.AddParam('end', true, 'string', 'End time in ISO-8601 UTC', '');
        HelpBuilder.AddParam('billable', false, 'boolean', 'Whether the time is billable', '');
        HelpBuilder.AddParam('tagIds', false, 'array', 'Clockify tag IDs. The first tag linked to a Work Type (TAG integration row) sets the Job Journal Line Work Type; otherwise the Clockify Default Work Type on Clockify Setup is used.', 'Clockify.Tag.List → id');
        HelpBuilder.AddParam('journalTemplate', false, 'string', 'BC Job Journal Template name (Code[10]). Defaults to the Clockify Job Journal Template on Clockify Setup.', '');
        HelpBuilder.AddParam('journalBatch', false, 'string', 'BC Job Journal Batch name (Code[10]). Defaults to the Clockify Job Journal Batch on Clockify Setup.', '');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "userId": "63...", "entryId": "68...", "projectId": "6a...", "taskId": "6a...", "description": "Testing", "start": "2026-06-09T12:00:00Z", "end": "2026-06-09T16:00:00Z", "billable": true, "journalTemplate": "VERK", "journalBatch": "CONTOSO" }');
        HelpBuilder.SetResponseNote('{ "result": "Created|Skipped|Updated|Corrected|Error", "message": "..." }');
        HelpBuilder.SetPreconditions('1. The Clockify project must be mapped to a BC Job (via Clockify Integration table, type=project).\' +
            '2. The Clockify task must be mapped to a BC Job Task (via Clockify Integration table, type=task).\' +
            '3. The journal template and batch must exist in BC.\' +
            '4. The Clockify user must be mapped to a BC Resource (via Clockify Integration table, type=user).');
        HelpBuilder.AddError(400, 'Missing required mapping', 'Ensure project/task/user mappings exist in Clockify Integration table');
        HelpBuilder.AddError(400, 'Journal template/batch not found', 'Verify template and batch names exist in BC');
        HelpBuilder.AddError(400, 'In-progress entry', 'Stop the timer first; `Clockify.TimeEntry.Sync` requires `end` to be set');
        HelpBuilder.SetNotes('- This is a **BC-side** operation — it does NOT call the Clockify API. It creates/updates a Job Journal Line in BC.\' +
            '- **Deduplication:** Uses `entryId` to detect if already synced. Returns `Skipped` if unchanged.\' +
            '- **Update detection:** If the entry was previously synced but Clockify data changed, returns `Updated`.\' +
            '- **Correction posting:** If the entry was already posted to a Job Ledger Entry, posts a correction (reversal + new). Returns `Corrected`.\' +
            '- **In-progress protection:** Entries with `end` = null are rejected and never written to Job Journal.\' +
            '- **Result values:** `Created` (new line), `Skipped` (already synced, unchanged), `Updated` (journal line updated), `Corrected` (posted entry corrected), `Error` (failed with message).');
        HelpBuilder.SetRelated('- **Get entries to sync:** `Clockify.TimeEntry.List` (filter by date range)\' +
            '- **Verify mappings:** `Data.Records.Get` on Clockify Integration (type=project/task/user)\' +
            '- **Set up mappings:** `Data.Records.Set` on Clockify Integration');
        exit(HelpBuilder.Render());
    end;

    /// <summary>Returns the help document for <c>Clockify.TimeEntry.SyncRange</c>.</summary>
    /// <param name="Description">The message type description shown in the help header.</param>
    local procedure GetTimeEntrySyncRangeHelp(Description: Text): Text
    var
        HelpBuilder: Codeunit "Clockify Help Builder ori";
    begin
        HelpBuilder.Init('Clockify.TimeEntry.SyncRange', Description, 'POST (BC-side)', '/internal/sync-time-entries');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Source workspace ID', 'Clockify.Workspace.List → id');
        HelpBuilder.AddParam('userId', true, 'string', 'Clockify user ID whose entries to sync', 'Clockify.User.GetCurrent → id or Clockify.User.List → id');
        HelpBuilder.AddParam('start', true, 'string', 'Range start in ISO-8601 UTC (inclusive)', '');
        HelpBuilder.AddParam('end', true, 'string', 'Range end in ISO-8601 UTC (inclusive)', '');
        HelpBuilder.AddParam('journalTemplate', false, 'string', 'BC Job Journal Template name (Code[10]). Defaults to the Clockify Job Journal Template on Clockify Setup.', '');
        HelpBuilder.AddParam('journalBatch', false, 'string', 'BC Job Journal Batch name (Code[10]). Defaults to the Clockify Job Journal Batch on Clockify Setup.', '');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "userId": "63...", "start": "2026-06-01T00:00:00Z", "end": "2026-06-30T23:59:59Z", "journalTemplate": "VERK", "journalBatch": "CONTOSO" }');
        HelpBuilder.SetResponseNote('{ "processed": 12, "created": 8, "skipped": 3, "updated": 1, "corrected": 0, "errors": 0, "results": [ { "entryId": "...", "result": "Created", "message": "..." } ] }');
        HelpBuilder.SetPreconditions('1. Each Clockify project/task/user in the range must be mapped in the Clockify Integration table.\' +
            '2. The journal template and batch must exist in BC.\' +
            '3. Only finished entries are synced — running timers (`end` = null) are excluded by the query.');
        HelpBuilder.AddError(400, 'Journal template/batch not configured', 'Set them on Clockify Setup or pass them in the request');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Clockify Setup');
        HelpBuilder.SetNotes('- Reads entries from Clockify (paged), then writes Job Journal Lines in BC — combines `Clockify.TimeEntry.List` + `Clockify.TimeEntry.Sync`.\' +
            '- Per-entry failures (e.g. a missing mapping) do NOT abort the batch; they are counted under `errors` and listed in `results`.\' +
            '- Safe to re-run: already-synced unchanged entries return `Skipped`.');
        HelpBuilder.SetRelated('- **Resolve userId:** `Clockify.User.GetCurrent` or `Clockify.User.List`\' +
            '- **Sync one entry:** `Clockify.TimeEntry.Sync`\' +
            '- **Inspect entries first:** `Clockify.TimeEntry.List`');
        exit(HelpBuilder.Render());
    end;
}
