namespace Origo.PTE.CloudEvents.Clockify;

using Origo.APP.CloudEvents;

/// <summary>
/// Extends <c>CE Request Log Type ori</c> with the Clockify service type.
/// Maps to <c>Clockify ReqLog Masker</c> which passes through JSON bodies
/// (the API key lives in HTTP headers, not in the body).
/// </summary>
enumextension 70009201 "Clockify Req Log Type" extends "CE Request Log Type ori"
{
    value(70009200; Clockify)
    {
        Caption = 'Clockify', Locked = true;
        Implementation = "CE Request Log Masker ori" = "Clockify ReqLog Masker";
    }
}
