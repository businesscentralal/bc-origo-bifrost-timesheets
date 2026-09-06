namespace Origo.Bifrost.Timesheets;

using Origo.Bifrost;

/// <summary>
/// Version 1 implementation of <see cref="Interface.ClockifyApiClient"/>: a thin
/// HTTP client for the public Clockify REST API, fixed on the
/// <c>https://api.clockify.me/api/v1</c> endpoint. Resolves the company API key
/// from <c>Clockify Secret Mgt ori</c>, authenticates every request with the
/// <c>X-Api-Key</c> header, and returns the raw response body and status code. The
/// API key is carried as <c>SecretText</c> so it is never exposed to the debugger
/// or written to the response.
/// </summary>
codeunit 70009201 "Clockify Client ori" implements "Clockify API Client ori"
{
    Access = Internal;

    var
        MissingApiKeyErr: Label 'No Clockify API key is stored. Open Clockify Setup and set the company API key.', Comment = 'is-IS=Enginn Clockify API lykill er geymdur. Opnaðu uppsetningu Clockify og skráðu API lykil fyrirtækis.';
        SendFailedErr: Label 'The Clockify request could not be sent: %1', Comment = '%1 = error text. is-IS=Ekki tókst að senda Clockify beiðnina: %1';
        ApiKeyHeaderTok: Label 'X-Api-Key', Locked = true;
        BaseUrlTok: Label 'https://api.clockify.me/api/v1', Locked = true;
        ServiceNameTok: Label 'Clockify', Locked = true;

    procedure Send(Method: Text; ResourcePath: Text; HasBody: Boolean; RequestBody: Text; var ResponseBody: Text; var StatusCode: Integer): Boolean
    var
        Logger: Codeunit "Request Logger ori";
        Client: HttpClient;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        RequestHeaders: HttpHeaders;
        ApiKey: SecretText;
        FullUrl: Text;
        ErrorText: Text;
        StartedAt: DateTime;
        Elapsed: Duration;
        Success: Boolean;
    begin
        ResponseBody := '';
        StatusCode := 0;

        ApiKey := ResolveApiKey();
        FullUrl := BuildUri(ResourcePath);

        RequestMessage.Method(Method);
        RequestMessage.SetRequestUri(FullUrl);
        RequestMessage.GetHeaders(RequestHeaders);
        RequestHeaders.Add(ApiKeyHeaderTok, ApiKey);

        if HasBody then begin
            Content.WriteFrom(RequestBody);
            Content.GetHeaders(ContentHeaders);
            if ContentHeaders.Contains('Content-Type') then
                ContentHeaders.Remove('Content-Type');
            ContentHeaders.Add('Content-Type', 'application/json');
            RequestMessage.Content(Content);
        end;

        StartedAt := CurrentDateTime();
        if not Client.Send(RequestMessage, ResponseMessage) then begin
            Elapsed := CurrentDateTime() - StartedAt;
            ErrorText := GetLastErrorText();
            Logger.InsertLog(
                CopyStr(ResourcePath, 1, 50), CopyStr(Method, 1, 10), FullUrl, ServiceNameTok,
                0, Elapsed, false, ErrorText, RequestBody, '',
                "Request Log Type ori"::Clockify);
            Error(SendFailedErr, ErrorText);
        end;
        Elapsed := CurrentDateTime() - StartedAt;

        StatusCode := ResponseMessage.HttpStatusCode();
        ResponseMessage.Content().ReadAs(ResponseBody);
        Success := ResponseMessage.IsSuccessStatusCode();

        if not Success then
            ErrorText := CopyStr(ResponseBody, 1, 2048);

        Logger.InsertLog(
            CopyStr(ResourcePath, 1, 50), CopyStr(Method, 1, 10), FullUrl, ServiceNameTok,
            StatusCode, Elapsed, Success, ErrorText, RequestBody, ResponseBody,
            "Request Log Type ori"::Clockify);

        exit(Success);
    end;

    local procedure BuildUri(ResourcePath: Text): Text
    begin
        if (ResourcePath <> '') and (ResourcePath[1] <> '/') then
            ResourcePath := '/' + ResourcePath;
        exit(BaseUrlTok + ResourcePath);
    end;

    local procedure ResolveApiKey(): SecretText
    var
        SecretMgt: Codeunit "Clockify Secret Mgt ori";
        ApiKey: SecretText;
    begin
        if not SecretMgt.TryGetApiKey(ApiKey) then
            Error(MissingApiKeyErr);
        exit(ApiKey);
    end;
}
