namespace Origo.Bifrost.Timesheets;

using Origo.Bifrost;

/// <summary>
/// Implementation of the <c>Clockify.Currency.List</c> message type.
/// Lists the currencies defined in a Clockify workspace. The Clockify internal
/// <c>id</c> (a GUID-shaped string) returned here is the value that must be sent
/// as <c>currencyId</c> in the body of <c>Clockify.Client.Create</c> and
/// <c>Clockify.Client.Update</c> -- Clockify silently ignores <c>currencyCode</c>
/// on those write paths.
/// </summary>
codeunit 70009215 "Clockify CurrencyList Impl ori" implements "Msg Interface ori"
{
    Access = Internal;

    internal procedure IsEnabled(): Boolean
    var
        ClockifyIntegration: Record "Clockify Integration ori";
        SecretMgt: Codeunit "Clockify Secret Mgt ori";
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

    internal procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit(Enum::"Msg Direction ori"::Outbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "Message Argument ori")
    var
        Help: Codeunit "Clockify Workspace Help ori";
    begin
        Argument.SetResponseMarkdown(Help.GetHelp(Enum::"Message Type ori"::"Clockify.Currency.List", GetDescription()));
    end;

    internal procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    var
        RequestMgt: Codeunit "Clockify Request Mgt ori";
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
        RequestMgt: Codeunit "Clockify Request Mgt ori";
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
