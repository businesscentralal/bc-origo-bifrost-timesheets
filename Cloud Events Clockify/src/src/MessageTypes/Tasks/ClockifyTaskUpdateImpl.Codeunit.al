namespace Origo.PTE.CloudEvents.Clockify;

using Origo.APP.CloudEvents;

/// <summary>
/// Implementation of the <c>Clockify.Task.Update</c> message type.
/// Updates an existing task from the request's <c>body</c> object.
/// </summary>
codeunit 71436 "Clockify Task Update Impl" implements "Cloud Event Msg Interface ori"
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
        exit('Updates an existing Clockify task from the request body.');
    end;

    internal procedure GetMessageDirection(): Enum "Cloud Event Msg Direction ori"
    begin
        exit(Enum::"Cloud Event Msg Direction ori"::Outbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "CE Message Argument ori")
    var
        HelpBuilder: Codeunit "Clockify Help Builder";
    begin
        HelpBuilder.Init('Clockify.Task.Update', GetDescription(), 'PUT', '/workspaces/{workspaceId}/projects/{projectId}/tasks/{taskId}');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Clockify.Workspace.List → id');
        HelpBuilder.AddParam('projectId', true, 'string', 'Parent project ID', 'Clockify.Project.List → id');
        HelpBuilder.AddParam('taskId', true, 'string', 'The task ID to update', 'Clockify.Task.List → id');
        HelpBuilder.AddParam('body.name', false, 'string', 'Task display name', '');
        HelpBuilder.AddParam('body.status', false, 'string', 'ACTIVE or DONE', '');
        HelpBuilder.AddParam('body.assigneeIds', false, 'array', 'Array of user IDs', 'Clockify.User.List → id');
        HelpBuilder.AddParam('body.billable', false, 'boolean', 'Override project billable default', '');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "projectId": "60...", "taskId": "61...", "body": { "name": "Design v2", "status": "ACTIVE" } }');
        HelpBuilder.SetResponseNote('the updated task object');
        HelpBuilder.AddError(400, 'Task name already exists in project', 'Choose a different name');
        HelpBuilder.AddError(404, 'Task or project not found', 'Verify IDs via `Clockify.Task.List`');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Cloud Events Setup');
        HelpBuilder.SetNotes('- Send only fields you want to change; omitted fields retain current values.\' +
            '- To mark a task complete, set `status` to `DONE`.');
        HelpBuilder.SetRelated('- **Resolve taskId:** `Clockify.Task.List` or Clockify Integration (type=task)\' +
            '- **Delete task:** `Clockify.Task.Delete` (no archive step needed for tasks)');
        Argument.SetResponseMarkdown(HelpBuilder.Render());
    end;

    internal procedure ExecuteCloudEventTask(var Argument: Record "CE Message Argument ori")
    var
        RequestMgt: Codeunit "Clockify Request Mgt";
        RequestJson: JsonObject;
        WorkspaceId: Text;
        ProjectId: Text;
        TaskId: Text;
        BodyText: Text;
    begin
        Argument.AssertVersion1();
        RequestJson := Argument.GetRequestJson();
        if not RequestMgt.ResolveWorkspaceId(Argument, RequestJson, WorkspaceId) then
            exit;
        if not RequestMgt.RequireParam(Argument, RequestJson, 'projectId', ProjectId) then
            exit;
        if not RequestMgt.RequireParam(Argument, RequestJson, 'taskId', TaskId) then
            exit;
        if not RequestMgt.RequireBody(Argument, RequestJson, BodyText) then
            exit;
        RequestMgt.Execute(Argument, 'PUT', '/workspaces/' + WorkspaceId + '/projects/' + ProjectId + '/tasks/' + TaskId, true, BodyText);
    end;
}
