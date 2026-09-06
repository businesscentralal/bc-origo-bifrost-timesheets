namespace Origo.Bifrost.Timesheets;

using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Ledger;

/// <summary>
/// Handles the synchronization of Clockify time entries to BC Job Journal Lines with
/// deduplication, update detection, and correction posting. Prevents duplicate journal
/// lines by checking the Clockify Integration table before creating, and posts reversals
/// when a synced time entry is updated in Clockify (hours, project, task, or work type changed).
///
/// Work Type is resolved from the entry's Clockify tags: the first tag linked to a Work Type
/// (a <c>TAG</c>-type Clockify Integration row whose BC Code is a Work Type Code) wins;
/// otherwise the Default Work Type on Clockify Setup is used. The Job Task always comes
/// from the Clockify task's <c>TASK</c> integration link.
/// </summary>
codeunit 70009205 "Clockify Time Entry Sync ori"
{
    Access = Internal;

    var
        DuplicateSkippedMsg: Label 'Time entry %1 already synced (Integration Entry %2). Skipped.', Comment = '%1 = Clockify ID, %2 = Entry No. is-IS=Tímafærsla %1 er þegar samstillt (tengifærsla %2). Sleppt.';
        CorrectionCreatedMsg: Label 'Time entry %1 was updated in Clockify. Reversal line %2 and new line %3 created.', Comment = '%1 = Clockify ID, %2 = reversal line no., %3 = new line no. is-IS=Tímafærslu %1 var breytt í Clockify. Mótfærslulína %2 og ný lína %3 stofnaðar.';
        NoProjectMappingErr: Label 'No integration mapping found for Clockify project %1.', Comment = '%1 = Clockify project ID. is-IS=Engin tenging fannst fyrir Clockify verkefni %1.';
        NoTaskMappingErr: Label 'No integration mapping found for Clockify task %1.', Comment = '%1 = Clockify task ID. is-IS=Engin tenging fannst fyrir Clockify verkþátt %1.';
        NoUserMappingErr: Label 'No integration mapping found for Clockify user %1.', Comment = '%1 = Clockify user ID. is-IS=Engin tenging fannst fyrir Clockify notanda %1.';
        EntryUpdatedMsg: Label 'Time entry %1 updated in journal (Integration Entry %2).', Comment = '%1 = Clockify ID, %2 = Entry No. is-IS=Tímafærsla %1 uppfærð í bók (tengifærsla %2).';
        NoActiveLinkMsg: Label 'No active integration link for Clockify time entry %1; nothing to reverse.', Comment = '%1 = Clockify ID. is-IS=Engin virk tenging fyrir Clockify tímafærslu %1; ekkert til að bakfæra.';
        DeletedLineMsg: Label 'Deleted the journal line for Clockify time entry %1.', Comment = '%1 = Clockify ID. is-IS=Bókarlínu fyrir Clockify tímafærslu %1 eytt.';
        LinkReversedMsg: Label 'Reversed the integration link for Clockify time entry %1 (journal line already gone).', Comment = '%1 = Clockify ID. is-IS=Tenging Clockify tímafærslu %1 bakfærð (bókarlínan var þegar horfin).';
        PostedManualMsg: Label 'Clockify time entry %1 was already posted; reversed the link. Post a manual correction for the ledger entry.', Comment = '%1 = Clockify ID. is-IS=Clockify tímafærsla %1 var þegar bókuð; tengingin var bakfærð. Bókaðu handvirka leiðréttingu fyrir færsluna.';

    /// <summary>
    /// Synchronizes a single Clockify time entry to a Job Journal Line. Returns the result:
    /// Created (new line), Skipped (duplicate, no changes), or Corrected (reversal + new line).
    /// </summary>
    /// <param name="JournalTemplateName">The Job Journal template.</param>
    /// <param name="JournalBatchName">The Job Journal batch.</param>
    /// <param name="ClockifyEntryId">The Clockify time entry ID.</param>
    /// <param name="ClockifyWorkspaceId">The workspace ID.</param>
    /// <param name="ClockifyUserId">The Clockify user who owns the entry.</param>
    /// <param name="ClockifyProjectId">The Clockify project ID (may be empty).</param>
    /// <param name="ClockifyTaskId">The Clockify task ID (may be empty).</param>
    /// <param name="Description">The time entry description.</param>
    /// <param name="PostingDate">The date of the time entry.</param>
    /// <param name="Hours">The duration in hours.</param>
    /// <param name="Billable">Whether the entry is billable.</param>
    /// <param name="ClockifyTagIds">The entry's Clockify tag IDs, used to resolve the Work Type.</param>
    /// <param name="ResultMessage">Out: a human-readable message about what happened.</param>
    /// <returns>The sync result: Created, Skipped, Updated, Corrected, or Error.</returns>
    procedure SyncTimeEntry(
        JournalTemplateName: Code[10];
        JournalBatchName: Code[10];
        ClockifyEntryId: Text[50];
        ClockifyWorkspaceId: Text[50];
        ClockifyUserId: Text[50];
        ClockifyProjectId: Text[50];
        ClockifyTaskId: Text[50];
        Description: Text;
        PostingDate: Date;
        Hours: Decimal;
        Billable: Boolean;
        ClockifyTagIds: List of [Text];
        var ResultMessage: Text): Enum "Clockify Sync Result ori"
    var
        ExistingIntegration: Record "Clockify Integration ori";
        JobNo: Code[20];
        JobTaskNo: Code[20];
        ResourceNo: Code[20];
        WorkType: Code[10];
    begin
        // Resolve BC mappings from integration table
        if not ResolveProjectMapping(ClockifyProjectId, JobNo) then begin
            ResultMessage := StrSubstNo(NoProjectMappingErr, ClockifyProjectId);
            exit(Enum::"Clockify Sync Result ori"::Error);
        end;
        if (ClockifyTaskId <> '') and (not ResolveTaskMapping(ClockifyTaskId, JobTaskNo)) then begin
            ResultMessage := StrSubstNo(NoTaskMappingErr, ClockifyTaskId);
            exit(Enum::"Clockify Sync Result ori"::Error);
        end;
        if not ResolveUserMapping(ClockifyUserId, ResourceNo) then begin
            ResultMessage := StrSubstNo(NoUserMappingErr, ClockifyUserId);
            exit(Enum::"Clockify Sync Result ori"::Error);
        end;

        // Work Type: first tag linked to a Work Type wins, else the setup default.
        WorkType := ResolveWorkType(ClockifyTagIds);

        // Serialize find-or-create against concurrent callers (e.g. a webhook push and
        // a reconciliation poll hitting the same entry at once) so the existence check
        // and the insert cannot interleave into duplicate journal lines.
        ExistingIntegration.LockTable();

        // Check if already synced
        if FindActiveIntegration(ClockifyEntryId, ExistingIntegration) then
            exit(HandleExistingEntry(
                ExistingIntegration, JournalTemplateName, JournalBatchName,
                ClockifyEntryId, ClockifyWorkspaceId,
                JobNo, JobTaskNo, ResourceNo, Description, PostingDate, Hours, Billable, WorkType,
                ResultMessage));

        // New entry — create journal line and integration record
        exit(CreateNewEntry(
            JournalTemplateName, JournalBatchName,
            ClockifyEntryId, ClockifyWorkspaceId,
            JobNo, JobTaskNo, ResourceNo, Description, PostingDate, Hours, Billable, WorkType,
            ResultMessage));
    end;

    /// <summary>
    /// Reverses a previously synced Clockify time entry — the inbound counterpart to
    /// a <c>TIME_ENTRY_DELETED</c> webhook. If the linked journal line still exists
    /// it is deleted (which reverses the integration link via the table subscriber);
    /// if the entry was already posted to the ledger the link is reversed and the
    /// caller is told a manual correction is required.
    /// </summary>
    /// <param name="ClockifyEntryId">The Clockify time entry ID to reverse.</param>
    /// <param name="ResultMessage">Out: a human-readable message about what happened.</param>
    /// <returns>Skipped (no active link), Updated (line deleted/link reversed), or Corrected (posted — manual correction needed).</returns>
    procedure ReverseTimeEntry(ClockifyEntryId: Text[50]; var ResultMessage: Text): Enum "Clockify Sync Result ori"
    var
        Integration: Record "Clockify Integration ori";
        JobJournalLine: Record "Job Journal Line";
    begin
        Integration.LockTable();
        if not FindActiveIntegration(ClockifyEntryId, Integration) then begin
            ResultMessage := StrSubstNo(NoActiveLinkMsg, ClockifyEntryId);
            exit(Enum::"Clockify Sync Result ori"::Skipped);
        end;

        if Integration."BC Table No." = Database::"Job Journal Line" then begin
            if FindJournalLineBySystemId(Integration."BC SystemId", JobJournalLine) then begin
                // Deleting the line fires OnAfterDeleteJobJournalLine, which reverses the link.
                JobJournalLine.Delete(true);
                ResultMessage := StrSubstNo(DeletedLineMsg, ClockifyEntryId);
                exit(Enum::"Clockify Sync Result ori"::Updated);
            end;
            ReverseIntegration(Integration);
            ResultMessage := StrSubstNo(LinkReversedMsg, ClockifyEntryId);
            exit(Enum::"Clockify Sync Result ori"::Updated);
        end;

        // Posted to the ledger — the entry cannot be auto-removed. Reverse the link
        // and signal that a manual correction is required for the posted entry.
        ReverseIntegration(Integration);
        ResultMessage := StrSubstNo(PostedManualMsg, ClockifyEntryId);
        exit(Enum::"Clockify Sync Result ori"::Corrected);
    end;

    local procedure FindActiveIntegration(ClockifyEntryId: Text[50]; var Integration: Record "Clockify Integration ori"): Boolean
    begin
        Integration.SetCurrentKey("Clockify Type", "Clockify Id", "Reversed");
        Integration.SetRange("Clockify Type", 'TIME_ENTRY');
        Integration.SetRange("Clockify Id", ClockifyEntryId);
        Integration.SetRange("Reversed", false);
        Integration.SetLoadFields("Entry No.", "BC Code", "BC SystemId", "BC Table No.", "Clockify Name");
        exit(Integration.FindFirst());
    end;

    local procedure HandleExistingEntry(
        var ExistingIntegration: Record "Clockify Integration ori";
        JournalTemplateName: Code[10];
        JournalBatchName: Code[10];
        ClockifyEntryId: Text[50];
        ClockifyWorkspaceId: Text[50];
        JobNo: Code[20];
        JobTaskNo: Code[20];
        ResourceNo: Code[20];
        Description: Text;
        PostingDate: Date;
        Hours: Decimal;
        Billable: Boolean;
        WorkType: Code[10];
        var ResultMessage: Text): Enum "Clockify Sync Result ori"
    var
        ExistingJournalLine: Record "Job Journal Line";
        PostedToLedger: Boolean;
        HasChanged: Boolean;
    begin
        // Check if the linked BC record is a journal line (unposted) or ledger entry (posted)
        PostedToLedger := (ExistingIntegration."BC Table No." = Database::"Job Ledger Entry");

        if not PostedToLedger then begin
            // Still a journal line — check if it still exists
            if FindJournalLineBySystemId(ExistingIntegration."BC SystemId", ExistingJournalLine) then begin
                HasChanged := DetectChanges(ExistingJournalLine, JobNo, JobTaskNo, ResourceNo, PostingDate, Hours, WorkType);
                if not HasChanged then begin
                    ResultMessage := StrSubstNo(DuplicateSkippedMsg, ClockifyEntryId, ExistingIntegration."Entry No.");
                    exit(Enum::"Clockify Sync Result ori"::Skipped);
                end;
                // Changed but not posted — update the existing journal line in place
                UpdateJournalLine(ExistingJournalLine, JobNo, JobTaskNo, ResourceNo, Description, PostingDate, Hours, Billable, WorkType);
                UpdateIntegrationName(ExistingIntegration, Description, Hours);
                ResultMessage := StrSubstNo(EntryUpdatedMsg, ClockifyEntryId, ExistingIntegration."Entry No.");
                exit(Enum::"Clockify Sync Result ori"::Updated);
            end;
            // Journal line was deleted — reverse integration and re-create
            ReverseIntegration(ExistingIntegration);
            exit(CreateNewEntry(
                JournalTemplateName, JournalBatchName,
                ClockifyEntryId, ClockifyWorkspaceId,
                JobNo, JobTaskNo, ResourceNo, Description, PostingDate, Hours, Billable, WorkType,
                ResultMessage));
        end;

        // Posted to ledger — need a correction (reversal line + new line)
        exit(CreateCorrectionEntry(
            ExistingIntegration, JournalTemplateName, JournalBatchName,
            ClockifyEntryId, ClockifyWorkspaceId,
            JobNo, JobTaskNo, ResourceNo, Description, PostingDate, Hours, Billable, WorkType,
            ResultMessage));
    end;

    local procedure CreateNewEntry(
        JournalTemplateName: Code[10];
        JournalBatchName: Code[10];
        ClockifyEntryId: Text[50];
        ClockifyWorkspaceId: Text[50];
        JobNo: Code[20];
        JobTaskNo: Code[20];
        ResourceNo: Code[20];
        Description: Text;
        PostingDate: Date;
        Hours: Decimal;
        Billable: Boolean;
        WorkType: Code[10];
        var ResultMessage: Text): Enum "Clockify Sync Result ori"
    var
        JobJournalLine: Record "Job Journal Line";
        Integration: Record "Clockify Integration ori";
        LineNo: Integer;
    begin
        LineNo := GetNextLineNo(JournalTemplateName, JournalBatchName);
        CreateJournalLine(
            JobJournalLine, JournalTemplateName, JournalBatchName, LineNo,
            JobNo, JobTaskNo, ResourceNo, Description, PostingDate, Hours, Billable, WorkType);

        CreateIntegrationRecord(
            Integration, ClockifyEntryId, ClockifyWorkspaceId,
            Database::"Job Journal Line", JobJournalLine.SystemId,
            JournalTemplateName + '-' + JournalBatchName + '-' + Format(LineNo),
            Description + ' ' + Format(Hours) + 'h');

        ResultMessage := 'Created journal line ' + Format(LineNo) + ' for ' + Format(Hours) + 'h on ' + JobNo + '/' + JobTaskNo;
        exit(Enum::"Clockify Sync Result ori"::Created);
    end;

    local procedure CreateCorrectionEntry(
        var ExistingIntegration: Record "Clockify Integration ori";
        JournalTemplateName: Code[10];
        JournalBatchName: Code[10];
        ClockifyEntryId: Text[50];
        ClockifyWorkspaceId: Text[50];
        JobNo: Code[20];
        JobTaskNo: Code[20];
        ResourceNo: Code[20];
        Description: Text;
        PostingDate: Date;
        Hours: Decimal;
        Billable: Boolean;
        WorkType: Code[10];
        var ResultMessage: Text): Enum "Clockify Sync Result ori"
    var
        OriginalJournalLine: Record "Job Journal Line";
        CorrectionJournalLine: Record "Job Journal Line";
        NewIntegration: Record "Clockify Integration ori";
        ReversalLineNo: Integer;
        NewLineNo: Integer;
        OriginalHours: Decimal;
    begin
        // Reverse the old integration record
        ReverseIntegration(ExistingIntegration);

        // Parse original hours from the integration name (format: "Description Xh")
        OriginalHours := ExtractHoursFromName(ExistingIntegration."Clockify Name");

        // Create reversal line (negative quantity)
        ReversalLineNo := GetNextLineNo(JournalTemplateName, JournalBatchName);
        CreateJournalLine(
            OriginalJournalLine, JournalTemplateName, JournalBatchName, ReversalLineNo,
            JobNo, JobTaskNo, ResourceNo,
            'CORRECTION (reversal): ' + Description, PostingDate, -OriginalHours, Billable, WorkType);

        // Create new correct line
        NewLineNo := ReversalLineNo + 10000;
        CreateJournalLine(
            CorrectionJournalLine, JournalTemplateName, JournalBatchName, NewLineNo,
            JobNo, JobTaskNo, ResourceNo, Description, PostingDate, Hours, Billable, WorkType);

        // Create new integration record pointing to the new line
        CreateIntegrationRecord(
            NewIntegration, ClockifyEntryId, ClockifyWorkspaceId,
            Database::"Job Journal Line", CorrectionJournalLine.SystemId,
            JournalTemplateName + '-' + JournalBatchName + '-' + Format(NewLineNo),
            Description + ' ' + Format(Hours) + 'h');

        ResultMessage := StrSubstNo(CorrectionCreatedMsg, ClockifyEntryId, ReversalLineNo, NewLineNo);
        exit(Enum::"Clockify Sync Result ori"::Corrected);
    end;

    local procedure CreateJournalLine(
        var JobJournalLine: Record "Job Journal Line";
        JournalTemplateName: Code[10];
        JournalBatchName: Code[10];
        LineNo: Integer;
        JobNo: Code[20];
        JobTaskNo: Code[20];
        ResourceNo: Code[20];
        Description: Text;
        PostingDate: Date;
        Hours: Decimal;
        Billable: Boolean;
        WorkType: Code[10])
    begin
        JobJournalLine.Init();
        JobJournalLine."Journal Template Name" := JournalTemplateName;
        JobJournalLine."Journal Batch Name" := JournalBatchName;
        JobJournalLine."Line No." := LineNo;
        JobJournalLine.Validate("Posting Date", PostingDate);
        JobJournalLine."Document No." := 'CLK-' + Format(PostingDate, 0, '<Year4><Month,2><Day,2>');
        JobJournalLine."Entry Type" := JobJournalLine."Entry Type"::Usage;
        JobJournalLine.Validate("Job No.", JobNo);
        JobJournalLine.Validate("Job Task No.", JobTaskNo);
        JobJournalLine.Validate(Type, JobJournalLine.Type::Resource);
        JobJournalLine.Validate("No.", ResourceNo);
        // Work Type before Quantity so work-type-specific prices apply to the quantity.
        JobJournalLine.Validate("Work Type Code", WorkType);
        JobJournalLine.Validate(Quantity, Hours);
        JobJournalLine.Description := CopyStr(Description, 1, MaxStrLen(JobJournalLine.Description));
        if Billable then
            JobJournalLine."Line Type" := JobJournalLine."Line Type"::"Both Budget and Billable"
        else
            JobJournalLine."Line Type" := JobJournalLine."Line Type"::Budget;
        JobJournalLine.Insert(true);
    end;

    local procedure UpdateJournalLine(
        var JobJournalLine: Record "Job Journal Line";
        JobNo: Code[20];
        JobTaskNo: Code[20];
        ResourceNo: Code[20];
        Description: Text;
        PostingDate: Date;
        Hours: Decimal;
        Billable: Boolean;
        WorkType: Code[10])
    begin
        if JobJournalLine."Job No." <> JobNo then
            JobJournalLine.Validate("Job No.", JobNo);
        if JobJournalLine."Job Task No." <> JobTaskNo then
            JobJournalLine.Validate("Job Task No.", JobTaskNo);
        if JobJournalLine."No." <> ResourceNo then
            JobJournalLine.Validate("No.", ResourceNo);
        if JobJournalLine."Work Type Code" <> WorkType then
            JobJournalLine.Validate("Work Type Code", WorkType);
        if JobJournalLine.Quantity <> Hours then
            JobJournalLine.Validate(Quantity, Hours);
        if JobJournalLine."Posting Date" <> PostingDate then
            JobJournalLine.Validate("Posting Date", PostingDate);
        JobJournalLine.Description := CopyStr(Description, 1, MaxStrLen(JobJournalLine.Description));
        if Billable then
            JobJournalLine."Line Type" := JobJournalLine."Line Type"::"Both Budget and Billable"
        else
            JobJournalLine."Line Type" := JobJournalLine."Line Type"::Budget;
        JobJournalLine.Modify(true);
    end;

    local procedure CreateIntegrationRecord(
        var Integration: Record "Clockify Integration ori";
        ClockifyEntryId: Text[50];
        ClockifyWorkspaceId: Text[50];
        BCTableNo: Integer;
        BCSystemId: Guid;
        BCCode: Code[50];
        ClockifyName: Text[250])
    begin
        Integration.Init();
        Integration."Entry No." := 0;
        Integration."BC Table No." := BCTableNo;
        Integration."BC SystemId" := BCSystemId;
        Integration."BC Code" := BCCode;
        Integration."Clockify Type" := 'TIME_ENTRY';
        Integration."Clockify Workspace Id" := ClockifyWorkspaceId;
        Integration."Clockify Id" := ClockifyEntryId;
        Integration."Clockify Name" := ClockifyName;
        Integration."Reversed" := false;
        Integration.Insert(true);
    end;

    local procedure ReverseIntegration(var Integration: Record "Clockify Integration ori")
    begin
        Integration."Reversed" := true;
        Integration.Modify(true);
    end;

    local procedure UpdateIntegrationName(var Integration: Record "Clockify Integration ori"; Description: Text; Hours: Decimal)
    begin
        Integration."Clockify Name" := CopyStr(Description + ' ' + Format(Hours) + 'h', 1, 250);
        Integration.Modify(true);
    end;

    internal procedure ResolveProjectMapping(ClockifyProjectId: Text[50]; var JobNo: Code[20]): Boolean
    var
        Integration: Record "Clockify Integration ori";
    begin
        if ClockifyProjectId = '' then
            exit(false);
        Integration.SetCurrentKey("Clockify Type", "Clockify Id", "Reversed");
        Integration.SetRange("Clockify Type", 'PROJECT');
        Integration.SetRange("Clockify Id", ClockifyProjectId);
        Integration.SetRange("Reversed", false);
        Integration.SetLoadFields("BC Code");
        if not Integration.FindFirst() then
            exit(false);
        JobNo := CopyStr(Integration."BC Code", 1, MaxStrLen(JobNo));
        exit(true);
    end;

    internal procedure ResolveTaskMapping(ClockifyTaskId: Text[50]; var JobTaskNo: Code[20]): Boolean
    var
        Integration: Record "Clockify Integration ori";
        BCCodeText: Text;
        DashPos: Integer;
    begin
        Integration.SetCurrentKey("Clockify Type", "Clockify Id", "Reversed");
        Integration.SetRange("Clockify Type", 'TASK');
        Integration.SetRange("Clockify Id", ClockifyTaskId);
        Integration.SetRange("Reversed", false);
        Integration.SetLoadFields("BC Code");
        if not Integration.FindFirst() then
            exit(false);
        // BC Code for tasks is "JobNo-TaskNo" format — extract last segment
        BCCodeText := Integration."BC Code";
        DashPos := BCCodeText.LastIndexOf('-');
        if DashPos > 0 then
            JobTaskNo := CopyStr(BCCodeText.Substring(DashPos + 1), 1, MaxStrLen(JobTaskNo))
        else
            JobTaskNo := CopyStr(Integration."BC Code", 1, MaxStrLen(JobTaskNo));
        exit(true);
    end;

    internal procedure ResolveUserMapping(ClockifyUserId: Text[50]; var ResourceNo: Code[20]): Boolean
    var
        Integration: Record "Clockify Integration ori";
    begin
        Integration.SetCurrentKey("Clockify Type", "Clockify Id", "Reversed");
        Integration.SetRange("Clockify Type", 'USER');
        Integration.SetRange("Clockify Id", ClockifyUserId);
        Integration.SetRange("Reversed", false);
        Integration.SetLoadFields("BC Code");
        if not Integration.FindFirst() then
            exit(false);
        ResourceNo := CopyStr(Integration."BC Code", 1, MaxStrLen(ResourceNo));
        exit(true);
    end;

    /// <summary>
    /// Resolves the Work Type for a time entry. The first Clockify tag that is linked
    /// to a Work Type wins; otherwise the Default Work Type on Clockify Setup is
    /// used (which may itself be blank).
    /// </summary>
    internal procedure ResolveWorkType(ClockifyTagIds: List of [Text]): Code[10]
    var
        SetupMgt: Codeunit "Clockify Setup Mgt ori";
        TagId: Text;
        WorkType: Code[10];
    begin
        foreach TagId in ClockifyTagIds do begin
            WorkType := ResolveTagWorkType(TagId);
            if WorkType <> '' then
                exit(WorkType);
        end;
        exit(SetupMgt.GetDefaultWorkType());
    end;

    local procedure ResolveTagWorkType(ClockifyTagId: Text): Code[10]
    var
        Integration: Record "Clockify Integration ori";
    begin
        if ClockifyTagId = '' then
            exit('');
        Integration.SetCurrentKey("Clockify Type", "Clockify Id", "Reversed");
        Integration.SetRange("Clockify Type", 'TAG');
        Integration.SetRange("Clockify Id", CopyStr(ClockifyTagId, 1, MaxStrLen(Integration."Clockify Id")));
        Integration.SetRange("Reversed", false);
        Integration.SetLoadFields("BC Code");
        if not Integration.FindFirst() then
            exit('');
        exit(CopyStr(Integration."BC Code", 1, 10));
    end;

    local procedure FindJournalLineBySystemId(SystemId: Guid; var JobJournalLine: Record "Job Journal Line"): Boolean
    begin
        JobJournalLine.SetLoadFields("Job No.", "Job Task No.", "No.", "Posting Date", Quantity, "Work Type Code");
        exit(JobJournalLine.GetBySystemId(SystemId));
    end;

    local procedure DetectChanges(JobJournalLine: Record "Job Journal Line"; JobNo: Code[20]; JobTaskNo: Code[20]; ResourceNo: Code[20]; PostingDate: Date; Hours: Decimal; WorkType: Code[10]): Boolean
    begin
        if JobJournalLine."Job No." <> JobNo then
            exit(true);
        if JobJournalLine."Job Task No." <> JobTaskNo then
            exit(true);
        if JobJournalLine."No." <> ResourceNo then
            exit(true);
        if JobJournalLine."Posting Date" <> PostingDate then
            exit(true);
        if JobJournalLine.Quantity <> Hours then
            exit(true);
        if JobJournalLine."Work Type Code" <> WorkType then
            exit(true);
        exit(false);
    end;

    local procedure GetNextLineNo(JournalTemplateName: Code[10]; JournalBatchName: Code[10]): Integer
    var
        JobJournalLine: Record "Job Journal Line";
    begin
        JobJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        JobJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        JobJournalLine.SetLoadFields("Line No.");
        if JobJournalLine.FindLast() then
            exit(JobJournalLine."Line No." + 10000);
        exit(10000);
    end;

    local procedure ExtractHoursFromName(Name: Text[250]): Decimal
    var
        Parts: List of [Text];
        LastPart: Text;
        HoursText: Text;
        Hours: Decimal;
    begin
        // Format is "Description Xh" — extract the last token before 'h'
        Parts := Name.Split(' ');
        if Parts.Count() = 0 then
            exit(0);
        LastPart := Parts.Get(Parts.Count());
        if not LastPart.EndsWith('h') then
            exit(0);
        HoursText := CopyStr(LastPart, 1, StrLen(LastPart) - 1);
        if Evaluate(Hours, HoursText) then
            exit(Hours);
        exit(0);
    end;
}
