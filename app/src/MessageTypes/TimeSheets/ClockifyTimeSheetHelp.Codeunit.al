namespace Origo.Bifrost.Timesheets;

using Origo.Bifrost;

/// <summary>
/// Builds the Markdown help documents for the <c>Clockify.TimeSheet.*</c> message types,
/// keeping the help text out of the individual <c>*Impl</c> codeunits.
/// </summary>
codeunit 10036838 "Clockify TimeSheet Help ori"
{
    Access = Internal;

    /// <summary>Returns the Markdown help document for one message type of this domain.</summary>
    /// <param name="MessageType">The message type to document.</param>
    /// <param name="Description">The message type description shown in the help header.</param>
    /// <returns>The rendered Markdown document, or an empty string for a message type this codeunit does not own.</returns>
    procedure GetHelp(MessageType: Enum "Message Type ori"; Description: Text): Text
    begin
        case MessageType of
            MessageType::"Clockify.TimeSheet.Create":
                exit(GetCreateHelp(Description));
            MessageType::"Clockify.TimeSheet.Approve":
                exit(GetApproveHelp(Description));
            MessageType::"Clockify.TimeSheet.Post":
                exit(GetPostHelp(Description));
            MessageType::"Clockify.TimeSheet.Archive":
                exit(GetArchiveHelp(Description));
            MessageType::"Clockify.TimeSheet.Reject":
                exit(GetRejectHelp(Description));
            MessageType::"Clockify.TimeSheet.Reopen":
                exit(GetReopenHelp(Description));
            MessageType::"Clockify.TimeEntry.SyncToTimeSheet":
                exit(GetSyncToTimeSheetHelp(Description));
            MessageType::"Clockify.TimeEntry.SyncRangeToTimeSheet":
                exit(GetSyncRangeToTimeSheetHelp(Description));
            MessageType::"Clockify.TimeEntry.SyncAllUsers":
                exit(GetSyncAllUsersHelp(Description));
        end;
        exit('');
    end;

    /// <summary>Returns the help document for <c>Clockify.TimeSheet.Create</c>.</summary>
    local procedure GetCreateHelp(Description: Text): Text
    var
        HelpBuilder: Codeunit "Clockify Help Builder ori";
    begin
        HelpBuilder.Init('Clockify.TimeSheet.Create', Description, 'POST (BC-side)', '/internal/timesheet-create');
        HelpBuilder.SetDirection(Enum::"Msg Direction ori"::Inbound);
        HelpBuilder.AddParam('weeksAhead', false, 'integer', 'Target number of upcoming sheets per resource (default 4).', '');
        HelpBuilder.SetRequestExample('{ "weeksAhead": 4 }');
        HelpBuilder.SetResponseNote('{ "status": "Success", "created": 8 }');
        HelpBuilder.SetNotes('- BC-side only; does not call Clockify.\' +
            '- Idempotent: only fills the gap up to `weeksAhead` sheets per resource.\' +
            '- Requires Resources Setup `Time Sheet Nos.` and resources with `Use Time Sheet` = true.');
        exit(HelpBuilder.Render());
    end;

    /// <summary>Returns the help document for <c>Clockify.TimeSheet.Approve</c>.</summary>
    local procedure GetApproveHelp(Description: Text): Text
    var
        HelpBuilder: Codeunit "Clockify Help Builder ori";
    begin
        HelpBuilder.Init('Clockify.TimeSheet.Approve', Description, 'POST (BC-side)', '/internal/timesheet-approve');
        HelpBuilder.SetDirection(Enum::"Msg Direction ori"::Inbound);
        HelpBuilder.AddParam('endingDateTo', false, 'string', 'Only approve sheets ending on or before this ISO date (YYYY-MM-DD). Defaults to the work date.', '');
        HelpBuilder.SetRequestExample('{ "endingDateTo": "2026-06-30" }');
        HelpBuilder.SetResponseNote('{ "status": "Success", "approvedLines": 24 }');
        HelpBuilder.SetNotes('- Runs the time-sheet approval engine (Submit + Approve) per line — not a Status field write.\' +
            '- BC-side only; does not call Clockify.');
        exit(HelpBuilder.Render());
    end;

    /// <summary>Returns the help document for <c>Clockify.TimeSheet.Post</c>.</summary>
    local procedure GetPostHelp(Description: Text): Text
    var
        HelpBuilder: Codeunit "Clockify Help Builder ori";
    begin
        HelpBuilder.Init('Clockify.TimeSheet.Post', Description, 'POST (BC-side)', '/internal/timesheet-post');
        HelpBuilder.SetDirection(Enum::"Msg Direction ori"::Inbound);
        HelpBuilder.AddParam('journalTemplate', false, 'string', 'Job Journal Template name (Code[10]). Defaults to the Clockify Job Journal Template on Clockify Setup.', '');
        HelpBuilder.AddParam('journalBatch', false, 'string', 'Job Journal Batch name (Code[10]). Defaults to the Clockify Job Journal Batch on Clockify Setup.', '');
        HelpBuilder.SetRequestExample('{ "journalTemplate": "VERK", "journalBatch": "CONTOSO" }');
        HelpBuilder.SetResponseNote('{ "status": "Success", "postedLines": 24 }');
        HelpBuilder.SetNotes('- Posts approved time-sheet detail to the Job Journal via `Job Jnl.-Post Line`.\' +
            '- BC-side only; does not call Clockify.\' +
            '- Only lines with `Type = Job`, `Status = Approved`, and not yet posted are included.');
        exit(HelpBuilder.Render());
    end;

    /// <summary>Returns the help document for <c>Clockify.TimeSheet.Archive</c>.</summary>
    local procedure GetArchiveHelp(Description: Text): Text
    var
        HelpBuilder: Codeunit "Clockify Help Builder ori";
    begin
        HelpBuilder.Init('Clockify.TimeSheet.Archive', Description, 'POST (BC-side)', '/internal/timesheet-archive');
        HelpBuilder.SetDirection(Enum::"Msg Direction ori"::Inbound);
        HelpBuilder.SetRequestExample('{ }');
        HelpBuilder.SetResponseNote('{ "status": "Success", "archived": 6 }');
        HelpBuilder.SetNotes('- Moves fully posted, non-open sheets to the archive; deletes empty posted sheets.\' +
            '- BC-side only; does not call Clockify.');
        exit(HelpBuilder.Render());
    end;

    /// <summary>Returns the help document for <c>Clockify.TimeSheet.Reject</c>.</summary>
    local procedure GetRejectHelp(Description: Text): Text
    var
        HelpBuilder: Codeunit "Clockify Help Builder ori";
    begin
        HelpBuilder.Init('Clockify.TimeSheet.Reject', Description, 'POST (BC-side)', '/internal/timesheet-reject');
        HelpBuilder.SetDirection(Enum::"Msg Direction ori"::Inbound);
        HelpBuilder.AddParam('endingDateTo', false, 'string', 'Only reject sheets ending on or before this ISO date (YYYY-MM-DD). Defaults to the work date.', '');
        HelpBuilder.SetRequestExample('{ "endingDateTo": "2026-06-30" }');
        HelpBuilder.SetResponseNote('{ "status": "Success", "rejectedLines": 3 }');
        HelpBuilder.SetNotes('- Runs the time-sheet approval engine (Reject) on submitted lines — not a Status field write.\' +
            '- BC-side only; does not call Clockify.');
        exit(HelpBuilder.Render());
    end;

    /// <summary>Returns the help document for <c>Clockify.TimeSheet.Reopen</c>.</summary>
    local procedure GetReopenHelp(Description: Text): Text
    var
        HelpBuilder: Codeunit "Clockify Help Builder ori";
    begin
        HelpBuilder.Init('Clockify.TimeSheet.Reopen', Description, 'POST (BC-side)', '/internal/timesheet-reopen');
        HelpBuilder.SetDirection(Enum::"Msg Direction ori"::Inbound);
        HelpBuilder.AddParam('endingDateTo', false, 'string', 'Only reopen sheets ending on or before this ISO date (YYYY-MM-DD). Defaults to the work date.', '');
        HelpBuilder.SetRequestExample('{ "endingDateTo": "2026-06-30" }');
        HelpBuilder.SetResponseNote('{ "status": "Success", "reopenedLines": 3 }');
        HelpBuilder.SetNotes('- Reopens submitted lines to Open and approved lines back through Submitted to Open.\' +
            '- BC-side only; does not call Clockify.');
        exit(HelpBuilder.Render());
    end;

    /// <summary>Returns the help document for <c>Clockify.TimeEntry.SyncToTimeSheet</c>.</summary>
    local procedure GetSyncToTimeSheetHelp(Description: Text): Text
    var
        HelpBuilder: Codeunit "Clockify Help Builder ori";
    begin
        HelpBuilder.Init('Clockify.TimeEntry.SyncToTimeSheet', Description, 'POST (BC-side)', '/internal/sync-time-entry-timesheet');
        HelpBuilder.SetDirection(Enum::"Msg Direction ori"::Inbound);
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Source workspace ID', 'Clockify.Workspace.List → id');
        HelpBuilder.AddParam('userId', true, 'string', 'Clockify user ID (mapped to a BC Resource)', 'Clockify.User.GetCurrent → id');
        HelpBuilder.AddParam('entryId', true, 'string', 'Clockify time entry ID', 'Clockify.TimeEntry.List → id');
        HelpBuilder.AddParam('projectId', true, 'string', 'Clockify project ID (mapped to BC Job No.)', 'Clockify.Project.List → id');
        HelpBuilder.AddParam('taskId', true, 'string', 'Clockify task ID (mapped to BC Job Task No.)', 'Clockify.Task.List → id');
        HelpBuilder.AddParam('description', false, 'string', 'Work description (becomes the time-sheet line description)', '');
        HelpBuilder.AddParam('start', true, 'string', 'Start time in ISO-8601 UTC', '');
        HelpBuilder.AddParam('end', true, 'string', 'End time in ISO-8601 UTC', '');
        HelpBuilder.AddParam('billable', false, 'boolean', 'Whether the time is billable', '');
        HelpBuilder.AddParam('tagIds', false, 'array', 'Clockify tag IDs used to resolve the Work Type', 'Clockify.Tag.List → id');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "userId": "63...", "entryId": "68...", "projectId": "6a...", "taskId": "6a...", "description": "Consulting", "start": "2026-06-09T08:00:00Z", "end": "2026-06-09T10:00:00Z", "billable": true, "tagIds": [ "62..." ] }');
        HelpBuilder.SetResponseNote('{ "result": "Created|Updated|Skipped|Error", "message": "...", "entryId": "...", "hours": 4, "postingDate": "2026-06-09" }');
        HelpBuilder.SetPreconditions('1. The Clockify project/task/user must be mapped in the Clockify Integration table.\' +
            '2. The resource must have an **open time sheet covering the entry date** — run `Clockify.TimeSheet.Create` first.');
        HelpBuilder.AddError(400, 'Missing mapping', 'Ensure project/task/user mappings exist in the Clockify Integration table');
        HelpBuilder.AddError(400, 'No open time sheet', 'Run `Clockify.TimeSheet.Create`, then retry');
        HelpBuilder.SetNotes('- Writes to a **BC Time Sheet** (line + detail), not the Job Journal.\' +
            '- Deduplicated by `entryId`: re-running returns `Skipped` when unchanged, `Updated` when hours/date changed.\' +
            '- After approval, post the sheet with `Clockify.TimeSheet.Post`.');
        HelpBuilder.SetRelated('- **Populate sheets:** `Clockify.TimeSheet.Create`\' +
            '- **Approve/post:** `Clockify.TimeSheet.Approve` → `Clockify.TimeSheet.Post`\' +
            '- **Journal-direct alternative:** `Clockify.TimeEntry.Sync`');
        exit(HelpBuilder.Render());
    end;

    /// <summary>Returns the help document for <c>Clockify.TimeEntry.SyncRangeToTimeSheet</c>.</summary>
    local procedure GetSyncRangeToTimeSheetHelp(Description: Text): Text
    var
        HelpBuilder: Codeunit "Clockify Help Builder ori";
    begin
        HelpBuilder.Init('Clockify.TimeEntry.SyncRangeToTimeSheet', Description, 'POST (BC-side)', '/internal/sync-time-entries-timesheet');
        HelpBuilder.SetDirection(Enum::"Msg Direction ori"::Inbound);
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Source workspace ID', 'Clockify.Workspace.List → id');
        HelpBuilder.AddParam('userId', true, 'string', 'Clockify user ID whose entries to sync', 'Clockify.User.GetCurrent → id');
        HelpBuilder.AddParam('start', true, 'string', 'Range start in ISO-8601 UTC (inclusive)', '');
        HelpBuilder.AddParam('end', true, 'string', 'Range end in ISO-8601 UTC (inclusive)', '');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "userId": "63...", "start": "2026-06-01T00:00:00Z", "end": "2026-06-30T23:59:59Z" }');
        HelpBuilder.SetResponseNote('{ "processed": 12, "created": 8, "skipped": 3, "updated": 1, "errors": 0, "results": [ ... ] }');
        HelpBuilder.SetPreconditions('1. Project/task/user mappings must exist in the Clockify Integration table.\' +
            '2. Each entry date must fall within an **open time sheet** for the resource — run `Clockify.TimeSheet.Create` first.\' +
            '3. Only finished entries are synced (running timers are excluded).');
        HelpBuilder.SetNotes('- Reads entries from Clockify (paged), then writes **BC Time Sheets** — combines `Clockify.TimeEntry.List` + `Clockify.TimeEntry.SyncToTimeSheet`.\' +
            '- Per-entry failures (missing mapping, no open sheet) are counted under `errors` and do not abort the batch.\' +
            '- Safe to re-run: unchanged entries return `Skipped`.');
        HelpBuilder.SetRelated('- **Populate sheets:** `Clockify.TimeSheet.Create`\' +
            '- **Approve/post:** `Clockify.TimeSheet.Approve` → `Clockify.TimeSheet.Post`\' +
            '- **Journal-direct alternative:** `Clockify.TimeEntry.SyncRange`');
        exit(HelpBuilder.Render());
    end;

    /// <summary>Returns the help document for <c>Clockify.TimeEntry.SyncAllUsers</c>.</summary>
    local procedure GetSyncAllUsersHelp(Description: Text): Text
    var
        HelpBuilder: Codeunit "Clockify Help Builder ori";
    begin
        HelpBuilder.Init('Clockify.TimeEntry.SyncAllUsers', Description, 'POST (BC-side)', '/internal/sync-all-users');
        HelpBuilder.SetDirection(Enum::"Msg Direction ori"::Inbound);
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Source workspace ID', 'Clockify.Workspace.List → id');
        HelpBuilder.AddParam('start', true, 'string', 'Range start in ISO-8601 UTC (inclusive)', '');
        HelpBuilder.AddParam('end', true, 'string', 'Range end in ISO-8601 UTC (inclusive)', '');
        HelpBuilder.AddParam('target', false, 'string', '''timesheet'' (default) writes BC Time Sheets; ''journal'' writes Job Journal lines.', '');
        HelpBuilder.AddParam('journalTemplate', false, 'string', 'Job Journal Template (Code[10]) — used when target=journal. Defaults to Clockify Setup.', '');
        HelpBuilder.AddParam('journalBatch', false, 'string', 'Job Journal Batch (Code[10]) — used when target=journal. Defaults to Clockify Setup.', '');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "start": "2026-06-01T00:00:00Z", "end": "2026-06-30T23:59:59Z", "target": "timesheet" }');
        HelpBuilder.SetResponseNote('{ "target": "timesheet", "users": 5, "created": 40, "skipped": 3, "updated": 2, "errors": 1, "userResults": [ { "userId": "63...", "processed": 9, "created": 8, ... } ] }');
        HelpBuilder.SetPreconditions('1. Each Clockify user must be mapped to a BC Resource (USER integration row).\' +
            '2. For target=timesheet, each entry date needs an open time sheet — run `Clockify.TimeSheet.Create` first.\' +
            '3. Project/task mappings must exist.');
        HelpBuilder.SetNotes('- Restores the legacy per-user auto-discovery: iterates every USER mapping, no need to pass `userId`.\' +
            '- Per-user and per-entry failures are counted and reported; they never abort the batch.\' +
            '- Safe to re-run: unchanged entries return `Skipped`.');
        HelpBuilder.SetRelated('- **Single user, time sheet:** `Clockify.TimeEntry.SyncRangeToTimeSheet`\' +
            '- **Single user, journal:** `Clockify.TimeEntry.SyncRange`\' +
            '- **Seed sheets:** `Clockify.TimeSheet.Create`');
        exit(HelpBuilder.Render());
    end;
}
