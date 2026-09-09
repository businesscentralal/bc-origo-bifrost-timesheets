namespace Origo.Bifrost.Timesheets.Providers.Clockify;

using Origo.Bifrost;

/// <summary>
/// Extends <c>Request Log Type ori</c> with the Clockify service type.
/// Maps to <c>Clockify ReqLog Masker ori</c> which passes through JSON bodies
/// (the API key lives in HTTP headers, not in the body).
/// </summary>
enumextension 10036786 "Clockify Req Log Type ori" extends "Request Log Type ori"
{
    value(10036785; Clockify)
    {
        Caption = 'Clockify', Locked = true;
        Implementation = "Request Log Masker ori" = "Clockify ReqLog Masker ori";
    }
}
