namespace Origo.Bifrost.Timesheets;

using Microsoft.Projects.TimeSheet;
using Origo.Bifrost;

/// <summary>Restricts generic status writes to the dedicated time-sheet decision messages.</summary>
codeunit 10036872 "TS Sheet Restrict ori"
{
    Access = Internal;

    var
        StatusHintTok: Label 'Timesheets.TimeSheet.Approve or Timesheets.TimeSheet.Reject', Locked = true;

    [EventSubscriber(ObjectType::Table, Database::"Message Argument ori", OnAfterIsFieldWriteRestrictedForDataRecords, '', false, false)]
    local procedure OnAfterIsFieldWriteRestricted(TableNo: Integer; FieldNo: Integer; var IsRestricted: Boolean)
    var
        TimeSheetLine: Record "Time Sheet Line";
    begin
        if (TableNo = Database::"Time Sheet Line") and (FieldNo = TimeSheetLine.FieldNo(Status)) then
            IsRestricted := true;
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
