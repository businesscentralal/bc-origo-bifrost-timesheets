namespace Origo.PTE.CloudEvents.Clockify;

using Origo.APP.CloudEvents;

/// <summary>
/// Implementation of the <c>Clockify.Currency.List</c> message type.
/// Lists the currencies defined in a Clockify workspace. The Clockify internal
/// <c>id</c> (a GUID-shaped string) returned here is the value that must be sent
/// as <c>currencyId</c> in the body of <c>Clockify.Client.Create</c> and
/// <c>Clockify.Client.Update</c> -- Clockify silently ignores <c>currencyCode</c>
/// on those write paths.
/// </summary>
codeunit 70009215 "Clockify Currency List Impl" implements "Cloud Event Msg Interface ori"
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
        exit('Lists the currencies defined in a Clockify workspace.');
    end;

    internal procedure GetMessageDirection(): Enum "Cloud Event Msg Direction ori"
    begin
        exit(Enum::"Cloud Event Msg Direction ori"::Outbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "CE Message Argument ori")
    var
        HelpBuilder: Codeunit "Clockify Help Builder";
    begin
        HelpBuilder.Init('Clockify.Currency.List', GetDescription(), 'GET', '/workspaces (inline `currencies` from workspace object)');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Clockify.Workspace.List → id');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f..." }');
        HelpBuilder.SetResponseNote('an array of currency objects (each with `id`, `code`, and the workspace default flag)');
        HelpBuilder.SetAfterSuccess('No tracking action required — this is a read operation. Use `id` as `currencyId` in client operations.');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Cloud Events Setup');
        HelpBuilder.SetNotes('- Clockify has no standalone currencies endpoint. This message type reads `GET /workspaces` and extracts the requested workspace''s `currencies` array.\' +
            '- Each item has an internal `id` (Clockify currency ID) and a 3-letter `code` (e.g. `ISK`, `USD`).\' +
            '- Use the `id` value (NOT the `code`) as `currencyId` in `Clockify.Client.Create` / `Clockify.Client.Update`. Passing `currencyCode` is silently ignored.\' +
            '- The list is per-workspace — the same currency code can have different IDs in different workspaces.');
        HelpBuilder.SetRelated('- **Use currencyId:** `Clockify.Client.Create` and `Clockify.Client.Update` (body.currencyId)\' +
            '- **Workspace info:** `Clockify.Workspace.List` returns the full workspace object including currencies');
        Argument.SetResponseMarkdown(HelpBuilder.Render());
    end;

    internal procedure ExecuteCloudEventTask(var Argument: Record "CE Message Argument ori")
    var
        RequestMgt: Codeunit "Clockify Request Mgt";
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
        WorkspaceId: Text;
        CurrenciesArray: JsonArray;
    begin
        Argument.AssertVersion1();
        RequestJson := Argument.GetRequestJson();
        if not RequestMgt.ResolveWorkspaceId(Argument, RequestJson, WorkspaceId) then
            exit;

        // Clockify exposes no /workspaces/{id}/currencies resource. A workspace's
        // currencies are returned inline on the workspace object, so fetch the
        // workspace list and project out the requested workspace's currencies.
        RequestMgt.Execute(Argument, 'GET', '/workspaces', false, '');

        ResponseJson := Argument.GetResponseJson();
        if GetStatusText(ResponseJson) <> 'Success' then
            exit;

        if not TryGetWorkspaceCurrencies(ResponseJson, WorkspaceId, CurrenciesArray) then begin
            Clear(ResponseJson);
            ResponseJson.Add('status', 'Error');
            ResponseJson.Add('error', StrSubstNo(WorkspaceNotFoundErr, WorkspaceId));
            Argument.SetResponseJson(ResponseJson);
            exit;
        end;

        Clear(ResponseJson);
        ResponseJson.Add('status', 'Success');
        ResponseJson.Add('statusCode', 200);
        ResponseJson.Add('data', CurrenciesArray);
        Argument.SetResponseJson(ResponseJson);
    end;

    local procedure TryGetWorkspaceCurrencies(ResponseJson: JsonObject; WorkspaceId: Text; var CurrenciesArray: JsonArray): Boolean
    var
        RequestMgt: Codeunit "Clockify Request Mgt";
        DataToken: JsonToken;
        WorkspaceToken: JsonToken;
        CurrenciesToken: JsonToken;
        WorkspaceObject: JsonObject;
    begin
        Clear(CurrenciesArray);
        if not ResponseJson.Get('data', DataToken) then
            exit(false);
        if not DataToken.IsArray() then
            exit(false);

        foreach WorkspaceToken in DataToken.AsArray() do
            if WorkspaceToken.IsObject() then begin
                WorkspaceObject := WorkspaceToken.AsObject();
                if RequestMgt.GetText(WorkspaceObject, 'id') = WorkspaceId then begin
                    if WorkspaceObject.Get('currencies', CurrenciesToken) then
                        if CurrenciesToken.IsArray() then
                            CurrenciesArray := CurrenciesToken.AsArray();
                    exit(true);
                end;
            end;

        exit(false);
    end;

    local procedure GetStatusText(ResponseJson: JsonObject): Text
    var
        Token: JsonToken;
    begin
        if not ResponseJson.Get('status', Token) then
            exit('');
        if not Token.IsValue() then
            exit('');
        exit(Token.AsValue().AsText());
    end;

    var
        WorkspaceNotFoundErr: Label 'The Clockify workspace ''%1'' was not found for the configured API key.', Comment = '%1 = workspace id', Locked = true;
}
