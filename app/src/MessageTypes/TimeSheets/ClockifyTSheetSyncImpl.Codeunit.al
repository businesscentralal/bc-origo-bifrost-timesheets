namespace Origo.Bifrost.Clockify;

using Origo.Bifrost;

/// <summary>
/// Implementation of the <c>Clockify.TimeEntry.SyncToTimeSheet</c> message type. Writes a
/// single Clockify time entry to the resource's open BC Time Sheet (line + detail) instead
/// of the Job Journal. BC-side operation.
/// </summary>
codeunit 70009255 "Clockify TSheetSync Impl ori" implements "Msg Interface ori"
{
    Access = Internal;

    var
        InProgressSyncErr: Label 'In-progress time entries are not synced. Provide an entry with a non-empty ''end'' value (timer stopped).', Locked = true;

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
        exit('Syncs a Clockify time entry to the resource''s open BC Time Sheet (line + detail) with deduplication and update detection.');
    end;

    internal procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit(Enum::"Msg Direction ori"::Inbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "Message Argument ori")
    var
        Help: Codeunit "Clockify TimeSheet Help ori";
    begin
        Argument.SetResponseMarkdown(Help.GetHelp(Enum::"Message Type ori"::"Clockify.TimeEntry.SyncToTimeSheet", GetDescription()));
    end;

    internal procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    var
        TimeSheetSync: Codeunit "Clockify TimeSheet Sync ori";
        RequestMgt: Codeunit "Clockify Request Mgt ori";
        ParseHelper: Codeunit "Clockify TimeEntry Parse ori";
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
        WorkspaceId: Text;
        UserId: Text;
        EntryId: Text;
        ProjectId: Text;
        TaskId: Text;
        Description: Text;
        StartText: Text;
        EndText: Text;
        Billable: Boolean;
        Hours: Decimal;
        PostingDate: Date;
        TagIds: List of [Text];
        SyncResult: Enum "Clockify Sync Result ori";
        ResultMessage: Text;
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

        TaskId := ParseHelper.GetText(RequestJson, 'taskId');
        Description := ParseHelper.GetText(RequestJson, 'description');
        StartText := ParseHelper.GetText(RequestJson, 'start');
        EndText := ParseHelper.GetText(RequestJson, 'end');
        Billable := ParseHelper.GetBoolean(RequestJson, 'billable', true);
        ParseHelper.GetTagIds(RequestJson, TagIds);

        if EndText = '' then begin
            Argument.RespondWithError(InProgressSyncErr);
            exit;
        end;

        Hours := ParseHelper.CalculateHours(StartText, EndText);
        PostingDate := ParseHelper.ParseDate(StartText);
        if (Hours = 0) or (PostingDate = 0D) then begin
            Argument.RespondWithError('Cannot derive hours and posting date: start and end must be ISO-8601 datetimes.');
            exit;
        end;

        SyncResult := TimeSheetSync.SyncTimeEntryToTimeSheet(
            CopyStr(EntryId, 1, 50), CopyStr(WorkspaceId, 1, 50), CopyStr(UserId, 1, 50),
            CopyStr(ProjectId, 1, 50), CopyStr(TaskId, 1, 50),
            Description, PostingDate, Hours, Billable, TagIds, ResultMessage);

        ResponseJson.Add('result', Format(SyncResult));
        ResponseJson.Add('message', ResultMessage);
        ResponseJson.Add('entryId', EntryId);
        ResponseJson.Add('hours', Hours);
        ResponseJson.Add('postingDate', Format(PostingDate, 0, 9));
        Argument.SetResponseJson(ResponseJson);
    end;
}
