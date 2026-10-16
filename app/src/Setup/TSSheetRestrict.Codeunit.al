namespace Origo.Bifrost.Timesheets;

using Microsoft.Projects.TimeSheet;
using Origo.Bifrost;

/// <summary>
/// Blocks generic Data.Records writes that belong to the native time-sheet message types.
/// Time Sheet Header inserts are refused at table level and point at Timesheets.TimeSheet.Create.
/// Time Sheet Line Status is refused at field level and points at Submit, Approve and Reject.
/// The subscriber matches the Foundation 28.0.1 event shape (no Force argument). On that
/// foundation the table event also blocks a generic modify, not only an insert.
/// </summary>
codeunit 10036872 "TS Sheet Restrict ori"
{
    Access = Internal;

    var
        HeaderHintTok: Label 'Timesheets.TimeSheet.Create', Locked = true;
        StatusHintTok: Label 'Timesheets.TimeSheet.Submit, Timesheets.TimeSheet.Approve, or Timesheets.TimeSheet.Reject', Locked = true;

    [EventSubscriber(ObjectType::Table, Database::"Message Argument ori", OnAfterIsTableWriteRestrictedForDataRecords, '', false, false)]
    local procedure OnAfterIsTableWriteRestricted(TableNo: Integer; var IsRestricted: Boolean)
    begin
        if TableNo = Database::"Time Sheet Header" then
            IsRestricted := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Message Argument ori", OnGetDedicatedMessageTypeHintForWrite, '', false, false)]
    local procedure OnGetDedicatedMessageTypeHintForWrite(TableNo: Integer; var Hint: Text)
    begin
        if TableNo = Database::"Time Sheet Header" then
            Hint := HeaderHintTok;
    end;

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
