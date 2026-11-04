namespace Origo.Bifrost.Timesheets;

using Microsoft.Projects.TimeSheet;
using Origo.Bifrost;

/// <summary>Protects native line creation and leaves daily hours empty only during a copy message.</summary>
codeunit 10036872 "TS Sheet Restrict ori"
{
    Access = Internal;

    var
        FillHintTok: Label 'Timesheets.TimeSheetLine.CopyFromPrevious, Timesheets.TimeSheetLine.CreateFromPlanning', Locked = true;

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
        Context: Codeunit "TS Native Context ori";
    begin
        if Context.IsCopyDestination(ToTimeSheetDetail."Time Sheet No.") then
            IsHandled := true;
    end;
}
