namespace Origo.Bifrost.Timesheets;

using Microsoft.Projects.TimeSheet;
using Origo.Bifrost;

/// <summary>Protects archived time sheets and dedicated time sheet status transitions from generic writes.</summary>
codeunit 10036872 "TS Sheet Restrict ori"
{
    Access = Internal;

    var
        ArchiveHintTok: Label 'Timesheets.TimeSheet.Archive', Locked = true;
        StatusHintTok: Label 'Timesheets.TimeSheet.Reopen, Clockify.TimeSheet.Approve, Clockify.TimeSheet.Reject', Locked = true;

    [EventSubscriber(ObjectType::Table, Database::"Message Argument ori", OnAfterIsTableWriteRestrictedForDataRecords, '', false, false)]
    local procedure OnAfterIsTableWriteRestricted(TableNo: Integer; var IsRestricted: Boolean)
    begin
        if IsArchiveTable(TableNo) then
            IsRestricted := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Message Argument ori", OnGetDedicatedMessageTypeHintForWrite, '', false, false)]
    local procedure OnGetDedicatedMessageTypeHintForWrite(TableNo: Integer; var Hint: Text)
    begin
        if IsArchiveTable(TableNo) then
            Hint := ArchiveHintTok;
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

    local procedure IsArchiveTable(TableNo: Integer): Boolean
    begin
        exit(TableNo in [Database::"Time Sheet Header Archive", Database::"Time Sheet Line Archive",
                        Database::"Time Sheet Detail Archive", Database::"Time Sheet Cmt. Line Archive"]);
    end;
}
