namespace Origo.PTE.CloudEvents.Clockify;

using Origo.APP.CloudEvents;

/// <summary>
/// Implementation of the <c>Clockify.Project.Create</c> message type.
/// Creates a project in a workspace from the request's <c>body</c> object.
/// </summary>
codeunit 70009219 "Clockify Project Create Impl" implements "Cloud Event Msg Interface ori"
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
        exit('Creates a project in a Clockify workspace from the request body.');
    end;

    internal procedure GetMessageDirection(): Enum "Cloud Event Msg Direction ori"
    begin
        exit(Enum::"Cloud Event Msg Direction ori"::Outbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "CE Message Argument ori")
    var
        HelpBuilder: Codeunit "Clockify Help Builder";
    begin
        HelpBuilder.Init('Clockify.Project.Create', GetDescription(), 'POST', '/workspaces/{workspaceId}/projects');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Clockify.Workspace.List → id');
        HelpBuilder.AddParam('body.name', true, 'string', 'Project display name (must be unique in workspace)', '');
        HelpBuilder.AddParam('body.clientId', false, 'string', 'Clockify client ID to associate (NOT the BC customer number)', 'Clockify.Client.List → id');
        HelpBuilder.AddParam('body.isPublic', false, 'boolean', 'true = visible to all workspace members (default true)', '');
        HelpBuilder.AddParam('body.billable', false, 'boolean', 'true = time entries default to billable', '');
        HelpBuilder.AddParam('body.color', false, 'string', 'Hex colour code (e.g. #f44336)', '');
        HelpBuilder.AddParam('body.note', false, 'string', 'Free-text project description', '');
        HelpBuilder.AddParam('body.hourlyRate', false, 'object', '{ "amount": <cents>, "currency": "USD" }', '');
        HelpBuilder.AddParam('body.userGroupIds', false, 'array', 'Array of Clockify user-group IDs', 'Clockify.UserGroup.List → id');
        HelpBuilder.AddParam('body.memberships', false, 'array', 'Array of { "userId": "...", "hourlyRate": {...} }', 'Clockify.User.List → id');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "body": { "name": "Implementation", "clientId": "60...", "isPublic": false, "billable": true, "color": "#f44336", "userGroupIds": [ "61..." ] } }');
        HelpBuilder.SetResponseNote('the created project object (includes `id`, `name`, `clientId`, `workspaceId`)');
        HelpBuilder.AddError(400, 'Project name already exists', 'Use `Clockify.Project.List` to find existing, or choose a different name');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Cloud Events Setup');
        HelpBuilder.AddError(403, 'Forbidden', 'API key user lacks workspace admin role');
        HelpBuilder.SetNotes('- `clientId` must be the Clockify internal ID (from `Clockify.Client.List`), not a BC customer number.\' +
            '- `userGroupIds` requires Clockify group IDs; group names are silently ignored.\' +
            '- Custom field defaults cannot be set at creation — create the project first, then call `Clockify.Project.Update` with `customFields` array.');
        HelpBuilder.SetRelated('- **Resolve clientId:** `Clockify.Client.List` or Clockify Integration (type=client)\' +
            '- **Resolve userGroupIds:** `Clockify.UserGroup.List` → `id`\' +
            '- **Set custom fields after create:** `Clockify.Project.Update` with `customFields`\' +
            '- **Add tasks:** `Clockify.Task.Create` (requires project `id` from response)\' +
            '- **To delete later:** Archive first (`Clockify.Project.Update` → `archived: true`), then `Clockify.Project.Delete`');
        Argument.SetResponseMarkdown(HelpBuilder.Render());
    end;

    internal procedure ExecuteCloudEventTask(var Argument: Record "CE Message Argument ori")
    var
        RequestMgt: Codeunit "Clockify Request Mgt";
        RequestJson: JsonObject;
        WorkspaceId: Text;
        BodyText: Text;
    begin
        Argument.AssertVersion1();
        RequestJson := Argument.GetRequestJson();
        if not RequestMgt.ResolveWorkspaceId(Argument, RequestJson, WorkspaceId) then
            exit;
        if not RequestMgt.RequireBody(Argument, RequestJson, BodyText) then
            exit;
        RequestMgt.Execute(Argument, 'POST', '/workspaces/' + WorkspaceId + '/projects', true, BodyText);
    end;
}
