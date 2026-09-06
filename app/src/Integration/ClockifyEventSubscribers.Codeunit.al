namespace Origo.Bifrost.Timesheets;

using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Posting;
using Microsoft.Sales.Customer;

/// <summary>
/// Event subscribers that keep Clockify Integration records in sync with BC lifecycle
/// events. Handles:
/// - Job Journal Line deletion → reverses the TIME_ENTRY integration record
/// - Job Ledger Entry insertion (posting) → updates integration to point to posted entry
/// - Customer/Job/Job Task deletion → archives linked Clockify Client/Project/Task
/// - Customer blocked → archives linked Clockify Client
/// - Job Status = Completed → archives linked Clockify Project
/// </summary>
codeunit 70009202 "Clockify Event Subscribers ori"
{
    Access = Internal;
    SingleInstance = true;

    [EventSubscriber(ObjectType::Table, Database::"Job Journal Line", OnAfterDeleteEvent, '', false, false)]
    local procedure OnAfterDeleteJobJournalLine(var Rec: Record "Job Journal Line"; RunTrigger: Boolean)
    var
        Integration: Record "Clockify Integration ori";
    begin
        // When a journal line is deleted, reverse any integration record pointing to it
        Integration.SetCurrentKey("BC Table No.", "BC SystemId", "Reversed");
        Integration.SetRange("BC Table No.", Database::"Job Journal Line");
        Integration.SetRange("BC SystemId", Rec.SystemId);
        Integration.SetRange("Reversed", false);
        Integration.SetLoadFields("Entry No.", "Reversed", "Reversed At");
        if Integration.FindSet() then
            repeat
                Integration."Reversed" := true;
                Integration.Modify(true);
            until Integration.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Jnl.-Post Line", OnAfterJobLedgEntryInsert, '', false, false)]
    local procedure HandleOnAfterJobLedgEntryInsert(var JobLedgerEntry: Record "Job Ledger Entry"; JobJournalLine: Record "Job Journal Line")
    var
        Integration: Record "Clockify Integration ori";
    begin
        // When a Job Journal Line is posted, the ledger entry is created.
        // Find the integration record that points to the journal line's SystemId
        // and update it to point to the new ledger entry instead.
        Integration.SetCurrentKey("BC Table No.", "BC SystemId", "Reversed");
        Integration.SetRange("BC Table No.", Database::"Job Journal Line");
        Integration.SetRange("BC SystemId", JobJournalLine.SystemId);
        Integration.SetRange("Reversed", false);
        Integration.SetLoadFields("Entry No.", "BC Table No.", "BC SystemId", "BC Code");
        if Integration.FindFirst() then begin
            Integration."BC Table No." := Database::"Job Ledger Entry";
            Integration."BC SystemId" := JobLedgerEntry.SystemId;
            Integration."BC Code" := CopyStr(JobLedgerEntry."Job No." + '-' + Format(JobLedgerEntry."Entry No."), 1, 50);
            Integration.Modify(true);
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::Customer, OnBeforeDeleteEvent, '', false, false)]
    local procedure OnBeforeDeleteCustomer(var Rec: Record Customer; RunTrigger: Boolean)
    var
        ArchiveSync: Codeunit "Clockify Archive Sync ori";
    begin
        if Rec.IsTemporary() then
            exit;
        ArchiveSync.ArchiveLinkedEntities(Database::Customer, Rec.SystemId, 'Customer', 'deleted');
    end;

    [EventSubscriber(ObjectType::Table, Database::Job, OnBeforeDeleteEvent, '', false, false)]
    local procedure OnBeforeDeleteJob(var Rec: Record Job; RunTrigger: Boolean)
    var
        ArchiveSync: Codeunit "Clockify Archive Sync ori";
    begin
        if Rec.IsTemporary() then
            exit;
        ArchiveSync.ArchiveByClockifyType('PROJECT', Rec."No.", 'Job', 'deleted');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Task", OnBeforeDeleteEvent, '', false, false)]
    local procedure OnBeforeDeleteJobTask(var Rec: Record "Job Task"; RunTrigger: Boolean)
    var
        ArchiveSync: Codeunit "Clockify Archive Sync ori";
        BCCode: Code[50];
    begin
        if Rec.IsTemporary() then
            exit;
        BCCode := CopyStr(Rec."Job No." + '-' + Rec."Job Task No.", 1, 50);
        ArchiveSync.ArchiveByClockifyType('TASK', BCCode, 'Job Task', 'deleted');
    end;

    [EventSubscriber(ObjectType::Table, Database::Customer, OnAfterModifyEvent, '', false, false)]
    local procedure OnAfterModifyCustomer(var Rec: Record Customer; var xRec: Record Customer; RunTrigger: Boolean)
    var
        ArchiveSync: Codeunit "Clockify Archive Sync ori";
    begin
        if Rec.IsTemporary() then
            exit;
        // Archive when customer becomes fully blocked (and wasn't before)
        if (Rec.Blocked = Rec.Blocked::All) and (xRec.Blocked <> xRec.Blocked::All) then
            ArchiveSync.ArchiveLinkedEntities(Database::Customer, Rec.SystemId, 'Customer', 'blocked');
    end;

    [EventSubscriber(ObjectType::Table, Database::Job, OnAfterModifyEvent, '', false, false)]
    local procedure OnAfterModifyJob(var Rec: Record Job; var xRec: Record Job; RunTrigger: Boolean)
    var
        ArchiveSync: Codeunit "Clockify Archive Sync ori";
    begin
        if Rec.IsTemporary() then
            exit;
        // Archive when job status changes to Completed
        if (Rec.Status = Rec.Status::Completed) and (xRec.Status <> xRec.Status::Completed) then
            ArchiveSync.ArchiveByClockifyType('PROJECT', Rec."No.", 'Job', 'completed');
    end;
}
