namespace Origo.Bifrost.Timesheets.Test;

using Origo.Bifrost.Timesheets;

/// <summary>
/// Mock implementation of <see cref="Interface.ClockifyApiClient"/> used by the
/// tests. It performs no HTTP: it records the request on
/// <see cref="Codeunit.ClockifyMockState"/> and returns the canned response armed
/// there. Selected by setting <c>Clockify Setup."Clockify API Version ori"</c> to
/// the <c>Mock</c> value added by <see cref="EnumExtension.ClockifyApiVersionTest"/>.
/// </summary>
codeunit 95603 "Clockify Mock Client" implements "Clockify API Client ori"
{
    Access = Internal;

    procedure Send(Method: Text; ResourcePath: Text; HasBody: Boolean; RequestBody: Text; var ResponseBody: Text; var StatusCode: Integer): Boolean
    var
        MockState: Codeunit "Clockify Mock State";
        QueuedSuccess: Boolean;
    begin
        // A persisted, company-scoped test fixture supports separate shipping MCP sessions.
        // Only the Clockify boundary is mocked; Foundation dispatch and paging run unchanged.
        if (CompanyName() = 'CRONUS SINDRI23 Verification') and
           ResourcePath.StartsWith('/workspaces/XSINDRI23/user/XSINDRI23-')
        then begin
            ResponseBody := '[]';
            StatusCode := 200;
            if ResourcePath.Contains('/user/XSINDRI23-000002/') then begin
                ResponseBody := 'Simulated fixture user failure.';
                StatusCode := 503;
                exit(false);
            end;
            exit(true);
        end;
        MockState.CaptureRequest(Method, ResourcePath, HasBody, RequestBody);
        if MockState.TryDequeueResponse(QueuedSuccess, StatusCode, ResponseBody) then
            exit(QueuedSuccess);
        ResponseBody := MockState.GetNextResponseBody();
        StatusCode := MockState.GetNextStatusCode();
        exit(MockState.GetNextIsSuccess());
    end;
}
