namespace Origo.Bifrost.Clockify;

/// <summary>
/// Selects which Clockify API implementation the connector talks to. The value
/// is stored on <c>Clockify Setup</c> and resolved to an
/// <see cref="Interface.ClockifyApiClient"/> at call time, replacing the former
/// free-text base-URL field.
///
/// <c>Version 1</c> is the default and is fixed on the public Clockify v1
/// endpoint. The enum is extensible so a test extension can add its own value
/// (for example a mock) without changing this app.
/// </summary>
enum 70009200 "Clockify API Version ori" implements "Clockify API Client ori"
{
    Extensible = true;
    DefaultImplementation = "Clockify API Client ori" = "Clockify Client ori";

    /// <summary>
    /// Clockify public REST API version 1, fixed on
    /// <c>https://api.clockify.me/api/v1</c>. This is the default.
    /// </summary>
    value(0; "Version 1")
    {
        Caption = 'Version 1', Comment = 'is-IS=Útgáfa 1';
        Implementation = "Clockify API Client ori" = "Clockify Client ori";
    }
}
