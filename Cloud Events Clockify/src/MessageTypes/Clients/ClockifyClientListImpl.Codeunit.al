namespace Origo.PTE.CloudEvents.Clockify;

using Origo.APP.CloudEvents;

/// <summary>
/// Implementation of the <c>Clockify.Client.List</c> message type.
/// Lists the clients in a workspace.
/// </summary>
codeunit 70009212 "Clockify Client List Impl" implements "Cloud Event Msg Interface ori"
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
        exit('Lists the clients in a Clockify workspace.');
    end;

    internal procedure GetMessageDirection(): Enum "Cloud Event Msg Direction ori"
    begin
        exit(Enum::"Cloud Event Msg Direction ori"::Outbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "CE Message Argument ori")
    var
        HelpBuilder: Codeunit "Clockify Help Builder";
    begin
        HelpBuilder.Init('Clockify.Client.List', GetDescription(), 'GET', '/workspaces/{workspaceId}/clients');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Clockify.Workspace.List → id');
        HelpBuilder.AddParam('query.page-size', false, 'integer', 'Results per page (default 50, max 5000)', '');
        HelpBuilder.AddParam('query.page', false, 'integer', 'Page number (1-based)', '');
        HelpBuilder.AddParam('query.archived', false, 'boolean', 'Filter: true=archived only, false=active only, omit=all', '');
        HelpBuilder.AddParam('query.name', false, 'string', 'Filter: partial name match (case-insensitive)', '');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "query": { "page-size": 50, "page": 1, "archived": false } }');
        HelpBuilder.SetResponseNote('an array of client objects (each with `id`, `name`, `workspaceId`, `archived`)');
        HelpBuilder.SetAfterSuccess('No tracking action required — this is a read operation. Use the returned `id` values for subsequent create/update/delete calls.');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Cloud Events Setup');
        HelpBuilder.AddError(403, 'Forbidden', 'API key user lacks workspace access');
        HelpBuilder.SetRelated('- **Get single client:** `Clockify.Client.Get` (when you have the ID)\' +
            '- **Create new client:** `Clockify.Client.Create`\' +
            '- **Use for ID resolution:** Match response `name` to BC Customer Name → extract `id` for write operations');
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
        RequestMgt.Execute(Argument, 'GET', RequestMgt.AppendQuery(RequestJson, '/workspaces/' + WorkspaceId + '/clients'), false, '');
    end;
}
