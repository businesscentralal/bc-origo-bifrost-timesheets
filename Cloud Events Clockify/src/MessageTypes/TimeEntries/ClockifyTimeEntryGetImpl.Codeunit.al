namespace Origo.PTE.CloudEvents.Clockify;

using Origo.APP.CloudEvents;

/// <summary>
/// Implementation of the <c>Clockify.TimeEntry.Get</c> message type.
/// Retrieves a single time entry by ID.
/// </summary>
codeunit 70009234 "Clockify TimeEntry Get Impl" implements "Cloud Event Msg Interface ori"
{
    Access = Internal;

    internal procedure IsEnabled(): Boolean
    var
        ClockifyIntegration: Record "Clockify Integration";
        SecretMgt: Codeunit "Clockify Secret Mgt";
    begin
        if not ClockifyIntegration.WritePermission() then
            exit(false);
        exit(SecretMgt.HasCompanyApiKey());
    end;

    internal procedure GetFilterTableNo(): Integer
    begin
        exit(0);
    end;

    internal procedure GetDescription(): Text[250]
    begin
        exit('Retrieves a single Clockify time entry by ID.');
    end;

    internal procedure GetMessageDirection(): Enum "Cloud Event Msg Direction ori"
    begin
        exit(Enum::"Cloud Event Msg Direction ori"::Outbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "CE Message Argument ori")
    var
        HelpBuilder: Codeunit "Clockify Help Builder";
    begin
        HelpBuilder.Init('Clockify.TimeEntry.Get', GetDescription(), 'GET', '/workspaces/{workspaceId}/time-entries/{timeEntryId}');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Clockify.Workspace.List → id');
        HelpBuilder.AddParam('timeEntryId', true, 'string', 'The time entry ID to retrieve', 'Clockify.TimeEntry.List → id');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "timeEntryId": "64..." }');
        HelpBuilder.SetResponseNote('the time-entry object (includes `id`, `start`, `end`, `duration`, `projectId`, `taskId`, `tagIds`, `billable`)');
        HelpBuilder.SetAfterSuccess('No tracking action required — this is a read operation.');
        HelpBuilder.AddError(404, 'Time entry not found', 'Verify timeEntryId via `Clockify.TimeEntry.List`');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Cloud Events Setup');
        HelpBuilder.SetRelated('- **Find timeEntryId:** `Clockify.TimeEntry.List` (requires userId)\' +
            '- **Update this entry:** `Clockify.TimeEntry.Update`\' +
            '- **Sync to BC:** `Clockify.TimeEntry.Sync`');
        Argument.SetResponseMarkdown(HelpBuilder.Render());
    end;

    internal procedure ExecuteCloudEventTask(var Argument: Record "CE Message Argument ori")
    var
        RequestMgt: Codeunit "Clockify Request Mgt";
        RequestJson: JsonObject;
        WorkspaceId: Text;
        TimeEntryId: Text;
    begin
        Argument.AssertVersion1();
        RequestJson := Argument.GetRequestJson();
        if not RequestMgt.ResolveWorkspaceId(Argument, RequestJson, WorkspaceId) then
            exit;
        if not RequestMgt.RequireParam(Argument, RequestJson, 'timeEntryId', TimeEntryId) then
            exit;
        RequestMgt.Execute(Argument, 'GET', '/workspaces/' + WorkspaceId + '/time-entries/' + TimeEntryId, false, '');
    end;
}
