namespace Origo.Bifrost.Timesheets;

using Origo.Bifrost;

/// <summary>
/// Restricts generic writes to the Clockify Webhook Receiver URL on Clockify Setup ori through
/// Bifr\u00f6st Foundation's Data.Records field events. That URL is where Clockify is told to
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

    /// <summary>
    /// Raises the dedicated message-type hint for the Webhook Receiver URL so the write-block
    /// error names the Timesheets setup page as the place to change it. No Clockify message type
    /// writes the receiver URL, so the hint points at the setup surface.
    /// </summary>
    var
        ReceiverUrlHintTok: Label 'Use the Timesheets setup page to change the Webhook Receiver URL.', Comment = 'is-IS=Not\u00ed\u00f0u uppsetningars\u00ed\u00f0\u00edn\u00f0 T\u00edmaskr\u00e1ningar til a\u00f0 breyta m\u00f3tt\u00f6kusu\u00f3\u00f0 vefkr\u00f3ka.';

    [EventSubscriber(ObjectType::Table, Database::"Message Argument ori", OnAfterIsFieldWriteRestrictedForDataRecords, '', false, false)]
    local procedure OnAfterIsFieldWriteRestricted(TableNo: Integer; FieldNo: Integer; var IsRestricted: Boolean)
    begin
        if (TableNo = Database::"Clockify Setup ori") and (FieldNo = 13) then
            IsRestricted := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Message Argument ori", OnGetDedicatedMessageTypeHintForField, '', false, false)]
    local procedure OnGetDedicatedMessageTypeHintForField(TableNo: Integer; FieldNo: Integer; var Hint: Text)
    begin
        if (TableNo = Database::"Clockify Setup ori") and (FieldNo = 13) then
            Hint := ReceiverUrlHintTok;
    end;
}
