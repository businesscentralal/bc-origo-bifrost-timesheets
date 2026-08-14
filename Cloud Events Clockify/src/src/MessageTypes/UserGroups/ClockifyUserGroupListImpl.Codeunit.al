namespace Origo.PTE.CloudEvents.Clockify;

using Origo.APP.CloudEvents;

/// <summary>
/// Implementation of the <c>Clockify.UserGroup.List</c> message type.
/// Lists the user groups defined in a Clockify workspace. The Clockify internal
/// <c>id</c> returned here is the value that must be sent as a member of
/// <c>userGroupIds</c> in the body of <c>Clockify.Project.Create</c> /
/// <c>Clockify.Project.Update</c> (project access and default assignees) and in
/// task assignment writes. Group names are not accepted on those write paths.
/// </summary>
codeunit 71449 "Clockify UserGroup List Impl" implements "Cloud Event Msg Interface ori"
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
        exit('Lists the user groups defined in a Clockify workspace.');
    end;

    internal procedure GetMessageDirection(): Enum "Cloud Event Msg Direction ori"
    begin
        exit(Enum::"Cloud Event Msg Direction ori"::Outbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "CE Message Argument ori")
    var
        HelpBuilder: Codeunit "Clockify Help Builder";
    begin
        HelpBuilder.Init('Clockify.UserGroup.List', GetDescription(), 'GET', '/workspaces/{workspaceId}/user-groups');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Clockify.Workspace.List → id');
        HelpBuilder.AddParam('query.page-size', false, 'integer', 'Results per page (default 50, max 5000)', '');
        HelpBuilder.AddParam('query.page', false, 'integer', 'Page number (1-based)', '');
        HelpBuilder.AddParam('query.name', false, 'string', 'Filter: partial name match', '');
        HelpBuilder.AddParam('query.projectId', false, 'string', 'Filter: groups assigned to this project', 'Clockify.Project.List → id');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "query": { "page-size": 50, "page": 1 } }');
        HelpBuilder.SetResponseNote('an array of user-group objects (each with `id`, `name`, `workspaceId`, `userIds`)');
        HelpBuilder.SetAfterSuccess('No tracking action required — this is a read operation. Use `id` values for project `userGroupIds`.');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Cloud Events Setup');
        HelpBuilder.SetNotes('- Each group has a `userIds` array listing member Clockify user IDs.\' +
            '- Use the `id` value as a member of `userGroupIds` in `Clockify.Project.Create` / `Clockify.Project.Update`. Group **names** are not accepted on those write paths.');
        HelpBuilder.SetRelated('- **Assign group to project:** `Clockify.Project.Create` or `Clockify.Project.Update` (body.userGroupIds)\' +
            '- **List group members:** Check `userIds` array in response; resolve to names via `Clockify.User.List`');
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
        RequestMgt.Execute(Argument, 'GET', RequestMgt.AppendQuery(RequestJson, '/workspaces/' + WorkspaceId + '/user-groups'), false, '');
    end;
}
