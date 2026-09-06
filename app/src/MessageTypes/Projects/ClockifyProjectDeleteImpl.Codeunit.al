namespace Origo.PTE.CloudEvents.Clockify;

using Origo.APP.CloudEvents;

/// <summary>
/// Implementation of the <c>Clockify.Project.Delete</c> message type.
/// Deletes a project by ID (the project must be archived first in Clockify).
/// </summary>
codeunit 70009220 "Clockify Project Delete Impl" implements "Cloud Event Msg Interface ori"
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
        exit('Deletes a Clockify project by ID. The project must be archived in Clockify before it can be deleted.');
    end;

    internal procedure GetMessageDirection(): Enum "Cloud Event Msg Direction ori"
    begin
        exit(Enum::"Cloud Event Msg Direction ori"::Outbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "CE Message Argument ori")
    var
        HelpBuilder: Codeunit "Clockify Help Builder";
    begin
        HelpBuilder.Init('Clockify.Project.Delete', GetDescription(), 'DELETE', '/workspaces/{workspaceId}/projects/{projectId}');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Clockify.Workspace.List → id');
        HelpBuilder.AddParam('projectId', true, 'string', 'The Clockify project ID to delete', 'Clockify Integration table → Clockify Id (type=project)');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "projectId": "60..." }');
        HelpBuilder.SetResponseNote('the deleted project object');
        HelpBuilder.SetPreconditions('1. The project **must be archived first** — call `Clockify.Project.Update` with body `{ "archived": true }`.\' +
            '2. Clockify rejects delete on active projects with HTTP 400.');
        HelpBuilder.AddError(400, 'Cannot delete an active project', 'Archive first: `Clockify.Project.Update` with `{ "archived": true }`');
        HelpBuilder.AddError(404, 'Project not found', 'Verify projectId via `Clockify.Project.List`');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Cloud Events Setup');
        HelpBuilder.SetNotes('- Two-step delete pattern: archive → delete. This is a Clockify platform requirement.\' +
            '- After delete, mark the `Clockify Integration` row as reversed (do NOT delete it).\' +
            '- Tasks under this project are also deleted by Clockify.');
        HelpBuilder.SetRelated('- **Step 1 (archive):** `Clockify.Project.Update` with `{ "archived": true }`\' +
            '- **Step 2 (delete):** This message type\' +
            '- **Step 3 (unlink):** `Data.Records.Set` on Clockify Integration → `Reversed` = true');
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
        RequestMgt.Execute(Argument, 'DELETE', '/workspaces/' + WorkspaceId + '/projects/' + ProjectId, false, '');
    end;
}
