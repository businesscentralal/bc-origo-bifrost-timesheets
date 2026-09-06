namespace Origo.Bifrost.Timesheets;

using Microsoft.Projects.Project.Job;
using Microsoft.Projects.TimeSheet;

/// <summary>
/// Syncs a Clockify time entry into a BC Time Sheet (line + detail) rather than the Job
/// Journal. Mirrors the legacy <c>Integrate Clockify to BC</c> import: it resolves the
/// Job/Task/Resource/Work Type mappings, finds the resource's open time sheet covering
/// the entry date, finds or creates the matching time-sheet line, and writes the day's
/// detail. Deduplication and update detection are tracked through a <c>TIME_ENTRY</c>
/// <c>Clockify Integration ori</c> record linked to the created Time Sheet Detail.
/// </summary>
codeunit 10036839 "Clockify TimeSheet Sync ori"
{
    Access = Internal;

    var
        NoProjectMappingErr: Label 'No integration mapping found for Clockify project %1.', Comment = '%1 = Clockify project ID', Locked = true;
        NoTaskMappingErr: Label 'No integration mapping found for Clockify task %1.', Comment = '%1 = Clockify task ID', Locked = true;
        NoUserMappingErr: Label 'No integration mapping found for Clockify user %1.', Comment = '%1 = Clockify user ID', Locked = true;
        NoOpenTimeSheetErr: Label 'No open time sheet found for resource %1 on %2. Run Clockify.TimeSheet.Create first.', Comment = '%1 = resource no., %2 = date', Locked = true;
        CreatedMsg: Label 'Time entry %1 written to time sheet %2 line %3.', Comment = '%1 = Clockify ID, %2 = time sheet no., %3 = line no.', Locked = true;
        UpdatedMsg: Label 'Time entry %1 updated on time sheet %2 line %3.', Comment = '%1 = Clockify ID, %2 = time sheet no., %3 = line no.', Locked = true;
        SkippedMsg: Label 'Time entry %1 already on time sheet, unchanged. Skipped.', Comment = '%1 = Clockify ID', Locked = true;
        NoActiveLinkMsg: Label 'No active time-sheet link for Clockify time entry %1; nothing to reverse.', Comment = '%1 = Clockify ID', Locked = true;
        LinkReversedMsg: Label 'Reversed the time-sheet link for Clockify time entry %1 (detail already gone).', Comment = '%1 = Clockify ID', Locked = true;
        DetailDeletedMsg: Label 'Removed the time-sheet detail for Clockify time entry %1.', Comment = '%1 = Clockify ID', Locked = true;
        NotOpenReversedMsg: Label 'Clockify time entry %1 is on a non-open time sheet; reversed the link. Adjust the sheet manually.', Comment = '%1 = Clockify ID', Locked = true;

    /// <summary>
    /// Syncs a single Clockify time entry to the resource's open time sheet.
    /// </summary>
    /// <returns>Created, Updated, Skipped, or Error.</returns>
    procedure SyncTimeEntryToTimeSheet(
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
        Integration: Record "Clockify Integration ori";
        JobTask: Record "Job Task";
        TimeSheet: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        EntrySync: Codeunit "Clockify Time Entry Sync ori";
        JobNo: Code[20];
        JobTaskNo: Code[20];
        ResourceNo: Code[20];
        WorkType: Code[10];
    begin
        if not EntrySync.ResolveProjectMapping(ClockifyProjectId, JobNo) then begin
            ResultMessage := StrSubstNo(NoProjectMappingErr, ClockifyProjectId);
            exit(Enum::"Clockify Sync Result ori"::Error);
        end;
        if ClockifyTaskId = '' then begin
            ResultMessage := 'Missing taskId: cannot map to a BC Job Task.';
            exit(Enum::"Clockify Sync Result ori"::Error);
        end;
        if not EntrySync.ResolveTaskMapping(ClockifyTaskId, JobTaskNo) then begin
            ResultMessage := StrSubstNo(NoTaskMappingErr, ClockifyTaskId);
            exit(Enum::"Clockify Sync Result ori"::Error);
        end;
        if not EntrySync.ResolveUserMapping(ClockifyUserId, ResourceNo) then begin
            ResultMessage := StrSubstNo(NoUserMappingErr, ClockifyUserId);
            exit(Enum::"Clockify Sync Result ori"::Error);
        end;
        WorkType := EntrySync.ResolveWorkType(ClockifyTagIds);

        JobTask.Get(JobNo, JobTaskNo);
        if not FindOpenTimeSheet(ResourceNo, PostingDate, TimeSheet) then begin
            ResultMessage := StrSubstNo(NoOpenTimeSheetErr, ResourceNo, PostingDate);
            exit(Enum::"Clockify Sync Result ori"::Error);
        end;

        Integration.LockTable();
        FindOrCreateTimeSheetLine(TimeSheet, JobTask, WorkType, Description, Billable, TimeSheetLine);

        if FindActiveIntegration(ClockifyEntryId, Integration) then
            exit(UpdateExisting(Integration, TimeSheet, TimeSheetLine, PostingDate, Hours, ClockifyEntryId, ResultMessage));

        exit(CreateNew(TimeSheet, TimeSheetLine, ClockifyEntryId, ClockifyWorkspaceId, PostingDate, Hours, Description, ResultMessage));
    end;

    /// <summary>
    /// Reverses a time entry previously written to a time sheet — the inbound counterpart to a
    /// <c>TIME_ENTRY_DELETED</c> webhook. Deletes the linked detail when its time-sheet line is
    /// still Open; otherwise reverses the link and reports that a manual correction is needed.
    /// </summary>
    /// <param name="ClockifyEntryId">The Clockify time entry ID to reverse.</param>
    /// <param name="ResultMessage">Out: a human-readable message about what happened.</param>
    /// <returns>Skipped (no active link), Updated (detail removed/link reversed), or Corrected (non-open sheet).</returns>
    procedure ReverseFromTimeSheet(ClockifyEntryId: Text[50]; var ResultMessage: Text): Enum "Clockify Sync Result ori"
    var
        Integration: Record "Clockify Integration ori";
        TimeSheetDetail: Record "Time Sheet Detail";
        TimeSheetLine: Record "Time Sheet Line";
    begin
        Integration.LockTable();
        if not FindActiveIntegration(ClockifyEntryId, Integration) then begin
            ResultMessage := StrSubstNo(NoActiveLinkMsg, ClockifyEntryId);
            exit(Enum::"Clockify Sync Result ori"::Skipped);
        end;

        if not TimeSheetDetail.GetBySystemId(Integration."BC SystemId") then begin
            Integration."Reversed" := true;
            Integration.Modify(true);
            ResultMessage := StrSubstNo(LinkReversedMsg, ClockifyEntryId);
            exit(Enum::"Clockify Sync Result ori"::Updated);
        end;

        if TimeSheetLine.Get(TimeSheetDetail."Time Sheet No.", TimeSheetDetail."Time Sheet Line No.") then
            if TimeSheetLine.Status <> TimeSheetLine.Status::Open then begin
                Integration."Reversed" := true;
                Integration.Modify(true);
                ResultMessage := StrSubstNo(NotOpenReversedMsg, ClockifyEntryId);
                exit(Enum::"Clockify Sync Result ori"::Corrected);
            end;

        TimeSheetDetail.Delete(false);
        Integration."Reversed" := true;
        Integration.Modify(true);
        ResultMessage := StrSubstNo(DetailDeletedMsg, ClockifyEntryId);
        exit(Enum::"Clockify Sync Result ori"::Updated);
    end;

    local procedure FindOpenTimeSheet(ResourceNo: Code[20]; PostingDate: Date; var TimeSheet: Record "Time Sheet Header"): Boolean
    begin
        TimeSheet.SetRange("Resource No.", ResourceNo);
        TimeSheet.SetFilter("Starting Date", '<=%1', PostingDate);
        TimeSheet.SetFilter("Ending Date", '>=%1', PostingDate);
        TimeSheet.SetRange("Open Exists", true);
        exit(TimeSheet.FindFirst());
    end;

    local procedure FindOrCreateTimeSheetLine(TimeSheet: Record "Time Sheet Header"; JobTask: Record "Job Task"; WorkType: Code[10]; Description: Text; Billable: Boolean; var TimeSheetLine: Record "Time Sheet Line")
    var
        LineDescription: Text[100];
    begin
        if Description = '' then
            LineDescription := CopyStr(JobTask.Description, 1, MaxStrLen(LineDescription))
        else
            LineDescription := CopyStr(Description, 1, MaxStrLen(LineDescription));

        TimeSheetLine.SetRange("Time Sheet No.", TimeSheet."No.");
        TimeSheetLine.SetRange(Type, TimeSheetLine.Type::Job);
        TimeSheetLine.SetRange("Job No.", JobTask."Job No.");
        TimeSheetLine.SetRange("Job Task No.", JobTask."Job Task No.");
        TimeSheetLine.SetRange("Work Type Code", WorkType);
        TimeSheetLine.SetRange(Description, LineDescription);
        TimeSheetLine.SetRange(Status, TimeSheetLine.Status::Open);
        if TimeSheetLine.FindFirst() then
            exit;

        TimeSheetLine.Reset();
        TimeSheetLine.SetRange("Time Sheet No.", TimeSheet."No.");
        if not TimeSheetLine.FindLast() then;
        TimeSheetLine.Init();
        TimeSheetLine."Time Sheet No." := TimeSheet."No.";
        TimeSheetLine."Line No." := TimeSheetLine."Line No." + 10000;
        TimeSheetLine."Time Sheet Starting Date" := TimeSheet."Starting Date";
        TimeSheetLine.Type := TimeSheetLine.Type::Job;
        TimeSheetLine."Job No." := JobTask."Job No.";
        TimeSheetLine."Job Task No." := JobTask."Job Task No.";
        TimeSheetLine."Work Type Code" := WorkType;
        TimeSheetLine.Chargeable := Billable;
        TimeSheetLine.Description := LineDescription;
        TimeSheetLine.Insert(false, true);
    end;

    local procedure CreateNew(TimeSheet: Record "Time Sheet Header"; TimeSheetLine: Record "Time Sheet Line"; ClockifyEntryId: Text[50]; ClockifyWorkspaceId: Text[50]; PostingDate: Date; Hours: Decimal; Description: Text; var ResultMessage: Text): Enum "Clockify Sync Result ori"
    var
        Integration: Record "Clockify Integration ori";
        TimeSheetDetail: Record "Time Sheet Detail";
    begin
        WriteDetail(TimeSheet, TimeSheetLine, PostingDate, Hours, TimeSheetDetail);
        CreateIntegrationRecord(Integration, ClockifyEntryId, ClockifyWorkspaceId, TimeSheetDetail, Description, Hours);
        ResultMessage := StrSubstNo(CreatedMsg, ClockifyEntryId, TimeSheet."No.", TimeSheetLine."Line No.");
        exit(Enum::"Clockify Sync Result ori"::Created);
    end;

    local procedure UpdateExisting(var Integration: Record "Clockify Integration ori"; TimeSheet: Record "Time Sheet Header"; TimeSheetLine: Record "Time Sheet Line"; PostingDate: Date; Hours: Decimal; ClockifyEntryId: Text[50]; var ResultMessage: Text): Enum "Clockify Sync Result ori"
    var
        TimeSheetDetail: Record "Time Sheet Detail";
    begin
        // Existing detail unchanged (same line, date and hours) → nothing to do.
        if TimeSheetDetail.GetBySystemId(Integration."BC SystemId") then
            if (TimeSheetDetail."Time Sheet No." = TimeSheetLine."Time Sheet No.") and
               (TimeSheetDetail."Time Sheet Line No." = TimeSheetLine."Line No.") and
               (TimeSheetDetail.Date = PostingDate) and
               (TimeSheetDetail.Quantity = Hours)
            then begin
                ResultMessage := StrSubstNo(SkippedMsg, ClockifyEntryId);
                exit(Enum::"Clockify Sync Result ori"::Skipped);
            end;

        if TimeSheetDetail.GetBySystemId(Integration."BC SystemId") then
            TimeSheetDetail.Delete(false);
        WriteDetail(TimeSheet, TimeSheetLine, PostingDate, Hours, TimeSheetDetail);
        Integration."BC SystemId" := TimeSheetDetail.SystemId;
        Integration."BC Code" := CopyStr(TimeSheetDetail."Time Sheet No." + '-' + Format(PostingDate, 0, 9), 1, 50);
        Integration.Modify(true);
        ResultMessage := StrSubstNo(UpdatedMsg, ClockifyEntryId, TimeSheet."No.", TimeSheetLine."Line No.");
        exit(Enum::"Clockify Sync Result ori"::Updated);
    end;

    local procedure WriteDetail(TimeSheet: Record "Time Sheet Header"; TimeSheetLine: Record "Time Sheet Line"; PostingDate: Date; Hours: Decimal; var TimeSheetDetail: Record "Time Sheet Detail")
    begin
        if TimeSheetDetail.Get(TimeSheetLine."Time Sheet No.", TimeSheetLine."Line No.", PostingDate) then
            TimeSheetDetail.Delete(false);
        TimeSheetDetail.Init();
        TimeSheetDetail.SystemId := CreateGuid();
        TimeSheetDetail."Time Sheet No." := TimeSheetLine."Time Sheet No.";
        TimeSheetDetail."Time Sheet Line No." := TimeSheetLine."Line No.";
        TimeSheetDetail.Date := PostingDate;
        TimeSheetDetail."Job No." := TimeSheetLine."Job No.";
        TimeSheetDetail."Job Task No." := TimeSheetLine."Job Task No.";
        TimeSheetDetail."Resource No." := TimeSheet."Resource No.";
        TimeSheetDetail.Type := TimeSheetLine.Type;
        TimeSheetDetail."Last Modified DateTime" := RoundDateTime(CurrentDateTime());
        TimeSheetDetail.Quantity := Hours;
        TimeSheetDetail.Insert(false, true);
    end;

    local procedure FindActiveIntegration(ClockifyEntryId: Text[50]; var Integration: Record "Clockify Integration ori"): Boolean
    begin
        Integration.SetCurrentKey("Clockify Type", "Clockify Id", "Reversed");
        Integration.SetRange("Clockify Type", 'TIME_ENTRY');
        Integration.SetRange("Clockify Id", ClockifyEntryId);
        Integration.SetRange("Reversed", false);
        Integration.SetRange("BC Table No.", Database::"Time Sheet Detail");
        exit(Integration.FindFirst());
    end;

    local procedure CreateIntegrationRecord(var Integration: Record "Clockify Integration ori"; ClockifyEntryId: Text[50]; ClockifyWorkspaceId: Text[50]; TimeSheetDetail: Record "Time Sheet Detail"; Description: Text; Hours: Decimal)
    begin
        Integration.Init();
        Integration."Entry No." := 0;
        Integration."BC Table No." := Database::"Time Sheet Detail";
        Integration."BC SystemId" := TimeSheetDetail.SystemId;
        Integration."BC Code" := CopyStr(TimeSheetDetail."Time Sheet No." + '-' + Format(TimeSheetDetail.Date, 0, 9), 1, 50);
        Integration."Clockify Type" := 'TIME_ENTRY';
        Integration."Clockify Workspace Id" := ClockifyWorkspaceId;
        Integration."Clockify Id" := ClockifyEntryId;
        Integration."Clockify Name" := CopyStr(Description + ' ' + Format(Hours) + 'h', 1, 250);
        Integration."Reversed" := false;
        Integration.Insert(true);
    end;
}
