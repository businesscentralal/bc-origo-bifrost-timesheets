namespace Origo.Bifrost.Timesheets;

using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Posting;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Posting;
using Microsoft.Projects.Resources.Journal;
using Microsoft.Projects.Resources.Ledger;

/// <summary>Tracks real posting and deletion events for linked usage journals.</summary>
codeunit 10036862 "TS Usage Events ori"
{
    Access = Internal;
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", OnAfterInsertItemLedgEntry, '', false, false)]
    local procedure ItemPosted(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemJournalLine: Record "Item Journal Line")
    begin
        UpdateUsage(Database::"Item Journal Line", ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name", ItemJournalLine."Line No.", ItemLedgerEntry."Entry No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", OnAfterDeleteEvent, '', false, false)]
    local procedure ItemDeleted(var Rec: Record "Item Journal Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;
        UpdateUsage(Database::"Item Journal Line", Rec."Journal Template Name", Rec."Journal Batch Name", Rec."Line No.", 0);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Res. Jnl.-Post Line", OnAfterResLedgEntryInsert, '', false, false)]
    local procedure ResourcePosted(var ResLedgerEntry: Record "Res. Ledger Entry"; ResJournalLine: Record "Res. Journal Line")
    begin
        UpdateUsage(Database::"Res. Journal Line", ResJournalLine."Journal Template Name", ResJournalLine."Journal Batch Name", ResJournalLine."Line No.", ResLedgerEntry."Entry No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Res. Journal Line", OnAfterDeleteEvent, '', false, false)]
    local procedure ResourceDeleted(var Rec: Record "Res. Journal Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;
        UpdateUsage(Database::"Res. Journal Line", Rec."Journal Template Name", Rec."Journal Batch Name", Rec."Line No.", 0);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Jnl.-Post Line", OnAfterJobLedgEntryInsert, '', false, false)]
    local procedure JobPosted(var JobLedgerEntry: Record "Job Ledger Entry"; JobJournalLine: Record "Job Journal Line")
    begin
        UpdateUsage(Database::"Job Journal Line", JobJournalLine."Journal Template Name", JobJournalLine."Journal Batch Name", JobJournalLine."Line No.", JobLedgerEntry."Entry No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Journal Line", OnAfterDeleteEvent, '', false, false)]
    local procedure JobDeleted(var Rec: Record "Job Journal Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;
        UpdateUsage(Database::"Job Journal Line", Rec."Journal Template Name", Rec."Journal Batch Name", Rec."Line No.", 0);
    end;

    local procedure UpdateUsage(TableNo: Integer; Template: Code[10]; Batch: Code[10]; LineNo: Integer; LedgerEntryNo: Integer)
    var
        Usage: Record "TS Usage Line ori";
    begin
        if (Template = '') or (Batch = '') or (LineNo = 0) then
            exit;
        Usage.ReadIsolation := IsolationLevel::UpdLock;
        Usage.SetRange("Journal Table No.", TableNo);
        Usage.SetRange("Journal Template", Template);
        Usage.SetRange("Journal Batch", Batch);
        Usage.SetRange("Journal Line No.", LineNo);
        Usage.SetRange(Status, Usage.Status::Approved);
        if Usage.FindSet(true) then
            repeat
                if LedgerEntryNo <> 0 then begin
                    Usage.Status := Usage.Status::Posted;
                    Usage."Ledger Entry No." := LedgerEntryNo;
                end else begin
                    Clear(Usage."Journal Table No.");
                    Clear(Usage."Journal Template");
                    Clear(Usage."Journal Batch");
                    Clear(Usage."Journal Line No.");
                end;
                Usage.Modify(true);
            until Usage.Next() = 0;
    end;
}
