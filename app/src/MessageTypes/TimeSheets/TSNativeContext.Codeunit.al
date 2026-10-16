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
        LineFilter: Text;
        CommentText: Text;
        HoursText: Text;
        CauseCode: Code[10];
        StartDate: Date;
        Periods: Integer;
        ResourceNosFilter: Text;
        ResourceGroupCode: Code[20];
        FromPlanning: Boolean;
        FlagNonWorking: Boolean;
        ResultText: Text;

    /// <summary>Drops the previous call so a later message cannot reuse it.</summary>
    procedure Clear()
    begin
        ClearAll();
    end;

    /// <summary>Stores a submit of the given lines. Line filter * means every open line.</summary>
    procedure SetSubmit(NewSheetNo: Code[20]; NewLineFilter: Text)
    begin
        ClearAll();
        Operation := 1;
        SheetNo := NewSheetNo;
        LineFilter := NewLineFilter;
    end;

    /// <summary>Stores an approval of the given lines. Line filter * means every submitted line.</summary>
    procedure SetApprove(NewSheetNo: Code[20]; NewLineFilter: Text)
    begin
        ClearAll();
        Operation := 2;
        SheetNo := NewSheetNo;
        LineFilter := NewLineFilter;
    end;

    /// <summary>Stores a rejection of the given lines and an optional comment.</summary>
    procedure SetReject(NewSheetNo: Code[20]; NewLineFilter: Text; NewComment: Text)
    begin
        ClearAll();
        Operation := 3;
        SheetNo := NewSheetNo;
        LineFilter := NewLineFilter;
        CommentText := NewComment;
    end;

    /// <summary>Stores a copy of the previous sheet onto this sheet.</summary>
    procedure SetCopy(NewSheetNo: Code[20])
    begin
        ClearAll();
        Operation := 4;
        SheetNo := NewSheetNo;
    end;

    /// <summary>Stores creation of lines from project planning.</summary>
    procedure SetPlanning(NewSheetNo: Code[20])
    begin
        ClearAll();
        Operation := 5;
        SheetNo := NewSheetNo;
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

    /// <summary>Stores creation of weekly sheets for a resource filter.</summary>
    procedure SetCreate(NewStart: Date; NewPeriods: Integer; NewResourceNos: Text; NewGroup: Code[20]; NewFromPlanning: Boolean)
    begin
        ClearAll();
        Operation := 7;
        StartDate := NewStart;
        Periods := NewPeriods;
        ResourceNosFilter := NewResourceNos;
        ResourceGroupCode := NewGroup;
        FromPlanning := NewFromPlanning;
    end;

    procedure GetOperation(): Integer
    begin
        exit(Operation);
    end;

    procedure GetSheetNo(): Code[20]
    begin
        exit(SheetNo);
    end;

    procedure GetLineFilter(): Text
    begin
        exit(LineFilter);
    end;

    procedure GetComment(): Text
    begin
        exit(CommentText);
    end;

    procedure GetHoursText(): Text
    begin
        exit(HoursText);
    end;

    procedure GetCause(): Code[10]
    begin
        exit(CauseCode);
    end;

    procedure GetStartDate(): Date
    begin
        exit(StartDate);
    end;

    procedure GetPeriods(): Integer
    begin
        exit(Periods);
    end;

    procedure GetResourceNosFilter(): Text
    begin
        exit(ResourceNosFilter);
    end;

    procedure GetResourceGroup(): Code[20]
    begin
        exit(ResourceGroupCode);
    end;

    procedure GetFromPlanning(): Boolean
    begin
        exit(FromPlanning);
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
