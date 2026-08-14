namespace Origo.PTE.CloudEvents.Clockify;

using Origo.APP.CloudEvents;

/// <summary>
/// Implementation of the <c>Clockify.Task.Create</c> message type.
/// Creates a task in a project from the request's <c>body</c> object.
/// </summary>
codeunit 71435 "Clockify Task Create Impl" implements "Cloud Event Msg Interface ori"
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
        exit('Creates a task in a Clockify project from the request body.');
    end;

    internal procedure GetMessageDirection(): Enum "Cloud Event Msg Direction ori"
    begin
        exit(Enum::"Cloud Event Msg Direction ori"::Outbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "CE Message Argument ori")
    var
        HelpBuilder: Codeunit "Clockify Help Builder";
    begin
        HelpBuilder.Init('Clockify.Task.Create', GetDescription(), 'POST', '/workspaces/{workspaceId}/projects/{projectId}/tasks');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Clockify.Workspace.List → id');
        HelpBuilder.AddParam('projectId', true, 'string', 'Parent project ID (tasks belong to a project)', 'Clockify.Project.List → id');
        HelpBuilder.AddParam('body.name', true, 'string', 'Task display name (must be unique within the project)', '');
        HelpBuilder.AddParam('body.status', false, 'string', 'ACTIVE (default) or DONE', '');
        HelpBuilder.AddParam('body.assigneeIds', false, 'array', 'Array of user IDs to assign', 'Clockify.User.List → id');
        HelpBuilder.AddParam('body.billable', false, 'boolean', 'Override project billable default', '');
        HelpBuilder.AddParam('body.hourlyRate', false, 'object', '{ "amount": <cents>, "currency": "USD" }', '');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "projectId": "60...", "body": { "name": "Design" } }');
        HelpBuilder.SetResponseNote('the created task object (includes `id`, `name`, `projectId`, `status`)');
        HelpBuilder.AddError(400, 'Task name already exists in project', 'Choose a different name or find existing via `Clockify.Task.List`');
        HelpBuilder.AddError(404, 'Project not found', 'Verify projectId via `Clockify.Project.List`');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Cloud Events Setup');
        HelpBuilder.SetNotes('- Tasks are scoped to a project — you always need both workspaceId and projectId.\' +
            '- Task names must be unique within a project but can repeat across projects.');
        HelpBuilder.SetRelated('- **Resolve projectId:** `Clockify.Project.List` or Clockify Integration (type=project)\' +
            '- **List existing tasks:** `Clockify.Task.List`\' +
            '- **Use in time entries:** Pass task `id` as `taskId` in `Clockify.TimeEntry.Create`');
        Argument.SetResponseMarkdown(HelpBuilder.Render());
    end;

    internal procedure ExecuteCloudEventTask(var Argument: Record "CE Message Argument ori")
    var
        RequestMgt: Codeunit "Clockify Request Mgt";
        RequestJson: JsonObject;
        WorkspaceId: Text;
        ProjectId: Text;
        BodyText: Text;
    begin
        Argument.AssertVersion1();
        RequestJson := Argument.GetRequestJson();
        if not RequestMgt.ResolveWorkspaceId(Argument, RequestJson, WorkspaceId) then
            exit;
        if not RequestMgt.RequireParam(Argument, RequestJson, 'projectId', ProjectId) then
            exit;
        if not RequestMgt.RequireBody(Argument, RequestJson, BodyText) then
            exit;
        RequestMgt.Execute(Argument, 'POST', '/workspaces/' + WorkspaceId + '/projects/' + ProjectId + '/tasks', true, BodyText);
    end;
}
