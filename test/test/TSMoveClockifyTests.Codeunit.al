namespace Origo.Bifrost.Timesheets.Test;

using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.UOM;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.TimeSheet;
using Origo.Bifrost;
using Origo.Bifrost.Timesheets;
using System.Security.User;
using System.TestLibraries.Utilities;

/// <summary>Issue 93: preserves Clockify bulk behavior after removing native message types.</summary>
codeunit 95637 "TS Move Clockify Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    /// <summary>Checks the retained Clockify path after the Projects move.</summary>
    [Test]
    procedure Scenario_AC02_ReopenWrongDate_RefusesWithoutWriting()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Request: JsonObject;
    begin
        // Story #93, AC02 | Time: no date-dependent setup | Risk: None
        // [GIVEN] A boolean where the optional cutoff date belongs.
        Request.Add('endingDateTo', true);
        // [WHEN] The retained Clockify handler is executed.
        Execute(TempArgument, 8, Request);
        // [THEN] The type returns a structured refusal before starting the write runner.
        AssertRefusal(TempArgument, 'InvalidParameterFormat', 'endingDateTo', 'Send the key with the documented type.');
    end;

    /// <summary>Checks the retained Clockify path after the Projects move.</summary>
    [Test]
    procedure Scenario_AC02_PostWrongTemplate_RefusesWithoutWriting()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Request: JsonObject;
    begin
        // Story #93, AC02 | Time: no date-dependent setup | Risk: None
        // [GIVEN] A numeric journal template.
        Request.Add('journalTemplate', 42);
        // [WHEN] The retained Clockify handler is executed.
        Execute(TempArgument, 9, Request);
        // [THEN] The numeric value is refused rather than coerced or truncated.
        AssertRefusal(TempArgument, 'InvalidParameterFormat', 'journalTemplate', 'Send the key with the documented type.');
    end;

    /// <summary>Checks the retained Clockify path after the Projects move.</summary>
    [Test]
    procedure Scenario_AC02_ArchiveUnknownKey_RefusesWithoutWriting()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Request: JsonObject;
    begin
        // Story #93, AC02 | Time: no date-dependent setup | Risk: None
        // [GIVEN] Archive has no supported parameters.
        Request.Add('extra', 'unexpected');
        // [WHEN] An unknown parameter is sent.
        Execute(TempArgument, 10, Request);
        // [THEN] Execution stops with the removable key named.
        AssertRefusal(TempArgument, 'UnknownParameter', 'extra', 'Remove the unknown key.');
    end;

    /// <summary>Checks the retained Clockify path after the Projects move.</summary>
    [Test]
    procedure Scenario_AC02_PostUnknownTemplate_ReturnsRecordNotFound()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Request: JsonObject;
    begin
        // Story #93, AC02 | Time: no date-dependent setup | Risk: None
        // [GIVEN] A random template that was not created.
        Request.Add('journalTemplate', CopyStr('X' + DelChr(Format(CreateGuid(), 0, 4), '=', '{}-'), 1, 10));
        Request.Add('journalBatch', 'MISSING');
        // [WHEN] Posting resolves the journal identifiers.
        Execute(TempArgument, 9, Request);
        // [THEN] No raw Get failure escapes to the caller.
        AssertRefusal(TempArgument, 'RecordNotFound', 'journalTemplate', 'Use an identifier that exists.');
    end;

    /// <summary>Checks the retained Clockify path after the Projects move.</summary>
    [Test]
    procedure Scenario_AC02_ReopenSubmittedLine_ChangesItToOpen()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Line: Record "Time Sheet Line";
        Request: JsonObject;
        Response: JsonObject;
        SheetNo: Code[20];
    begin
        // Story #93, AC02 | Time: WorkDate minus two weeks isolates the cutoff | Risk: bulk reopen
        // [GIVEN] An owned submitted line before the cutoff.
        SheetNo := CreateSheet(CreateResource(true), WorkDate() - 14, UserId());
        CreateLine(SheetNo, 10000, 'Submitted');
        Request.Add('endingDateTo', Format(WorkDate() - 8, 0, 9));
        // [WHEN] The retained Clockify handler runs through its real implementation.
        Execute(TempArgument, 8, Request);
        // [THEN] The standard approval engine reopens the line.
        Response := TempArgument.GetResponseJson();
        Assert.AreEqual('Success', ReadText(Response, 'status'), 'Clockify reopen should succeed.');
        Assert.IsTrue(Response.Contains('reopenedLines'), 'Keep the existing response count.');
        Line.Get(SheetNo, 10000);
        Assert.AreEqual(Line.Status::Open, Line.Status, 'Submitted line must be open.');
    end;

    /// <summary>Checks the retained Clockify path after the Projects move.</summary>
    [Test]
    procedure Scenario_AC02_ReopenOpenLine_LeavesItOpen()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Line: Record "Time Sheet Line";
        Request: JsonObject;
        SheetNo: Code[20];
    begin
        // Story #93, AC02 | Time: WorkDate minus two weeks | Risk: bulk reopen
        // [GIVEN] A line already in the target status.
        SheetNo := CreateSheet(CreateResource(true), WorkDate() - 14, UserId());
        CreateLine(SheetNo, 10000, 'Open');
        Request.Add('endingDateTo', Format(WorkDate() - 8, 0, 9));
        // [WHEN] Reopening the sheet.
        Execute(TempArgument, 8, Request);
        // [THEN] It remains open and the response retains the count field.
        Line.Get(SheetNo, 10000);
        Assert.AreEqual(Line.Status::Open, Line.Status, 'Already-open line stays open.');
        Assert.IsTrue(TempArgument.GetResponseJson().Contains('reopenedLines'), 'Keep the existing response shape.');
    end;

    /// <summary>Checks the retained Clockify path after the Projects move.</summary>
    [Test]
    procedure Scenario_AC02_PostEmptyJournal_ReturnsSuccessCount()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Request: JsonObject;
        Response: JsonObject;
    begin
        // Story #93, AC02 | Time: WorkDate | Risk: existing bulk posting semantics
        // [GIVEN] An owned journal template and batch.
        CreateJournal(Request);
        // [WHEN] The retained Clockify handler invokes the existing posting engine.
        Execute(TempArgument, 9, Request);
        // [THEN] Even an empty operation uses the old success shape.
        Response := TempArgument.GetResponseJson();
        Assert.AreEqual('Success', ReadText(Response, 'status'), 'Empty posting should succeed.');
        Assert.IsTrue(Response.Contains('postedLines'), 'Keep postedLines in the response.');
        Assert.IsFalse(Response.Contains('warnings'), 'The retained Clockify handler has no legacy-name warning.');
    end;

    /// <summary>Checks the retained Clockify path after the Projects move.</summary>
    [Test]
    procedure Scenario_AC02_PostUnknownBatch_ReturnsStructuredRefusal()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Request: JsonObject;
    begin
        // Story #93, AC02 | Time: no date-dependent setup | Risk: None
        // [GIVEN] A real template but an absent batch.
        CreateJournal(Request);
        Request.Replace('journalBatch', 'MISSING');
        // [WHEN] The retained Clockify handler resolves the batch.
        Execute(TempArgument, 9, Request);
        // [THEN] The caller receives a corrective next step.
        AssertRefusal(TempArgument, 'RecordNotFound', 'journalBatch', 'Use an identifier that exists.');
    end;

    /// <summary>Checks the retained Clockify path after the Projects move.</summary>
    [Test]
    procedure Scenario_AC02_ArchivePostedSheet_MovesOwnedRecord()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Header: Record "Time Sheet Header";
        HeaderArchive: Record "Time Sheet Header Archive";
        Line: Record "Time Sheet Line";
        Request: JsonObject;
        Response: JsonObject;
        SheetNo: Code[20];
    begin
        // Story #93, AC02 | Time: WorkDate minus two weeks meets archive cutoff | Risk: bulk archive
        // [GIVEN] An owned posted line on an old time sheet.
        SheetNo := CreateSheet(CreateResource(true), WorkDate() - 14, UserId());
        CreateLine(SheetNo, 10000, 'Approved');
        Line.Get(SheetNo, 10000);
        Line.Posted := true;
        Line.Modify(false);
        // [WHEN] The retained Clockify handler calls the standard archive engine.
        Execute(TempArgument, 10, Request);
        // [THEN] The fixture is archived through the BC codeunit.
        Response := TempArgument.GetResponseJson();
        Assert.AreEqual('Success', ReadText(Response, 'status'), 'Archive should succeed.');
        Assert.IsFalse(Header.Get(SheetNo), 'Active sheet must be removed.');
        Assert.IsTrue(HeaderArchive.Get(SheetNo), 'Archive must contain the owned sheet.');
    end;

    /// <summary>Checks the retained Clockify path after the Projects move.</summary>
    [Test]
    procedure Scenario_AC02_ArchiveOpenSheet_LeavesOwnedRecord()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Header: Record "Time Sheet Header";
        Request: JsonObject;
        SheetNo: Code[20];
    begin
        // Story #93, AC02 | Time: WorkDate minus two weeks | Risk: bulk archive
        // [GIVEN] An old sheet with an open line must not be archived.
        SheetNo := CreateSheet(CreateResource(true), WorkDate() - 14, UserId());
        CreateLine(SheetNo, 10000, 'Open');
        // [WHEN] Archiving eligible sheets.
        Execute(TempArgument, 10, Request);
        // [THEN] The open fixture is preserved.
        Assert.IsTrue(Header.Get(SheetNo), 'Open sheet must remain active.');
        Assert.IsTrue(TempArgument.GetResponseJson().Contains('archived'), 'Keep the old count field.');
    end;

    /// <summary>Checks the retained Clockify path after the Projects move.</summary>
    [Test]
    procedure Scenario_AC02_PostApprovedJobDetail_CreatesLedgerEntry()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Batch: Record "Job Journal Batch";
        Job: Record Job;
        JobTask: Record "Job Task";
        LedgerEntry: Record "Job Ledger Entry";
        Detail: Record "Time Sheet Detail";
        Line: Record "Time Sheet Line";
        Series: Record "No. Series";
        SeriesLine: Record "No. Series Line";
        LibraryJob: Codeunit "Library - Job";
        Request: JsonObject;
        Response: JsonObject;
        SheetNo: Code[20];
        Token: JsonToken;
    begin
        // Story #93, AC02 | Time: WorkDate for posting | Risk: real BC project posting path
        // [GIVEN] Self-created project, task, resource, journal and approved quantity.
        LibraryJob.CreateJob(Job);
        Job.Validate(Status, Job.Status::Open);
        Job.Modify(true);
        LibraryJob.CreateJobTask(Job, JobTask);
        SheetNo := CreateSheet(CreateResource(true), WorkDate(), UserId());
        CreateLine(SheetNo, 10000, 'Approved');
        Line.Get(SheetNo, 10000);
        Line.Type := Line.Type::Job;
        Line."Job No." := Job."No.";
        Line."Job Task No." := JobTask."Job Task No.";
        Line.Modify(false);
        Detail.Init();
        Detail."Time Sheet No." := SheetNo;
        Detail."Time Sheet Line No." := 10000;
        Detail.Date := WorkDate();
        Detail.CopyFromTimeSheetLine(Line);
        Detail.Validate(Quantity, 2);
        Detail.Insert(true);
        CreateJournal(Request);
        Request.Get('journalTemplate', Token);
        Batch."Journal Template Name" := CopyStr(Token.AsValue().AsText(), 1, MaxStrLen(Batch."Journal Template Name"));
        Request.Get('journalBatch', Token);
        Batch.Name := CopyStr(Token.AsValue().AsText(), 1, MaxStrLen(Batch.Name));
        Batch.Get(Batch."Journal Template Name", Batch.Name);
        Series.Init();
        Series.Code := CopyStr('X' + DelChr(Format(CreateGuid(), 0, 4), '=', '{}-'), 1, MaxStrLen(Series.Code));
        Series."Default Nos." := true;
        Series.Insert(true);
        SeriesLine.Init();
        SeriesLine."Series Code" := Series.Code;
        SeriesLine."Line No." := 10000;
        SeriesLine."Starting No." := 'W467000001';
        SeriesLine."Ending No." := 'W467999999';
        SeriesLine."Increment-by No." := 1;
        SeriesLine.Insert(true);
        Batch.Validate("No. Series", Series.Code);
        Batch.Modify(true);
        // [WHEN] The retained Clockify handler invokes the actual project posting engine.
        Execute(TempArgument, 9, Request);
        // [THEN] A real posted entry and the corresponding time sheet posting exist.
        Response := TempArgument.GetResponseJson();
        Assert.AreEqual('Success', ReadText(Response, 'status'), 'Posting must succeed through the BC engine. ' + ReadText(Response, 'error') + ' ' + ReadText(Response, 'nextStep') + ' ' + GetLastErrorText());
        Response.Get('postedLines', Token);
        Assert.AreEqual(1, Token.AsValue().AsInteger(), 'One owned detail must actually post.');
        LedgerEntry.SetRange("Job No.", Job."No.");
        Assert.IsTrue(LedgerEntry.FindFirst(), 'A project ledger entry must be posted, not merely counted.');
        Assert.AreEqual(2, LedgerEntry.Quantity, 'Posted resource quantity must match the owned detail.');
        Detail.Get(SheetNo, 10000, WorkDate());
        Assert.IsTrue(Detail.Posted, 'The BC posting path must mark the time sheet detail posted.');
    end;

    /// <summary>Checks the retained Clockify path after the Projects move.</summary>
    [Test]
    procedure Scenario_AC02_PostOverlongTemplate_IsNotTruncated()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Request: JsonObject;
        JournalToken: JsonToken;
    begin
        // Story #93, AC02 | Time: not used | Risk: truncation must not address another journal
        // [GIVEN] A real ten-character template, followed by an extra character.
        CreateJournal(Request);
        Request.Get('journalTemplate', JournalToken);
        Request.Replace('journalTemplate', JournalToken.AsValue().AsText() + 'X');
        // [WHEN] The overlong identifier is submitted.
        Execute(TempArgument, 9, Request);
        // [THEN] It is refused rather than silently resolving to the existing prefix.
        AssertRefusal(TempArgument, 'InvalidParameterFormat', 'journalTemplate', 'Send the key with the documented type.');
    end;

    local procedure CreateJournal(var Request: JsonObject)
    var
        Batch: Record "Job Journal Batch";
        JournalTemplateRecord: Record "Job Journal Template";
    begin
        JournalTemplateRecord.Init();
        JournalTemplateRecord.Name := CopyStr('X' + DelChr(Format(CreateGuid(), 0, 4), '=', '{}-'), 1, MaxStrLen(JournalTemplateRecord.Name));
        JournalTemplateRecord.Insert(true);
        Batch.Init();
        Batch."Journal Template Name" := JournalTemplateRecord.Name;
        Batch.Name := 'X93';
        Batch.Insert(true);
        Request.Add('journalTemplate', JournalTemplateRecord.Name);
        Request.Add('journalBatch', Batch.Name);
    end;

    local procedure AssertRefusal(var TempArgument: Record "Message Argument ori" temporary; ExpectedCode: Text; ExpectedParameter: Text; ExpectedNext: Text)
    var
        Response: JsonObject;
    begin
        Response := TempArgument.GetResponseJson();
        Assert.AreEqual('Error', ReadText(Response, 'status'), 'The call should be refused.');
        Assert.AreEqual(ExpectedCode, ReadText(Response, 'code'), 'Refusal code.');
        Assert.AreEqual(ExpectedParameter, ReadText(Response, 'parameter'), 'Refusal parameter.');
        Assert.AreEqual(GetExpectedNextStep(ExpectedNext), ReadText(Response, 'nextStep'), 'Refusal next step.');
    end;

    local procedure GetExpectedNextStep(EnglishText: Text): Text
    begin
        if GlobalLanguage() <> 1039 then
            exit(EnglishText);
        case EnglishText of
            'Use the retained Clockify handler.':
                exit('Notaðu innlenda heitið.');
            'Send the key with the documented type.':
                exit('Sendu lykilinn með skráðu tagi.');
            'Remove the unknown key.':
                exit('Fjarlægðu óþekkta lykilinn.');
            'Use an identifier that exists.':
                exit('Notaðu auðkenni sem er til.');
            'Assign the BIFROST Timeshts ori permission set.':
                exit('Úthlutaðu heimildasamstæðunni BIFROST Timeshts ori.');
        end;
        Error('Missing Icelandic test expectation for %1.', EnglishText);
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
        UnitOfMeasure: Record "Unit of Measure";
        LibraryResource: Codeunit "Library - Resource";
    begin
        EnsureUserSetup();
        LibraryResource.CreateResourceNew(Resource);
        Resource.Rename(CopyStr('X' + Resource."No.", 1, MaxStrLen(Resource."No.")));
        if Resource.Type <> Resource.Type::Person then
            Resource.Validate(Type, Resource.Type::Person);
        if Resource."Base Unit of Measure" = '' then begin
            if not UnitOfMeasure.Get('HOUR') then begin
                UnitOfMeasure.Init();
                UnitOfMeasure.Code := 'HOUR';
                UnitOfMeasure.Description := 'Hour';
                UnitOfMeasure.Insert(true);
            end;
            Resource.Validate("Base Unit of Measure", UnitOfMeasure.Code);
        end;
        Resource.Validate("Use Time Sheet", UseTimeSheet);
        Resource."Time Sheet Owner User ID" := CopyStr(UserId(), 1, MaxStrLen(Resource."Time Sheet Owner User ID"));
        Resource."Time Sheet Approver User ID" := Resource."Time Sheet Owner User ID";
        Resource.Modify(true);
        exit(Resource."No.");
    end;

    local procedure EnsureUserSetup()
    var
        UserSetup: Record "User Setup";
    begin
        // Standard approve and reject read User Setup for the caller before they compare the line approver.
        if UserSetup.Get(UserId()) then
            exit;
        UserSetup.Init();
        UserSetup.Validate("User ID", CopyStr(UserId(), 1, MaxStrLen(UserSetup."User ID")));
        UserSetup.Insert(true);
    end;

    local procedure CreateSheet(ResourceNo: Code[20]; StartingDate: Date; Owner: Text): Code[20]
    var
        Header: Record "Time Sheet Header";
    begin
        Header.Init();
        Header."No." := CopyStr('X93' + DelChr(Format(CreateGuid(), 0, 4), '=', '{}-'), 1, MaxStrLen(Header."No."));
        Header."Resource No." := ResourceNo;
        Header."Starting Date" := StartingDate;
        Header."Ending Date" := StartingDate + 6;
        Header."Owner User ID" := CopyStr(Owner, 1, MaxStrLen(Header."Owner User ID"));
        Header."Approver User ID" := CopyStr(Owner, 1, MaxStrLen(Header."Approver User ID"));
        Header.Insert(false);
        exit(Header."No.");
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

    // Clockify enum entries are deliberately unpublished. Exercise their retained
    // internal handlers directly, without restoring any message type registration.
    local procedure Execute(var TempArgument: Record "Message Argument ori" temporary; Operation: Integer; RequestJson: JsonObject)
    var
        ReopenHandler: Codeunit "Clockify TSheetReopen Impl ori";
        PostHandler: Codeunit "Clockify TSheetPost Impl ori";
        ArchiveHandler: Codeunit "Clockify TSheetArch Impl ori";
    begin
        TempArgument.DeleteAll();
        TempArgument.Init();
        TempArgument.ID := CreateGuid();
        TempArgument.Version := TempArgument.Version::"1.0";
        TempArgument."Omit Commit" := true;
        TempArgument.Insert();
        TempArgument.SetRequestJson(RequestJson);
        case Operation of
            8:
                ReopenHandler.ExecuteBifrostTask(TempArgument);
            9:
                PostHandler.ExecuteBifrostTask(TempArgument);
            10:
                ArchiveHandler.ExecuteBifrostTask(TempArgument);
        end;
    end;
}
