namespace Origo.PTE.CloudEvents.Clockify;

using Microsoft.Projects.Project.Journal;
using Microsoft.Utilities;
using Origo.APP.CloudEvents;

/// <summary>
/// Extends <c>Cloud Events Setup</c> with the company-level Clockify connector
/// settings. Field IDs are allocated from the extension's own object range.
///
/// The connector talks to Clockify through the API implementation selected by
/// the <c>Clockify API Version</c> field (default <c>Version 1</c>, fixed on the
/// public v1 endpoint) — see <see cref="Interface.ClockifyApiClient"/>.
///
/// The Clockify API key itself is never stored in a table field — it is held in
/// IsolatedStorage (Company scope) by <see cref="Codeunit.ClockifySecretMgt"/>.
/// The Setup page reads key presence live via that codeunit.
/// </summary>
tableextension 71401 "Clockify Setup Ext" extends "Cloud Events Setup ori"
{
    fields
    {
        /// <summary>
        /// Selects which Clockify API implementation the connector uses. Defaults
        /// to <c>Version 1</c>, fixed on the public endpoint
        /// <c>https://api.clockify.me/api/v1</c>. Resolved to an
        /// <see cref="Interface.ClockifyApiClient"/> at call time.
        /// </summary>
        field(71402; "Clockify API Version"; Enum "Clockify API Version")
        {
            Caption = 'Clockify API Version', Comment = 'is-IS=Clockify API útgáfa';
            DataClassification = SystemMetadata;
        }

        /// <summary>
        /// Default Clockify workspace ID used when a message request omits the
        /// <c>workspaceId</c> property. Picked from the live workspace list on the
        /// Setup card; the matching name is held in
        /// <see cref="Clockify Workspace Name"/>.
        /// </summary>
        field(71401; "Clockify Default Workspace"; Text[50])
        {
            Caption = 'Clockify Default Workspace ID', Comment = 'is-IS=Clockify sjálfgefið vinnusvæði';
            DataClassification = SystemMetadata;
        }

        /// <summary>
        /// Display name of the selected default workspace, captured when it is
        /// picked. Shown read-only beside the ID so the selection is recognisable.
        /// </summary>
        field(71403; "Clockify Workspace Name"; Text[250])
        {
            Caption = 'Clockify Default Workspace', Comment = 'is-IS=Clockify sjálfgefið vinnusvæði';
            DataClassification = SystemMetadata;
            Editable = false;
        }

        /// <summary>
        /// Base URL of the Clockify webhook receiver (the Azure Function endpoint),
        /// including the target BC company, for example
        /// <c>https://my-site/api/clockify-webhooks?companyId={guid}</c>. The
        /// connector appends <c>&amp;workspaceId={id}</c> when registering each
        /// webhook, so the receiver can label the source workspace. Used by
        /// <see cref="Codeunit.ClockifyWebhookMgt"/> to register/remove the
        /// real-time time-entry webhooks in Clockify.
        /// </summary>
        field(71404; "Clockify Webhook Receiver URL"; Text[250])
        {
            Caption = 'Clockify Webhook Receiver URL', Comment = 'is-IS=Clockify vefkróka móttökuslóð';
            DataClassification = SystemMetadata;
            ExtendedDatatype = URL;
        }

        /// <summary>
        /// Job Journal template that synced Clockify time entries are written to,
        /// by both the <c>Clockify.TimeEntry.Sync</c> message type and the real-time
        /// webhook handler. The message type may override it per request; the
        /// webhook handler always uses this value and skips when it is blank.
        /// </summary>
        field(71405; "Clockify Job Jnl. Template"; Code[10])
        {
            Caption = 'Clockify Job Journal Template', Comment = 'is-IS=Clockify verkbókarlýsing';
            DataClassification = SystemMetadata;
            TableRelation = "Job Journal Template".Name;
        }

        /// <summary>
        /// Job Journal batch (within <see cref="Clockify Job Jnl. Template"/>) that
        /// synced Clockify time entries are written to.
        /// </summary>
        field(71406; "Clockify Job Jnl. Batch"; Code[10])
        {
            Caption = 'Clockify Job Journal Batch', Comment = 'is-IS=Clockify verkbókarflokkur';
            DataClassification = SystemMetadata;
            TableRelation = "Job Journal Batch".Name where("Journal Template Name" = field("Clockify Job Jnl. Template"));
        }

        /// <summary>
        /// Work Type assigned to a synced Job Journal Line when the Clockify time
        /// entry has no tag linked to a Work Type. A linked Clockify tag (a
        /// <c>TAG</c>-type Clockify Integration row whose BC Code is a Work Type
        /// Code) takes precedence; this value is the fallback. Blank leaves the
        /// journal line's Work Type empty.
        /// </summary>
        field(71407; "Clockify Default Work Type"; Code[10])
        {
            Caption = 'Clockify Default Work Type', Comment = 'is-IS=Clockify sjálfgefin vinnutegund';
            DataClassification = SystemMetadata;
            TableRelation = "Work Type".Code;
        }
    }
}
