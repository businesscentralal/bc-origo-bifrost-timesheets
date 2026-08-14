namespace Origo.PTE.CloudEvents.Clockify;

using Origo.APP.CloudEvents;

/// <summary>
/// Implementation of the <c>Clockify.Project.Get</c> message type.
/// Retrieves a single project by ID.
/// </summary>
codeunit 71430 "Clockify Project Get Impl" implements "Cloud Event Msg Interface ori"
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
        exit('Retrieves a single Clockify project by ID.');
    end;

    internal procedure GetMessageDirection(): Enum "Cloud Event Msg Direction ori"
    begin
        exit(Enum::"Cloud Event Msg Direction ori"::Outbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "CE Message Argument ori")
    var
        HelpBuilder: Codeunit "Clockify Help Builder";
    begin
        HelpBuilder.Init('Clockify.Project.Get', GetDescription(), 'GET', '/workspaces/{workspaceId}/projects/{projectId}');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Clockify.Workspace.List → id');
        HelpBuilder.AddParam('projectId', true, 'string', 'The Clockify project ID to retrieve', 'Clockify Integration table → Clockify Id (type=project)');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "projectId": "60..." }');
        HelpBuilder.SetResponseNote('the project object (includes `id`, `name`, `clientId`, `memberships`, `archived`, `customFields`)');
        HelpBuilder.SetAfterSuccess('No tracking action required — this is a read operation.');
        HelpBuilder.AddError(404, 'Project not found', 'Verify projectId exists via `Clockify.Project.List`');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Cloud Events Setup');
        HelpBuilder.SetRelated('- **Find projectId:** `Clockify.Project.List` or `Data.Records.Get` on Clockify Integration (type=project)\' +
            '- **List tasks under this project:** `Clockify.Task.List` (requires projectId)\' +
            '- **Update this project:** `Clockify.Project.Update`');
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
        RequestMgt.Execute(Argument, 'GET', '/workspaces/' + WorkspaceId + '/projects/' + ProjectId, false, '');
    end;
}
