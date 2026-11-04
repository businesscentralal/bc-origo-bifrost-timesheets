namespace Origo.Bifrost.Timesheets;

using Microsoft.Projects.TimeSheet;
using Origo.Bifrost;

/// <summary>Restricts generic status writes to the dedicated time-sheet decision messages.</summary>
codeunit 10036872 "TS Sheet Restrict ori"
{
    Access = Internal;

    var
        StatusHintTok: Label 'Timesheets.TimeSheet.Submit, Timesheets.TimeSheet.Approve or Timesheets.TimeSheet.Reject', Comment = 'is-IS=Timesheets.TimeSheet.Submit, Timesheets.TimeSheet.Approve eða Timesheets.TimeSheet.Reject';

    [EventSubscriber(ObjectType::Table, Database::"Message Argument ori", OnAfterIsFieldWriteRestrictedForDataRecords, '', false, false)]
    local procedure OnAfterIsFieldWriteRestricted(TableNo: Integer; FieldNo: Integer; var IsRestricted: Boolean)
    var
        TimeSheetLine: Record "Time Sheet Line";
    begin
        if (TableNo = Database::"Time Sheet Line") and (FieldNo = TimeSheetLine.FieldNo(Status)) then
            IsRestricted := true;
    end;

    /// <summary>Preserves the status workflow hint when a table-wide guard refuses the write before the field guard.</summary>
    [EventSubscriber(ObjectType::Table, Database::"Message Argument ori", OnGetDedicatedMessageTypeHintForWrite, '', false, false)]
    local procedure OnGetDedicatedMessageTypeHintForWrite(TableNo: Integer; var Hint: Text)
    begin
        if TableNo = Database::"Time Sheet Line" then
            Hint := StatusHintTok;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Message Argument ori", OnGetDedicatedMessageTypeHintForField, '', false, false)]
    local procedure OnGetDedicatedMessageTypeHintForField(TableNo: Integer; FieldNo: Integer; var Hint: Text)
    var
        TimeSheetLine: Record "Time Sheet Line";
    begin
        if (TableNo = Database::"Time Sheet Line") and (FieldNo = TimeSheetLine.FieldNo(Status)) then
            Hint := StatusHintTok;
    end;
}
