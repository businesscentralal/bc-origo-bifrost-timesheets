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

    /// <summary>Handles SetSubmit for the Submit message contract.</summary>
    procedure SetSubmit(NewSheetNo: Code[20]; NewLineFilter: Text)
    begin
        ClearAll();
        SheetNo := NewSheetNo;
        LineFilter := NewLineFilter;
    end;

    /// <summary>Returns GetSheetNo for the Submit message contract.</summary>
    procedure GetSheetNo(): Code[20]
    begin
        exit(SheetNo);
    end;

    /// <summary>Returns GetLineFilter for the Submit message contract.</summary>
    procedure GetLineFilter(): Text
    begin
        exit(LineFilter);
    end;

    /// <summary>Handles SetResult for the Submit message contract.</summary>
    procedure SetResult(NewResult: Text)
    begin
        ResultText := NewResult;
    end;

    /// <summary>Returns GetResult for the Submit message contract.</summary>
    procedure GetResult(): Text
    begin
        exit(ResultText);
    end;
}
