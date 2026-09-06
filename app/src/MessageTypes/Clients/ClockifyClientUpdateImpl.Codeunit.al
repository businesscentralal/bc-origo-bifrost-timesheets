namespace Origo.PTE.CloudEvents.Clockify;

using Origo.APP.CloudEvents;

/// <summary>
/// Implementation of the <c>Clockify.Client.Update</c> message type.
/// Updates an existing client from the request's <c>body</c> object.
/// </summary>
codeunit 70009213 "Clockify Client Update Impl" implements "Cloud Event Msg Interface ori"
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
        exit('Updates an existing Clockify client from the request body.');
    end;

    internal procedure GetMessageDirection(): Enum "Cloud Event Msg Direction ori"
    begin
        exit(Enum::"Cloud Event Msg Direction ori"::Outbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "CE Message Argument ori")
    var
        HelpBuilder: Codeunit "Clockify Help Builder";
    begin
        HelpBuilder.Init('Clockify.Client.Update', GetDescription(), 'PUT', '/workspaces/{workspaceId}/clients/{clientId}');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Clockify.Workspace.List → id');
        HelpBuilder.AddParam('clientId', true, 'string', 'The Clockify client ID to update', 'Clockify Integration table → Clockify Id (type=client)');
        HelpBuilder.AddParam('body.name', false, 'string', 'Client display name', '');
        HelpBuilder.AddParam('body.address', false, 'string', 'Single-line address', '');
        HelpBuilder.AddParam('body.email', false, 'string', 'Client contact email', '');
        HelpBuilder.AddParam('body.note', false, 'string', 'Free-text note', '');
        HelpBuilder.AddParam('body.currencyId', false, 'string', 'Clockify currency ID (NOT the ISO code)', 'Clockify.Currency.List → id');
        HelpBuilder.AddParam('body.archived', false, 'boolean', 'Set true to archive, false to unarchive', '');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "clientId": "60...", "body": { "name": "Acme Ltd.", "currencyId": "6a...", "archived": false } }');
        HelpBuilder.SetResponseNote('the updated client object');
        HelpBuilder.AddError(400, 'Client name already exists', 'Choose a different name or use existing client');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Cloud Events Setup');
        HelpBuilder.AddError(404, 'Client not found', 'Verify clientId via `Clockify.Client.List`');
        HelpBuilder.SetNotes('- `currencyCode` is **silently ignored** — Clockify returns 200 but the currency is unchanged. Always use `currencyId`.\' +
            '- Setting `archived: true` is the **required first step** before `Clockify.Client.Delete`.\' +
            '- Send only the fields you want to change; omitted fields retain their current values.');
        HelpBuilder.SetRelated('- **Archive before delete:** Set `body.archived` = true, then call `Clockify.Client.Delete`\' +
            '- **Resolve currencyId:** `Clockify.Currency.List` → match on `code` → use `id`\' +
            '- **Unarchive:** Set `body.archived` = false');
        Argument.SetResponseMarkdown(HelpBuilder.Render());
    end;

    internal procedure ExecuteCloudEventTask(var Argument: Record "CE Message Argument ori")
    var
        RequestMgt: Codeunit "Clockify Request Mgt";
        RequestJson: JsonObject;
        WorkspaceId: Text;
        ClientId: Text;
        BodyText: Text;
    begin
        Argument.AssertVersion1();
        RequestJson := Argument.GetRequestJson();
        if not RequestMgt.ResolveWorkspaceId(Argument, RequestJson, WorkspaceId) then
            exit;
        if not RequestMgt.RequireParam(Argument, RequestJson, 'clientId', ClientId) then
            exit;
        if not RequestMgt.RequireBody(Argument, RequestJson, BodyText) then
            exit;
        RequestMgt.Execute(Argument, 'PUT', '/workspaces/' + WorkspaceId + '/clients/' + ClientId, true, BodyText);
    end;
}
