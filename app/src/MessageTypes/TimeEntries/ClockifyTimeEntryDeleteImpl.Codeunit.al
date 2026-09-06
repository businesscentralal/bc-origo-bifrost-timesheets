namespace Origo.PTE.CloudEvents.Clockify;

using Origo.APP.CloudEvents;

/// <summary>
/// Implementation of the <c>Clockify.TimeEntry.Delete</c> message type.
/// Deletes a time entry by ID.
/// </summary>
codeunit 70009233 "Clockify TimeEntry Delete Impl" implements "Cloud Event Msg Interface ori"
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
        exit('Deletes a Clockify time entry by ID.');
    end;

    internal procedure GetMessageDirection(): Enum "Cloud Event Msg Direction ori"
    begin
        exit(Enum::"Cloud Event Msg Direction ori"::Outbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "CE Message Argument ori")
    var
        HelpBuilder: Codeunit "Clockify Help Builder";
    begin
        HelpBuilder.Init('Clockify.TimeEntry.Delete', GetDescription(), 'DELETE', '/workspaces/{workspaceId}/time-entries/{timeEntryId}');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Clockify.Workspace.List → id');
        HelpBuilder.AddParam('timeEntryId', true, 'string', 'The time entry ID to delete', 'Clockify.TimeEntry.List → id');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "timeEntryId": "64..." }');
        HelpBuilder.SetResponseNote('empty body (HTTP 204 No Content on success)');
        HelpBuilder.AddError(404, 'Time entry not found', 'Verify timeEntryId via `Clockify.TimeEntry.List`');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Cloud Events Setup');
        HelpBuilder.SetNotes('- No archive step required — time entries can be deleted directly.\' +
            '- If the entry was already synced to BC, consider reversing the Job Journal Line in BC as well.');
        HelpBuilder.SetRelated('- **Alternative:** Update with corrected times instead of deleting (`Clockify.TimeEntry.Update`)\' +
            '- **After delete in BC context:** Reverse or delete the corresponding Job Journal Line');
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
        RequestMgt.Execute(Argument, 'DELETE', '/workspaces/' + WorkspaceId + '/time-entries/' + TimeEntryId, false, '');
    end;
}
