namespace Origo.PTE.CloudEvents.Clockify;

/// <summary>
/// Transport contract for talking to the Clockify REST API. The concrete
/// implementation is selected by the <see cref="Enum.ClockifyApiVersion"/> value
/// stored on <c>Cloud Events Setup</c>, so the rest of the connector never
/// depends on a specific endpoint or HTTP stack. A test extension can supply a
/// mock implementation through an enum extension for fully offline testing.
/// </summary>
interface "Clockify API Client"
{
    /// <summary>
    /// Sends a request to the Clockify API and returns the outcome.
    /// </summary>
    /// <param name="Method">HTTP method: GET, POST, PUT or DELETE.</param>
    /// <param name="ResourcePath">Resource path appended to the base URL, starting with '/' (for example '/workspaces').</param>
    /// <param name="HasBody">True when <paramref name="RequestBody"/> should be sent as the request content.</param>
    /// <param name="RequestBody">JSON request body (used only when <paramref name="HasBody"/> is true).</param>
    /// <param name="ResponseBody">Out: the raw response body returned by Clockify.</param>
    /// <param name="StatusCode">Out: the HTTP status code returned by Clockify.</param>
    /// <returns>True when Clockify returned a 2xx status code.</returns>
    procedure Send(Method: Text; ResourcePath: Text; HasBody: Boolean; RequestBody: Text; var ResponseBody: Text; var StatusCode: Integer): Boolean
}
