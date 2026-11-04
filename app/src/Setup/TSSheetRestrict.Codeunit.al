namespace Origo.Bifrost.Timesheets;

using Microsoft.Projects.TimeSheet;
using Origo.Bifrost;

/// <summary>Restricts generic status writes to the dedicated time-sheet decision messages.</summary>
codeunit 10036872 "TS Sheet Restrict ori"
{
    Access = Internal;

    var
        ReopenHintTok: Label 'Timesheets.TimeSheet.Reopen', Locked = true;
        PostingHintTok: Label 'Timesheets.TimeSheet.Post', Locked = true;
        ArchiveHintTok: Label 'Timesheets.TimeSheet.Archive', Locked = true;
        StatusHintTok: Label 'Timesheets.TimeSheet.Approve or Timesheets.TimeSheet.Reject', Comment = 'is-IS=Timesheets.TimeSheet.Approve eða Timesheets.TimeSheet.Reject';

    [EventSubscriber(ObjectType::Table, Database::"Message Argument ori", OnAfterIsFieldWriteRestrictedForDataRecords, '', false, false)]
    local procedure OnAfterIsFieldWriteRestricted(TableNo: Integer; FieldNo: Integer; var IsRestricted: Boolean)
    begin
        if ManagedFieldHint(TableNo, FieldNo) <> '' then
            IsRestricted := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Message Argument ori", OnGetDedicatedMessageTypeHintForField, '', false, false)]
    local procedure OnGetDedicatedMessageTypeHintForField(TableNo: Integer; FieldNo: Integer; var Hint: Text)
    var
        ManagedHint: Text;
    begin
        ManagedHint := ManagedFieldHint(TableNo, FieldNo);
        if ManagedHint <> '' then
            Hint := ManagedHint;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Message Argument ori", OnAfterIsTableWriteRestrictedForDataRecords, '', false, false)]
    local procedure OnAfterIsTableWriteRestricted(TableNo: Integer; var IsRestricted: Boolean)
    begin
        if IsArchiveTable(TableNo) or (TableNo = Database::"Time Sheet Posting Entry") then
            IsRestricted := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Message Argument ori", OnGetDedicatedMessageTypeHintForWrite, '', false, false)]
    local procedure OnGetDedicatedMessageTypeHintForWrite(TableNo: Integer; var Hint: Text)
    begin
        if IsArchiveTable(TableNo) then
            Hint := ArchiveHintTok;
        if TableNo = Database::"Time Sheet Posting Entry" then
            Hint := PostingHintTok;
    end;

    local procedure ManagedFieldHint(TableNo: Integer; FieldNo: Integer): Text
    var
        Detail: Record "Time Sheet Detail";
        Line: Record "Time Sheet Line";
    begin
        case TableNo of
            Database::"Time Sheet Line":
                begin
                    if FieldNo = Line.FieldNo(Status) then
                        exit(StatusHintTok + ', ' + ReopenHintTok);
                    if FieldNo = Line.FieldNo(Posted) then
                        exit(PostingHintTok);
                end;
            Database::"Time Sheet Detail":
                begin
                    if FieldNo = Detail.FieldNo(Status) then
                        exit(StatusHintTok + ', ' + ReopenHintTok);
                    if FieldNo in [Detail.FieldNo(Posted), Detail.FieldNo("Posted Quantity")] then
                        exit(PostingHintTok);
                end;
        end;
    end;

    local procedure IsArchiveTable(TableNo: Integer): Boolean
    begin
        exit(TableNo in [Database::"Time Sheet Header Archive", Database::"Time Sheet Line Archive",
                        Database::"Time Sheet Detail Archive", Database::"Time Sheet Cmt. Line Archive"]);
    end;
}
