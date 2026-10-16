namespace Origo.Bifrost.Timesheets.Test;

using Microsoft.Foundation.NoSeries;
using Microsoft.HumanResources.Absence;
using Microsoft.HumanResources.Employee;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.Resources.Setup;
using Microsoft.Projects.TimeSheet;
using Origo.Bifrost;
using Origo.Bifrost.Timesheets;
using System.TestLibraries.Utilities;

/// <summary>Behavior tests for the native time sheet message types.</summary>
codeunit 95615 "TS Native Sheet Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    [Test]
    procedure Submit_MissingKey_IsMissingParameter()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Request: JsonObject;
    begin
        Execute(TempArgument, "Message Type ori"::"Timesheets.TimeSheet.Submit", Request);
        AssertRefusal(TempArgument, 'MissingParameter', 'timeSheetNo', 'Send the missing key.');
    end;

    [Test]
    procedure Submit_UnknownKey_IsRefused()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Request: JsonObject;
    begin
        Request.Add('timeSheetNo', 'TS');
        Request.Add('extra', 'x');
        Execute(TempArgument, "Message Type ori"::"Timesheets.TimeSheet.Submit", Request);
        AssertRefusal(TempArgument, 'UnknownParameter', 'extra', 'Remove the unknown key.');
    end;

    [Test]
    procedure Submit_NotOwner_WritesNothing()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Line: Record "Time Sheet Line";
        Request: JsonObject;
        SheetNo: Code[20];
    begin
        SheetNo := CreateSheet(CreateResource(true), WorkDate(), 'OTHER');
        CreateLine(SheetNo, 10000, 'Open');
        Request.Add('timeSheetNo', SheetNo);
        Execute(TempArgument, "Message Type ori"::"Timesheets.TimeSheet.Submit", Request);
        AssertRefusal(TempArgument, 'PermissionDenied', 'timeSheetNo', 'Only the owner can submit; ask the owner.');
        Line.Get(SheetNo, 10000);
        Assert.AreEqual('Open', Format(Line.Status), 'A refused submit must leave the line open.');
    end;

    [Test]
    procedure Submit_NoOpenLines_IsPreconditionFailed()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Request: JsonObject;
        SheetNo: Code[20];
    begin
        SheetNo := CreateSheet(CreateResource(true), WorkDate(), UserId());
        Request.Add('timeSheetNo', SheetNo);
        Execute(TempArgument, "Message Type ori"::"Timesheets.TimeSheet.Submit", Request);
        AssertRefusal(TempArgument, 'PreconditionFailed', 'lineNos', 'Add lines first.');
    end;

    [Test]
    procedure Submit_OpenLine_ThenAlreadySubmitted()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Line: Record "Time Sheet Line";
        Request: JsonObject;
        Response: JsonObject;
        SheetNo: Code[20];
    begin
        SheetNo := CreateSheet(CreateResource(true), WorkDate(), UserId());
        CreateLine(SheetNo, 10000, 'Open');
        Request.Add('timeSheetNo', SheetNo);
        Execute(TempArgument, "Message Type ori"::"Timesheets.TimeSheet.Submit", Request);
        Response := TempArgument.GetResponseJson();
        Assert.AreEqual('Success', ReadText(Response, 'status'), 'Submit should succeed.');
        Line.Get(SheetNo, 10000);
        Assert.AreEqual('Submitted', Format(Line.Status), 'The open line should be submitted.');

        Execute(TempArgument, "Message Type ori"::"Timesheets.TimeSheet.Submit", Request);
        Response := TempArgument.GetResponseJson();
        Assert.AreEqual('Success', ReadText(Response, 'status'), 'Submitting again should succeed.');
        Assert.IsTrue(ReadText(Response, 'lines').Contains('"changed":false') or not Response.Contains('lines'), 'An already submitted explicit selection is unchanged.');
    end;

    [Test]
    procedure Submit_BadJobLine_IsInvalidLine()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Line: Record "Time Sheet Line";
        Request: JsonObject;
        SheetNo: Code[20];
    begin
        SheetNo := CreateSheet(CreateResource(true), WorkDate(), UserId());
        Line.Init();
        Line."Time Sheet No." := SheetNo;
        Line."Line No." := 10000;
        Line."Time Sheet Starting Date" := WorkDate();
        Line.Type := Line.Type::Job;
        Line.Status := Line.Status::Open;
        Line.Insert(false);
        Request.Add('timeSheetNo', SheetNo);
        Execute(TempArgument, "Message Type ori"::"Timesheets.TimeSheet.Submit", Request);
        AssertRefusal(TempArgument, 'InvalidLine', 'lineNos', 'Fix the line and submit again.');
        Line.Get(SheetNo, 10000);
        Assert.AreEqual('Open', Format(Line.Status), 'A failed submit must roll the line back.');
    end;

    [Test]
    procedure Create_BadWeekday_WritesNothing()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Header: Record "Time Sheet Header";
        ResourcesSetup: Record "Resources Setup";
        Request: JsonObject;
        ResourceNo: Code[20];
        StartingDate: Date;
        Before: Integer;
    begin
        EnsureSetup(ResourcesSetup);
        ResourceNo := CreateResource(true);
        StartingDate := WorkDate();
        while Date2DWY(StartingDate, 1) = (ResourcesSetup."Time Sheet First Weekday" + 1) do
            StartingDate += 1;
        Before := Header.Count();
        Request.Add('startingDate', Format(StartingDate, 0, 9));
        Request.Add('resourceNo', ResourceNo);
        Execute(TempArgument, "Message Type ori"::"Timesheets.TimeSheet.Create", Request);
        AssertRefusal(TempArgument, 'PreconditionFailed', 'startingDate', 'Use the first weekday named in the refusal.');
        Assert.AreEqual(Before, Header.Count(), 'A bad weekday must not create a sheet.');
    end;

    [Test]
    procedure Create_TooManyPeriods_IsLimitExceeded()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Request: JsonObject;
    begin
        Request.Add('startingDate', '2026-06-01');
        Request.Add('numberOfPeriods', 53);
        Request.Add('resourceNo', 'RES');
        Execute(TempArgument, "Message Type ori"::"Timesheets.TimeSheet.Create", Request);
        AssertRefusal(TempArgument, 'LimitExceeded', 'numberOfPeriods', 'Split the call.');
    end;

    [Test]
    procedure Create_UnknownResource_IsRecordNotFound()
    var
        TempArgument: Record "Message Argument ori" temporary;
        ResourcesSetup: Record "Resources Setup";
        Request: JsonObject;
        StartingDate: Date;
    begin
        EnsureSetup(ResourcesSetup);
        StartingDate := NextWeekday(ResourcesSetup."Time Sheet First Weekday" + 1);
        Request.Add('startingDate', Format(StartingDate, 0, 9));
        Request.Add('resourceNo', 'NO-SUCH-W17');
        Execute(TempArgument, "Message Type ori"::"Timesheets.TimeSheet.Create", Request);
        AssertRefusal(TempArgument, 'RecordNotFound', 'resourceNo', 'Turn on Use Time Sheet on the resource.');
    end;

    [Test]
    procedure Create_OnePeriod_ThenSkipped()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Header: Record "Time Sheet Header";
        ResourcesSetup: Record "Resources Setup";
        Request: JsonObject;
        Response: JsonObject;
        ResourceNo: Code[20];
        StartingDate: Date;
    begin
        EnsureSetup(ResourcesSetup);
        EnsureNumberSeries(ResourcesSetup);
        ResourceNo := CreateResource(true);
        StartingDate := NextWeekday(ResourcesSetup."Time Sheet First Weekday" + 1);
        Request.Add('startingDate', Format(StartingDate, 0, 9));
        Request.Add('numberOfPeriods', 1);
        Request.Add('resourceNo', ResourceNo);
        Execute(TempArgument, "Message Type ori"::"Timesheets.TimeSheet.Create", Request);
        Response := TempArgument.GetResponseJson();
        Assert.AreEqual('Success', ReadText(Response, 'status'), 'Create should succeed.');
        Header.SetRange("Resource No.", ResourceNo);
        Header.SetRange("Starting Date", StartingDate);
        Assert.AreEqual(1, Header.Count(), 'One sheet should be created.');

        Execute(TempArgument, "Message Type ori"::"Timesheets.TimeSheet.Create", Request);
        Response := TempArgument.GetResponseJson();
        Assert.AreEqual('Success', ReadText(Response, 'status'), 'Creating the same period again should succeed.');
        Assert.IsTrue(ReadText(Response, 'skipped').Contains(ResourceNo), 'The existing sheet should be listed under skipped.');
        Assert.AreEqual(1, Header.Count(), 'The second call must not add another sheet.');
    end;

    [Test]
    procedure Approve_NotApprover_WritesNothing()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Line: Record "Time Sheet Line";
        Request: JsonObject;
        SheetNo: Code[20];
    begin
        SheetNo := CreateSheet(CreateResource(true), WorkDate(), UserId());
        SetApprover(SheetNo, 'OTHER');
        CreateLine(SheetNo, 10000, 'Submitted');
        Request.Add('timeSheetNo', SheetNo);
        Execute(TempArgument, "Message Type ori"::"Timesheets.TimeSheet.Approve", Request);
        AssertRefusal(TempArgument, 'PermissionDenied', 'timeSheetNo', 'Only the approver named on the time sheet can approve.');
        Line.Get(SheetNo, 10000);
        Assert.AreEqual('Submitted', Format(Line.Status), 'A refused approval must leave the line submitted.');
    end;

    [Test]
    procedure Approve_OpenLine_MustBeSubmittedFirst()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Request: JsonObject;
        Lines: JsonArray;
        SheetNo: Code[20];
    begin
        SheetNo := CreateSheet(CreateResource(true), WorkDate(), UserId());
        SetApprover(SheetNo, UserId());
        CreateLine(SheetNo, 10000, 'Open');
        Lines.Add(10000);
        Request.Add('timeSheetNo', SheetNo);
        Request.Add('lineNos', Lines);
        Execute(TempArgument, "Message Type ori"::"Timesheets.TimeSheet.Approve", Request);
        AssertRefusal(TempArgument, 'InvalidLine', 'lineNos', 'Submit it first with Timesheets.TimeSheet.Submit.');
    end;

    [Test]
    procedure Approve_Submitted_ThenUnchanged()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Line: Record "Time Sheet Line";
        Request: JsonObject;
        Response: JsonObject;
        SheetNo: Code[20];
    begin
        SheetNo := CreateSheet(CreateResource(true), WorkDate(), UserId());
        SetApprover(SheetNo, UserId());
        CreateLine(SheetNo, 10000, 'Submitted');
        Request.Add('timeSheetNo', SheetNo);
        Execute(TempArgument, "Message Type ori"::"Timesheets.TimeSheet.Approve", Request);
        Response := TempArgument.GetResponseJson();
        Assert.AreEqual('Success', ReadText(Response, 'status'), 'Approve should succeed.');
        Line.Get(SheetNo, 10000);
        Assert.AreEqual('Approved', Format(Line.Status), 'The submitted line should be approved.');

        Execute(TempArgument, "Message Type ori"::"Timesheets.TimeSheet.Approve", Request);
        Response := TempArgument.GetResponseJson();
        Assert.AreEqual('Success', ReadText(Response, 'status'), 'Approving again should succeed.');
        Assert.IsFalse(ReadText(Response, 'lines').Contains('"changed":true'), 'An already approved line should not change.');
    end;

    [Test]
    procedure Reject_WithComment()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Line: Record "Time Sheet Line";
        Comment: Record "Time Sheet Comment Line";
        Request: JsonObject;
        SheetNo: Code[20];
    begin
        SheetNo := CreateSheet(CreateResource(true), WorkDate(), UserId());
        SetApprover(SheetNo, UserId());
        CreateLine(SheetNo, 10000, 'Submitted');
        Request.Add('timeSheetNo', SheetNo);
        Request.Add('comment', 'Please split the job.');
        Execute(TempArgument, "Message Type ori"::"Timesheets.TimeSheet.Reject", Request);
        Assert.AreEqual('Success', ReadText(TempArgument.GetResponseJson(), 'status'), 'Reject should succeed.');
        Line.Get(SheetNo, 10000);
        Assert.AreEqual('Rejected', Format(Line.Status), 'The line should be rejected.');
        Comment.SetRange("No.", SheetNo);
        Comment.SetRange("Time Sheet Line No.", 10000);
        Assert.IsFalse(Comment.IsEmpty(), 'The comment should be stored on the line.');
    end;

    [Test]
    procedure Pending_BadRange_AndEmpty()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Request: JsonObject;
        Response: JsonObject;
    begin
        Request.Add('from', '2026-06-10');
        Request.Add('to', '2026-06-01');
        Execute(TempArgument, "Message Type ori"::"Timesheets.PendingApproval.Get", Request);
        AssertRefusal(TempArgument, 'InvalidParameter', 'from', 'Use from <= to.');

        Clear(Request);
        Request.Add('from', '1990-01-01');
        Request.Add('to', '1990-01-07');
        Execute(TempArgument, "Message Type ori"::"Timesheets.PendingApproval.Get", Request);
        Response := TempArgument.GetResponseJson();
        Assert.AreEqual('Success', ReadText(Response, 'status'), 'An empty approval list should succeed.');
        Assert.IsTrue(ReadText(Response, 'lines').Contains('[]'), 'The 1990 range should return no lines.');
    end;

    [Test]
    procedure Pending_ShowsSubmittedLineForApprover()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Request: JsonObject;
        Response: JsonObject;
        SheetNo: Code[20];
        ResourceNo: Code[20];
    begin
        ResourceNo := CreateResource(true);
        SheetNo := CreateSheet(ResourceNo, WorkDate(), UserId());
        SetApprover(SheetNo, UserId());
        CreateLine(SheetNo, 10000, 'Submitted');
        Request.Add('resource', ResourceNo);
        Execute(TempArgument, "Message Type ori"::"Timesheets.PendingApproval.Get", Request);
        Response := TempArgument.GetResponseJson();
        Assert.AreEqual('Success', ReadText(Response, 'status'), 'Pending approval should succeed.');
        Assert.IsTrue(ReadText(Response, 'lines').Contains(SheetNo), 'The submitted line should be in the list.');
    end;

    local procedure Execute(var TempArgument: Record "Message Argument ori" temporary; MessageType: Enum "Message Type ori"; RequestJson: JsonObject)
    var
        MsgInterface: Interface "Msg Interface ori";
    begin
        TempArgument.Init();
        TempArgument."Type" := MessageType;
        TempArgument."Version" := TempArgument."Version"::"1.0";
        TempArgument.Insert();
        TempArgument.SetRequestJson(RequestJson);
        MsgInterface := TempArgument.GetMessageTypeInterface();
        MsgInterface.ExecuteBifrostTask(TempArgument);
    end;

    local procedure AssertRefusal(var TempArgument: Record "Message Argument ori" temporary; ExpectedCode: Text; ExpectedParameter: Text; ExpectedNext: Text)
    var
        Response: JsonObject;
    begin
        Response := TempArgument.GetResponseJson();
        Assert.AreEqual('Error', ReadText(Response, 'status'), 'The call should be refused.');
        Assert.AreEqual(ExpectedCode, ReadText(Response, 'code'), 'Refusal code.');
        Assert.AreEqual(ExpectedParameter, ReadText(Response, 'parameter'), 'Refusal parameter.');
        Assert.AreEqual(ExpectedNext, ReadText(Response, 'nextStep'), 'Refusal next step.');
    end;

    local procedure ReadText(Response: JsonObject; Name: Text): Text
    var
        Token: JsonToken;
        Nested: Text;
    begin
        if not Response.Get(Name, Token) then
            exit('');
        if Token.IsValue() then
            exit(Token.AsValue().AsText());
        Token.WriteTo(Nested);
        exit(Nested);
    end;

    local procedure CreateResource(UseTimeSheet: Boolean): Code[20]
    var
        Resource: Record Resource;
        LibraryResource: Codeunit "Library - Resource";
    begin
        LibraryResource.CreateResourceNew(Resource);
        Resource.Validate("Use Time Sheet", UseTimeSheet);
        Resource."Time Sheet Owner User ID" := CopyStr(UserId(), 1, MaxStrLen(Resource."Time Sheet Owner User ID"));
        Resource."Time Sheet Approver User ID" := Resource."Time Sheet Owner User ID";
        Resource.Modify(true);
        exit(Resource."No.");
    end;

    local procedure CreateSheet(ResourceNo: Code[20]; StartingDate: Date; Owner: Text): Code[20]
    var
        Header: Record "Time Sheet Header";
    begin
        Header.Init();
        Header."No." := CopyStr('W17' + DelChr(Format(CreateGuid(), 0, 4), '=', '{}-'), 1, MaxStrLen(Header."No."));
        Header."Resource No." := ResourceNo;
        Header."Starting Date" := StartingDate;
        Header."Ending Date" := StartingDate + 6;
        Header."Owner User ID" := CopyStr(Owner, 1, MaxStrLen(Header."Owner User ID"));
        Header."Approver User ID" := CopyStr(Owner, 1, MaxStrLen(Header."Approver User ID"));
        Header.Insert(false);
        exit(Header."No.");
    end;

    local procedure SetApprover(SheetNo: Code[20]; Approver: Text)
    var
        Header: Record "Time Sheet Header";
    begin
        Header.Get(SheetNo);
        Header."Approver User ID" := CopyStr(Approver, 1, MaxStrLen(Header."Approver User ID"));
        Header.Modify(false);
    end;

    local procedure CreateLine(SheetNo: Code[20]; LineNo: Integer; StatusName: Text)
    var
        Line: Record "Time Sheet Line";
        Header: Record "Time Sheet Header";
    begin
        Header.Get(SheetNo);
        Line.Init();
        Line."Time Sheet No." := SheetNo;
        Line."Line No." := LineNo;
        Line."Time Sheet Starting Date" := Header."Starting Date";
        Line.Type := Line.Type::Resource;
        case StatusName of
            'Submitted':
                Line.Status := Line.Status::Submitted;
            'Approved':
                Line.Status := Line.Status::Approved;
            else
                Line.Status := Line.Status::Open;
        end;
        Line.Insert(false);
    end;

    local procedure EnsureSetup(var ResourcesSetup: Record "Resources Setup")
    begin
        if not ResourcesSetup.Get() then begin
            ResourcesSetup.Init();
            ResourcesSetup.Insert();
        end;
    end;

    local procedure EnsureNumberSeries(var ResourcesSetup: Record "Resources Setup")
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        if ResourcesSetup."Time Sheet Nos." <> '' then
            exit;
        if not NoSeries.Get('TSNW17') then begin
            NoSeries.Init();
            NoSeries.Code := 'TSNW17';
            NoSeries."Default Nos." := true;
            NoSeries.Insert();
        end;
        if not NoSeriesLine.Get('TSNW17', 10000) then begin
            NoSeriesLine.Init();
            NoSeriesLine."Series Code" := 'TSNW17';
            NoSeriesLine."Line No." := 10000;
            NoSeriesLine."Starting No." := 'TSN00001';
            NoSeriesLine."Increment-by No." := 1;
            NoSeriesLine.Open := true;
            NoSeriesLine.Insert();
        end;
        ResourcesSetup."Time Sheet Nos." := 'TSNW17';
        ResourcesSetup.Modify();
    end;

    local procedure NextWeekday(Expected: Integer): Date
    var
        StartingDate: Date;
    begin
        StartingDate := WorkDate();
        while Date2DWY(StartingDate, 1) <> Expected do
            StartingDate += 1;
        exit(StartingDate);
    end;
}
