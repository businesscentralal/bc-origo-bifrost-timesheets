namespace Origo.Bifrost.Timesheets;

using Microsoft.HumanResources.Absence;
using Microsoft.HumanResources.Employee;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.Resources.Setup;
using Microsoft.Projects.TimeSheet;
using Origo.Bifrost;

/// <summary>
/// Request checks and dispatch for the native Timesheets message types.
/// Each Execute procedure reads only that type's keys. Writes run in
/// "TS Native Runner ori" so a failure rolls back.
/// </summary>
codeunit 10036868 "TS Native Mgt ori"
{
    Access = Internal;

    var
        MissingKeyNextTxt: Label 'Send the missing key.', Comment = 'is-IS=Sendu lykilinn sem vantar.';
        TypeNextTxt: Label 'Send the key with the documented type.', Comment = 'is-IS=Sendu lykilinn með skráðu tagi.';
        UnknownKeyNextTxt: Label 'Remove the unknown key.', Comment = 'is-IS=Fjarlægðu óþekkta lykilinn.';
        IdentifierNextTxt: Label 'Use an identifier that exists.', Comment = 'is-IS=Notaðu auðkenni sem er til.';
        OneIdentifierNextTxt: Label 'Send only one identifier for the time sheet.', Comment = 'is-IS=Sendu aðeins eitt auðkenni fyrir tímaskýrsluna.';
        OwnerSubmitNextTxt: Label 'Only the owner can submit; ask the owner.', Comment = 'is-IS=Aðeins eigandinn getur sent inn. Biddu eigandann.';
        AddLinesNextTxt: Label 'Add lines first.', Comment = 'is-IS=Bættu við línum fyrst.';
        FixLineNextTxt: Label 'Fix the line and submit again.', Comment = 'is-IS=Lagfærðu línuna og sendu aftur inn.';
        WeekdayNextTxt: Label 'Use the first weekday named in the refusal.', Comment = 'is-IS=Notaðu fyrsta vikudaginn sem höfnunin nefnir.';
        UseTimeSheetNextTxt: Label 'Turn on Use Time Sheet on the resource.', Comment = 'is-IS=Kveiktu á Notaðu tímaskýrslu á auðlindinni.';
        SplitNextTxt: Label 'Split the call.', Comment = 'is-IS=Skiptu kallinu.';
        PeriodNextTxt: Label 'Send a number from 1 to 52.', Comment = 'is-IS=Sendu tölu frá 1 til 52.';
        AskPermNextTxt: Label 'Ask for the Timesheets permission set.', Comment = 'is-IS=Biddu um heimildasamstæðu tímaskýrslna.';
        FromToNextTxt: Label 'Use from <= to.', Comment = 'is-IS=Notaðu frá sem er minna eða jafnt og til.';
        ApproverNextTxt: Label 'Only the approver named on the time sheet can approve.', Comment = 'is-IS=Aðeins samþykktaraðilinn sem er nefndur á tímaskýrslunni getur samþykkt.';
        SubmitFirstNextTxt: Label 'Submit it first with Timesheets.TimeSheet.Submit.', Comment = 'is-IS=Sendu hana fyrst inn með Timesheets.TimeSheet.Submit.';
        AddByHandNextTxt: Label 'Add lines by hand.', Comment = 'is-IS=Bættu við línum handvirkt.';
        AskOwnerNextTxt: Label 'Ask the owner.', Comment = 'is-IS=Biddu eigandann.';
        LinkEmployeeNextTxt: Label 'Link the resource to an employee in BC.', Comment = 'is-IS=Tengdu auðlindina við starfsmann í BC.';
        CauseNextTxt: Label 'Use a code from Causes of Absence.', Comment = 'is-IS=Notaðu kóða úr fjarvistarástæðum.';
        NativeNameNextTxt: Label 'Use the native name.', Comment = 'is-IS=Notaðu innlenda heitið.';
        AssignSetNextTxt: Label 'Assign the BIFROST Timeshts ori permission set.', Comment = 'is-IS=Úthlutaðu heimildasamstæðunni BIFROST Timeshts ori.';
        RetryNextTxt: Label 'Retry the call.', Comment = 'is-IS=Reyndu kallið aftur.';
        MissingKeyMsg: Label 'A required key is missing.', Comment = 'is-IS=Nauðsynlegur lykill vantar.';
        TypeMsg: Label 'A key has the wrong JSON type.', Comment = 'is-IS=Lykill er af röngu JSON-tagi.';
        UnknownKeyMsg: Label 'The request contains an unknown key.', Comment = 'is-IS=Beiðnin inniheldur óþekktan lykil.';
        IdentifierMsg: Label 'The identifier does not match a record.', Comment = 'is-IS=Auðkennið passar ekki við færslu.';
        OneIdentifierMsg: Label 'The request names the time sheet in more than one way.', Comment = 'is-IS=Beiðnin nefnir tímaskýrsluna á fleiri en einn hátt.';
        OwnerSubmitMsg: Label 'The caller is not the owner of the time sheet.', Comment = 'is-IS=Kallandinn er ekki eigandi tímaskýrslunnar.';
        AddLinesMsg: Label 'The time sheet has no open lines.', Comment = 'is-IS=Tímaskýrslan hefur engar opnar línur.';
        FixLineMsg: Label 'Business Central rejected the line.', Comment = 'is-IS=Business Central hafnaði línunni.';
        WeekdayMsg: Label 'startingDate must be a %1.', Comment = '%1 = weekday|is-IS=startingDate verður að vera %1.';
        UseTimeSheetMsg: Label 'The resource was not found or Use Time Sheet is off.', Comment = 'is-IS=Auðlindin fannst ekki eða slökkt er á Notaðu tímaskýrslu.';
        SplitMsg: Label 'numberOfPeriods is above 52.', Comment = 'is-IS=numberOfPeriods er yfir 52.';
        PeriodMsg: Label 'numberOfPeriods must be from 1 to 52.', Comment = 'is-IS=numberOfPeriods verður að vera frá 1 til 52.';
        AskPermMsg: Label 'The caller cannot read time sheets.', Comment = 'is-IS=Kallandinn getur ekki lesið tímaskýrslur.';
        FromToMsg: Label 'The date range has from after to.', Comment = 'is-IS=Dagsetningabilið hefur frá á eftir til.';
        ApproverMsg: Label 'The caller is not the approver named on the time sheet.', Comment = 'is-IS=Kallandinn er ekki samþykktaraðilinn sem er nefndur á tímaskýrslunni.';
        SubmitFirstMsg: Label 'The line is not submitted.', Comment = 'is-IS=Línan hefur ekki verið send inn.';
        AddByHandMsg: Label 'The resource has no previous time sheet.', Comment = 'is-IS=Auðlindin hefur enga fyrri tímaskýrslu.';
        AskOwnerMsg: Label 'The caller is not the owner of the time sheet.', Comment = 'is-IS=Kallandinn er ekki eigandi tímaskýrslunnar.';
        LinkEmployeeMsg: Label 'The resource is not linked to an employee.', Comment = 'is-IS=Auðlindin er ekki tengd við starfsmann.';
        CauseMsg: Label 'The cause of absence was not found.', Comment = 'is-IS=Fjarvistarástæðan fannst ekki.';
        AssignSetMsg: Label 'The caller cannot write time sheets.', Comment = 'is-IS=Kallandinn getur ekki skrifað tímaskýrslur.';
        LegacyMsg: Label 'The Clockify.TimeSheet name still runs. Use the native name.', Comment = 'is-IS=Clockify.TimeSheet heitið keyrir enn. Notaðu innlenda heitið.';
        NoJournalErr: Label 'No Job Journal target is configured. Set the Clockify Job Journal Template and Batch on Clockify Setup, or pass ''journalTemplate'' and ''journalBatch'' in the request.', Locked = true;

    /// <summary>True when the caller may insert or modify time sheet header, line and detail.</summary>
    procedure CanMaintainSheets(): Boolean
    var
        Detail: Record "Time Sheet Detail";
        Header: Record "Time Sheet Header";
        Line: Record "Time Sheet Line";
    begin
        exit(Header.WritePermission() and Line.WritePermission() and Detail.WritePermission());
    end;

    /// <summary>True when the caller may read time sheet header, line and detail.</summary>
    procedure CanReadSheets(): Boolean
    var
        Detail: Record "Time Sheet Detail";
        Header: Record "Time Sheet Header";
        Line: Record "Time Sheet Line";
    begin
        exit(Header.ReadPermission() and Line.ReadPermission() and Detail.ReadPermission());
    end;

    /// <summary>Adds the deprecation warning the old Clockify.TimeSheet names return on success.</summary>
    procedure AddLegacyNameWarning(var ResponseJson: JsonObject)
    var
        Warning: JsonObject;
        Warnings: JsonArray;
    begin
        Warning.Add('code', 'DeprecatedParameter');
        Warning.Add('message', LegacyMsg);
        Warning.Add('parameter', 'type');
        Warning.Add('nextStep', NativeNameNextTxt);
        Warnings.Add(Warning);
        ResponseJson.Add('warnings', Warnings);
    end;

    /// <summary>Submits open lines on one time sheet.</summary>
    procedure ExecuteSubmit(var Argument: Record "Message Argument ori")
    var
        Header: Record "Time Sheet Header";
        Context: Codeunit "TS Native Context ori";
        Allowed: List of [Text];
        DateToken: JsonToken;
        LineFilter: Text;
        LinesToken: JsonToken;
        Numbers: List of [Integer];
        OpenCount: Integer;
        RequestJson: JsonObject;
        ResourceToken: JsonToken;
        SheetToken: JsonToken;
    begin
        if Deny(Argument, false) then
            exit;
        RequestJson := Argument.GetRequestJson();
        Allowed.Add('timeSheetNo');
        Allowed.Add('resourceNo');
        Allowed.Add('date');
        Allowed.Add('lineNos');
        if not AllowOnly(Argument, RequestJson, Allowed) then
            exit;
        if not ResolveSheet(Argument, RequestJson, SheetToken, ResourceToken, DateToken, Header) then
            exit;
        if not SameUser(Header."Owner User ID") then begin
            Fail(Argument, "Bifrost Error Code ori"::PermissionDenied, OwnerSubmitMsg, 'timeSheetNo', OwnerSubmitNextTxt);
            exit;
        end;
        if not ReadLineSelection(Argument, RequestJson, LinesToken, Numbers, LineFilter) then
            exit;
        if not SubmitSelection(Argument, Header, Numbers, LineFilter, OpenCount) then
            exit;
        if OpenCount = 0 then begin
            RespondExisting(Argument, Header."No.", LineFilter, false);
            exit;
        end;
        Context.SetSubmit(Header."No.", LineFilter);
        RunAndRespond(Argument);
    end;

    /// <summary>Creates weekly time sheets for the chosen resources and periods.</summary>
    procedure ExecuteCreate(var Argument: Record "Message Argument ori")
    var
        ResourcesSetup: Record "Resources Setup";
        Context: Codeunit "TS Native Context ori";
        Allowed: List of [Text];
        Expected: Integer;
        FromPlanning: Boolean;
        GroupCode: Code[20];
        Periods: Integer;
        PeriodToken: JsonToken;
        PlanToken: JsonToken;
        RequestJson: JsonObject;
        ResourceFilter: Text;
        StartingDate: Date;
        StartToken: JsonToken;
    begin
        if Deny(Argument, false) then
            exit;
        if not CanReadSetup() then begin
            Fail(Argument, "Bifrost Error Code ori"::PermissionDenied, AssignSetMsg, '', AssignSetNextTxt);
            exit;
        end;
        RequestJson := Argument.GetRequestJson();
        Allowed.Add('startingDate');
        Allowed.Add('numberOfPeriods');
        Allowed.Add('resourceNos');
        Allowed.Add('resourceNo');
        Allowed.Add('resourceGroup');
        Allowed.Add('createLinesFromPlanning');
        if not AllowOnly(Argument, RequestJson, Allowed) then
            exit;
        if not RequestJson.Get('startingDate', StartToken) then begin
            Fail(Argument, "Bifrost Error Code ori"::MissingParameter, MissingKeyMsg, 'startingDate', MissingKeyNextTxt);
            exit;
        end;
        if not ReadJsonDate(StartToken, StartingDate) then begin
            Fail(Argument, "Bifrost Error Code ori"::InvalidParameterFormat, TypeMsg, 'startingDate', TypeNextTxt);
            exit;
        end;
        Periods := 1;
        if RequestJson.Get('numberOfPeriods', PeriodToken) then begin
            if not ReadJsonInteger(PeriodToken, Periods) then begin
                Fail(Argument, "Bifrost Error Code ori"::InvalidParameterFormat, TypeMsg, 'numberOfPeriods', TypeNextTxt);
                exit;
            end;
            if Periods > 52 then begin
                Fail(Argument, "Bifrost Error Code ori"::LimitExceeded, SplitMsg, 'numberOfPeriods', SplitNextTxt);
                exit;
            end;
            if Periods < 1 then begin
                Fail(Argument, "Bifrost Error Code ori"::InvalidParameter, PeriodMsg, 'numberOfPeriods', PeriodNextTxt);
                exit;
            end;
        end;
        FromPlanning := false;
        if RequestJson.Get('createLinesFromPlanning', PlanToken) then
            if not ReadJsonBoolean(PlanToken, FromPlanning) then begin
                Fail(Argument, "Bifrost Error Code ori"::InvalidParameterFormat, TypeMsg, 'createLinesFromPlanning', TypeNextTxt);
                exit;
            end;
        if not ReadResourceChoice(Argument, RequestJson, ResourceFilter, GroupCode) then
            exit;
        if not ResourcesSetup.Get() then begin
            Fail(Argument, "Bifrost Error Code ori"::PreconditionFailed, UseTimeSheetMsg, 'startingDate', UseTimeSheetNextTxt);
            exit;
        end;
        Expected := ResourcesSetup."Time Sheet First Weekday" + 1;
        if Date2DWY(StartingDate, 1) <> Expected then begin
            Fail(Argument, "Bifrost Error Code ori"::PreconditionFailed, StrSubstNo(WeekdayMsg, Format(ResourcesSetup."Time Sheet First Weekday")), 'startingDate', WeekdayNextTxt);
            exit;
        end;
        if not ResourcesAcceptTimeSheets(Argument, ResourceFilter, GroupCode) then
            exit;
        Context.SetCreate(StartingDate, Periods, ResourceFilter, GroupCode, FromPlanning);
        RunAndRespond(Argument);
    end;

    /// <summary>Lists submitted lines waiting for the caller.</summary>
    procedure ExecutePending(var Argument: Record "Message Argument ori")
    var
        Header: Record "Time Sheet Header";
        Line: Record "Time Sheet Line";
        Resource: Record Resource;
        Allowed: List of [Text];
        FromDate: Date;
        FromToken: JsonToken;
        HasFrom: Boolean;
        HasTo: Boolean;
        Lines: JsonArray;
        RequestJson: JsonObject;
        ResourceNo: Code[20];
        ResourceToken: JsonToken;
        Response: JsonObject;
        Returned: Integer;
        Seen: Integer;
        Skip: Integer;
        SkipToken: JsonToken;
        Take: Integer;
        TakeToken: JsonToken;
        ToDate: Date;
        ToToken: JsonToken;
        TypeName: Text;
        TypeToken: JsonToken;
    begin
        if Deny(Argument, true) then
            exit;
        RequestJson := Argument.GetRequestJson();
        Allowed.Add('from');
        Allowed.Add('to');
        Allowed.Add('resource');
        Allowed.Add('type');
        Allowed.Add('take');
        Allowed.Add('skip');
        if not AllowOnly(Argument, RequestJson, Allowed) then
            exit;
        HasFrom := RequestJson.Get('from', FromToken);
        HasTo := RequestJson.Get('to', ToToken);
        if HasFrom and (not ReadJsonDate(FromToken, FromDate)) then begin
            Fail(Argument, "Bifrost Error Code ori"::InvalidParameterFormat, TypeMsg, 'from', TypeNextTxt);
            exit;
        end;
        if HasTo and (not ReadJsonDate(ToToken, ToDate)) then begin
            Fail(Argument, "Bifrost Error Code ori"::InvalidParameterFormat, TypeMsg, 'to', TypeNextTxt);
            exit;
        end;
        if HasFrom and HasTo and (FromDate > ToDate) then begin
            Fail(Argument, "Bifrost Error Code ori"::InvalidParameter, FromToMsg, 'from', FromToNextTxt);
            exit;
        end;
        if RequestJson.Get('resource', ResourceToken) then begin
            if not IsJsonString(ResourceToken) then begin
                Fail(Argument, "Bifrost Error Code ori"::InvalidParameterFormat, TypeMsg, 'resource', TypeNextTxt);
                exit;
            end;
            ResourceNo := CopyStr(ResourceToken.AsValue().AsText(), 1, MaxStrLen(ResourceNo));
            if not Resource.Get(ResourceNo) then begin
                Fail(Argument, "Bifrost Error Code ori"::RecordNotFound, IdentifierMsg, 'resource', IdentifierNextTxt);
                exit;
            end;
        end;
        if RequestJson.Get('type', TypeToken) then begin
            if not IsJsonString(TypeToken) then begin
                Fail(Argument, "Bifrost Error Code ori"::InvalidParameterFormat, TypeMsg, 'type', TypeNextTxt);
                exit;
            end;
            TypeName := TypeToken.AsValue().AsText();
            if not KnownLineType(TypeName) then begin
                Fail(Argument, "Bifrost Error Code ori"::InvalidParameter, TypeMsg, 'type', TypeNextTxt);
                exit;
            end;
        end;
        Take := 50;
        Skip := 0;
        Seen := 0;
        Returned := 0;
        if RequestJson.Get('take', TakeToken) then begin
            if not ReadJsonInteger(TakeToken, Take) then begin
                Fail(Argument, "Bifrost Error Code ori"::InvalidParameterFormat, TypeMsg, 'take', TypeNextTxt);
                exit;
            end;
            if Take < 0 then begin
                Fail(Argument, "Bifrost Error Code ori"::InvalidParameter, PeriodMsg, 'take', TypeNextTxt);
                exit;
            end;
            if Take > 100 then begin
                Fail(Argument, "Bifrost Error Code ori"::LimitExceeded, SplitMsg, 'take', SplitNextTxt);
                exit;
            end;
        end;
        if RequestJson.Get('skip', SkipToken) then begin
            if not ReadJsonInteger(SkipToken, Skip) then begin
                Fail(Argument, "Bifrost Error Code ori"::InvalidParameterFormat, TypeMsg, 'skip', TypeNextTxt);
                exit;
            end;
            if Skip < 0 then begin
                Fail(Argument, "Bifrost Error Code ori"::InvalidParameter, PeriodMsg, 'skip', TypeNextTxt);
                exit;
            end;
        end;

        Line.SetRange(Status, Line.Status::Submitted);
        if TypeName <> '' then
            Line.SetRange(Type, LineTypeFromName(TypeName));
        if Line.FindSet() then
            repeat
                Header.Get(Line."Time Sheet No.");
                if PendingLineMatches(Header, ResourceNo, HasFrom, FromDate, HasTo, ToDate) then begin
                    if (Seen >= Skip) and (Returned < Take) then begin
                        Lines.Add(PendingNode(Header, Line));
                        Returned += 1;
                    end;
                    Seen += 1;
                end;
            until (Line.Next() = 0) or (Returned >= Take);
        Response.Add('status', 'Success');
        Response.Add('lines', Lines);
        Response.Add('take', Take);
        Response.Add('skip', Skip);
        Argument.SetResponseJson(Response);
    end;

    /// <summary>Approves submitted lines on one time sheet.</summary>
    procedure ExecuteApprove(var Argument: Record "Message Argument ori")
    begin
        ExecuteDecision(Argument, false, '');
    end;

    /// <summary>Rejects submitted lines on one time sheet.</summary>
    procedure ExecuteReject(var Argument: Record "Message Argument ori")
    var
        Comment: Text;
        CommentToken: JsonToken;
        RequestJson: JsonObject;
    begin
        if Deny(Argument, false) then
            exit;
        RequestJson := Argument.GetRequestJson();
        if RequestJson.Get('comment', CommentToken) then begin
            if not IsJsonString(CommentToken) then begin
                Fail(Argument, "Bifrost Error Code ori"::InvalidParameterFormat, TypeMsg, 'comment', TypeNextTxt);
                exit;
            end;
            Comment := CommentToken.AsValue().AsText();
        end;
        ExecuteDecision(Argument, true, Comment);
    end;

    /// <summary>Copies lines from the resource's previous time sheet.</summary>
    procedure ExecuteCopy(var Argument: Record "Message Argument ori")
    var
        Header: Record "Time Sheet Header";
        Previous: Record "Time Sheet Header";
        PreviousLine: Record "Time Sheet Line";
        Context: Codeunit "TS Native Context ori";
    begin
        if not RequireSheet(Argument, Header) then
            exit;
        if not SameUser(Header."Owner User ID") then begin
            Fail(Argument, "Bifrost Error Code ori"::PermissionDenied, AskOwnerMsg, 'timeSheetNo', AskOwnerNextTxt);
            exit;
        end;
        Previous.SetRange("Resource No.", Header."Resource No.");
        Previous.SetFilter("Starting Date", '<%1', Header."Starting Date");
        if not Previous.FindLast() then begin
            Fail(Argument, "Bifrost Error Code ori"::PreconditionFailed, AddByHandMsg, 'timeSheetNo', AddByHandNextTxt);
            exit;
        end;
        PreviousLine.SetRange("Time Sheet No.", Previous."No.");
        if PreviousLine.IsEmpty() then begin
            RespondCount(Argument, 'copied', 0);
            exit;
        end;
        Context.SetCopy(Header."No.");
        RunAndRespond(Argument);
    end;

    /// <summary>Creates lines from the resource's project planning in the sheet period.</summary>
    procedure ExecutePlanning(var Argument: Record "Message Argument ori")
    var
        Header: Record "Time Sheet Header";
        Context: Codeunit "TS Native Context ori";
    begin
        if not RequireSheet(Argument, Header) then
            exit;
        if not SameUser(Header."Owner User ID") then begin
            Fail(Argument, "Bifrost Error Code ori"::PermissionDenied, AskOwnerMsg, 'timeSheetNo', AskOwnerNextTxt);
            exit;
        end;
        Context.SetPlanning(Header."No.");
        RunAndRespond(Argument);
    end;

    /// <summary>Registers an absence line and its daily hours.</summary>
    procedure ExecuteAbsence(var Argument: Record "Message Argument ori")
    var
        Cause: Record "Cause of Absence";
        Employee: Record Employee;
        Header: Record "Time Sheet Header";
        Context: Codeunit "TS Native Context ori";
        Allowed: List of [Text];
        CauseCode: Code[10];
        CauseToken: JsonToken;
        DateToken: JsonToken;
        HoursText: Text;
        HoursToken: JsonToken;
        NonWorking: Boolean;
        QtyToken: JsonToken;
        RequestJson: JsonObject;
        ResourceToken: JsonToken;
        SheetToken: JsonToken;
    begin
        if Deny(Argument, false) then
            exit;
        RequestJson := Argument.GetRequestJson();
        Allowed.Add('timeSheetNo');
        Allowed.Add('resourceNo');
        Allowed.Add('date');
        Allowed.Add('causeOfAbsenceCode');
        Allowed.Add('hours');
        Allowed.Add('quantity');
        if not AllowOnly(Argument, RequestJson, Allowed) then
            exit;
        if not ResolveSheet(Argument, RequestJson, SheetToken, ResourceToken, DateToken, Header) then
            exit;
        if not RequestJson.Get('causeOfAbsenceCode', CauseToken) then begin
            Fail(Argument, "Bifrost Error Code ori"::MissingParameter, MissingKeyMsg, 'causeOfAbsenceCode', MissingKeyNextTxt);
            exit;
        end;
        if not IsJsonString(CauseToken) then begin
            Fail(Argument, "Bifrost Error Code ori"::InvalidParameterFormat, TypeMsg, 'causeOfAbsenceCode', TypeNextTxt);
            exit;
        end;
        CauseCode := CopyStr(CauseToken.AsValue().AsText(), 1, MaxStrLen(CauseCode));
        if not Cause.Get(CauseCode) then begin
            Fail(Argument, "Bifrost Error Code ori"::RecordNotFound, CauseMsg, 'causeOfAbsenceCode', CauseNextTxt);
            exit;
        end;
        if not ReadHours(Argument, RequestJson, HoursToken, QtyToken, DateToken, HoursText, NonWorking) then
            exit;
        if not Employee.ReadPermission() then begin
            Fail(Argument, "Bifrost Error Code ori"::PermissionDenied, AssignSetMsg, '', AssignSetNextTxt);
            exit;
        end;
        Employee.SetRange("Resource No.", Header."Resource No.");
        if Employee.IsEmpty() then begin
            Fail(Argument, "Bifrost Error Code ori"::PreconditionFailed, LinkEmployeeMsg, 'resourceNo', LinkEmployeeNextTxt);
            exit;
        end;
        // Resource has no Base Calendar Code in the BC 28 symbol set this app compiles against.
        // Non-working days are Saturday and Sunday (Date2DWY >= 6) only.
        Context.SetAbsence(Header."No.", CauseCode, HoursText, NonWorking);
        RunAndRespond(Argument);
    end;

    /// <summary>Reopens submitted or approved lines under the native name.</summary>
    procedure ExecuteReopen(var Argument: Record "Message Argument ori")
    var
        TimeSheetMgt: Codeunit "Clockify TimeSheet Mgt ori";
        Allowed: List of [Text];
        DateToken: JsonToken;
        EndingDateTo: Date;
        RequestJson: JsonObject;
        Response: JsonObject;
    begin
        if Deny(Argument, false) then
            exit;
        RequestJson := Argument.GetRequestJson();
        Allowed.Add('endingDateTo');
        if not AllowOnly(Argument, RequestJson, Allowed) then
            exit;
        if RequestJson.Get('endingDateTo', DateToken) then
            if not ReadJsonDate(DateToken, EndingDateTo) then begin
                Fail(Argument, "Bifrost Error Code ori"::InvalidParameterFormat, TypeMsg, 'endingDateTo', TypeNextTxt);
                exit;
            end;
        Response.Add('status', 'Success');
        Response.Add('reopenedLines', TimeSheetMgt.ReopenTimeSheets(EndingDateTo));
        Argument.SetResponseJson(Response);
    end;

    /// <summary>Posts approved lines under the native name.</summary>
    procedure ExecutePost(var Argument: Record "Message Argument ori")
    var
        SetupMgt: Codeunit "Clockify Setup Mgt ori";
        TimeSheetMgt: Codeunit "Clockify TimeSheet Mgt ori";
        Allowed: List of [Text];
        BatchToken: JsonToken;
        JournalBatch: Code[10];
        JournalTemplate: Code[10];
        RequestJson: JsonObject;
        Response: JsonObject;
        TemplateToken: JsonToken;
    begin
        if Deny(Argument, false) then
            exit;
        RequestJson := Argument.GetRequestJson();
        Allowed.Add('journalTemplate');
        Allowed.Add('journalBatch');
        if not AllowOnly(Argument, RequestJson, Allowed) then
            exit;
        SetupMgt.TryGetJobJournal(JournalTemplate, JournalBatch);
        if RequestJson.Get('journalTemplate', TemplateToken) then begin
            if not IsJsonString(TemplateToken) then begin
                Fail(Argument, "Bifrost Error Code ori"::InvalidParameterFormat, TypeMsg, 'journalTemplate', TypeNextTxt);
                exit;
            end;
            JournalTemplate := CopyStr(TemplateToken.AsValue().AsText(), 1, MaxStrLen(JournalTemplate));
        end;
        if RequestJson.Get('journalBatch', BatchToken) then begin
            if not IsJsonString(BatchToken) then begin
                Fail(Argument, "Bifrost Error Code ori"::InvalidParameterFormat, TypeMsg, 'journalBatch', TypeNextTxt);
                exit;
            end;
            JournalBatch := CopyStr(BatchToken.AsValue().AsText(), 1, MaxStrLen(JournalBatch));
        end;
        if (JournalTemplate = '') or (JournalBatch = '') then begin
            Argument.RespondWithError(NoJournalErr);
            exit;
        end;
        Response.Add('status', 'Success');
        Response.Add('postedLines', TimeSheetMgt.PostApprovedTimeSheets(JournalTemplate, JournalBatch));
        Argument.SetResponseJson(Response);
    end;

    /// <summary>Archives posted time sheets under the native name.</summary>
    procedure ExecuteArchive(var Argument: Record "Message Argument ori")
    var
        TimeSheetMgt: Codeunit "Clockify TimeSheet Mgt ori";
        Allowed: List of [Text];
        RequestJson: JsonObject;
        Response: JsonObject;
    begin
        if Deny(Argument, false) then
            exit;
        RequestJson := Argument.GetRequestJson();
        if not AllowOnly(Argument, RequestJson, Allowed) then
            exit;
        Response.Add('status', 'Success');
        Response.Add('archived', TimeSheetMgt.ArchivePostedTimeSheets());
        Argument.SetResponseJson(Response);
    end;

    local procedure ExecuteDecision(var Argument: Record "Message Argument ori"; IsReject: Boolean; Comment: Text)
    var
        CommentLine: Record "Time Sheet Comment Line";
        Header: Record "Time Sheet Header";
        Context: Codeunit "TS Native Context ori";
        Actionable: Integer;
        Allowed: List of [Text];
        LineFilter: Text;
        LinesToken: JsonToken;
        Numbers: List of [Integer];
        RequestJson: JsonObject;
        SheetToken: JsonToken;
    begin
        if Deny(Argument, false) then
            exit;
        if IsReject and (not CommentLine.WritePermission()) then begin
            Fail(Argument, "Bifrost Error Code ori"::PermissionDenied, AssignSetMsg, '', AssignSetNextTxt);
            exit;
        end;
        RequestJson := Argument.GetRequestJson();
        Allowed.Add('timeSheetNo');
        Allowed.Add('lineNos');
        if IsReject then
            Allowed.Add('comment');
        if not AllowOnly(Argument, RequestJson, Allowed) then
            exit;
        if not RequestJson.Get('timeSheetNo', SheetToken) then begin
            Fail(Argument, "Bifrost Error Code ori"::MissingParameter, MissingKeyMsg, 'timeSheetNo', MissingKeyNextTxt);
            exit;
        end;
        if not LoadSheetToken(Argument, SheetToken, Header) then
            exit;
        if not SameUser(Header."Approver User ID") then begin
            Fail(Argument, "Bifrost Error Code ori"::PermissionDenied, ApproverMsg, 'timeSheetNo', ApproverNextTxt);
            exit;
        end;
        if not ReadLineSelection(Argument, RequestJson, LinesToken, Numbers, LineFilter) then
            exit;
        if not DecisionSelection(Argument, Header, Numbers, LineFilter, Actionable) then
            exit;
        if Actionable = 0 then begin
            RespondExisting(Argument, Header."No.", LineFilter, true);
            exit;
        end;
        if IsReject then
            Context.SetReject(Header."No.", LineFilter, Comment)
        else
            Context.SetApprove(Header."No.", LineFilter);
        RunAndRespond(Argument);
    end;

    local procedure RequireSheet(var Argument: Record "Message Argument ori"; var Header: Record "Time Sheet Header"): Boolean
    var
        Allowed: List of [Text];
        RequestJson: JsonObject;
        SheetToken: JsonToken;
    begin
        if Deny(Argument, false) then
            exit(false);
        RequestJson := Argument.GetRequestJson();
        Allowed.Add('timeSheetNo');
        if not AllowOnly(Argument, RequestJson, Allowed) then
            exit(false);
        if not RequestJson.Get('timeSheetNo', SheetToken) then begin
            Fail(Argument, "Bifrost Error Code ori"::MissingParameter, MissingKeyMsg, 'timeSheetNo', MissingKeyNextTxt);
            exit(false);
        end;
        exit(LoadSheetToken(Argument, SheetToken, Header));
    end;

    local procedure ResolveSheet(var Argument: Record "Message Argument ori"; RequestJson: JsonObject; var SheetToken: JsonToken; var ResourceToken: JsonToken; var DateToken: JsonToken; var Header: Record "Time Sheet Header"): Boolean
    var
        HasDate: Boolean;
        HasResource: Boolean;
        HasSheet: Boolean;
        ResourceNo: Code[20];
        SheetDate: Date;
    begin
        HasSheet := RequestJson.Get('timeSheetNo', SheetToken);
        HasResource := RequestJson.Get('resourceNo', ResourceToken);
        HasDate := RequestJson.Get('date', DateToken);
        if HasSheet and (HasResource or HasDate) then begin
            Fail(Argument, "Bifrost Error Code ori"::ConflictingIdentifiers, OneIdentifierMsg, 'timeSheetNo', OneIdentifierNextTxt);
            exit(false);
        end;
        if not HasSheet and not HasResource then begin
            Fail(Argument, "Bifrost Error Code ori"::MissingParameter, MissingKeyMsg, 'timeSheetNo', MissingKeyNextTxt);
            exit(false);
        end;
        if HasSheet then
            exit(LoadSheetToken(Argument, SheetToken, Header));
        if not HasDate then begin
            Fail(Argument, "Bifrost Error Code ori"::MissingParameter, MissingKeyMsg, 'date', MissingKeyNextTxt);
            exit(false);
        end;
        if not IsJsonString(ResourceToken) then begin
            Fail(Argument, "Bifrost Error Code ori"::InvalidParameterFormat, TypeMsg, 'resourceNo', TypeNextTxt);
            exit(false);
        end;
        if not ReadJsonDate(DateToken, SheetDate) then begin
            Fail(Argument, "Bifrost Error Code ori"::InvalidParameterFormat, TypeMsg, 'date', TypeNextTxt);
            exit(false);
        end;
        ResourceNo := CopyStr(ResourceToken.AsValue().AsText(), 1, MaxStrLen(ResourceNo));
        Header.SetRange("Resource No.", ResourceNo);
        Header.SetFilter("Starting Date", '<=%1', SheetDate);
        Header.SetFilter("Ending Date", '>=%1', SheetDate);
        if Header.Count() > 1 then begin
            Fail(Argument, "Bifrost Error Code ori"::ConflictingIdentifiers, OneIdentifierMsg, 'date', OneIdentifierNextTxt);
            exit(false);
        end;
        if not Header.FindFirst() then begin
            Fail(Argument, "Bifrost Error Code ori"::RecordNotFound, IdentifierMsg, 'resourceNo', IdentifierNextTxt);
            exit(false);
        end;
        exit(true);
    end;

    local procedure LoadSheetToken(var Argument: Record "Message Argument ori"; SheetToken: JsonToken; var Header: Record "Time Sheet Header"): Boolean
    var
        SheetNo: Code[20];
    begin
        if not IsJsonString(SheetToken) then begin
            Fail(Argument, "Bifrost Error Code ori"::InvalidParameterFormat, TypeMsg, 'timeSheetNo', TypeNextTxt);
            exit(false);
        end;
        SheetNo := CopyStr(SheetToken.AsValue().AsText(), 1, MaxStrLen(SheetNo));
        if not Header.Get(SheetNo) then begin
            Fail(Argument, "Bifrost Error Code ori"::RecordNotFound, IdentifierMsg, 'timeSheetNo', IdentifierNextTxt);
            exit(false);
        end;
        exit(true);
    end;

    local procedure ReadLineSelection(var Argument: Record "Message Argument ori"; RequestJson: JsonObject; var LinesToken: JsonToken; var Numbers: List of [Integer]; var LineFilter: Text): Boolean
    var
        Entry: JsonToken;
        Index: Integer;
        LineNo: Integer;
    begin
        if not RequestJson.Get('lineNos', LinesToken) then begin
            LineFilter := '*';
            exit(true);
        end;
        if not LinesToken.IsArray() then begin
            Fail(Argument, "Bifrost Error Code ori"::InvalidParameterFormat, TypeMsg, 'lineNos', TypeNextTxt);
            exit(false);
        end;
        LineFilter := '';
        for Index := 0 to LinesToken.AsArray().Count() - 1 do begin
            LinesToken.AsArray().Get(Index, Entry);
            if not ReadJsonInteger(Entry, LineNo) then begin
                Fail(Argument, "Bifrost Error Code ori"::InvalidParameterFormat, TypeMsg, 'lineNos', TypeNextTxt);
                exit(false);
            end;
            Numbers.Add(LineNo);
            if LineFilter <> '' then
                LineFilter += '|';
            LineFilter += Format(LineNo);
        end;
        exit(true);
    end;

    local procedure SubmitSelection(var Argument: Record "Message Argument ori"; Header: Record "Time Sheet Header"; Numbers: List of [Integer]; var LineFilter: Text; var OpenCount: Integer): Boolean
    var
        Line: Record "Time Sheet Line";
        LineNo: Integer;
    begin
        OpenCount := 0;
        if LineFilter = '*' then begin
            Line.SetRange("Time Sheet No.", Header."No.");
            if Line.IsEmpty() then begin
                Fail(Argument, "Bifrost Error Code ori"::PreconditionFailed, AddLinesMsg, 'lineNos', AddLinesNextTxt);
                exit(false);
            end;
            Line.SetRange(Status, Line.Status::Open);
            OpenCount := Line.Count();
            // No open line left: list the lines that are already submitted as unchanged.
            if OpenCount = 0 then
                Line.SetRange(Status);
            LineFilter := FilterOf(Line);
            exit(true);
        end;
        if Numbers.Count() = 0 then begin
            Line.SetRange("Time Sheet No.", Header."No.");
            Line.SetRange(Status, Line.Status::Open);
            if Line.IsEmpty() then begin
                Fail(Argument, "Bifrost Error Code ori"::PreconditionFailed, AddLinesMsg, 'lineNos', AddLinesNextTxt);
                exit(false);
            end;
            exit(true);
        end;
        foreach LineNo in Numbers do begin
            if not Line.Get(Header."No.", LineNo) then begin
                Fail(Argument, "Bifrost Error Code ori"::RecordNotFound, IdentifierMsg, 'lineNos', IdentifierNextTxt);
                exit(false);
            end;
            if Line.Status = Line.Status::Open then
                OpenCount += 1
            else
                if Line.Status <> Line.Status::Submitted then begin
                    Fail(Argument, "Bifrost Error Code ori"::InvalidLine, FixLineMsg, 'lineNos', FixLineNextTxt);
                    exit(false);
                end;
        end;
        exit(true);
    end;

    local procedure DecisionSelection(var Argument: Record "Message Argument ori"; Header: Record "Time Sheet Header"; Numbers: List of [Integer]; var LineFilter: Text; var Actionable: Integer): Boolean
    var
        Line: Record "Time Sheet Line";
        LineNo: Integer;
    begin
        Actionable := 0;
        if LineFilter = '*' then begin
            Line.SetRange("Time Sheet No.", Header."No.");
            Line.SetRange(Status, Line.Status::Submitted);
            Actionable := Line.Count();
            if Actionable = 0 then begin
                // Already approved or rejected: list those lines as unchanged.
                Line.SetRange(Status);
                if Line.IsEmpty() then
                    LineFilter := ''
                else
                    LineFilter := FilterOf(Line);
            end else
                LineFilter := FilterOf(Line);
            exit(true);
        end;
        if Numbers.Count() = 0 then
            exit(true);
        foreach LineNo in Numbers do begin
            if not Line.Get(Header."No.", LineNo) then begin
                Fail(Argument, "Bifrost Error Code ori"::RecordNotFound, IdentifierMsg, 'lineNos', IdentifierNextTxt);
                exit(false);
            end;
            if Line.Status = Line.Status::Submitted then
                Actionable += 1
            else
                if Line.Status = Line.Status::Open then begin
                    Fail(Argument, "Bifrost Error Code ori"::InvalidLine, SubmitFirstMsg, 'lineNos', SubmitFirstNextTxt);
                    exit(false);
                end;
        end;
        exit(true);
    end;

    local procedure ReadResourceChoice(var Argument: Record "Message Argument ori"; RequestJson: JsonObject; var ResourceFilter: Text; var GroupCode: Code[20]): Boolean
    var
        Entry: JsonToken;
        GroupToken: JsonToken;
        HasGroup: Boolean;
        HasNo: Boolean;
        HasNos: Boolean;
        Index: Integer;
        NosToken: JsonToken;
        NoToken: JsonToken;
        ResourceNo: Code[20];
    begin
        HasNos := RequestJson.Get('resourceNos', NosToken);
        HasNo := RequestJson.Get('resourceNo', NoToken);
        HasGroup := RequestJson.Get('resourceGroup', GroupToken);
        if (HasNos and HasNo) or (HasNos and HasGroup) or (HasNo and HasGroup) then begin
            Fail(Argument, "Bifrost Error Code ori"::ConflictingIdentifiers, OneIdentifierMsg, 'resourceNo', OneIdentifierNextTxt);
            exit(false);
        end;
        if not HasNos and not HasNo and not HasGroup then begin
            Fail(Argument, "Bifrost Error Code ori"::MissingParameter, MissingKeyMsg, 'resourceNo', MissingKeyNextTxt);
            exit(false);
        end;
        if HasNo then begin
            if not IsJsonString(NoToken) then begin
                Fail(Argument, "Bifrost Error Code ori"::InvalidParameterFormat, TypeMsg, 'resourceNo', TypeNextTxt);
                exit(false);
            end;
            ResourceFilter := NoToken.AsValue().AsText();
            if ResourceFilter = '' then begin
                Fail(Argument, "Bifrost Error Code ori"::MissingParameter, MissingKeyMsg, 'resourceNo', MissingKeyNextTxt);
                exit(false);
            end;
            exit(true);
        end;
        if HasGroup then begin
            if not IsJsonString(GroupToken) then begin
                Fail(Argument, "Bifrost Error Code ori"::InvalidParameterFormat, TypeMsg, 'resourceGroup', TypeNextTxt);
                exit(false);
            end;
            GroupCode := CopyStr(GroupToken.AsValue().AsText(), 1, MaxStrLen(GroupCode));
            exit(true);
        end;
        if not NosToken.IsArray() then begin
            Fail(Argument, "Bifrost Error Code ori"::InvalidParameterFormat, TypeMsg, 'resourceNos', TypeNextTxt);
            exit(false);
        end;
        for Index := 0 to NosToken.AsArray().Count() - 1 do begin
            NosToken.AsArray().Get(Index, Entry);
            if not IsJsonString(Entry) then begin
                Fail(Argument, "Bifrost Error Code ori"::InvalidParameterFormat, TypeMsg, 'resourceNos', TypeNextTxt);
                exit(false);
            end;
            ResourceNo := CopyStr(Entry.AsValue().AsText(), 1, MaxStrLen(ResourceNo));
            if ResourceFilter <> '' then
                ResourceFilter += '|';
            ResourceFilter += ResourceNo;
        end;
        if ResourceFilter = '' then begin
            Fail(Argument, "Bifrost Error Code ori"::MissingParameter, MissingKeyMsg, 'resourceNo', MissingKeyNextTxt);
            exit(false);
        end;
        exit(true);
    end;

    local procedure ResourcesAcceptTimeSheets(var Argument: Record "Message Argument ori"; ResourceFilter: Text; GroupCode: Code[20]): Boolean
    var
        Resource: Record Resource;
        ResourceGroup: Record "Resource Group";
        Seen: Integer;
    begin
        if not Resource.ReadPermission() then begin
            Fail(Argument, "Bifrost Error Code ori"::PermissionDenied, AssignSetMsg, '', AssignSetNextTxt);
            exit(false);
        end;
        if GroupCode <> '' then begin
            if not ResourceGroup.Get(GroupCode) then begin
                Fail(Argument, "Bifrost Error Code ori"::RecordNotFound, UseTimeSheetMsg, 'resourceGroup', UseTimeSheetNextTxt);
                exit(false);
            end;
            Resource.SetRange("Resource Group No.", GroupCode);
        end else
            Resource.SetFilter("No.", ResourceFilter);
        if Resource.FindSet() then
            repeat
                Seen += 1;
                if (not Resource."Use Time Sheet") or Resource.Blocked then begin
                    Fail(Argument, "Bifrost Error Code ori"::RecordNotFound, UseTimeSheetMsg, 'resourceNo', UseTimeSheetNextTxt);
                    exit(false);
                end;
            until Resource.Next() = 0;
        if Seen = 0 then begin
            Fail(Argument, "Bifrost Error Code ori"::RecordNotFound, UseTimeSheetMsg, 'resourceNo', UseTimeSheetNextTxt);
            exit(false);
        end;
        exit(true);
    end;

    local procedure ReadHours(var Argument: Record "Message Argument ori"; RequestJson: JsonObject; var HoursToken: JsonToken; var QtyToken: JsonToken; DateToken: JsonToken; var HoursText: Text; var NonWorking: Boolean): Boolean
    var
        DateText: Text;
        DateValueToken: JsonToken;
        Entry: JsonToken;
        HasHours: Boolean;
        HasQty: Boolean;
        HourDate: Date;
        Index: Integer;
        QtyValueToken: JsonToken;
        Quantity: Decimal;
    begin
        HasHours := RequestJson.Get('hours', HoursToken);
        HasQty := RequestJson.Get('quantity', QtyToken);
        if HasHours and HasQty then begin
            Fail(Argument, "Bifrost Error Code ori"::ConflictingIdentifiers, OneIdentifierMsg, 'hours', OneIdentifierNextTxt);
            exit(false);
        end;
        if not HasHours and not HasQty then begin
            Fail(Argument, "Bifrost Error Code ori"::MissingParameter, MissingKeyMsg, 'hours', MissingKeyNextTxt);
            exit(false);
        end;
        if HasQty then begin
            if not RequestJson.Contains('date') then begin
                Fail(Argument, "Bifrost Error Code ori"::MissingParameter, MissingKeyMsg, 'date', MissingKeyNextTxt);
                exit(false);
            end;
            if not ReadJsonDecimal(QtyToken, Quantity) then begin
                Fail(Argument, "Bifrost Error Code ori"::InvalidParameterFormat, TypeMsg, 'quantity', TypeNextTxt);
                exit(false);
            end;
            if not ReadJsonDate(DateToken, HourDate) then begin
                Fail(Argument, "Bifrost Error Code ori"::InvalidParameterFormat, TypeMsg, 'date', TypeNextTxt);
                exit(false);
            end;
            DateText := Format(HourDate, 0, 9);
            HoursText := DateText + '|' + Format(Quantity, 0, 9);
            NonWorking := Date2DWY(HourDate, 1) >= 6;
            exit(true);
        end;
        if not HoursToken.IsArray() then begin
            Fail(Argument, "Bifrost Error Code ori"::InvalidParameterFormat, TypeMsg, 'hours', TypeNextTxt);
            exit(false);
        end;
        if HoursToken.AsArray().Count() = 0 then begin
            Fail(Argument, "Bifrost Error Code ori"::MissingParameter, MissingKeyMsg, 'hours', MissingKeyNextTxt);
            exit(false);
        end;
        for Index := 0 to HoursToken.AsArray().Count() - 1 do begin
            HoursToken.AsArray().Get(Index, Entry);
            if not Entry.IsObject() then begin
                Fail(Argument, "Bifrost Error Code ori"::InvalidParameterFormat, TypeMsg, 'hours', TypeNextTxt);
                exit(false);
            end;
            if not Entry.AsObject().Get('date', DateValueToken) then begin
                Fail(Argument, "Bifrost Error Code ori"::MissingParameter, MissingKeyMsg, 'hours', MissingKeyNextTxt);
                exit(false);
            end;
            if not Entry.AsObject().Get('quantity', QtyValueToken) then begin
                Fail(Argument, "Bifrost Error Code ori"::MissingParameter, MissingKeyMsg, 'hours', MissingKeyNextTxt);
                exit(false);
            end;
            if not ReadJsonDate(DateValueToken, HourDate) then begin
                Fail(Argument, "Bifrost Error Code ori"::InvalidParameterFormat, TypeMsg, 'hours', TypeNextTxt);
                exit(false);
            end;
            if not ReadJsonDecimal(QtyValueToken, Quantity) then begin
                Fail(Argument, "Bifrost Error Code ori"::InvalidParameterFormat, TypeMsg, 'hours', TypeNextTxt);
                exit(false);
            end;
            if HoursText <> '' then
                HoursText += ';';
            HoursText += Format(HourDate, 0, 9) + '|' + Format(Quantity, 0, 9);
            if Date2DWY(HourDate, 1) >= 6 then
                NonWorking := true;
        end;
        exit(true);
    end;

    local procedure PendingLineMatches(Header: Record "Time Sheet Header"; ResourceNo: Code[20]; HasFrom: Boolean; FromDate: Date; HasTo: Boolean; ToDate: Date): Boolean
    begin
        if not SameUser(Header."Approver User ID") then
            exit(false);
        if (ResourceNo <> '') and (Header."Resource No." <> ResourceNo) then
            exit(false);
        if HasTo and (Header."Starting Date" > ToDate) then
            exit(false);
        if HasFrom and (Header."Ending Date" < FromDate) then
            exit(false);
        exit(true);
    end;

    local procedure PendingNode(Header: Record "Time Sheet Header"; Line: Record "Time Sheet Line") Node: JsonObject
    var
        Detail: Record "Time Sheet Detail";
        Hour: JsonObject;
        Hours: JsonArray;
        Total: Decimal;
    begin
        Node.Add('timeSheetNo', Header."No.");
        Node.Add('resourceNo', Header."Resource No.");
        Node.Add('startingDate', Format(Header."Starting Date", 0, 9));
        Node.Add('endingDate', Format(Header."Ending Date", 0, 9));
        Node.Add('lineNo', Line."Line No.");
        Node.Add('lineType', Format(Line.Type));
        Node.Add('jobNo', Line."Job No.");
        Node.Add('jobTaskNo', Line."Job Task No.");
        Node.Add('causeOfAbsenceCode', Line."Cause of Absence Code");
        Detail.SetRange("Time Sheet No.", Line."Time Sheet No.");
        Detail.SetRange("Time Sheet Line No.", Line."Line No.");
        if Detail.FindSet() then
            repeat
                Clear(Hour);
                Hour.Add('date', Format(Detail.Date, 0, 9));
                Hour.Add('quantity', Detail.Quantity);
                Hours.Add(Hour);
                Total += Detail.Quantity;
            until Detail.Next() = 0;
        Node.Add('hours', Hours);
        Node.Add('total', Total);
    end;

    local procedure KnownLineType(TypeName: Text): Boolean
    begin
        case LowerCase(TypeName) of
            'resource', 'job', 'service', 'absence':
                exit(true);
        end;
        exit(false);
    end;

    local procedure LineTypeFromName(TypeName: Text): Enum "Time Sheet Line Type"
    var
        Line: Record "Time Sheet Line";
    begin
        case LowerCase(TypeName) of
            'resource':
                exit(Line.Type::Resource);
            'job':
                exit(Line.Type::Job);
            'service':
                exit(Line.Type::Service);
            'absence':
                exit(Line.Type::Absence);
            else
                exit(Line.Type::Job);
        end;
    end;

    local procedure FilterOf(var Line: Record "Time Sheet Line") Result: Text
    begin
        if Line.FindSet() then
            repeat
                if Result <> '' then
                    Result += '|';
                Result += Format(Line."Line No.");
            until Line.Next() = 0;
    end;

    local procedure RespondExisting(var Argument: Record "Message Argument ori"; SheetNo: Code[20]; LineFilter: Text; Decision: Boolean)
    var
        Line: Record "Time Sheet Line";
        Lines: JsonArray;
        Response: JsonObject;
    begin
        if LineFilter <> '' then begin
            Line.SetRange("Time Sheet No.", SheetNo);
            if LineFilter <> '*' then
                Line.SetFilter("Line No.", LineFilter);
            if Line.FindSet() then
                repeat
                    Lines.Add(ExistingNode(Line, Decision));
                until Line.Next() = 0;
        end;
        Response.Add('status', 'Success');
        Response.Add('lines', Lines);
        Argument.SetResponseJson(Response);
    end;

    local procedure ExistingNode(Line: Record "Time Sheet Line"; Decision: Boolean) Node: JsonObject
    begin
        Node.Add('timeSheetNo', Line."Time Sheet No.");
        Node.Add('lineNo', Line."Line No.");
        Node.Add('status', Format(Line.Status));
        Node.Add('changed', false);
        Node.Add('lineType', Format(Line.Type));
        if Decision then
            Node.Add('decision', true);
    end;

    local procedure RespondCount(var Argument: Record "Message Argument ori"; FieldName: Text; Value: Integer)
    var
        Lines: JsonArray;
        Response: JsonObject;
    begin
        Response.Add('status', 'Success');
        Response.Add(FieldName, Value);
        Response.Add('lines', Lines);
        Argument.SetResponseJson(Response);
    end;

    local procedure RunAndRespond(var Argument: Record "Message Argument ori")
    var
        Context: Codeunit "TS Native Context ori";
        Err: Text;
        Response: JsonObject;
    begin
        // Omit Commit stays inside the caller's write transaction. Capturing the return
        // value of Codeunit.Run is illegal there, so a platform error propagates.
        if Argument."Omit Commit" then begin
            Codeunit.Run(Codeunit::"TS Native Runner ori");
            Response.ReadFrom(Context.GetResult());
            Context.Clear();
            Argument.SetResponseJson(Response);
            exit;
        end;

        // A captured Codeunit.Run cannot roll a failure back while a write transaction is
        // already open: the platform stops that transaction and hides the cause. Commit
        // first. The runner then has its own transaction, which commits or rolls back.
        if Database.IsInWriteTransaction() then
            Commit();

        if not Codeunit.Run(Codeunit::"TS Native Runner ori") then begin
            Err := GetLastErrorText();
            Context.Clear();
            if StrPos(Err, 'InvalidLine') > 0 then
                Fail(Argument, "Bifrost Error Code ori"::InvalidLine, FixLineMsg, 'lineNos', FixLineNextTxt)
            else
                Fail(Argument, "Bifrost Error Code ori"::BusinessCentralError, CopyStr(Err, 1, 250), '', RetryNextTxt);
            exit;
        end;

        Response.ReadFrom(Context.GetResult());
        Context.Clear();
        Argument.SetResponseJson(Response);
    end;

    local procedure Deny(var Argument: Record "Message Argument ori"; ReadOnly: Boolean): Boolean
    begin
        if ReadOnly then begin
            if CanReadSheets() then
                exit(false);
            Fail(Argument, "Bifrost Error Code ori"::PermissionDenied, AskPermMsg, '', AskPermNextTxt);
            exit(true);
        end;
        if CanMaintainSheets() then
            exit(false);
        Fail(Argument, "Bifrost Error Code ori"::PermissionDenied, AssignSetMsg, '', AssignSetNextTxt);
        exit(true);
    end;

    local procedure Fail(var Argument: Record "Message Argument ori"; ErrorCode: Enum "Bifrost Error Code ori"; Message: Text; Parameter: Text; NextStep: Text)
    begin
        Argument.RespondWithError(ErrorCode, Message, Parameter, '', '', NextStep);
    end;

    local procedure AllowOnly(var Argument: Record "Message Argument ori"; RequestJson: JsonObject; Allowed: List of [Text]): Boolean
    var
        KeyName: Text;
        Keys: List of [Text];
    begin
        Keys := RequestJson.Keys();
        foreach KeyName in Keys do
            if not Allowed.Contains(KeyName) then begin
                Fail(Argument, "Bifrost Error Code ori"::UnknownParameter, UnknownKeyMsg, KeyName, UnknownKeyNextTxt);
                exit(false);
            end;
        exit(true);
    end;

    local procedure CanReadSetup(): Boolean
    var
        Resource: Record Resource;
        ResourcesSetup: Record "Resources Setup";
    begin
        exit(ResourcesSetup.ReadPermission() and Resource.ReadPermission());
    end;

    local procedure SameUser(Stored: Code[50]): Boolean
    begin
        if Stored = '' then
            exit(false);
        exit(Stored = CopyStr(UserId(), 1, MaxStrLen(Stored)));
    end;

    local procedure IsJsonString(Token: JsonToken): Boolean
    var
        Raw: Text;
    begin
        if not Token.IsValue() then
            exit(false);
        Token.WriteTo(Raw);
        exit(CopyStr(DelChr(Raw, '<>', ' '), 1, 1) = '"');
    end;

    local procedure IsJsonNumber(Token: JsonToken): Boolean
    var
        First: Text[1];
        Raw: Text;
    begin
        if not Token.IsValue() then
            exit(false);
        Token.WriteTo(Raw);
        Raw := DelChr(Raw, '<>', ' ');
        First := CopyStr(Raw, 1, 1);
        exit(First in ['-', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9']);
    end;

    local procedure ReadJsonDate(Token: JsonToken; var DateValue: Date): Boolean
    begin
        if not IsJsonString(Token) then
            exit(false);
        exit(Evaluate(DateValue, Token.AsValue().AsText(), 9));
    end;

    local procedure ReadJsonInteger(Token: JsonToken; var IntValue: Integer): Boolean
    var
        DecimalValue: Decimal;
    begin
        if not IsJsonNumber(Token) then
            exit(false);
        if not Evaluate(DecimalValue, Token.AsValue().AsText(), 9) then
            exit(false);
        if DecimalValue <> Round(DecimalValue, 1) then
            exit(false);
        IntValue := DecimalValue;
        exit(true);
    end;

    local procedure ReadJsonDecimal(Token: JsonToken; var DecimalValue: Decimal): Boolean
    begin
        if not IsJsonNumber(Token) then
            exit(false);
        exit(Evaluate(DecimalValue, Token.AsValue().AsText(), 9));
    end;

    local procedure ReadJsonBoolean(Token: JsonToken; var Value: Boolean): Boolean
    var
        Raw: Text;
    begin
        if not Token.IsValue() then
            exit(false);
        Token.WriteTo(Raw);
        Raw := DelChr(Raw, '<>', ' ');
        if Raw = 'true' then begin
            Value := true;
            exit(true);
        end;
        if Raw = 'false' then begin
            Value := false;
            exit(true);
        end;
        exit(false);
    end;
}
