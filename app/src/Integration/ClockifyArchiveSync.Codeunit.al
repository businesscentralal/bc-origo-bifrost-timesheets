namespace Origo.Bifrost.Timesheets;

/// <summary>
/// Archives Clockify entities (Client, Project, Task) when the corresponding BC
/// record is deleted, blocked, or completed. Calls the Clockify Update API with
/// <c>{ "archived": true }</c>. Non-blocking: if the API call fails, a telemetry
/// warning is logged but the BC operation is not prevented.
/// </summary>
codeunit 10036785 "Clockify Archive Sync ori"
{
    Access = Internal;

    var
        ArchiveBodyTok: Label '{"archived":true}', Locked = true;
        ArchiveFailedMsg: Label 'Failed to archive Clockify %1 %2 (HTTP %3). BC operation was not blocked.', Comment = '%1 = type, %2 = Clockify ID, %3 = status code. is-IS=Ekki tókst að setja Clockify %1 %2 í geymslu (HTTP %3). Aðgerðin í BC var ekki stöðvuð.';
        ArchiveSuccessMsg: Label 'Archived Clockify %1 %2 after BC %3 was %4.', Comment = '%1 = type, %2 = Clockify ID, %3 = BC entity, %4 = action. is-IS=Clockify %1 %2 sett í geymslu eftir að BC %3 var %4.';

    /// <summary>
    /// Archives all active Clockify entities linked to a given BC table/SystemId.
    /// </summary>
    /// <param name="BCTableNo">The BC table number (e.g. 18 for Customer).</param>
    /// <param name="BCSystemId">The SystemId of the BC record being deleted/blocked.</param>
    /// <param name="BCEntityName">Human-readable entity name for telemetry (e.g. 'Customer').</param>
    /// <param name="ActionName">The BC action that triggered this (e.g. 'deleted', 'blocked').</param>
    procedure ArchiveLinkedEntities(BCTableNo: Integer; BCSystemId: Guid; BCEntityName: Text; ActionName: Text)
    var
        Integration: Record "Clockify Integration ori";
    begin
        Integration.SetCurrentKey("BC Table No.", "BC SystemId", "Reversed");
        Integration.SetRange("BC Table No.", BCTableNo);
        Integration.SetRange("BC SystemId", BCSystemId);
        Integration.SetRange("Reversed", false);
        Integration.SetLoadFields("Entry No.", "BC Code", "Clockify Type", "Clockify Workspace Id", "Clockify Id", "Reversed");
        if not Integration.FindSet() then
            exit;

        repeat
            ArchiveInClockify(Integration, BCEntityName, ActionName);
        until Integration.Next() = 0;
    end;

    /// <summary>
    /// Archives all active Clockify entities linked to a given BC table and Code field.
    /// Used when only the record key is available (e.g. Job No.) but SystemId may not be stable.
    /// </summary>
    /// <param name="ClockifyType">The integration type to look for (e.g. 'CLIENT', 'PROJECT', 'TASK').</param>
    /// <param name="BCCode">The BC Code stored in the integration record.</param>
    /// <param name="BCEntityName">Human-readable entity name for telemetry.</param>
    /// <param name="ActionName">The BC action that triggered this.</param>
    procedure ArchiveByClockifyType(ClockifyType: Code[20]; BCCode: Code[50]; BCEntityName: Text; ActionName: Text)
    var
        Integration: Record "Clockify Integration ori";
    begin
        Integration.SetCurrentKey("Clockify Type", "Clockify Id", "Reversed");
        Integration.SetRange("Clockify Type", ClockifyType);
        Integration.SetRange("Reversed", false);
        Integration.SetRange("BC Code", BCCode);
        Integration.SetLoadFields("Entry No.", "BC Code", "Clockify Type", "Clockify Workspace Id", "Clockify Id", "Reversed");
        if not Integration.FindSet() then
            exit;

        repeat
            ArchiveInClockify(Integration, BCEntityName, ActionName);
        until Integration.Next() = 0;
    end;

    local procedure ArchiveInClockify(var Integration: Record "Clockify Integration ori"; BCEntityName: Text; ActionName: Text)
    var
        RequestMgt: Codeunit "Clockify Request Mgt ori";
        ApiClient: Interface "Clockify API Client ori";
        ResourcePath: Text;
        ResponseBody: Text;
        StatusCode: Integer;
        Success: Boolean;
    begin
        ResourcePath := BuildArchivePath(Integration);
        if ResourcePath = '' then
            exit;

        ApiClient := RequestMgt.GetApiClient();
        Success := ApiClient.Send('PUT', ResourcePath, true, ArchiveBodyTok, ResponseBody, StatusCode);

        if Success then begin
            Integration."Reversed" := true;
            Integration.Modify(true);
            Session.LogMessage(
                'CLK0010', StrSubstNo(ArchiveSuccessMsg, Integration."Clockify Type", Integration."Clockify Id", BCEntityName, ActionName),
                Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'Clockify');
        end else
            Session.LogMessage(
                'CLK0011', StrSubstNo(ArchiveFailedMsg, Integration."Clockify Type", Integration."Clockify Id", StatusCode),
                Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'Clockify');
    end;

    local procedure BuildArchivePath(Integration: Record "Clockify Integration ori"): Text
    var
        WorkspaceId: Text;
    begin
        WorkspaceId := Integration."Clockify Workspace Id";
        if WorkspaceId = '' then
            exit('');

        case Integration."Clockify Type" of
            'CLIENT':
                exit('/workspaces/' + WorkspaceId + '/clients/' + Integration."Clockify Id");
            'PROJECT':
                exit('/workspaces/' + WorkspaceId + '/projects/' + Integration."Clockify Id");
            'TASK':
                exit(BuildTaskPath(Integration));
        end;
        exit('');
    end;

    local procedure BuildTaskPath(Integration: Record "Clockify Integration ori"): Text
    var
        ProjectIntegration: Record "Clockify Integration ori";
        WorkspaceId: Text;
        ProjectId: Text;
        BCCode: Text;
        DashPos: Integer;
        JobNo: Code[50];
    begin
        // Task BC Code is "JobNo-TaskNo" — extract JobNo to find the project integration
        WorkspaceId := Integration."Clockify Workspace Id";
        BCCode := Integration."BC Code";
        DashPos := BCCode.LastIndexOf('-');
        if DashPos <= 0 then
            exit('');

        JobNo := CopyStr(BCCode.Substring(1, DashPos - 1), 1, MaxStrLen(JobNo));

        // Find the project's Clockify ID — read-only lookup, no update lock needed.
        ProjectIntegration.ReadIsolation := IsolationLevel::ReadCommitted;
        ProjectIntegration.SetCurrentKey("Clockify Type", "Clockify Id", "Reversed");
        ProjectIntegration.SetRange("Clockify Type", 'PROJECT');
        ProjectIntegration.SetRange("BC Code", JobNo);
        ProjectIntegration.SetRange("Reversed", false);
        ProjectIntegration.SetLoadFields("Clockify Id");
        if not ProjectIntegration.FindFirst() then
            exit('');

        ProjectId := ProjectIntegration."Clockify Id";
        exit('/workspaces/' + WorkspaceId + '/projects/' + ProjectId + '/tasks/' + Integration."Clockify Id");
    end;
}
