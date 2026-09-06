namespace Origo.Bifrost.Clockify;

using Microsoft.Projects.Project.Journal;
using Microsoft.Utilities;

/// <summary>
/// Company-level setup for the Bifrost Clockify connector. Bifröst Foundation's own
/// <c>Setup ori</c> table is not extended: every Clockify setting lives here so the
/// connector can be installed, configured and removed without touching Foundation.
///
/// The connector talks to Clockify through the API implementation selected by the
/// <see cref="API Version"/> field (default <c>Version 1</c>, fixed on the public v1
/// endpoint) - see <c>Clockify API Client ori</c>.
///
/// The Clockify API key itself is never stored in a table field - it is held in
/// IsolatedStorage (Company scope) by <c>Clockify Secret Mgt ori</c>. The setup page
/// reads key presence live through that codeunit.
/// </summary>
table 70009268 "Clockify Setup ori"
{
    Caption = 'Clockify Setup', Comment = 'is-IS=Uppsetning Clockify';
    DataClassification = SystemMetadata;

    fields
    {
        /// <summary>Primary key of the singleton setup record; always blank.</summary>
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key', Comment = 'is-IS=Aðallykill';
            DataClassification = SystemMetadata;
        }

        /// <summary>
        /// Selects which Clockify API implementation the connector uses. Defaults to
        /// <c>Version 1</c>, fixed on the public endpoint
        /// <c>https://api.clockify.me/api/v1</c>. Resolved to a
        /// <c>Clockify API Client ori</c> implementation at call time.
        /// </summary>
        field(10; "API Version"; Enum "Clockify API Version ori")
        {
            Caption = 'Clockify API Version', Comment = 'is-IS=Clockify API útgáfa';
            DataClassification = SystemMetadata;
        }

        /// <summary>
        /// Default Clockify workspace ID used when a message request omits the
        /// <c>workspaceId</c> property. Picked from the live workspace list on the
        /// setup card; the matching name is held in <see cref="Workspace Name"/>.
        /// </summary>
        field(11; "Default Workspace"; Text[50])
        {
            Caption = 'Default Workspace ID', Comment = 'is-IS=Sjálfgefið vinnusvæði';
            DataClassification = SystemMetadata;
        }

        /// <summary>
        /// Display name of the selected default workspace, captured when it is picked.
        /// Shown read-only beside the ID so the selection is recognisable.
        /// </summary>
        field(12; "Workspace Name"; Text[250])
        {
            Caption = 'Default Workspace', Comment = 'is-IS=Sjálfgefið vinnusvæði';
            DataClassification = SystemMetadata;
            Editable = false;
        }

        /// <summary>
        /// Base URL of the Clockify webhook receiver (the Azure Function endpoint),
        /// including the target BC company, for example
        /// <c>https://my-site/api/clockify-webhooks?companyId={guid}</c>. The connector
        /// appends <c>&amp;workspaceId={id}</c> when registering each webhook, so the
        /// receiver can label the source workspace. Used by <c>Clockify Webhook Mgt ori</c>
        /// to register and remove the real-time time-entry webhooks in Clockify.
        /// </summary>
        field(13; "Webhook Receiver URL"; Text[250])
        {
            Caption = 'Webhook Receiver URL', Comment = 'is-IS=Móttökuslóð vefkróka';
            DataClassification = SystemMetadata;
            ExtendedDatatype = URL;
        }

        /// <summary>
        /// Job Journal template that synced Clockify time entries are written to, by
        /// both the <c>Clockify.TimeEntry.Sync</c> message type and the real-time webhook
        /// handler. The message type may override it per request; the webhook handler
        /// always uses this value and skips when it is blank.
        /// </summary>
        field(14; "Job Jnl. Template"; Code[10])
        {
            Caption = 'Job Journal Template', Comment = 'is-IS=Verkbókarlýsing';
            DataClassification = SystemMetadata;
            TableRelation = "Job Journal Template".Name;
        }

        /// <summary>
        /// Job Journal batch (within <see cref="Job Jnl. Template"/>) that synced
        /// Clockify time entries are written to.
        /// </summary>
        field(15; "Job Jnl. Batch"; Code[10])
        {
            Caption = 'Job Journal Batch', Comment = 'is-IS=Verkbókarflokkur';
            DataClassification = SystemMetadata;
            TableRelation = "Job Journal Batch".Name where("Journal Template Name" = field("Job Jnl. Template"));
        }

        /// <summary>
        /// Work Type assigned to a synced Job Journal Line when the Clockify time entry
        /// has no tag linked to a Work Type. A linked Clockify tag (a <c>TAG</c>-type
        /// Clockify Integration row whose BC Code is a Work Type Code) takes precedence;
        /// this value is the fallback. Blank leaves the journal line's Work Type empty.
        /// </summary>
        field(16; "Default Work Type"; Code[10])
        {
            Caption = 'Default Work Type', Comment = 'is-IS=Sjálfgefin vinnutegund';
            DataClassification = SystemMetadata;
            TableRelation = "Work Type".Code;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    /// <summary>
    /// Reads the singleton setup record, inserting an empty one the first time it is
    /// requested so callers never have to test for its existence.
    /// </summary>
    internal procedure GetSetup()
    begin
        if Rec.Get() then
            exit;
        Rec.Init();
        if not Rec.Insert() then
            Rec.Get();
    end;
}
