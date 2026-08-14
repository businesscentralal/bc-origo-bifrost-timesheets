namespace Origo.PTE.CloudEvents.Clockify;

using Origo.APP.CloudEvents;
using System.Reflection;

/// <summary>
/// Shared helper for the Clockify message-type implementations. Resolves common
/// request parameters (workspace ID, required values, request body, query string)
/// and packages every Clockify HTTP response into the uniform Cloud Event response
/// envelope <c>{ status, statusCode, data | raw, error }</c>.
/// </summary>
codeunit 71407 "Clockify Request Mgt"
{
    Access = Internal;

    var
        MissingWorkspaceErr: Label 'No workspace was supplied. Provide ''workspaceId'' in the request or set a Default Workspace ID on Cloud Events Setup.', Locked = true;
        MissingParamErr: Label 'Missing required ''%1'' in the request.', Comment = '%1 = parameter name', Locked = true;
        MissingBodyErr: Label 'Missing required ''body'' object in the request.', Locked = true;

    /// <summary>
    /// Calls the Clockify API and writes the uniform JSON response envelope onto the
    /// Cloud Event argument. A 2xx response yields <c>status = Success</c>; otherwise
    /// <c>status = Error</c> with an <c>error</c> message and the original status code.
    /// </summary>
    /// <param name="Argument">The Cloud Event message argument that receives the response.</param>
    /// <param name="Method">HTTP method: GET, POST, PUT or DELETE.</param>
    /// <param name="ResourcePath">Resource path (starting with '/') appended to the base URL.</param>
    /// <param name="HasBody">True when <paramref name="RequestBody"/> should be sent.</param>
    /// <param name="RequestBody">JSON body text (used only when <paramref name="HasBody"/> is true).</param>
    procedure Execute(var Argument: Record "CE Message Argument ori"; Method: Text; ResourcePath: Text; HasBody: Boolean; RequestBody: Text)
    var
        IntegrationGate: Codeunit "Clockify Integration Gate";
        ApiClient: Interface "Clockify API Client";
        ResponseJson: JsonObject;
        DataToken: JsonToken;
        ResponseBody: Text;
        StatusCode: Integer;
        Success: Boolean;
    begin
        if not IntegrationGate.AssertCanWriteIntegration(Argument) then
            exit;

        ApiClient := GetApiClient();
        Success := ApiClient.Send(Method, ResourcePath, HasBody, RequestBody, ResponseBody, StatusCode);

        if Success then
            ResponseJson.Add('status', 'Success')
        else
            ResponseJson.Add('status', 'Error');
        ResponseJson.Add('statusCode', StatusCode);

        case true of
            (ResponseBody <> '') and DataToken.ReadFrom(ResponseBody) and DataToken.IsArray():
                ResponseJson.Add('data', DataToken.AsArray());
            (ResponseBody <> '') and DataToken.ReadFrom(ResponseBody) and DataToken.IsObject():
                ResponseJson.Add('data', DataToken.AsObject());
            ResponseBody <> '':
                ResponseJson.Add('raw', ResponseBody);
        end;

        if not Success then
            ResponseJson.Add('error', ExtractErrorMessage(ResponseBody));

        Argument.SetResponseJson(ResponseJson);
        Argument."Content Type" := 'text/json';
    end;

    /// <summary>Reads a string property from a JSON object, returning '' when absent or null.</summary>
    /// <param name="RequestJson">The JSON object to read from.</param>
    /// <param name="PropertyName">The property name to read.</param>
    /// <returns>The property value as text, or an empty string.</returns>
    procedure GetText(RequestJson: JsonObject; PropertyName: Text): Text
    var
        Token: JsonToken;
    begin
        if not RequestJson.Get(PropertyName, Token) then
            exit('');
        if not Token.IsValue() then
            exit('');
        if Token.AsValue().IsNull() then
            exit('');
        exit(Token.AsValue().AsText());
    end;

    /// <summary>
    /// Resolves the Clockify workspace ID from the request (<c>workspaceId</c>),
    /// falling back to the Default Workspace ID on Cloud Events Setup. On failure
    /// it sets an error response on the argument and returns false.
    /// </summary>
    /// <param name="Argument">The Cloud Event argument (receives the error response on failure).</param>
    /// <param name="RequestJson">The request JSON.</param>
    /// <param name="WorkspaceId">Out: the resolved workspace ID.</param>
    /// <returns>True when a workspace ID was resolved.</returns>
    procedure ResolveWorkspaceId(var Argument: Record "CE Message Argument ori"; RequestJson: JsonObject; var WorkspaceId: Text): Boolean
    begin
        WorkspaceId := GetText(RequestJson, 'workspaceId');
        if WorkspaceId = '' then
            WorkspaceId := GetDefaultWorkspaceId();
        if WorkspaceId = '' then begin
            Argument.RespondWithError(MissingWorkspaceErr);
            exit(false);
        end;
        exit(true);
    end;

    /// <summary>
    /// Resolves the Clockify API client implementation selected on
    /// <c>Cloud Events Setup</c>. When no setup record exists the enum default
    /// (<c>Version 1</c>) is used.
    /// </summary>
    /// <returns>The configured <see cref="Interface.ClockifyApiClient"/> implementation.</returns>
    internal procedure GetApiClient(): Interface "Clockify API Client"
    var
        CloudEventsSetup: Record "Cloud Events Setup ori";
    begin
        if not CloudEventsSetup.Get() then
            CloudEventsSetup.Init();
        exit(CloudEventsSetup."Clockify API Version");
    end;

    /// <summary>Returns the configured default Clockify workspace ID, or an empty string.</summary>
    /// <returns>The default workspace ID from Cloud Events Setup.</returns>
    local procedure GetDefaultWorkspaceId(): Text
    var
        CloudEventsSetup: Record "Cloud Events Setup ori";
    begin
        if not CloudEventsSetup.Get() then
            exit('');
        exit(CloudEventsSetup."Clockify Default Workspace");
    end;

    /// <summary>
    /// Reads a required string parameter. On failure it sets an error response on
    /// the argument and returns false.
    /// </summary>
    /// <param name="Argument">The Cloud Event argument (receives the error response on failure).</param>
    /// <param name="RequestJson">The request JSON.</param>
    /// <param name="PropertyName">The required property name.</param>
    /// <param name="Value">Out: the parameter value.</param>
    /// <returns>True when the parameter was present and non-empty.</returns>
    procedure RequireParam(var Argument: Record "CE Message Argument ori"; RequestJson: JsonObject; PropertyName: Text; var Value: Text): Boolean
    begin
        Value := GetText(RequestJson, PropertyName);
        if Value = '' then begin
            Argument.RespondWithError(StrSubstNo(MissingParamErr, PropertyName));
            exit(false);
        end;
        exit(true);
    end;

    /// <summary>
    /// Reads the <c>body</c> object/array from the request and returns it as JSON text
    /// to be sent verbatim to Clockify. On failure it sets an error response and returns false.
    /// </summary>
    /// <param name="Argument">The Cloud Event argument (receives the error response on failure).</param>
    /// <param name="RequestJson">The request JSON.</param>
    /// <param name="BodyText">Out: the body serialized as JSON text.</param>
    /// <returns>True when a body object/array was present.</returns>
    procedure RequireBody(var Argument: Record "CE Message Argument ori"; RequestJson: JsonObject; var BodyText: Text): Boolean
    var
        Token: JsonToken;
    begin
        if not RequestJson.Get('body', Token) then begin
            Argument.RespondWithError(MissingBodyErr);
            exit(false);
        end;
        Token.WriteTo(BodyText);
        exit(true);
    end;

    /// <summary>
    /// Appends a query string to a resource path from the request's optional
    /// <c>query</c> object. Each property becomes a URL-encoded <c>key=value</c> pair.
    /// </summary>
    /// <param name="RequestJson">The request JSON, optionally containing a <c>query</c> object.</param>
    /// <param name="ResourcePath">The base resource path.</param>
    /// <returns>The resource path with the query string appended, if any.</returns>
    procedure AppendQuery(RequestJson: JsonObject; ResourcePath: Text): Text
    var
        TypeHelper: Codeunit "Type Helper";
        QueryToken: JsonToken;
        QueryObject: JsonObject;
        ValueToken: JsonToken;
        QueryKeys: List of [Text];
        QueryKey: Text;
        EncodedKey: Text;
        EncodedValue: Text;
        QueryString: Text;
        Separator: Text;
    begin
        if not RequestJson.Get('query', QueryToken) then
            exit(ResourcePath);
        if not QueryToken.IsObject() then
            exit(ResourcePath);
        QueryObject := QueryToken.AsObject();
        QueryKeys := QueryObject.Keys();
        Separator := '?';
        foreach QueryKey in QueryKeys do begin
            QueryObject.Get(QueryKey, ValueToken);
            EncodedKey := QueryKey;
            EncodedValue := ValueTokenAsText(ValueToken);
            QueryString += Separator + TypeHelper.UrlEncode(EncodedKey) + '=' + TypeHelper.UrlEncode(EncodedValue);
            Separator := '&';
        end;
        exit(ResourcePath + QueryString);
    end;

    local procedure ValueTokenAsText(Token: JsonToken): Text
    begin
        if not Token.IsValue() then
            exit('');
        if Token.AsValue().IsNull() then
            exit('');
        exit(Token.AsValue().AsText());
    end;

    local procedure ExtractErrorMessage(ResponseBody: Text): Text
    var
        ErrorToken: JsonToken;
        MessageToken: JsonToken;
    begin
        if ResponseBody = '' then
            exit('Clockify returned an error with no response body.');
        if ErrorToken.ReadFrom(ResponseBody) then
            if ErrorToken.IsObject() then
                if ErrorToken.AsObject().Get('message', MessageToken) then
                    if MessageToken.IsValue() then
                        exit(MessageToken.AsValue().AsText());
        exit(ResponseBody);
    end;
}
