namespace Origo.Bifrost.Timesheets.Providers.Clockify;

using Origo.Bifrost;

/// <summary>
/// Implementation of the <c>Timesheets.JobJournal.SyncRangeFromClockify</c> message type.
/// Pulls every finished time entry for one Clockify user within a date range and
/// syncs each to a BC Job Journal Line through the shared sync engine (with the
/// same deduplication, update detection and correction behaviour as
/// <c>Timesheets.JobJournal.SyncFromClockify</c>). This is the single automatable entry point a
/// Job Queue or message chain needs — the per-entry <c>Timesheets.JobJournal.SyncFromClockify</c>
/// requires the caller to supply and loop over each entry itself.
/// </summary>
codeunit 10036832 "Clockify TEntryRange Impl ori" implements "Msg Interface ori"
{
    Access = Internal;

    var
        JournalTemplateParamLbl: Label 'journalTemplate', Locked = true;
        JournalBatchParamLbl: Label 'journalBatch', Locked = true;
        MissingJournalErr: Label 'No Job Journal target is configured. Set the Clockify Job Journal Template and Batch on Clockify Setup, or pass ''journalTemplate'' and ''journalBatch'' in the request.', Locked = true;
        ListFailedErr: Label 'Failed to read time entries from Clockify (HTTP %1): %2', Comment = '%1 = status code, %2 = error body', Locked = true;
        NoFinishedIntervalMsg: Label 'Entry has no finished interval; counted as error.', Locked = true;

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
        exit('Syncs all of a user''s finished Clockify time entries in a date range to BC Job Journal Lines in a single call.');
    end;

    internal procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit(Enum::"Msg Direction ori"::Inbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "Message Argument ori")
    var
        Help: Codeunit "Clockify TimeEntry Help ori";
    begin
        Argument.SetResponseMarkdown(Help.GetHelp(Enum::"Message Type ori"::"Timesheets.JobJournal.SyncRangeFromClockify", GetDescription()));
    end;

    internal procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    var
        TimeEntrySync: Codeunit "Clockify Time Entry Sync ori";
        RequestMgt: Codeunit "Clockify Request Mgt ori";
        SetupMgt: Codeunit "Clockify Setup Mgt ori";
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
    local procedure FetchEntries(var Argument: Record "Message Argument ori"; WorkspaceId: Text; UserId: Text; StartText: Text; EndText: Text; var Entries: JsonArray): Boolean
    var
        RequestMgt: Codeunit "Clockify Request Mgt ori";
        ApiClient: Interface "Clockify API Client ori";
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

    local procedure SyncEntries(var TimeEntrySync: Codeunit "Clockify Time Entry Sync ori"; JournalTemplate: Code[10]; JournalBatch: Code[10]; WorkspaceId: Text; UserId: Text; Entries: JsonArray; var Results: JsonArray; var Counts: Dictionary of [Text, Integer])
    var
        ParseHelper: Codeunit "Clockify TimeEntry Parse ori";
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
        SyncResult: Enum "Clockify Sync Result ori";
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
                ResultMessage := NoFinishedIntervalMsg;
            end else
                SyncResult := TimeEntrySync.SyncTimeEntry(
                    JournalTemplate, JournalBatch,
                    CopyStr(EntryId, 1, 50), CopyStr(WorkspaceId, 1, 50),
                    CopyStr(UserId, 1, 50), CopyStr(ProjectId, 1, 50),
                    CopyStr(TaskId, 1, 50),
                    Description, PostingDate, Hours, Billable, TagIds,
                    ResultMessage);

            ResultText := ParseHelper.SyncResultName(SyncResult);
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
        if not Evaluate(StartDT, StartText, 9) then
            exit(0);
        if not Evaluate(EndDT, EndText, 9) then
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
        if not Evaluate(DateTimeParsed, DateTimeText, 9) then
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
