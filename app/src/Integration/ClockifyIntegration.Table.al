namespace Origo.Bifrost.Timesheets;

/// <summary>
/// Tracks the links between Business Central records and the Clockify objects they
/// correspond to (for example a BC Customer and a Clockify Client). External
/// integrators read and write this table through the base Bifrost
/// <c>Data.Records.Get</c> / <c>Data.Records.Set</c> message types.
///
/// Neither message type can delete rows, so a link is broken by setting
/// <see cref="Reversed"/> to <c>true</c> rather than deleting the row. A retention
/// policy (registered by <see cref="Codeunit.ClockifyInstall"/>) then physically
/// removes reversed rows about one month after they were reversed, keyed off
/// <see cref="Reversed At"/>.
/// </summary>
table 10036785 "Clockify Integration ori"
{
    Caption = 'Clockify Integration', Comment = 'is-IS=Clockify tenging';
    DataClassification = CustomerContent;
    LookupPageId = "Clockify Integration List ori";
    DrillDownPageId = "Clockify Integration List ori";

    fields
    {
        /// <summary>Auto-incrementing primary key.</summary>
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.', Comment = 'is-IS=Færslunúmer';
            AutoIncrement = true;
        }
        /// <summary>The Business Central table the linked record belongs to (for example 18 for Customer).</summary>
        field(2; "BC Table No."; Integer)
        {
            Caption = 'BC Table No.', Comment = 'is-IS=Töflunúmer í BC';
        }
        /// <summary>The SystemId of the linked Business Central record — the stable link target.</summary>
        field(3; "BC SystemId"; Guid)
        {
            Caption = 'BC SystemId', Comment = 'is-IS=Kerfiskenni BC færslu';
        }
        /// <summary>The human-readable key of the BC record (for example the Customer No.).</summary>
        field(4; "BC Code"; Code[50])
        {
            Caption = 'BC Code', Comment = 'is-IS=BC kóði';
        }
        /// <summary>The kind of Clockify object: CLIENT, PROJECT, TASK, TAG, TIME_ENTRY, USER or WORKSPACE (WORKSPACE currently unused by this app).</summary>
        field(10; "Clockify Type"; Code[20])
        {
            Caption = 'Clockify Type', Comment = 'is-IS=Clockify tegund';
        }
        /// <summary>The Clockify workspace the object lives in.</summary>
        field(11; "Clockify Workspace Id"; Text[50])
        {
            Caption = 'Clockify Workspace ID', Comment = 'is-IS=Clockify vinnusvæðiskenni';
        }
        /// <summary>The Clockify object identifier.</summary>
        field(12; "Clockify Id"; Text[50])
        {
            Caption = 'Clockify ID', Comment = 'is-IS=Clockify kenni';
        }
        /// <summary>The display name of the Clockify object.</summary>
        field(13; "Clockify Name"; Text[250])
        {
            Caption = 'Clockify Name', Comment = 'is-IS=Clockify heiti';
        }
        /// <summary>
        /// Set to <c>true</c> to break the link. Reversed rows are excluded from
        /// active lookups and are purged by the retention policy.
        /// </summary>
        field(20; "Reversed"; Boolean)
        {
            Caption = 'Reversed', Comment = 'is-IS=Afturkölluð';
        }
        /// <summary>
        /// When the row was reversed. Stamped automatically when <see cref="Reversed"/>
        /// becomes <c>true</c>; cleared when it becomes <c>false</c>. Drives the
        /// one-month retention policy.
        /// </summary>
        field(21; "Reversed At"; DateTime)
        {
            Caption = 'Reversed At', Comment = 'is-IS=Afturkölluð þann';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(BCRecord; "BC Table No.", "BC SystemId", "Reversed") { }
        key(ClockifyObject; "Clockify Type", "Clockify Id", "Reversed") { }
        key(Retention; "Reversed", "Reversed At") { }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "BC Code", "Clockify Type", "Clockify Name") { }
    }

    trigger OnInsert()
    begin
        UpdateReversedAt();
    end;

    trigger OnModify()
    begin
        UpdateReversedAt();
    end;

    local procedure UpdateReversedAt()
    begin
        if Rec."Reversed" and (Rec."Reversed At" = 0DT) then
            Rec."Reversed At" := CurrentDateTime()
        else
            if not Rec."Reversed" then
                Rec."Reversed At" := 0DT;
    end;
}
