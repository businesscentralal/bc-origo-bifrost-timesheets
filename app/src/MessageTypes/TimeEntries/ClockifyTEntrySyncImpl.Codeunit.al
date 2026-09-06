namespace Origo.Bifrost.Clockify;

using Microsoft.Projects.Project.Journal;
using Origo.Bifrost;

/// <summary>
/// Implementation of the <c>Clockify.TimeEntry.Sync</c> message type.
/// Synchronizes a single Clockify time entry to a BC Job Journal Line with
/// deduplication: skips if already synced (unchanged), updates if still in journal
/// (changed), or creates a correction if posted to ledger (changed).
/// Requires: workspaceId, userId, and either entryId (to fetch from Clockify and sync)
/// or full entry data (entryId, projectId, taskId, description, start, end, billable).
/// </summary>
codeunit 70009236 "Clockify TEntrySync Impl ori" implements "Msg Interface ori"
{
    Access = Internal;

    var
        JournalTemplateParamLbl: Label 'journalTemplate', Locked = true;
        JournalBatchParamLbl: Label 'journalBatch', Locked = true;
        MissingJournalErr: Label 'No Job Journal target is configured. Set the Clockify Job Journal Template and Batch on Clockify Setup, or pass ''journalTemplate'' and ''journalBatch'' in the request.', Locked = true;
        InProgressSyncErr: Label 'In-progress time entries are not synced to Job Journal. Provide an entry with a non-empty ''end'' value (timer stopped).', Locked = true;

    internal procedure IsEnabled(): Boolean
    var
        ClockifyIntegration: Record "Clockify Integration ori";
        SecretMgt: Codeunit "Clockify Secret Mgt ori";
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

    internal procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit(Enum::"Msg Direction ori"::Inbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "Message Argument ori")
    var
        Help: Codeunit "Clockify TimeEntry Help ori";
    begin
        Argument.SetResponseMarkdown(Help.GetHelp(Enum::"Message Type ori"::"Clockify.TimeEntry.Sync", GetDescription()));
    end;

    internal procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    var
        TimeEntrySync: Codeunit "Clockify Time Entry Sync ori";
        RequestMgt: Codeunit "Clockify Request Mgt ori";
        SetupMgt: Codeunit "Clockify Setup Mgt ori";
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
        SyncResult: Enum "Clockify Sync Result ori";
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

        // Journal template/batch: default to the Clockify Setup configuration,
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
