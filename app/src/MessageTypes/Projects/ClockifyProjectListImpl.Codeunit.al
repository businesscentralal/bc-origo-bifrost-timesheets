namespace Origo.PTE.CloudEvents.Clockify;

using Origo.APP.CloudEvents;

/// <summary>
/// Implementation of the <c>Clockify.Project.List</c> message type.
/// Lists the projects in a workspace.
/// </summary>
codeunit 70009222 "Clockify Project List Impl" implements "Cloud Event Msg Interface ori"
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
        exit('Lists the projects in a Clockify workspace.');
    end;

    internal procedure GetMessageDirection(): Enum "Cloud Event Msg Direction ori"
    begin
        exit(Enum::"Cloud Event Msg Direction ori"::Outbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "CE Message Argument ori")
    var
        HelpBuilder: Codeunit "Clockify Help Builder";
    begin
        HelpBuilder.Init('Clockify.Project.List', GetDescription(), 'GET', '/workspaces/{workspaceId}/projects');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Clockify.Workspace.List → id');
        HelpBuilder.AddParam('query.page-size', false, 'integer', 'Results per page (default 50, max 5000)', '');
        HelpBuilder.AddParam('query.page', false, 'integer', 'Page number (1-based)', '');
        HelpBuilder.AddParam('query.archived', false, 'boolean', 'Filter: true=archived only, false=active only, omit=all', '');
        HelpBuilder.AddParam('query.name', false, 'string', 'Filter: partial name match (case-insensitive)', '');
        HelpBuilder.AddParam('query.clients', false, 'string', 'Filter: comma-separated client IDs', 'Clockify.Client.List → id');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "query": { "page-size": 50, "page": 1, "archived": false } }');
        HelpBuilder.SetResponseNote('an array of project objects (each with `id`, `name`, `clientId`, `archived`)');
        HelpBuilder.SetAfterSuccess('No tracking action required — this is a read operation. Use the returned `id` values for task/timeEntry operations.');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Cloud Events Setup');
        HelpBuilder.SetRelated('- **Get single project:** `Clockify.Project.Get`\' +
            '- **Create project:** `Clockify.Project.Create`\' +
            '- **List tasks under project:** `Clockify.Task.List` (requires projectId from this response)');
        Argument.SetResponseMarkdown(HelpBuilder.Render());
    end;

    internal procedure ExecuteCloudEventTask(var Argument: Record "CE Message Argument ori")
    var
        RequestMgt: Codeunit "Clockify Request Mgt";
        RequestJson: JsonObject;
        WorkspaceId: Text;
    begin
        Argument.AssertVersion1();
        RequestJson := Argument.GetRequestJson();
        if not RequestMgt.ResolveWorkspaceId(Argument, RequestJson, WorkspaceId) then
            exit;
        RequestMgt.Execute(Argument, 'GET', RequestMgt.AppendQuery(RequestJson, '/workspaces/' + WorkspaceId + '/projects'), false, '');
    end;
}
