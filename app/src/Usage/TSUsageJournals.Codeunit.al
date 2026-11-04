namespace Origo.Bifrost.Timesheets;

using Microsoft.Inventory.Journal;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Resources.Journal;
using Microsoft.Projects.TimeSheet;
using Origo.Bifrost;

/// <summary>Creates reviewed journals without posting, preserving their source usage link.</summary>
codeunit 10036863 "TS Usage Journals ori"
{
    Access = Internal;

    /// <summary>Maps usage to a project, item or resource journal in the caller's isolated transaction.</summary>
    procedure Create(var Usage: Record "TS Usage Line ori"; Template: Code[10]; Batch: Code[10]; Reversal: Boolean)
    var
        SheetLine: Record "Time Sheet Line";
        JournalTableNo: Integer;
        JournalLineNo: Integer;
        Quantity: Decimal;
    begin
        SheetLine.Get(Usage."Time Sheet No.", Usage."Time Sheet Line No.");
        Quantity := Usage.Quantity;
        if Reversal then
            Quantity := -Quantity;
        if SheetLine."Job No." <> '' then begin
            JournalTableNo := Database::"Job Journal Line";
            JournalLineNo := CreateJob(Usage, SheetLine, Template, Batch, Quantity);
        end else
            if Usage.Type = Usage.Type::Item then begin
                JournalTableNo := Database::"Item Journal Line";
                JournalLineNo := CreateItem(Usage, Template, Batch, Quantity);
            end else begin
                JournalTableNo := Database::"Res. Journal Line";
                JournalLineNo := CreateResource(Usage, Template, Batch, Quantity);
            end;
        if Reversal then
            exit;
        Usage."Journal Table No." := JournalTableNo;
        Usage."Journal Template" := Template;
        Usage."Journal Batch" := Batch;
        Usage."Journal Line No." := JournalLineNo;
    end;

    local procedure CheckPermission(Allowed: Boolean)
    var
        Context: Codeunit "TS Usage Context ori";
        PermissionLbl: Label 'Journal write permission is required for Transfer or Reverse.', Comment = 'is-IS=Skrifheimild í færslubók er nauðsynleg fyrir Transfer eða Reverse.';
    begin
        if not Allowed then
            Context.Refuse("Bifrost Error Code ori"::PermissionDenied, 'journalTemplate', PermissionLbl);
    end;

    local procedure CreateItem(Usage: Record "TS Usage Line ori"; Template: Code[10]; Batch: Code[10]; Quantity: Decimal): Integer
    var
        Journal: Record "Item Journal Line";
        JournalBatch: Record "Item Journal Batch";
        LineNo: Integer;
    begin
        CheckPermission(Journal.ReadPermission() and Journal.WritePermission() and JournalBatch.ReadPermission());
        JournalBatch.Get(Template, Batch);
        Journal.ReadIsolation := IsolationLevel::UpdLock;
        Journal.SetRange("Journal Template Name", Template);
        Journal.SetRange("Journal Batch Name", Batch);
        if Journal.FindLast() then
            LineNo := Journal."Line No.";
        Journal.Init();
        Journal."Journal Template Name" := Template;
        Journal."Journal Batch Name" := Batch;
        Journal."Line No." := LineNo + 10000;
        Journal.Validate("Entry Type", Journal."Entry Type"::"Negative Adjmt.");
        Journal.Validate("Posting Date", Usage.Date);
        Journal."Document No." := Usage."Time Sheet No.";
        Journal.Validate("Item No.", Usage."No.");
        if Usage."Unit of Measure" <> '' then
            Journal.Validate("Unit of Measure Code", Usage."Unit of Measure");
        Journal.Validate(Quantity, Quantity);
        Journal.Description := Usage.Description;
        Journal.Insert(true);
        exit(Journal."Line No.");
    end;

    local procedure CreateResource(Usage: Record "TS Usage Line ori"; Template: Code[10]; Batch: Code[10]; Quantity: Decimal): Integer
    var
        Journal: Record "Res. Journal Line";
        JournalBatch: Record "Res. Journal Batch";
        LineNo: Integer;
    begin
        CheckPermission(Journal.ReadPermission() and Journal.WritePermission() and JournalBatch.ReadPermission());
        JournalBatch.Get(Template, Batch);
        Journal.ReadIsolation := IsolationLevel::UpdLock;
        Journal.SetRange("Journal Template Name", Template);
        Journal.SetRange("Journal Batch Name", Batch);
        if Journal.FindLast() then
            LineNo := Journal."Line No.";
        Journal.Init();
        Journal."Journal Template Name" := Template;
        Journal."Journal Batch Name" := Batch;
        Journal."Line No." := LineNo + 10000;
        Journal.Validate("Entry Type", Journal."Entry Type"::Usage);
        Journal.Validate("Posting Date", Usage.Date);
        Journal."Document No." := Usage."Time Sheet No.";
        Journal.Validate("Resource No.", Usage."No.");
        if Usage."Unit of Measure" <> '' then
            Journal.Validate("Unit of Measure Code", Usage."Unit of Measure");
        Journal.Validate(Quantity, Quantity);
        Journal.Description := Usage.Description;
        Journal.Insert(true);
        exit(Journal."Line No.");
    end;

    local procedure CreateJob(Usage: Record "TS Usage Line ori"; SheetLine: Record "Time Sheet Line"; Template: Code[10]; Batch: Code[10]; Quantity: Decimal): Integer
    var
        Journal: Record "Job Journal Line";
        JournalBatch: Record "Job Journal Batch";
        LineNo: Integer;
    begin
        CheckPermission(Journal.ReadPermission() and Journal.WritePermission() and JournalBatch.ReadPermission());
        JournalBatch.Get(Template, Batch);
        Journal.ReadIsolation := IsolationLevel::UpdLock;
        Journal.SetRange("Journal Template Name", Template);
        Journal.SetRange("Journal Batch Name", Batch);
        if Journal.FindLast() then
            LineNo := Journal."Line No.";
        Journal.Init();
        Journal."Journal Template Name" := Template;
        Journal."Journal Batch Name" := Batch;
        Journal."Line No." := LineNo + 10000;
        Journal.Validate("Posting Date", Usage.Date);
        Journal."Document No." := Usage."Time Sheet No.";
        Journal.Validate("Job No.", SheetLine."Job No.");
        Journal.Validate("Job Task No.", SheetLine."Job Task No.");
        if Usage.Type = Usage.Type::Item then
            Journal.Validate(Type, Journal.Type::Item)
        else
            Journal.Validate(Type, Journal.Type::Resource);
        Journal.Validate("No.", Usage."No.");
        if Usage."Unit of Measure" <> '' then
            Journal.Validate("Unit of Measure Code", Usage."Unit of Measure");
        Journal.Validate(Quantity, Quantity);
        Journal.Description := Usage.Description;
        Journal.Insert(true);
        exit(Journal."Line No.");
    end;
}
