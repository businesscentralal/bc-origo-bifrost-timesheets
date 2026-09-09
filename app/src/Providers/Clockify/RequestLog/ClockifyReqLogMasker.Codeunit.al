namespace Origo.Bifrost.Timesheets.Providers.Clockify;

using Origo.Bifrost;

/// <summary>
/// Masker implementation for Clockify request log entries.
/// </summary>
/// <remarks>
/// Clockify authenticates with the <c>X-Api-Key</c> HTTP header, which is never present in a
/// request or response body, so bodies are otherwise safe to store unmasked. The one exception
/// is the webhook signing token: <c>POST /workspaces/{id}/webhooks</c> and the webhook list
/// return it as <c>authToken</c>, and it is the only credential that authenticates an inbound
/// Clockify webhook. Response bodies are therefore scanned and that value is redacted before the
/// entry is written to the request log.
/// </remarks>
codeunit 10036827 "Clockify ReqLog Masker ori" implements "Request Log Masker ori"
{
    Access = Internal;

    var
        AuthTokenTok: Label 'authToken', Locked = true;
        AuthTokenPropTok: Label '"authToken"', Locked = true;
        RedactedTok: Label '***', Locked = true;

    procedure MaskRequestBody(Body: Text; DebugMode: Boolean): Text
    begin
        exit(Body);
    end;

    procedure MaskResponseBody(Body: Text; DebugMode: Boolean): Text
    begin
        exit(RedactSigningTokens(Body));
    end;

    /// <summary>
    /// Replaces every <c>authToken</c> value anywhere in a JSON response body with a placeholder.
    /// </summary>
    /// <param name="Body">The raw response body.</param>
    /// <returns>The body with every signing token redacted, or the body unchanged when it carries none or is not JSON.</returns>
    procedure RedactSigningTokens(Body: Text) Result: Text
    var
        RootToken: JsonToken;
    begin
        if Body = '' then
            exit(Body);
        if StrPos(Body, AuthTokenPropTok) = 0 then
            exit(Body);
        if not RootToken.ReadFrom(Body) then
            exit(Body);
        RedactToken(RootToken);
        RootToken.WriteTo(Result);
    end;

    local procedure RedactToken(var Token: JsonToken)
    var
        JObject: JsonObject;
        JArray: JsonArray;
        ChildToken: JsonToken;
        PropertyName: Text;
        Index: Integer;
    begin
        if Token.IsObject() then begin
            JObject := Token.AsObject();
            foreach PropertyName in JObject.Keys() do
                if PropertyName = AuthTokenTok then
                    JObject.Replace(PropertyName, RedactedTok)
                else begin
                    JObject.Get(PropertyName, ChildToken);
                    RedactToken(ChildToken);
                    JObject.Replace(PropertyName, ChildToken);
                end;
            exit;
        end;

        if Token.IsArray() then begin
            JArray := Token.AsArray();
            for Index := 0 to JArray.Count() - 1 do begin
                JArray.Get(Index, ChildToken);
                RedactToken(ChildToken);
                JArray.Set(Index, ChildToken);
            end;
        end;
    end;

    procedure MaskErrorText(ErrorText: Text; DebugMode: Boolean): Text
    begin
        exit(ErrorText);
    end;

    procedure GetBaseUrl(FullUrl: Text): Text
    var
        SchemeEnd: Integer;
        HostEnd: Integer;
        UrlAfterScheme: Text;
    begin
        if FullUrl = '' then
            exit('');
        SchemeEnd := StrPos(FullUrl, '://');
        if SchemeEnd = 0 then
            exit(FullUrl);
        UrlAfterScheme := CopyStr(FullUrl, SchemeEnd + 3);
        HostEnd := StrPos(UrlAfterScheme, '/');
        if HostEnd = 0 then
            exit(FullUrl);
        exit(CopyStr(FullUrl, 1, SchemeEnd + 2 + HostEnd - 1));
    end;
}
