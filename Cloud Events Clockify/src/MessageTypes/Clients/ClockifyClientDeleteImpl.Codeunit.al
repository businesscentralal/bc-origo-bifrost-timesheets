namespace Origo.PTE.CloudEvents.Clockify;

using Origo.APP.CloudEvents;

/// <summary>
/// Implementation of the <c>Clockify.Client.Delete</c> message type.
/// Deletes a client by ID.
/// </summary>
codeunit 70009210 "Clockify Client Delete Impl" implements "Cloud Event Msg Interface ori"
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
        exit('Deletes a Clockify client by ID.');
    end;

    internal procedure GetMessageDirection(): Enum "Cloud Event Msg Direction ori"
    begin
        exit(Enum::"Cloud Event Msg Direction ori"::Outbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "CE Message Argument ori")
    var
        HelpBuilder: Codeunit "Clockify Help Builder";
    begin
        HelpBuilder.Init('Clockify.Client.Delete', GetDescription(), 'DELETE', '/workspaces/{workspaceId}/clients/{clientId}');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Clockify.Workspace.List → id');
        HelpBuilder.AddParam('clientId', true, 'string', 'The Clockify client ID to delete', 'Clockify Integration table → Clockify Id (type=client)');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "clientId": "60..." }');
        HelpBuilder.SetResponseNote('the deleted client object');
        HelpBuilder.SetPreconditions('1. The client **must be archived first** — call `Clockify.Client.Update` with body `{ "archived": true }`.\' +
            '2. Clockify rejects delete on active clients with HTTP 400.');
        HelpBuilder.AddError(400, 'Cannot delete an active client', 'Archive first: `Clockify.Client.Update` with `{ "archived": true }`');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Cloud Events Setup');
        HelpBuilder.AddError(404, 'Client not found', 'Verify clientId via `Clockify.Client.List`');
        HelpBuilder.SetNotes('- Two-step delete pattern: archive → delete. This is a Clockify platform requirement.\' +
            '- After delete, mark the `Clockify Integration` row as reversed (do NOT delete it).');
        HelpBuilder.SetRelated('- **Step 1 (archive):** `Clockify.Client.Update` with `{ "archived": true }`\' +
            '- **Step 2 (delete):** This message type\' +
            '- **Step 3 (unlink):** `Data.Records.Set` on Clockify Integration → `Reversed` = true');
        Argument.SetResponseMarkdown(HelpBuilder.Render());
    end;

    internal procedure ExecuteCloudEventTask(var Argument: Record "CE Message Argument ori")
    var
        RequestMgt: Codeunit "Clockify Request Mgt";
        RequestJson: JsonObject;
        WorkspaceId: Text;
        ClientId: Text;
    begin
        Argument.AssertVersion1();
        Argument.AssertLicense();
        RequestJson := Argument.GetRequestJson();
        if not RequestMgt.ResolveWorkspaceId(Argument, RequestJson, WorkspaceId) then
            exit;
        if not RequestMgt.RequireParam(Argument, RequestJson, 'clientId', ClientId) then
            exit;
        RequestMgt.Execute(Argument, 'DELETE', '/workspaces/' + WorkspaceId + '/clients/' + ClientId, false, '');
    end;
}
