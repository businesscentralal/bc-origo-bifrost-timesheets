namespace Origo.Bifrost.Timesheets;

using Origo.Bifrost;

/// <summary>
/// Restricts generic writes to the Clockify Webhook Receiver URL on Clockify Setup ori through
/// Bifröst Foundation's Data.Records field events. That URL is where Clockify is told to
/// deliver real-time time-entry webhooks; a caller who can change it through Data.Records.Set,
/// then re-register the webhooks, can have time-entry data delivered to a server of their
/// choice. Only the receiver URL (field 13) is write-blocked for the generic data API. Reading
/// the field stays allowed, and the Timesheets setup page and the Clockify message types (which
/// read the URL from code, and the webhook handler) are unaffected - they do not go through
/// Data.Records.Set.
/// </summary>
codeunit 10036838 "Clockify Field Restrict ori"
{
    Access = Internal;

    var
        ReceiverUrlHintTok: Label 'the Timesheets setup page (Clockify Setup)', Locked = true;

    [EventSubscriber(ObjectType::Table, Database::"Message Argument ori", OnAfterIsFieldWriteRestrictedForDataRecords, '', false, false)]
    local procedure OnAfterIsFieldWriteRestricted(TableNo: Integer;
        FieldNo: Integer;
        var IsRestricted: Boolean)
    var
        ClockifySetup: Record "Clockify Setup ori";
    begin
        if (TableNo = Database::"Clockify Setup ori") and (FieldNo = ClockifySetup.FieldNo("Webhook Receiver URL")) then
            IsRestricted := true;
    end;

    /// <summary>Returns the setup surface as a bare phrase for Foundation to compose the refusal.</summary>
    [EventSubscriber(ObjectType::Table, Database::"Message Argument ori", OnGetDedicatedMessageTypeHintForField, '', false, false)]
    local procedure OnGetDedicatedMessageTypeHintForField(TableNo: Integer;
        FieldNo: Integer;
        var Hint: Text)
    var
        ClockifySetup: Record "Clockify Setup ori";
    begin
        if (TableNo = Database::"Clockify Setup ori") and (FieldNo = ClockifySetup.FieldNo("Webhook Receiver URL")) then
            Hint := ReceiverUrlHintTok;
    end;
}
