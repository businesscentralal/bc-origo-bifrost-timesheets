namespace Origo.Bifrost.Timesheets;

using Microsoft.Foundation.NoSeries;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.Resources.Setup;
using Microsoft.Projects.TimeSheet;

/// <summary>
/// Write isolation for the native time-sheet message types. OnRun is started with
/// Codeunit.Run. A platform error rolls the write back and the caller maps it to a
/// clean refusal. This codeunit does not re-check the request; the manager did that.
/// </summary>
codeunit 10036871 "TS Native Runner ori"
{
    Access = Internal;

    trigger OnRun()
    var
        Context: Codeunit "TS Native Context ori";
    begin
        case Context.GetOperation() of
            1:
                Submit(Context);
            2:
                Approve(Context);
            3:
                Reject(Context);
            4:
                CopyPrevious(Context);
            5:
                CreateFromPlanning(Context);
            6:
                RegisterAbsence(Context);
            7:
                CreateSheets(Context);
            else
                Error(InvalidLineTok);
        end;
    end;

    var
        InvalidLineTok: Label 'InvalidLine', Locked = true;
        WeekTok: Label 'Week %1', Comment = '%1 = week number|is-IS=Vika %1';
        NonWorkingMsg: Label 'Hours fall on a non-working day.', Comment = 'is-IS=Klukkustundir lenda á degi sem er ekki vinnudagur.';
        NonWorkingNextTxt: Label 'Confirm the date or move the hours to a working day.', Comment = 'is-IS=Staðfestu dagsetninguna eða færðu klukkustundirnar á vinnudag.';

    local procedure Submit(Context: Codeunit "TS Native Context ori")
    var
        TimeSheetLine: Record "Time Sheet Line";
        ApprovalMgt: Codeunit "Time Sheet Approval Management";
        Lines: JsonArray;
    begin
        SelectLines(Context, TimeSheetLine);
        if TimeSheetLine.FindSet(true) then
            repeat
                if TimeSheetLine.Status = TimeSheetLine.Status::Open then begin
                    ApprovalMgt.Submit(TimeSheetLine);
                    TimeSheetLine.Get(TimeSheetLine."Time Sheet No.", TimeSheetLine."Line No.");
                    Lines.Add(LineNode(TimeSheetLine, true));
                end else
                    Lines.Add(LineNode(TimeSheetLine, false));
            until TimeSheetLine.Next() = 0;
        StoreLines(Context, Lines);
    end;

    local procedure Approve(Context: Codeunit "TS Native Context ori")
    var
        TimeSheetLine: Record "Time Sheet Line";
        ApprovalMgt: Codeunit "Time Sheet Approval Management";
        Lines: JsonArray;
    begin
        SelectLines(Context, TimeSheetLine);
        if TimeSheetLine.FindSet(true) then
            repeat
                if TimeSheetLine.Status = TimeSheetLine.Status::Submitted then begin
                    ApprovalMgt.Approve(TimeSheetLine);
                    TimeSheetLine.Get(TimeSheetLine."Time Sheet No.", TimeSheetLine."Line No.");
                    Lines.Add(LineNode(TimeSheetLine, true));
                end else
                    Lines.Add(LineNode(TimeSheetLine, false));
            until TimeSheetLine.Next() = 0;
        StoreLines(Context, Lines);
    end;

    local procedure Reject(Context: Codeunit "TS Native Context ori")
    var
        TimeSheetLine: Record "Time Sheet Line";
        ApprovalMgt: Codeunit "Time Sheet Approval Management";
        Lines: JsonArray;
    begin
        SelectLines(Context, TimeSheetLine);
        if TimeSheetLine.FindSet(true) then
            repeat
                if TimeSheetLine.Status = TimeSheetLine.Status::Submitted then begin
                    ApprovalMgt.Reject(TimeSheetLine);
                    TimeSheetLine.Get(TimeSheetLine."Time Sheet No.", TimeSheetLine."Line No.");
                    if Context.GetComment() <> '' then
                        WriteComment(TimeSheetLine, Context.GetComment());
                    Lines.Add(LineNode(TimeSheetLine, true));
                end else
                    Lines.Add(LineNode(TimeSheetLine, false));
            until TimeSheetLine.Next() = 0;
        StoreLines(Context, Lines);
    end;

    local procedure CopyPrevious(Context: Codeunit "TS Native Context ori")
    var
        Header: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetMgt: Codeunit "Time Sheet Management";
        Lines: JsonArray;
        BeforeLines: List of [Integer];
    begin
        Header.Get(Context.GetSheetNo());
        TimeSheetLine.SetRange("Time Sheet No.", Header."No.");
        if TimeSheetLine.FindSet() then
            repeat
                BeforeLines.Add(TimeSheetLine."Line No.");
            until TimeSheetLine.Next() = 0;
        TimeSheetMgt.CopyPrevTimeSheetLines(Header);
        TimeSheetLine.SetRange("Time Sheet No.", Header."No.");
        if TimeSheetLine.FindSet() then
            repeat
                Lines.Add(LineNode(TimeSheetLine, not BeforeLines.Contains(TimeSheetLine."Line No.")));
            until TimeSheetLine.Next() = 0;
        StoreCopied(Context, Lines, TimeSheetLine.Count() - BeforeLines.Count());
    end;

    local procedure CreateFromPlanning(Context: Codeunit "TS Native Context ori")
    var
        Header: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetMgt: Codeunit "Time Sheet Management";
        Lines: JsonArray;
        BeforeLines: List of [Integer];
        Created: Integer;
    begin
        Header.Get(Context.GetSheetNo());
        TimeSheetLine.SetRange("Time Sheet No.", Header."No.");
        if TimeSheetLine.FindSet() then
            repeat
                BeforeLines.Add(TimeSheetLine."Line No.");
            until TimeSheetLine.Next() = 0;
        Created := TimeSheetMgt.CreateLinesFromJobPlanning(Header);
        TimeSheetLine.SetRange("Time Sheet No.", Header."No.");
        if TimeSheetLine.FindSet() then
            repeat
                Lines.Add(LineNode(TimeSheetLine, not BeforeLines.Contains(TimeSheetLine."Line No.")));
            until TimeSheetLine.Next() = 0;
        StoreObject(Context, Lines, Created);
    end;

    local procedure RegisterAbsence(Context: Codeunit "TS Native Context ori")
    var
        Header: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        Detail: Record "Time Sheet Detail";
        Pair: Text;
        DateText: Text;
        QtyText: Text;
        Hours: JsonArray;
        Hour: JsonObject;
        Response: JsonObject;
        Warnings: JsonArray;
        Warning: JsonObject;
        WorkDateValue: Date;
        Quantity: Decimal;
        LineNo: Integer;
        PairPos: Integer;
    begin
        Header.Get(Context.GetSheetNo());
        TimeSheetLine.SetRange("Time Sheet No.", Header."No.");
        if TimeSheetLine.FindLast() then
            LineNo := TimeSheetLine."Line No." + 10000
        else
            LineNo := 10000;
        TimeSheetLine.Init();
        TimeSheetLine."Time Sheet No." := Header."No.";
        TimeSheetLine."Line No." := LineNo;
        TimeSheetLine."Time Sheet Starting Date" := Header."Starting Date";
        TimeSheetLine.Validate(Type, TimeSheetLine.Type::Absence);
        TimeSheetLine.Validate("Cause of Absence Code", Context.GetCause());
        TimeSheetLine.Insert(true);

        foreach Pair in Context.GetHoursText().Split(';') do begin
            PairPos := StrPos(Pair, '|');
            DateText := CopyStr(Pair, 1, PairPos - 1);
            QtyText := CopyStr(Pair, PairPos + 1);
            Evaluate(WorkDateValue, DateText, 9);
            Evaluate(Quantity, QtyText, 9);
            Detail.Init();
            Detail.Validate("Time Sheet No.", Header."No.");
            Detail.Validate("Time Sheet Line No.", LineNo);
            Detail.Validate(Date, WorkDateValue);
            Detail.Validate(Quantity, Quantity);
            Detail.Insert(true);
            Clear(Hour);
            Hour.Add('date', DateText);
            Hour.Add('quantity', Quantity);
            Hours.Add(Hour);
        end;

        Response.Add('status', 'Success');
        Response.Add('timeSheetNo', Header."No.");
        Response.Add('lineNo', LineNo);
        Response.Add('causeOfAbsenceCode', Context.GetCause());
        Response.Add('resourceNo', Header."Resource No.");
        Response.Add('hours', Hours);
        if Context.GetFlagNonWorking() then begin
            Warning.Add('code', 'InvalidParameter');
            Warning.Add('message', NonWorkingMsg);
            Warning.Add('parameter', 'hours');
            Warning.Add('nextStep', NonWorkingNextTxt);
            Warnings.Add(Warning);
            Response.Add('warnings', Warnings);
        end;
        Context.SetResult(JsonText(Response));
    end;

    local procedure CreateSheets(Context: Codeunit "TS Native Context ori")
    var
        Resource: Record Resource;
        ResourcesSetup: Record "Resources Setup";
        Existing: Record "Time Sheet Header";
        Header: Record "Time Sheet Header";
        NoSeries: Codeunit "No. Series";
        TimeSheetMgt: Codeunit "Time Sheet Management";
        Created: JsonArray;
        Skipped: JsonArray;
        Response: JsonObject;
        PeriodStart: Date;
        PeriodEnd: Date;
        Index: Integer;
    begin
        ResourcesSetup.Get();
        ResourcesSetup.TestField("Time Sheet Nos.");
        ApplyResourceFilter(Resource, Context);
        Resource.SetRange(Blocked, false);
        Resource.SetRange("Use Time Sheet", true);
        if Resource.FindSet() then
            repeat
                for Index := 1 to Context.GetPeriods() do begin
                    PeriodStart := Context.GetStartDate() + ((Index - 1) * 7);
                    PeriodEnd := PeriodStart + 6;
                    Existing.SetRange("Resource No.", Resource."No.");
                    Existing.SetRange("Starting Date", PeriodStart);
                    if Existing.FindFirst() then
                        Skipped.Add(SheetNode(Existing."No.", Resource."No.", PeriodStart, Existing."Ending Date"))
                    else begin
                        Header.Init();
                        Header."No." := NoSeries.GetNextNo(ResourcesSetup."Time Sheet Nos.", PeriodStart);
                        Header."Starting Date" := PeriodStart;
                        Header."Ending Date" := PeriodEnd;
                        Header.Validate("Resource No.", Resource."No.");
                        Header.Description := StrSubstNo(WeekTok, Date2DWY(PeriodStart, 2));
                        Header.Insert(true);
                        if Context.GetFromPlanning() then
                            TimeSheetMgt.CreateLinesFromJobPlanning(Header);
                        Created.Add(SheetNode(Header."No.", Resource."No.", PeriodStart, PeriodEnd));
                    end;
                end;
            until Resource.Next() = 0;
        Response.Add('status', 'Success');
        Response.Add('created', Created);
        Response.Add('skipped', Skipped);
        Context.SetResult(JsonText(Response));
    end;

    local procedure ApplyResourceFilter(var Resource: Record Resource; Context: Codeunit "TS Native Context ori")
    begin
        Resource.SetLoadFields("No.", "Use Time Sheet", Blocked, "Resource Group No.");
        if Context.GetResourceGroup() <> '' then
            Resource.SetRange("Resource Group No.", Context.GetResourceGroup())
        else
            Resource.SetFilter("No.", Context.GetResourceNosFilter());
    end;

    local procedure SelectLines(Context: Codeunit "TS Native Context ori"; var TimeSheetLine: Record "Time Sheet Line")
    begin
        TimeSheetLine.SetRange("Time Sheet No.", Context.GetSheetNo());
        if Context.GetLineFilter() <> '*' then
            TimeSheetLine.SetFilter("Line No.", Context.GetLineFilter());
    end;

    local procedure WriteComment(TimeSheetLine: Record "Time Sheet Line"; Comment: Text)
    var
        CommentLine: Record "Time Sheet Comment Line";
        LineNo: Integer;
    begin
        CommentLine.SetRange("No.", TimeSheetLine."Time Sheet No.");
        CommentLine.SetRange("Time Sheet Line No.", TimeSheetLine."Line No.");
        if CommentLine.FindLast() then
            LineNo := CommentLine."Line No." + 10000
        else
            LineNo := 10000;
        CommentLine.Init();
        CommentLine."No." := TimeSheetLine."Time Sheet No.";
        CommentLine."Time Sheet Line No." := TimeSheetLine."Line No.";
        CommentLine."Line No." := LineNo;
        CommentLine.Date := TimeSheetLine."Time Sheet Starting Date";
        CommentLine.Comment := CopyStr(Comment, 1, MaxStrLen(CommentLine.Comment));
        CommentLine.Insert(true);
    end;

    local procedure LineNode(TimeSheetLine: Record "Time Sheet Line"; Changed: Boolean) Node: JsonObject
    begin
        Node.Add('timeSheetNo', TimeSheetLine."Time Sheet No.");
        Node.Add('lineNo', TimeSheetLine."Line No.");
        Node.Add('status', Format(TimeSheetLine.Status));
        Node.Add('changed', Changed);
        Node.Add('lineType', Format(TimeSheetLine.Type));
    end;

    local procedure SheetNode(TimeSheetNo: Code[20]; ResourceNo: Code[20]; StartingDate: Date; EndingDate: Date) Node: JsonObject
    begin
        Node.Add('timeSheetNo', TimeSheetNo);
        Node.Add('resourceNo', ResourceNo);
        Node.Add('startingDate', Format(StartingDate, 0, 9));
        Node.Add('endingDate', Format(EndingDate, 0, 9));
    end;

    local procedure StoreCopied(Context: Codeunit "TS Native Context ori"; Lines: JsonArray; Copied: Integer)
    var
        Response: JsonObject;
    begin
        Response.Add('status', 'Success');
        Response.Add('copied', Copied);
        Response.Add('lines', Lines);
        Context.SetResult(JsonText(Response));
    end;

    local procedure StoreLines(Context: Codeunit "TS Native Context ori"; Lines: JsonArray)
    var
        Response: JsonObject;
    begin
        Response.Add('status', 'Success');
        Response.Add('lines', Lines);
        Context.SetResult(JsonText(Response));
    end;

    local procedure StoreObject(Context: Codeunit "TS Native Context ori"; Lines: JsonArray; Created: Integer)
    var
        Response: JsonObject;
    begin
        Response.Add('status', 'Success');
        Response.Add('created', Created);
        Response.Add('lines', Lines);
        Context.SetResult(JsonText(Response));
    end;

    local procedure JsonText(Response: JsonObject): Text
    var
        Result: Text;
    begin
        Response.WriteTo(Result);
        exit(Result);
    end;
}
