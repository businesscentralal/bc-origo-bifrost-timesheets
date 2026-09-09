namespace Origo.Bifrost.Timesheets.Providers.Clockify;

/// <summary>
/// In-memory buffer that carries the Clockify workspaces returned by
/// <c>GET /workspaces</c> into the <see cref="Page.ClockifyWorkspaceLookup"/>
/// picker. Never persisted — it is always used as a temporary table.
/// </summary>
table 10036787 "Clockify Workspace Buffer ori"
{
    TableType = Temporary;
    DataClassification = SystemMetadata;
    Caption = 'Clockify Workspace', Comment = 'is-IS=Clockify vinnusvæði';

    fields
    {
        /// <summary>The Clockify workspace identifier.</summary>
        field(1; "Workspace ID"; Text[50])
        {
            Caption = 'Workspace ID', Comment = 'is-IS=Kenni vinnusvæðis';
        }
        /// <summary>The display name of the workspace.</summary>
        field(2; "Name"; Text[250])
        {
            Caption = 'Name', Comment = 'is-IS=Heiti';
        }
    }

    keys
    {
        key(PK; "Workspace ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Name", "Workspace ID") { }
    }
}
