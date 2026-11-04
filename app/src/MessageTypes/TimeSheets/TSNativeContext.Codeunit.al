namespace Origo.Bifrost.Timesheets;

/// <summary>
/// Session state for one native time-sheet write. The runner reads it inside
/// Codeunit.Run so a failed write rolls back without a raw error to the caller.
/// </summary>
codeunit 10036870 "TS Native Context ori"
{
    Access = Internal;
    SingleInstance = true;

    var
        SheetNo: Code[20];
        LineFilter: Text;
        ResultText: Text;

    /// <summary>Drops the previous call so a later message cannot reuse it.</summary>
    procedure Clear()
    begin
        ClearAll();
    end;

    procedure SetSubmit(NewSheetNo: Code[20]; NewLineFilter: Text)
    begin
        ClearAll();
        SheetNo := NewSheetNo;
        LineFilter := NewLineFilter;
    end;

    procedure GetSheetNo(): Code[20]
    begin
        exit(SheetNo);
    end;

    procedure GetLineFilter(): Text
    begin
        exit(LineFilter);
    end;

    procedure SetResult(NewResult: Text)
    begin
        ResultText := NewResult;
    end;

    procedure GetResult(): Text
    begin
        exit(ResultText);
    end;
}
