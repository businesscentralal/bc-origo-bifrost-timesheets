namespace Origo.Bifrost.Timesheets;

/// <summary>
/// Tracks the Clockify webhooks the connector has registered for real-time
/// time-entry sync. One row per Clockify event type (for example
/// <c>NEW_TIME_ENTRY</c>), holding the webhook ID returned by Clockify so the
/// registration can later be inspected or deleted. Maintained by
/// <see cref="Codeunit.ClockifyWebhookMgt"/>.
///
/// The per-webhook signing token (<c>authToken</c>) is a secret and is never
/// stored here — it is held in IsolatedStorage by
/// <see cref="Codeunit.ClockifySecretMgt"/>.
/// </summary>
table 10036786 "Clockify Webhook ori"
{
    Caption = 'Clockify Webhook', Comment = 'is-IS=Clockify vefkrókur';
    DataClassification = SystemMetadata;
    LookupPageId = "Clockify Webhooks ori";
    DrillDownPageId = "Clockify Webhooks ori";

    fields
    {
        /// <summary>The Clockify webhook event this row registers, for example <c>NEW_TIME_ENTRY</c>.</summary>
        field(1; "Event"; Code[30])
        {
            Caption = 'Event', Comment = 'is-IS=Atburður';
        }
        /// <summary>The webhook identifier returned by Clockify on creation. Used to delete the webhook later.</summary>
        field(10; "Webhook Id"; Text[50])
        {
            Caption = 'Webhook ID', Comment = 'is-IS=Vefkróka kenni';
        }
        /// <summary>The display name the connector gave the webhook in Clockify.</summary>
        field(11; "Webhook Name"; Text[100])
        {
            Caption = 'Webhook Name', Comment = 'is-IS=Heiti vefkróks';
        }
        /// <summary>The receiver URL the webhook was registered against.</summary>
        field(12; "Url"; Text[250])
        {
            Caption = 'URL', Comment = 'is-IS=Slóð';
            ExtendedDatatype = URL;
        }
        /// <summary>The Clockify workspace the webhook belongs to.</summary>
        field(13; "Workspace Id"; Text[50])
        {
            Caption = 'Workspace ID', Comment = 'is-IS=Vinnusvæðiskenni';
        }
        /// <summary>When the connector registered the webhook.</summary>
        field(20; "Registered At"; DateTime)
        {
            Caption = 'Registered At', Comment = 'is-IS=Skráð þann';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Event")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Event", "Webhook Id", "Registered At") { }
    }
}
