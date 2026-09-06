namespace Origo.PTE.CloudEvents.Clockify;

/// <summary>
/// Mock implementation of <see cref="Interface.ClockifyApiClient"/> used by the
/// tests. It performs no HTTP: it records the request on
/// <see cref="Codeunit.ClockifyMockState"/> and returns the canned response armed
/// there. Selected by setting <c>Cloud Events Setup."Clockify API Version"</c> to
/// the <c>Mock</c> value added by <see cref="EnumExtension.ClockifyApiVersionTest"/>.
/// </summary>
codeunit 95603 "Clockify Mock Client" implements "Clockify API Client"
{
    Access = Internal;

    procedure Send(Method: Text; ResourcePath: Text; HasBody: Boolean; RequestBody: Text; var ResponseBody: Text; var StatusCode: Integer): Boolean
    var
        MockState: Codeunit "Clockify Mock State";
    begin
        MockState.CaptureRequest(Method, ResourcePath, HasBody, RequestBody);
        ResponseBody := MockState.GetNextResponseBody();
        StatusCode := MockState.GetNextStatusCode();
        exit(MockState.GetNextIsSuccess());
    end;
}
