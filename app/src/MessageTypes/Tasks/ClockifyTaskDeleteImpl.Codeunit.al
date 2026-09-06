namespace Origo.PTE.CloudEvents.Clockify;

using Origo.APP.CloudEvents;

/// <summary>
/// Implementation of the <c>Clockify.Task.Delete</c> message type.
/// Deletes a task by ID.
/// </summary>
codeunit 70009229 "Clockify Task Delete Impl" implements "Cloud Event Msg Interface ori"
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
        exit('Deletes a Clockify task by ID.');
    end;

    internal procedure GetMessageDirection(): Enum "Cloud Event Msg Direction ori"
    begin
        exit(Enum::"Cloud Event Msg Direction ori"::Outbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "CE Message Argument ori")
    var
        HelpBuilder: Codeunit "Clockify Help Builder";
    begin
        HelpBuilder.Init('Clockify.Task.Delete', GetDescription(), 'DELETE', '/workspaces/{workspaceId}/projects/{projectId}/tasks/{taskId}');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Clockify.Workspace.List → id');
        HelpBuilder.AddParam('projectId', true, 'string', 'Parent project ID', 'Clockify.Project.List → id');
        HelpBuilder.AddParam('taskId', true, 'string', 'The task ID to delete', 'Clockify.Task.List → id');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "projectId": "60...", "taskId": "61..." }');
        HelpBuilder.SetResponseNote('the deleted task object');
        HelpBuilder.AddError(404, 'Task or project not found', 'Verify IDs via `Clockify.Task.List`');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Cloud Events Setup');
        HelpBuilder.SetNotes('- Unlike clients and projects, tasks do NOT require archiving before delete.\' +
            '- Time entries referencing this task retain their data but the task link becomes orphaned.');
        HelpBuilder.SetRelated('- **Alternative to delete:** Set status to DONE via `Clockify.Task.Update`\' +
            '- **After delete:** `Data.Records.Set` on Clockify Integration → `Reversed` = true');
        Argument.SetResponseMarkdown(HelpBuilder.Render());
    end;

    internal procedure ExecuteCloudEventTask(var Argument: Record "CE Message Argument ori")
    var
        RequestMgt: Codeunit "Clockify Request Mgt";
        RequestJson: JsonObject;
        WorkspaceId: Text;
        ProjectId: Text;
        TaskId: Text;
    begin
        Argument.AssertVersion1();
        RequestJson := Argument.GetRequestJson();
        if not RequestMgt.ResolveWorkspaceId(Argument, RequestJson, WorkspaceId) then
            exit;
        if not RequestMgt.RequireParam(Argument, RequestJson, 'projectId', ProjectId) then
            exit;
        if not RequestMgt.RequireParam(Argument, RequestJson, 'taskId', TaskId) then
            exit;
        RequestMgt.Execute(Argument, 'DELETE', '/workspaces/' + WorkspaceId + '/projects/' + ProjectId + '/tasks/' + TaskId, false, '');
    end;
}
