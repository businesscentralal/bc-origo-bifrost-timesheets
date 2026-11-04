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
        Operation: Integer;
        SheetNo: Code[20];
        HoursText: Text;
        CauseCode: Code[10];
        FlagNonWorking: Boolean;
        ResultText: Text;

    /// <summary>Drops the previous call so a later message cannot reuse it.</summary>
    procedure Clear()
    begin
        ClearAll();
    end;

    /// <summary>Stores an absence registration. Hours text is date|quantity pairs separated by ;.</summary>
    procedure SetAbsence(NewSheetNo: Code[20]; NewCause: Code[10]; NewHours: Text; NonWorking: Boolean)
    begin
        ClearAll();
        Operation := 6;
        SheetNo := NewSheetNo;
        CauseCode := NewCause;
        HoursText := NewHours;
        FlagNonWorking := NonWorking;
    end;

    procedure GetOperation(): Integer
    begin
        exit(Operation);
    end;

    procedure GetSheetNo(): Code[20]
    begin
        exit(SheetNo);
    end;

    procedure GetHoursText(): Text
    begin
        exit(HoursText);
    end;

    procedure GetCause(): Code[10]
    begin
        exit(CauseCode);
    end;

    procedure GetFlagNonWorking(): Boolean
    begin
        exit(FlagNonWorking);
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
