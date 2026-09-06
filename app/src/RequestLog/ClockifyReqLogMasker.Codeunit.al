namespace Origo.Bifrost.Clockify;

using Origo.Bifrost;

/// <summary>
/// Masker implementation for Clockify request log entries.
/// Clockify authenticates via the <c>X-Api-Key</c> HTTP header which is never
/// present in the request or response body. Bodies are plain JSON and safe to
/// store unmasked regardless of debug mode.
/// </summary>
codeunit 70009242 "Clockify ReqLog Masker ori" implements "Request Log Masker ori"
{
    Access = Internal;

    procedure MaskRequestBody(Body: Text; DebugMode: Boolean): Text
    begin
        exit(Body);
    end;

    procedure MaskResponseBody(Body: Text; DebugMode: Boolean): Text
    begin
        exit(Body);
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
