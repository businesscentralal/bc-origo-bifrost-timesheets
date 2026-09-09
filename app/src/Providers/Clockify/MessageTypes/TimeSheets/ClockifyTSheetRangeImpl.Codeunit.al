namespace Origo.Bifrost.Timesheets.Providers.Clockify;

using Origo.Bifrost;

/// <summary>
/// Implementation of the <c>Timesheets.TimeSheet.SyncRangeFromClockify</c> message type. Pulls
/// every finished time entry for one Clockify user in a date range and writes each to the
/// resource's open BC Time Sheet in a single call. BC-side operation (reads Clockify, then
/// writes time sheets).
/// </summary>
codeunit 10036841 "Clockify TSheetRange Impl ori" implements "Msg Interface ori"
{
    Access = Internal;

    var
        ListFailedErr: Label 'Failed to read time entries from Clockify (HTTP %1): %2', Comment = '%1 = status code, %2 = error body', Locked = true;
        NoFinishedIntervalMsg: Label 'Entry has no finished interval; counted as error.', Locked = true;

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
        exit('Syncs all of a user''s finished Clockify time entries in a date range to their open BC Time Sheets in one call.');
    end;

    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit(Enum::"Msg Direction ori"::Inbound);
    end;

    procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "Message Argument ori")
    var
        Help: Codeunit "Clockify TimeSheet Help ori";
    begin
        Argument.SetResponseMarkdown(Help.GetHelp(Enum::"Message Type ori"::"Timesheets.TimeSheet.SyncRangeFromClockify", GetDescription()));
    end;

    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    var
        RequestMgt: Codeunit "Clockify Request Mgt ori";
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
        Results: JsonArray;
        Entries: JsonArray;
        WorkspaceId: Text;
        UserId: Text;
        StartText: Text;
        EndText: Text;
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

        if not FetchEntries(Argument, WorkspaceId, UserId, StartText, EndText, Entries) then
            exit;

        SyncEntries(WorkspaceId, UserId, Entries, Results, Counts);

        ResponseJson.Add('processed', Results.Count());
        ResponseJson.Add('created', GetCount(Counts, 'Created'));
        ResponseJson.Add('skipped', GetCount(Counts, 'Skipped'));
        ResponseJson.Add('updated', GetCount(Counts, 'Updated'));
        ResponseJson.Add('errors', GetCount(Counts, 'Error'));
        ResponseJson.Add('results', Results);
        Argument.SetResponseJson(ResponseJson);
    end;

    local procedure FetchEntries(var Argument: Record "Message Argument ori"; WorkspaceId: Text; UserId: Text; StartText: Text; EndText: Text; var Entries: JsonArray): Boolean
    var
        RequestMgt: Codeunit "Clockify Request Mgt ori";
        TypeHelper: Codeunit System.Reflection."Type Helper";
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
                '?start=' + TypeHelper.UrlEncode(StartText) +
                '&end=' + TypeHelper.UrlEncode(EndText) +
                '&in-progress=false' +
                '&page-size=' + Format(PageSize, 0, 9) +
                '&page=' + Format(PageNo, 0, 9);
            if not ApiClient.Send('GET', ResourcePath, false, '', ResponseBody, StatusCode) then begin
                Argument.RespondWithError(StrSubstNo(ListFailedErr, StatusCode, ResponseBody));
                exit(false);
            end;
            Clear(PageArray);
            if (ResponseBody <> '') and PageToken.ReadFrom(ResponseBody) and PageToken.IsArray() then
                PageArray := PageToken.AsArray();
            foreach EntryToken in PageArray do
                Entries.Add(EntryToken);
        until PageArray.Count() < PageSize;
        exit(true);
    end;

    local procedure SyncEntries(WorkspaceId: Text; UserId: Text; Entries: JsonArray; var Results: JsonArray; var Counts: Dictionary of [Text, Integer])
    var
        TimeSheetSync: Codeunit "Clockify TimeSheet Sync ori";
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
            EntryId := ParseHelper.GetText(EntryObject, 'id');
            ProjectId := ParseHelper.GetText(EntryObject, 'projectId');
            TaskId := ParseHelper.GetText(EntryObject, 'taskId');
            Description := ParseHelper.GetText(EntryObject, 'description');
            GetInterval(EntryObject, EntryStart, EntryEnd);
            Billable := ParseHelper.GetBoolean(EntryObject, 'billable', true);
            ParseHelper.GetTagIds(EntryObject, TagIds);

            Hours := ParseHelper.CalculateHours(EntryStart, EntryEnd);
            PostingDate := ParseHelper.ParseDate(EntryStart);

            if (EntryEnd = '') or (Hours = 0) or (PostingDate = 0D) then begin
                SyncResult := SyncResult::Error;
                ResultMessage := NoFinishedIntervalMsg;
            end else
                SyncResult := TimeSheetSync.SyncTimeEntryToTimeSheet(
                    CopyStr(EntryId, 1, 50), CopyStr(WorkspaceId, 1, 50), CopyStr(UserId, 1, 50),
                    CopyStr(ProjectId, 1, 50), CopyStr(TaskId, 1, 50),
                    Description, PostingDate, Hours, Billable, TagIds, ResultMessage);

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
        ParseHelper: Codeunit "Clockify TimeEntry Parse ori";
        Token: JsonToken;
    begin
        StartText := '';
        EndText := '';
        if not EntryObject.Get('timeInterval', Token) then
            exit;
        if not Token.IsObject() then
            exit;
        StartText := ParseHelper.GetText(Token.AsObject(), 'start');
        EndText := ParseHelper.GetText(Token.AsObject(), 'end');
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
}
