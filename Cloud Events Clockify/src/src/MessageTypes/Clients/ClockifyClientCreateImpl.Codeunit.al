namespace Origo.PTE.CloudEvents.Clockify;

using Origo.APP.CloudEvents;

/// <summary>
/// Implementation of the <c>Clockify.Client.Create</c> message type.
/// Creates a client in a workspace from the request's <c>body</c> object.
/// </summary>
codeunit 71426 "Clockify Client Create Impl" implements "Cloud Event Msg Interface ori"
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
        exit('Creates a client in a Clockify workspace from the request body.');
    end;

    internal procedure GetMessageDirection(): Enum "Cloud Event Msg Direction ori"
    begin
        exit(Enum::"Cloud Event Msg Direction ori"::Outbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "CE Message Argument ori")
    var
        HelpBuilder: Codeunit "Clockify Help Builder";
    begin
        HelpBuilder.Init('Clockify.Client.Create', GetDescription(), 'POST', '/workspaces/{workspaceId}/clients');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Clockify.Workspace.List → id');
        HelpBuilder.AddParam('body.name', true, 'string', 'Client display name (must be unique in workspace)', '');
        HelpBuilder.AddParam('body.address', false, 'string', 'Single-line address (concatenate BC Address + Address 2 + Post Code + City + Country)', '');
        HelpBuilder.AddParam('body.email', false, 'string', 'Client contact email', '');
        HelpBuilder.AddParam('body.note', false, 'string', 'Free-text note', '');
        HelpBuilder.AddParam('body.currencyId', false, 'string', 'Clockify currency ID (NOT the ISO code). Omit for workspace default', 'Clockify.Currency.List → id');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "body": { "name": "Acme Inc.", "address": "Main St 1, 101 Reykjavik, IS", "currencyId": "6a..." } }');
        HelpBuilder.SetResponseNote('the created client object (includes `id`, `name`, `workspaceId`)');
        HelpBuilder.AddError(400, 'Client name already exists in workspace', 'Use `Clockify.Client.List` to find existing client, or choose a different name');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Cloud Events Setup');
        HelpBuilder.AddError(403, 'Forbidden', 'API key user lacks workspace admin role');
        HelpBuilder.SetNotes('- `currencyCode` is **silently ignored** — Clockify returns 201 but uses workspace default. Always use `currencyId`.\' +
            '- `address` is a single free-text field; concatenate multi-line BC address fields before sending.');
        HelpBuilder.SetRelated('- **Resolve currencyId:** `Clockify.Currency.List` → match on `code` → use `id`\' +
            '- **After creating:** Record integration link, then optionally create projects under this client\' +
            '- **To update later:** `Clockify.Client.Update` (requires `clientId` from create response)\' +
            '- **To delete later:** First archive (`Clockify.Client.Update` body `{ "archived": true }`), then `Clockify.Client.Delete`');
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
        RequestMgt.Execute(Argument, 'POST', '/workspaces/' + WorkspaceId + '/clients', true, BodyText);
    end;
}
