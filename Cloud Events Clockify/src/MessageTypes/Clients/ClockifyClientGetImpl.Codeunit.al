namespace Origo.PTE.CloudEvents.Clockify;

using Origo.APP.CloudEvents;

/// <summary>
/// Implementation of the <c>Clockify.Client.Get</c> message type.
/// Retrieves a single client by ID.
/// </summary>
codeunit 70009211 "Clockify Client Get Impl" implements "Cloud Event Msg Interface ori"
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
        exit('Retrieves a single Clockify client by ID.');
    end;

    internal procedure GetMessageDirection(): Enum "Cloud Event Msg Direction ori"
    begin
        exit(Enum::"Cloud Event Msg Direction ori"::Outbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "CE Message Argument ori")
    var
        HelpBuilder: Codeunit "Clockify Help Builder";
    begin
        HelpBuilder.Init('Clockify.Client.Get', GetDescription(), 'GET', '/workspaces/{workspaceId}/clients/{clientId}');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Clockify.Workspace.List → id');
        HelpBuilder.AddParam('clientId', true, 'string', 'The Clockify client ID to retrieve', 'Clockify Integration table → Clockify Id (type=client)');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "clientId": "60..." }');
        HelpBuilder.SetResponseNote('the client object (includes `id`, `name`, `workspaceId`, `archived`, `currencyId`)');
        HelpBuilder.SetAfterSuccess('No tracking action required — this is a read operation.');
        HelpBuilder.AddError(404, 'Client not found', 'Verify clientId exists via `Clockify.Client.List` or check Clockify Integration table');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Cloud Events Setup');
        HelpBuilder.SetRelated('- **Find clientId:** `Clockify.Client.List` or `Data.Records.Get` on Clockify Integration (type=client)\' +
            '- **Update this client:** `Clockify.Client.Update`\' +
            '- **Delete this client:** Archive first, then `Clockify.Client.Delete`');
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
        RequestJson := Argument.GetRequestJson();
        if not RequestMgt.ResolveWorkspaceId(Argument, RequestJson, WorkspaceId) then
            exit;
        if not RequestMgt.RequireParam(Argument, RequestJson, 'clientId', ClientId) then
            exit;
        RequestMgt.Execute(Argument, 'GET', '/workspaces/' + WorkspaceId + '/clients/' + ClientId, false, '');
    end;
}
