namespace Origo.Bifrost.Timesheets;

using Microsoft.Projects.TimeSheet;
using Origo.Bifrost;

/// <summary>Restricts generic status writes to the dedicated time-sheet decision messages.</summary>
codeunit 10036872 "TS Sheet Restrict ori"
{
    Access = Internal;

    var
        FillHintTok: Label 'Timesheets.TimeSheetLine.CopyFromPrevious, Timesheets.TimeSheetLine.CreateFromPlanning', Locked = true;
        StatusHintTok: Label 'Timesheets.TimeSheet.Submit, Timesheets.TimeSheet.Approve or Timesheets.TimeSheet.Reject', Comment = 'is-IS=Timesheets.TimeSheet.Submit, Timesheets.TimeSheet.Approve eða Timesheets.TimeSheet.Reject';

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
    [EventSubscriber(ObjectType::Table, Database::"Message Argument ori", OnAfterIsTableInsertRestrictedForDataRecords, '', false, false)]
    local procedure RestrictLineInsert(TableNo: Integer; RecRef: RecordRef; Force: Boolean; IdentityInsert: Boolean; var IsRestricted: Boolean)
    begin
        if TableNo = Database::"Time Sheet Line" then
            IsRestricted := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Message Argument ori", OnGetDedicatedMessageTypeHintForWrite, '', false, false)]
    local procedure FillHint(TableNo: Integer; var Hint: Text)
    begin
        if TableNo = Database::"Time Sheet Line" then
            Hint := FillHintTok;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Time Sheet Management", OnBeforeTimeSheetDetailInsert, '', false, false)]
    local procedure LeaveCopiedHoursEmpty(var ToTimeSheetDetail: Record "Time Sheet Detail"; FromTimeSheetDetail: Record "Time Sheet Detail"; var IsHandled: Boolean)
    var
        Context: Codeunit "TS Fill Context ori";
    begin
        if Context.IsCopyDestination(ToTimeSheetDetail."Time Sheet No.") then
            IsHandled := true;
    end;
}
