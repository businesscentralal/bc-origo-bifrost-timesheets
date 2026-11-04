namespace Origo.Bifrost.Timesheets;

using Origo.Bifrost;

/// <summary>
/// Implementation of the <c>Clockify.TimeEntry.SyncToTimeSheet</c> message type. Writes a
/// single Clockify time entry to the resource's open BC Time Sheet (line + detail) instead
/// of the Job Journal. BC-side operation.
/// </summary>
codeunit 10036840 "Clockify TSheetSync Impl ori" implements "Msg Interface ori", "Msg Contract ori", "Msg Discovery ori"
{
    Access = Internal;

    var
        InProgressSyncErr: Label 'In-progress time entries are not synced. Provide an entry with a non-empty ''end'' value (timer stopped).', Locked = true;

    /// <summary>Checks the caller permissions required for absence registration.</summary>
    procedure IsEnabled(): Boolean
    var
        ClockifyIntegration: Record "Clockify Integration ori";
        SecretMgt: Codeunit "Clockify Secret Mgt ori";
    begin
        if not ClockifyIntegration.WritePermission() then
            exit(false);
        exit(SecretMgt.HasCompanyApiKey());
    end;

    /// <summary>Returns zero because this message addresses a time sheet through request parameters.</summary>
    procedure GetFilterTableNo(): Integer
    begin
        exit(0);
    end;

    /// <summary>Returns the localized description of absence registration.</summary>
    procedure GetDescription(): Text[250]
    begin
        exit('Syncs a Clockify time entry to the resource''s open BC Time Sheet (line + detail) with deduplication and update detection.');
    end;


    /// <summary>Returns localized absence discovery keywords.</summary>
    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'time entry, sync, time sheet, Clockify, timesheets', Comment = 'is-IS=tímaskráning, samstilla, tímaskýrsla, Clockify, tímaskýrslur';
    begin
        exit(KeywordsLbl);
    end;

    /// <summary>Returns the localized message picker description.</summary>
    procedure GetSelectionDescription(): Text
    var
        SelectionLbl: Label 'Clockify.TimeEntry.SyncToTimeSheet: Syncs one finished time entry to an open BC time sheet. Run Clockify.TimeSheet.Create first. Use Clockify.TimeEntry.Sync for the Job Journal.', Comment = 'is-IS=Clockify.TimeEntry.SyncToTimeSheet: Samstillir eina lokna tímaskráningu við opna tímaskýrslu í BC. Keyrðu Clockify.TimeSheet.Create fyrst. Notaðu Clockify.TimeEntry.Sync fyrir verkbók.';
    begin
        exit(SelectionLbl);
    end;

    /// <summary>Describes the supported task envelope.</summary>
    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    var
        Parts: Codeunit "Clockify Contract Parts ori";
    begin
        exit(Parts.GetEnvelope(GetMessageType(), Envelope));
    end;

    /// <summary>Describes the time-sheet identifier.</summary>
    procedure GetTarget(var Target: JsonArray): Boolean
    var
        Parts: Codeunit "Clockify Contract Parts ori";
    begin
        exit(Parts.GetTarget(GetMessageType(), Target));
    end;

    /// <summary>Lists the accepted absence registration parameters.</summary>
    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        Parts: Codeunit "Clockify Contract Parts ori";
    begin
        exit(Parts.GetParameters(GetMessageType(), Parameters));
    end;

    /// <summary>Describes the absence line returned on success.</summary>
    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Parts: Codeunit "Clockify Contract Parts ori";
    begin
        exit(Parts.GetResponse(GetMessageType(), Response));
    end;

    /// <summary>Lists documented refusals and recovery steps.</summary>
    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Parts: Codeunit "Clockify Contract Parts ori";
    begin
        exit(Parts.GetErrors(GetMessageType(), Errors));
    end;

    /// <summary>Describes the committed write and required permissions.</summary>
    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Parts: Codeunit "Clockify Contract Parts ori";
    begin
        exit(Parts.GetEffect(GetMessageType(), Effect));
    end;

    /// <summary>Indicates that the type has no additional metering chapter.</summary>
    procedure GetMetering(var Metering: JsonObject): Boolean
    var
        Parts: Codeunit "Clockify Contract Parts ori";
    begin
        exit(Parts.GetMetering(Metering));
    end;

    /// <summary>Lists related discovery messages.</summary>
    procedure GetRelated(var Related: JsonArray): Boolean
    var
        Parts: Codeunit "Clockify Contract Parts ori";
    begin
        exit(Parts.GetRelated(GetMessageType(), Related));
    end;

    /// <summary>Describes the absence registration workflow.</summary>
    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    var
        Parts: Codeunit "Clockify Contract Parts ori";
    begin
        exit(Parts.GetWorkflow(GetMessageType(), Workflow));
    end;

    /// <summary>Provides an absence registration request and response example.</summary>
    procedure GetExamples(var Examples: JsonArray): Boolean
    var
        Parts: Codeunit "Clockify Contract Parts ori";
    begin
        exit(Parts.GetExamples(GetMessageType(), Examples));
    end;

    /// <summary>Returns the localized purpose of the message.</summary>
    procedure GetOverview(var Overview: Text): Boolean
    var
        Parts: Codeunit "Clockify Contract Parts ori";
    begin
        exit(Parts.GetOverview(GetMessageType(), Overview));
    end;

    /// <summary>Explains employee linking, weekend warnings and commit behavior.</summary>
    procedure GetNotes(var Notes: Text): Boolean
    var
        Parts: Codeunit "Clockify Contract Parts ori";
    begin
        exit(Parts.GetNotes(GetMessageType(), Notes));
    end;

    local procedure GetMessageType(): Enum "Message Type ori"
    begin
        exit(Enum::"Message Type ori"::"Clockify.TimeEntry.SyncToTimeSheet");
    end;

    /// <summary>Declares the message as an inbound write.</summary>
    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit(Enum::"Msg Direction ori"::Inbound);
    end;

    /// <summary>Validates the message version and dispatches isolated absence registration.</summary>
    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
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

        ResponseJson.Add('result', ParseHelper.SyncResultName(SyncResult));
        ResponseJson.Add('message', ResultMessage);
        ResponseJson.Add('entryId', EntryId);
        ResponseJson.Add('hours', Hours);
        ResponseJson.Add('postingDate', Format(PostingDate, 0, 9));
        Argument.SetResponseJson(ResponseJson);
    end;
}
