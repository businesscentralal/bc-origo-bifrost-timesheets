namespace Origo.PTE.CloudEvents.Clockify;

using Origo.APP.CloudEvents;

/// <summary>
/// Implementation of the <c>Clockify.Project.Update</c> message type.
/// Updates an existing project from the request's <c>body</c> object.
/// </summary>
codeunit 70009223 "Clockify Project Update Impl" implements "Cloud Event Msg Interface ori"
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
        exit('Updates an existing Clockify project from the request body.');
    end;

    internal procedure GetMessageDirection(): Enum "Cloud Event Msg Direction ori"
    begin
        exit(Enum::"Cloud Event Msg Direction ori"::Outbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "CE Message Argument ori")
    var
        HelpBuilder: Codeunit "Clockify Help Builder";
    begin
        HelpBuilder.Init('Clockify.Project.Update', GetDescription(), 'PUT', '/workspaces/{workspaceId}/projects/{projectId}');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Clockify.Workspace.List → id');
        HelpBuilder.AddParam('projectId', true, 'string', 'The Clockify project ID to update', 'Clockify Integration table → Clockify Id (type=project)');
        HelpBuilder.AddParam('body.name', false, 'string', 'Project display name', '');
        HelpBuilder.AddParam('body.clientId', false, 'string', 'Clockify client ID', 'Clockify.Client.List → id');
        HelpBuilder.AddParam('body.isPublic', false, 'boolean', 'Visibility to all workspace members', '');
        HelpBuilder.AddParam('body.billable', false, 'boolean', 'Default billable status for time entries', '');
        HelpBuilder.AddParam('body.color', false, 'string', 'Hex colour code', '');
        HelpBuilder.AddParam('body.note', false, 'string', 'Free-text description', '');
        HelpBuilder.AddParam('body.archived', false, 'boolean', 'Set true to archive (required before delete)', '');
        HelpBuilder.AddParam('body.userGroupIds', false, 'array', 'Array of Clockify user-group IDs', 'Clockify.UserGroup.List → id');
        HelpBuilder.AddParam('body.customFields', false, 'array', 'Array of { customFieldId, status, defaultValue }', 'Clockify.CustomField.List → id');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "projectId": "60...", "body": { "name": "Implementation 2026", "archived": false, "billable": true, "customFields": [ { "customFieldId": "62...", "status": "VISIBLE", "defaultValue": "Iceland" } ] } }');
        HelpBuilder.SetResponseNote('the updated project object');
        HelpBuilder.AddError(400, 'Project name already exists', 'Choose a different name');
        HelpBuilder.AddError(404, 'Project not found', 'Verify projectId via `Clockify.Project.List`');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Cloud Events Setup');
        HelpBuilder.SetNotes('- `clientId` and `userGroupIds` require Clockify IDs — names and BC keys are silently ignored.\' +
            '- `customFields` format: `{ "customFieldId": "...", "status": "VISIBLE"|"INVISIBLE", "defaultValue": ... }`. Get `customFieldId` from `Clockify.CustomField.List`.\' +
            '- Setting `archived: true` is the **required first step** before `Clockify.Project.Delete`.\' +
            '- Send only fields you want to change; omitted fields retain current values.');
        HelpBuilder.SetRelated('- **Archive before delete:** Set `body.archived` = true, then `Clockify.Project.Delete`\' +
            '- **Resolve customFieldId:** `Clockify.CustomField.List` → `id`\' +
            '- **Resolve clientId:** `Clockify.Client.List` or Clockify Integration (type=client)');
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
        RequestMgt.Execute(Argument, 'PUT', '/workspaces/' + WorkspaceId + '/projects/' + ProjectId, true, BodyText);
    end;
}
