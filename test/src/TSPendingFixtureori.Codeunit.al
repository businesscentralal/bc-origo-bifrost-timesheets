namespace Origo.Bifrost.Timesheets.Test;

using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.TimeSheet;

/// <summary>Seeds isolated native records for issue 62 tests and owned MCP verification.</summary>
codeunit 95621 "TS Pending Fixture ori"
{
    trigger OnRun()
    begin
        Seed();
    end;

    /// <summary>Creates an isolated manager, foreign-manager and mixed-status dataset, refusing collisions.</summary>
    procedure Seed()
    var
        Resource: Record Resource;
        Header: Record "Time Sheet Header";
    begin
        if Resource.Get('TS62-REGINN') or Resource.Get('TS62-OTHER') or Header.Get('TS62-A') or Header.Get('TS62-B') then
            Error('Issue 62 fixture already exists; inspect its provenance before reuse.');
        Resource.Init();
        Resource."No." := 'TS62-REGINN';
        Resource.Name := 'Issue 62 owned verification';
        Resource."Use Time Sheet" := true;
        Resource."Time Sheet Owner User ID" := CopyStr(UserId(), 1, MaxStrLen(Resource."Time Sheet Owner User ID"));
        Resource."Time Sheet Approver User ID" := Resource."Time Sheet Owner User ID";
        Resource.Insert(false);
        Resource.Init();
        Resource."No." := 'TS62-OTHER';
        Resource.Name := 'Issue 62 other resource';
        Resource.Insert(false);
        AddHeader('TS62-A', 'TS62-REGINN', CopyStr(UserId(), 1, 50));
        AddHeader('TS62-B', 'TS62-OTHER', 'TS62-FOREIGN');
        AddLine('TS62-A', 10000, "Time Sheet Line Type"::Job, "Time Sheet Status"::Submitted, 3);
        AddLine('TS62-A', 20000, "Time Sheet Line Type"::Resource, "Time Sheet Status"::Open, 9);
        AddLine('TS62-A', 30000, "Time Sheet Line Type"::Absence, "Time Sheet Status"::Submitted, 4);
        AddLine('TS62-B', 10000, "Time Sheet Line Type"::Resource, "Time Sheet Status"::Submitted, 7);
    end;

    local procedure AddHeader(SheetNo: Code[20]; ResourceNo: Code[20]; Approver: Code[50])
    var
        Header: Record "Time Sheet Header";
    begin
        Header.Init();
        Header."No." := SheetNo;
        Header."Resource No." := ResourceNo;
        Header."Starting Date" := 20261102D;
        Header."Ending Date" := 20261108D;
        Header."Owner User ID" := CopyStr(UserId(), 1, 50);
        Header."Approver User ID" := Approver;
        Header.Insert(false);
    end;

    local procedure AddLine(SheetNo: Code[20]; LineNo: Integer; LineType: Enum "Time Sheet Line Type"; Status: Enum "Time Sheet Status"; Hours: Decimal)
    var
        Line: Record "Time Sheet Line";
        Detail: Record "Time Sheet Detail";
        DayOffset: Integer;
    begin
        Line.Init();
        Line."Time Sheet No." := SheetNo;
        Line."Line No." := LineNo;
        Line."Time Sheet Starting Date" := 20261102D;
        Line.Type := LineType;
        Line.Status := Status;
        Line.Description := 'Issue 62 owned verification';
        if LineType = LineType::Job then begin
            Line."Job No." := 'TS62-PROJECT';
            Line."Job Task No." := 'TS62-TASK';
        end;
        if LineType = LineType::Absence then
            Line."Cause of Absence Code" := 'TS62';
        Line.Insert(false);
        for DayOffset := 0 to 1 do begin
            Detail.Init();
            Detail."Time Sheet No." := SheetNo;
            Detail."Time Sheet Line No." := LineNo;
            Detail.Date := 20261102D + DayOffset;
            Detail.Type := LineType;
            Detail.Status := Status;
            Detail.Quantity := Hours + DayOffset;
            Detail.Insert(false);
        end;
    end;

    /// <summary>Deletes only records bearing the fixed issue 62 ownership identifiers.</summary>
    procedure Cleanup()
    var
        Resource: Record Resource;
        Header: Record "Time Sheet Header";
        Line: Record "Time Sheet Line";
        Detail: Record "Time Sheet Detail";
    begin
        Detail.SetFilter("Time Sheet No.", 'TS62-A|TS62-B');
        Detail.DeleteAll(false);
        Line.SetFilter("Time Sheet No.", 'TS62-A|TS62-B');
        Line.DeleteAll(false);
        Header.SetFilter("No.", 'TS62-A|TS62-B');
        Header.DeleteAll(false);
        Resource.SetFilter("No.", 'TS62-REGINN|TS62-OTHER');
        Resource.DeleteAll(false);
    end;
}
