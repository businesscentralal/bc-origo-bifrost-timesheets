namespace Origo.PTE.CloudEvents.Clockify;

using Origo.APP.CloudEvents;

/// <summary>
/// Implementation of the <c>Clockify.User.List</c> message type.
/// Lists the users in a workspace.
/// </summary>
codeunit 70009240 "Clockify User List Impl" implements "Cloud Event Msg Interface ori"
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
        exit('Lists the users in a Clockify workspace.');
    end;

    internal procedure GetMessageDirection(): Enum "Cloud Event Msg Direction ori"
    begin
        exit(Enum::"Cloud Event Msg Direction ori"::Outbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "CE Message Argument ori")
    var
        HelpBuilder: Codeunit "Clockify Help Builder";
    begin
        HelpBuilder.Init('Clockify.User.List', GetDescription(), 'GET', '/workspaces/{workspaceId}/users');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Clockify.Workspace.List → id');
        HelpBuilder.AddParam('query.page-size', false, 'integer', 'Results per page (default 50, max 5000)', '');
        HelpBuilder.AddParam('query.page', false, 'integer', 'Page number (1-based)', '');
        HelpBuilder.AddParam('query.email', false, 'string', 'Filter: exact email match', '');
        HelpBuilder.AddParam('query.name', false, 'string', 'Filter: partial name match', '');
        HelpBuilder.AddParam('query.status', false, 'string', 'Filter: ACTIVE, PENDING, DECLINED, INACTIVE', '');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "query": { "page-size": 50, "page": 1 } }');
        HelpBuilder.SetResponseNote('an array of user objects (each with `id`, `name`, `email`, `status`)');
        HelpBuilder.SetAfterSuccess('No tracking action required — this is a read operation. Use returned `id` values for time-entry and assignment operations.');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Cloud Events Setup');
        HelpBuilder.SetNotes('- Returns all members of the workspace, including pending invitations.\' +
            '- The `id` field is the `userId` needed for `Clockify.TimeEntry.Create/List` and `memberships` in project/task operations.');
        HelpBuilder.SetRelated('- **Get API key owner only:** `Clockify.User.GetCurrent`\' +
            '- **Assign to projects:** Use `id` in `memberships` array of `Clockify.Project.Create/Update`\' +
            '- **Map to BC Resource:** Store mapping in Clockify Integration table (type=user)');
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
        RequestMgt.Execute(Argument, 'GET', RequestMgt.AppendQuery(RequestJson, '/workspaces/' + WorkspaceId + '/users'), false, '');
    end;
}
