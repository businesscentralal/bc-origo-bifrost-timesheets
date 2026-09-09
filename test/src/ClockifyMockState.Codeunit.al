namespace Origo.Bifrost.Timesheets.Test;

using Origo.Bifrost.Timesheets;
using Origo.Bifrost.Timesheets.Providers.Clockify;

/// <summary>
/// Single-instance scratch pad that links a test to the <c>Mock</c> Clockify API
/// client. The test arms the next canned response here; the
/// <see cref="Codeunit.ClockifyMockClient"/> reads it and records the request it
/// received so the test can assert on the HTTP method, path and body without any
/// network access.
/// </summary>
codeunit 95602 "Clockify Mock State"
{
    SingleInstance = true;
    Access = Internal;

    var
        NextResponseBody: Text;
        LastMethod: Text;
        LastResourcePath: Text;
        LastRequestBody: Text;
        NextStatusCode: Integer;
        NextIsSuccess: Boolean;
        LastHasBody: Boolean;

    /// <summary>Clears the armed response and any captured request.</summary>
    procedure Reset()
    begin
        NextIsSuccess := false;
        NextStatusCode := 0;
        NextResponseBody := '';
        LastMethod := '';
        LastResourcePath := '';
        LastRequestBody := '';
        LastHasBody := false;
    end;

    /// <summary>Arms the response the mock client returns on its next <c>Send</c>.</summary>
    /// <param name="IsSuccess">Value the mock returns from <c>Send</c>.</param>
    /// <param name="StatusCode">HTTP status code the mock reports.</param>
    /// <param name="ResponseBody">Raw response body the mock returns.</param>
    procedure SetNextResponse(IsSuccess: Boolean; StatusCode: Integer; ResponseBody: Text)
    begin
        NextIsSuccess := IsSuccess;
        NextStatusCode := StatusCode;
        NextResponseBody := ResponseBody;
    end;

    /// <summary>Records the request the mock client received. Called by the mock only.</summary>
    /// <param name="Method">HTTP method of the captured request.</param>
    /// <param name="ResourcePath">Resource path of the captured request.</param>
    /// <param name="HasBody">Whether the captured request carried a body.</param>
    /// <param name="RequestBody">Body text of the captured request.</param>
    procedure CaptureRequest(Method: Text; ResourcePath: Text; HasBody: Boolean; RequestBody: Text)
    begin
        LastMethod := Method;
        LastResourcePath := ResourcePath;
        LastHasBody := HasBody;
        LastRequestBody := RequestBody;
    end;

    /// <summary>Returns the success flag armed for the next response.</summary>
    procedure GetNextIsSuccess(): Boolean
    begin
        exit(NextIsSuccess);
    end;

    /// <summary>Returns the status code armed for the next response.</summary>
    procedure GetNextStatusCode(): Integer
    begin
        exit(NextStatusCode);
    end;

    /// <summary>Returns the body armed for the next response.</summary>
    procedure GetNextResponseBody(): Text
    begin
        exit(NextResponseBody);
    end;

    /// <summary>Returns the HTTP method of the last captured request.</summary>
    procedure GetLastMethod(): Text
    begin
        exit(LastMethod);
    end;

    /// <summary>Returns the resource path of the last captured request.</summary>
    procedure GetLastResourcePath(): Text
    begin
        exit(LastResourcePath);
    end;

    /// <summary>Returns the body text of the last captured request.</summary>
    procedure GetLastRequestBody(): Text
    begin
        exit(LastRequestBody);
    end;

    /// <summary>Returns whether the last captured request carried a body.</summary>
    procedure GetLastHasBody(): Boolean
    begin
        exit(LastHasBody);
    end;
}
