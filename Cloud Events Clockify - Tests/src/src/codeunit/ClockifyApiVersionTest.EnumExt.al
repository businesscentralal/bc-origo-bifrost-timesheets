namespace Origo.PTE.CloudEvents.Clockify;

/// <summary>
/// Adds a test-only <c>Mock</c> value to the <c>Clockify API Version</c> enum,
/// bound to <see cref="Codeunit.ClockifyMockClient"/>. Selecting this value on
/// <c>Cloud Events Setup</c> routes every connector call through the mock,
/// enabling fully offline testing of the request/response pipeline.
/// </summary>
enumextension 95604 "Clockify API Version Test" extends "Clockify API Version"
{
    /// <summary>Routes Clockify calls to the in-memory mock client. Test use only.</summary>
    value(95600; Mock)
    {
        Caption = 'Mock', Locked = true;
        Implementation = "Clockify API Client" = "Clockify Mock Client";
    }
}
