namespace Origo.PTE.CloudEvents.Clockify;

using Origo.APP.CloudEvents;

/// <summary>
/// Implementation of the <c>Clockify.TimeEntry.SyncRange</c> message type.
/// Pulls every finished time entry for one Clockify user within a date range and
/// syncs each to a BC Job Journal Line through the shared sync engine (with the
/// same deduplication, update detection and correction behaviour as
/// <c>Clockify.TimeEntry.Sync</c>). This is the single automatable entry point a
/// Job Queue or message chain needs — the per-entry <c>Clockify.TimeEntry.Sync</c>
/// requires the caller to supply and loop over each entry itself.
/// </summary>
codeunit 70009247 "Clockify TimeEntrySyncRng Impl" implements "Cloud Event Msg Interface ori"
{
    Access = Internal;

    var
        JournalTemplateParamLbl: Label 'journalTemplate', Locked = true;
        JournalBatchParamLbl: Label 'journalBatch', Locked = true;
        MissingJournalErr: Label 'No Job Journal target is configured. Set the Clockify Job Journal Template and Batch on Cloud Events Setup, or pass ''journalTemplate'' and ''journalBatch'' in the request.', Locked = true;
        ListFailedErr: Label 'Failed to read time entries from Clockify (HTTP %1): %2', Comment = '%1 = status code, %2 = error body', Locked = true;

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
        exit('Syncs all of a user''s finished Clockify time entries in a date range to BC Job Journal Lines in a single call.');
    end;

    internal procedure GetMessageDirection(): Enum "Cloud Event Msg Direction ori"
    begin
        exit(Enum::"Cloud Event Msg Direction ori"::Inbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "CE Message Argument ori")
    var
        HelpBuilder: Codeunit "Clockify Help Builder";
    begin
        HelpBuilder.Init('Clockify.TimeEntry.SyncRange', GetDescription(), 'POST (BC-side)', '/internal/sync-time-entries');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Source workspace ID', 'Clockify.Workspace.List → id');
        HelpBuilder.AddParam('userId', true, 'string', 'Clockify user ID whose entries to sync', 'Clockify.User.GetCurrent → id or Clockify.User.List → id');
        HelpBuilder.AddParam('start', true, 'string', 'Range start in ISO-8601 UTC (inclusive)', '');
        HelpBuilder.AddParam('end', true, 'string', 'Range end in ISO-8601 UTC (inclusive)', '');
        HelpBuilder.AddParam('journalTemplate', false, 'string', 'BC Job Journal Template name (Code[10]). Defaults to the Clockify Job Journal Template on Cloud Events Setup.', '');
        HelpBuilder.AddParam('journalBatch', false, 'string', 'BC Job Journal Batch name (Code[10]). Defaults to the Clockify Job Journal Batch on Cloud Events Setup.', '');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "userId": "63...", "start": "2026-06-01T00:00:00Z", "end": "2026-06-30T23:59:59Z", "journalTemplate": "VERK", "journalBatch": "CONTOSO" }');
        HelpBuilder.SetResponseNote('{ "processed": 12, "created": 8, "skipped": 3, "updated": 1, "corrected": 0, "errors": 0, "results": [ { "entryId": "...", "result": "Created", "message": "..." } ] }');
        HelpBuilder.SetPreconditions('1. Each Clockify project/task/user in the range must be mapped in the Clockify Integration table.\' +
            '2. The journal template and batch must exist in BC.\' +
            '3. Only finished entries are synced — running timers (`end` = null) are excluded by the query.');
        HelpBuilder.AddError(400, 'Journal template/batch not configured', 'Set them on Cloud Events Setup or pass them in the request');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Cloud Events Setup');
        HelpBuilder.SetNotes('- Reads entries from Clockify (paged), then writes Job Journal Lines in BC — combines `Clockify.TimeEntry.List` + `Clockify.TimeEntry.Sync`.\' +
            '- Per-entry failures (e.g. a missing mapping) do NOT abort the batch; they are counted under `errors` and listed in `results`.\' +
            '- Safe to re-run: already-synced unchanged entries return `Skipped`.');
        HelpBuilder.SetRelated('- **Resolve userId:** `Clockify.User.GetCurrent` or `Clockify.User.List`\' +
            '- **Sync one entry:** `Clockify.TimeEntry.Sync`\' +
            '- **Inspect entries first:** `Clockify.TimeEntry.List`');
        Argument.SetResponseMarkdown(HelpBuilder.Render());
    end;

    internal procedure ExecuteCloudEventTask(var Argument: Record "CE Message Argument ori")
    var
        TimeEntrySync: Codeunit "Clockify Time Entry Sync";
        RequestMgt: Codeunit "Clockify Request Mgt";
        SetupMgt: Codeunit "Clockify Setup Mgt";
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
        Results: JsonArray;
        Entries: JsonArray;
        WorkspaceId: Text;
        UserId: Text;
        StartText: Text;
        EndText: Text;
        JournalTemplate: Code[10];
        JournalBatch: Code[10];
        JsonToken: JsonToken;
        Counts: Dictionary of [Text, Integer];
    begin
        Argument.AssertVersion1();
        RequestJson := Argument.GetRequestJson();

        if not RequestMgt.ResolveWorkspaceId(Argument, RequestJson, WorkspaceId) then
            exit;
        if not RequestMgt.RequireParam(Argument, RequestJson, 'userId', UserId) then
            exit;
        if not RequestMgt.RequireParam(Argument, RequestJson, 'start', StartText) then
            exit;
        if not RequestMgt.RequireParam(Argument, RequestJson, 'end', EndText) then
            exit;

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

        if not FetchEntries(Argument, WorkspaceId, UserId, StartText, EndText, Entries) then
            exit;

        SyncEntries(TimeEntrySync, JournalTemplate, JournalBatch, WorkspaceId, UserId, Entries, Results, Counts);

        ResponseJson.Add('processed', Results.Count());
        ResponseJson.Add('created', GetCount(Counts, 'Created'));
        ResponseJson.Add('skipped', GetCount(Counts, 'Skipped'));
        ResponseJson.Add('updated', GetCount(Counts, 'Updated'));
        ResponseJson.Add('corrected', GetCount(Counts, 'Corrected'));
        ResponseJson.Add('errors', GetCount(Counts, 'Error'));
        ResponseJson.Add('results', Results);
        Argument.SetResponseJson(ResponseJson);
    end;

    /// <summary>Reads every finished entry for the user/range from Clockify, following pages.</summary>
    local procedure FetchEntries(var Argument: Record "CE Message Argument ori"; WorkspaceId: Text; UserId: Text; StartText: Text; EndText: Text; var Entries: JsonArray): Boolean
    var
        RequestMgt: Codeunit "Clockify Request Mgt";
        ApiClient: Interface "Clockify API Client";
        PageArray: JsonArray;
        PageToken: JsonToken;
        EntryToken: JsonToken;
        ResourcePath: Text;
        ResponseBody: Text;
        StatusCode: Integer;
        PageNo: Integer;
        PageSize: Integer;
    begin
        Clear(Entries);
        PageSize := 200;
        ApiClient := RequestMgt.GetApiClient();
        PageNo := 0;
        repeat
            PageNo += 1;
            ResourcePath :=
                '/workspaces/' + WorkspaceId + '/user/' + UserId + '/time-entries' +
                '?start=' + UrlEncode(StartText) +
                '&end=' + UrlEncode(EndText) +
                '&in-progress=false' +
                '&page-size=' + Format(PageSize, 0, 9) +
                '&page=' + Format(PageNo, 0, 9);
            if not ApiClient.Send('GET', ResourcePath, false, '', ResponseBody, StatusCode) then begin
                Argument.RespondWithError(StrSubstNo(ListFailedErr, StatusCode, ResponseBody));
                exit(false);
            end;
            Clear(PageArray);
            if ResponseBody <> '' then begin
                if not PageToken.ReadFrom(ResponseBody) or not PageToken.IsArray() then begin
                    Argument.RespondWithError('Unexpected response from Clockify when listing time entries: expected a JSON array.');
                    exit(false);
                end;
                PageArray := PageToken.AsArray();
            end;
            foreach EntryToken in PageArray do
                Entries.Add(EntryToken);
        until PageArray.Count() < PageSize;
        exit(true);
    end;

    local procedure SyncEntries(var TimeEntrySync: Codeunit "Clockify Time Entry Sync"; JournalTemplate: Code[10]; JournalBatch: Code[10]; WorkspaceId: Text; UserId: Text; Entries: JsonArray; var Results: JsonArray; var Counts: Dictionary of [Text, Integer])
    var
        EntryToken: JsonToken;
        EntryObject: JsonObject;
        ResultObject: JsonObject;
        EntryId: Text;
        ProjectId: Text;
        TaskId: Text;
        Description: Text;
        EntryStart: Text;
        EntryEnd: Text;
        Billable: Boolean;
        Hours: Decimal;
        PostingDate: Date;
        TagIds: List of [Text];
        SyncResult: Enum "Clockify Sync Result";
        ResultMessage: Text;
        ResultText: Text;
    begin
        foreach EntryToken in Entries do begin
            EntryObject := EntryToken.AsObject();
            EntryId := GetText(EntryObject, 'id');
            ProjectId := GetText(EntryObject, 'projectId');
            TaskId := GetText(EntryObject, 'taskId');
            Description := GetText(EntryObject, 'description');
            GetInterval(EntryObject, EntryStart, EntryEnd);
            Billable := GetBoolean(EntryObject, 'billable', true);
            GetTagIds(EntryObject, TagIds);

            Hours := CalculateHours(EntryStart, EntryEnd);
            PostingDate := ParseDate(EntryStart);

            if (EntryEnd = '') or (Hours = 0) or (PostingDate = 0D) then begin
                SyncResult := SyncResult::Error;
                ResultMessage := 'Entry has no finished interval; skipped.';
            end else
                SyncResult := TimeEntrySync.SyncTimeEntry(
                    JournalTemplate, JournalBatch,
                    CopyStr(EntryId, 1, 50), CopyStr(WorkspaceId, 1, 50),
                    CopyStr(UserId, 1, 50), CopyStr(ProjectId, 1, 50),
                    CopyStr(TaskId, 1, 50),
                    Description, PostingDate, Hours, Billable, TagIds,
                    ResultMessage);

            ResultText := Format(SyncResult);
            IncrementCount(Counts, ResultText);

            Clear(ResultObject);
            ResultObject.Add('entryId', EntryId);
            ResultObject.Add('result', ResultText);
            ResultObject.Add('message', ResultMessage);
            Results.Add(ResultObject);
        end;
    end;

    local procedure GetInterval(EntryObject: JsonObject; var StartText: Text; var EndText: Text)
    var
        Token: JsonToken;
        IntervalObject: JsonObject;
    begin
        StartText := '';
        EndText := '';
        if not EntryObject.Get('timeInterval', Token) then
            exit;
        if not Token.IsObject() then
            exit;
        IntervalObject := Token.AsObject();
        StartText := GetText(IntervalObject, 'start');
        EndText := GetText(IntervalObject, 'end');
    end;

    local procedure GetTagIds(EntryObject: JsonObject; var TagIds: List of [Text])
    var
        Token: JsonToken;
        TagToken: JsonToken;
    begin
        Clear(TagIds);
        if not EntryObject.Get('tagIds', Token) then
            exit;
        if not Token.IsArray() then
            exit;
        foreach TagToken in Token.AsArray() do
            if TagToken.IsValue() then
                if not TagToken.AsValue().IsNull() then
                    TagIds.Add(TagToken.AsValue().AsText());
    end;

    local procedure GetText(JsonObject: JsonObject; PropertyName: Text): Text
    var
        Token: JsonToken;
    begin
        if not JsonObject.Get(PropertyName, Token) then
            exit('');
        if not Token.IsValue() then
            exit('');
        if Token.AsValue().IsNull() then
            exit('');
        exit(Token.AsValue().AsText());
    end;

    local procedure GetBoolean(JsonObject: JsonObject; PropertyName: Text; DefaultValue: Boolean): Boolean
    var
        Token: JsonToken;
    begin
        if not JsonObject.Get(PropertyName, Token) then
            exit(DefaultValue);
        if not Token.IsValue() then
            exit(DefaultValue);
        if Token.AsValue().IsNull() then
            exit(DefaultValue);
        exit(Token.AsValue().AsBoolean());
    end;

    local procedure IncrementCount(var Counts: Dictionary of [Text, Integer]; ResultKey: Text)
    var
        Current: Integer;
    begin
        if Counts.Get(ResultKey, Current) then
            Counts.Set(ResultKey, Current + 1)
        else
            Counts.Add(ResultKey, 1);
    end;

    local procedure GetCount(Counts: Dictionary of [Text, Integer]; ResultKey: Text): Integer
    var
        Current: Integer;
    begin
        if Counts.Get(ResultKey, Current) then
            exit(Current);
        exit(0);
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

    local procedure UrlEncode(Value: Text): Text
    var
        TypeHelper: Codeunit System.Reflection."Type Helper";
    begin
        exit(TypeHelper.UrlEncode(Value));
    end;
}
