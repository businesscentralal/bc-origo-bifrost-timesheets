namespace Origo.PTE.CloudEvents.Clockify;

using Origo.APP.CloudEvents;

/// <summary>
/// Implementation of the <c>Clockify.Task.List</c> message type.
/// Lists the tasks of a project.
/// </summary>
codeunit 70009230 "Clockify Task List Impl" implements "Cloud Event Msg Interface ori"
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
        exit('Lists the tasks of a Clockify project.');
    end;

    internal procedure GetMessageDirection(): Enum "Cloud Event Msg Direction ori"
    begin
        exit(Enum::"Cloud Event Msg Direction ori"::Outbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "CE Message Argument ori")
    var
        HelpBuilder: Codeunit "Clockify Help Builder";
    begin
        HelpBuilder.Init('Clockify.Task.List', GetDescription(), 'GET', '/workspaces/{workspaceId}/projects/{projectId}/tasks');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Clockify.Workspace.List → id');
        HelpBuilder.AddParam('projectId', true, 'string', 'Parent project ID', 'Clockify.Project.List → id');
        HelpBuilder.AddParam('query.page-size', false, 'integer', 'Results per page (default 50, max 5000)', '');
        HelpBuilder.AddParam('query.page', false, 'integer', 'Page number (1-based)', '');
        HelpBuilder.AddParam('query.is-active', false, 'boolean', 'Filter: true=active only, false=done only', '');
        HelpBuilder.AddParam('query.name', false, 'string', 'Filter: partial name match', '');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "projectId": "60...", "query": { "page-size": 50, "page": 1 } }');
        HelpBuilder.SetResponseNote('an array of task objects (each with `id`, `name`, `projectId`, `status`)');
        HelpBuilder.SetAfterSuccess('No tracking action required — this is a read operation. Use returned `id` values for time-entry or update calls.');
        HelpBuilder.AddError(404, 'Project not found', 'Verify projectId via `Clockify.Project.List`');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Cloud Events Setup');
        HelpBuilder.SetRelated('- **Create task:** `Clockify.Task.Create`\' +
            '- **Use in time entries:** Pass task `id` as `taskId` in `Clockify.TimeEntry.Create`\' +
            '- **Update task:** `Clockify.Task.Update`');
        Argument.SetResponseMarkdown(HelpBuilder.Render());
    end;

    internal procedure ExecuteCloudEventTask(var Argument: Record "CE Message Argument ori")
    var
        RequestMgt: Codeunit "Clockify Request Mgt";
        RequestJson: JsonObject;
        WorkspaceId: Text;
        ProjectId: Text;
    begin
        Argument.AssertVersion1();
        RequestJson := Argument.GetRequestJson();
        if not RequestMgt.ResolveWorkspaceId(Argument, RequestJson, WorkspaceId) then
            exit;
        if not RequestMgt.RequireParam(Argument, RequestJson, 'projectId', ProjectId) then
            exit;
        RequestMgt.Execute(Argument, 'GET', RequestMgt.AppendQuery(RequestJson, '/workspaces/' + WorkspaceId + '/projects/' + ProjectId + '/tasks'), false, '');
    end;
}
