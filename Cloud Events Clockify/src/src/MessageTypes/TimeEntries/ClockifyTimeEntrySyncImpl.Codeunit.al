namespace Origo.PTE.CloudEvents.Clockify;

using Microsoft.Projects.Project.Journal;
using Origo.APP.CloudEvents;

/// <summary>
/// Implementation of the <c>Clockify.TimeEntry.Sync</c> message type.
/// Synchronizes a single Clockify time entry to a BC Job Journal Line with
/// deduplication: skips if already synced (unchanged), updates if still in journal
/// (changed), or creates a correction if posted to ledger (changed).
/// Requires: workspaceId, userId, and either entryId (to fetch from Clockify and sync)
/// or full entry data (entryId, projectId, taskId, description, start, end, billable).
/// </summary>
codeunit 71453 "Clockify TimeEntry Sync Impl" implements "Cloud Event Msg Interface ori"
{
    Access = Internal;

    var
        JournalTemplateParamLbl: Label 'journalTemplate', Locked = true;
        JournalBatchParamLbl: Label 'journalBatch', Locked = true;
        MissingJournalErr: Label 'No Job Journal target is configured. Set the Clockify Job Journal Template and Batch on Cloud Events Setup, or pass ''journalTemplate'' and ''journalBatch'' in the request.', Locked = true;
        InProgressSyncErr: Label 'In-progress time entries are not synced to Job Journal. Provide an entry with a non-empty ''end'' value (timer stopped).', Locked = true;

    internal procedure IsEnabled(): Boolean
    var
        ClockifyIntegration: Record "Clockify Integration";
        SecretMgt: Codeunit "Clockify Secret Mgt";
    begin
        if not ClockifyIntegration.WritePermission() then
            exit(false);
        exit(SecretMgt.HasCompanyApiKey());
    end;

    internal procedure GetFilterTableNo(): Integer
    begin
        exit(0);
    end;

    internal procedure GetDescription(): Text[250]
    begin
        exit('Syncs a Clockify time entry to a BC Job Journal Line with deduplication, update detection, and correction posting.');
    end;

    internal procedure GetMessageDirection(): Enum "Cloud Event Msg Direction ori"
    begin
        exit(Enum::"Cloud Event Msg Direction ori"::Inbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "CE Message Argument ori")
    var
        HelpBuilder: Codeunit "Clockify Help Builder";
    begin
        HelpBuilder.Init('Clockify.TimeEntry.Sync', GetDescription(), 'POST (BC-side)', '/internal/sync-time-entry');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Source workspace ID', 'Clockify.Workspace.List → id');
        HelpBuilder.AddParam('userId', true, 'string', 'Clockify user ID', 'Clockify.User.GetCurrent → id');
        HelpBuilder.AddParam('entryId', true, 'string', 'Clockify time entry ID to sync', 'Clockify.TimeEntry.List → id');
        HelpBuilder.AddParam('projectId', true, 'string', 'Clockify project ID (mapped to BC Job No.)', 'Clockify.Project.List → id');
        HelpBuilder.AddParam('taskId', false, 'string', 'Clockify task ID (mapped to BC Job Task No.)', 'Clockify.Task.List → id');
        HelpBuilder.AddParam('description', false, 'string', 'Work description (becomes Journal Line Description)', '');
        HelpBuilder.AddParam('start', true, 'string', 'Start time in ISO-8601 UTC', '');
        HelpBuilder.AddParam('end', true, 'string', 'End time in ISO-8601 UTC', '');
        HelpBuilder.AddParam('billable', false, 'boolean', 'Whether the time is billable', '');
        HelpBuilder.AddParam('tagIds', false, 'array', 'Clockify tag IDs. The first tag linked to a Work Type (TAG integration row) sets the Job Journal Line Work Type; otherwise the Clockify Default Work Type on Cloud Events Setup is used.', 'Clockify.Tag.List → id');
        HelpBuilder.AddParam('journalTemplate', false, 'string', 'BC Job Journal Template name (Code[10]). Defaults to the Clockify Job Journal Template on Cloud Events Setup.', '');
        HelpBuilder.AddParam('journalBatch', false, 'string', 'BC Job Journal Batch name (Code[10]). Defaults to the Clockify Job Journal Batch on Cloud Events Setup.', '');
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
        Argument.SetResponseMarkdown(HelpBuilder.Render());
    end;

    internal procedure ExecuteCloudEventTask(var Argument: Record "CE Message Argument ori")
    var
        TimeEntrySync: Codeunit "Clockify Time Entry Sync";
        RequestMgt: Codeunit "Clockify Request Mgt";
        SetupMgt: Codeunit "Clockify Setup Mgt";
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
        WorkspaceId: Text;
        UserId: Text;
        EntryId: Text;
        ProjectId: Text;
        TaskId: Text;
        Description: Text;
        StartDateText: Text;
        EndDateText: Text;
        JournalTemplate: Code[10];
        JournalBatch: Code[10];
        PostingDate: Date;
        Hours: Decimal;
        Billable: Boolean;
        SyncResult: Enum "Clockify Sync Result";
        ResultMessage: Text;
        TagIds: List of [Text];
        JsonToken: JsonToken;
    begin
        Argument.AssertVersion1();
        RequestJson := Argument.GetRequestJson();

        if not RequestMgt.ResolveWorkspaceId(Argument, RequestJson, WorkspaceId) then
            exit;
        if not RequestMgt.RequireParam(Argument, RequestJson, 'userId', UserId) then
            exit;
        if not RequestMgt.RequireParam(Argument, RequestJson, 'entryId', EntryId) then
            exit;
        if not RequestMgt.RequireParam(Argument, RequestJson, 'projectId', ProjectId) then
            exit;

        // Optional parameters
        GetOptionalParam(RequestJson, 'taskId', TaskId);
        GetOptionalParam(RequestJson, 'description', Description);
        GetOptionalParam(RequestJson, 'start', StartDateText);
        GetOptionalParam(RequestJson, 'end', EndDateText);

        if EndDateText = '' then begin
            Argument.RespondWithError(InProgressSyncErr);
            exit;
        end;

        // Billable defaults to true
        Billable := true;
        if RequestJson.Get('billable', JsonToken) then
            if JsonToken.IsValue() then
                Billable := JsonToken.AsValue().AsBoolean();

        // Tag IDs drive the Work Type resolution in the sync engine.
        GetTagIds(RequestJson, TagIds);

        // Journal template/batch: default to the Cloud Events Setup configuration,
        // then let the request override either value. Both must resolve to non-blank.
        SetupMgt.TryGetJobJournal(JournalTemplate, JournalBatch);
        if RequestJson.Get(JournalTemplateParamLbl, JsonToken) then
            if JsonToken.IsValue() then
                JournalTemplate := CopyStr(JsonToken.AsValue().AsText(), 1, 10);
        if RequestJson.Get(JournalBatchParamLbl, JsonToken) then
            if JsonToken.IsValue() then
                JournalBatch := CopyStr(JsonToken.AsValue().AsText(), 1, 10);
        if (JournalTemplate = '') or (JournalBatch = '') then begin
            Argument.RespondWithError(MissingJournalErr);
            exit;
        end;

        // Calculate hours from start/end
        Hours := CalculateHours(StartDateText, EndDateText);
        if Hours = 0 then begin
            Argument.RespondWithError('Cannot calculate hours: start and end are required ISO 8601 datetime values.');
            exit;
        end;

        // Parse posting date from start
        PostingDate := ParseDate(StartDateText);
        if PostingDate = 0D then begin
            Argument.RespondWithError('Cannot parse posting date from start value.');
            exit;
        end;

        // Call the sync logic
        SyncResult := TimeEntrySync.SyncTimeEntry(
            JournalTemplate, JournalBatch,
            CopyStr(EntryId, 1, 50), CopyStr(WorkspaceId, 1, 50),
            CopyStr(UserId, 1, 50), CopyStr(ProjectId, 1, 50),
            CopyStr(TaskId, 1, 50),
            Description, PostingDate, Hours, Billable, TagIds,
            ResultMessage);

        // Build response
        ResponseJson.Add('result', Format(SyncResult));
        ResponseJson.Add('message', ResultMessage);
        ResponseJson.Add('entryId', EntryId);
        ResponseJson.Add('hours', Hours);
        ResponseJson.Add('postingDate', Format(PostingDate, 0, 9));
        Argument.SetResponseJson(ResponseJson);
    end;

    local procedure GetOptionalParam(RequestJson: JsonObject; ParamName: Text; var ParamValue: Text)
    var
        JsonToken: JsonToken;
    begin
        ParamValue := '';
        if RequestJson.Get(ParamName, JsonToken) then
            if JsonToken.IsValue() then
                if not JsonToken.AsValue().IsNull() then
                    ParamValue := JsonToken.AsValue().AsText();
    end;

    local procedure GetTagIds(RequestJson: JsonObject; var TagIds: List of [Text])
    var
        Token: JsonToken;
        TagToken: JsonToken;
    begin
        Clear(TagIds);
        if not RequestJson.Get('tagIds', Token) then
            exit;
        if not Token.IsArray() then
            exit;
        foreach TagToken in Token.AsArray() do
            if TagToken.IsValue() then
                if not TagToken.AsValue().IsNull() then
                    TagIds.Add(TagToken.AsValue().AsText());
    end;

    local procedure CalculateHours(StartText: Text; EndText: Text): Decimal
    var
        StartDT: DateTime;
        EndDT: DateTime;
        DurationMs: BigInteger;
    begin
        if (StartText = '') or (EndText = '') then
            exit(0);
        if not Evaluate(StartDT, StartText) then
            exit(0);
        if not Evaluate(EndDT, EndText) then
            exit(0);
        DurationMs := EndDT - StartDT;
        exit(DurationMs / 3600000);
    end;

    local procedure ParseDate(DateTimeText: Text): Date
    var
        DateTimeParsed: DateTime;
    begin
        if DateTimeText = '' then
            exit(0D);
        if not Evaluate(DateTimeParsed, DateTimeText) then
            exit(0D);
        exit(DT2Date(DateTimeParsed));
    end;
}
