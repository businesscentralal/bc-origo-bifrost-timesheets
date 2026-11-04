namespace Origo.Bifrost.Timesheets;

/// <summary>Session-local request and result state for one isolated native time sheet operation.</summary>
codeunit 10036870 "TS Native Context ori"
{
    Access = Internal;
    SingleInstance = true;

    var
        Operation: Integer;
        StartDate: Date;
        JournalTemplate: Code[10];
        JournalBatch: Code[10];
        ResultText: Text;

    /// <summary>Drops the previous call so a later message cannot reuse it.</summary>
    procedure Clear()
    begin
        ClearAll();
    end;

    /// <summary>Stores a bulk reopen through the existing time sheet engine.</summary>
    procedure SetReopen(EndingDateTo: Date)
    begin
        ClearAll();
        Operation := 8;
        StartDate := EndingDateTo;
    end;

    /// <summary>Stores a bulk post through the existing job journal engine.</summary>
    procedure SetPost(NewJournalTemplate: Code[10]; NewJournalBatch: Code[10])
    begin
        ClearAll();
        Operation := 9;
        JournalTemplate := NewJournalTemplate;
        JournalBatch := NewJournalBatch;
    end;

    /// <summary>Stores a bulk archive through the existing time sheet engine.</summary>
    procedure SetArchive()
    begin
        ClearAll();
        Operation := 10;
    end;

    /// <summary>Returns the validated job journal template.</summary>
    procedure GetJournalTemplate(): Code[10]
    begin
        exit(JournalTemplate);
    end;

    /// <summary>Returns the validated job journal batch.</summary>
    procedure GetJournalBatch(): Code[10]
    begin
        exit(JournalBatch);
    end;

    procedure GetOperation(): Integer
    begin
        exit(Operation);
    end;

    procedure GetStartDate(): Date
    begin
        exit(StartDate);
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
