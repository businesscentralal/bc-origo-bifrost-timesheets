namespace Origo.Bifrost.Timesheets;

/// <summary>Item and resource consumption linked to an owned native time sheet line.</summary>
table 10036878 "TS Usage Line ori"
{
    Caption = 'Time Sheet Usage', Comment = 'is-IS=Notkun tímaskýrslu';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.', Comment = 'is-IS=Færslunr.';
            ToolTip = 'Specifies the entry no. of the time sheet usage.', Comment = 'is-IS=Tilgreinir færslunr. fyrir notkun tímaskýrslu.';
            AutoIncrement = true;
        }
        field(2; "Time Sheet No."; Code[20])
        {
            Caption = 'Time Sheet No.', Comment = 'is-IS=Tímaskýrslunr.';
            ToolTip = 'Specifies the time sheet no. of the time sheet usage.', Comment = 'is-IS=Tilgreinir tímaskýrslunr. fyrir notkun tímaskýrslu.';
        }
        field(3; "Time Sheet Line No."; Integer)
        {
            Caption = 'Time Sheet Line No.', Comment = 'is-IS=Línunr. tímaskýrslu';
            ToolTip = 'Specifies the time sheet line no. of the time sheet usage.', Comment = 'is-IS=Tilgreinir línunr. tímaskýrslu fyrir notkun tímaskýrslu.';
        }
        field(4; "Resource No."; Code[20])
        {
            Caption = 'Resource No.', Comment = 'is-IS=Forðanr.';
            ToolTip = 'Specifies the resource no. of the time sheet usage.', Comment = 'is-IS=Tilgreinir forðanr. fyrir notkun tímaskýrslu.';
        }
        field(5; "Type"; Enum "TS Usage Type ori")
        {
            Caption = 'Type', Comment = 'is-IS=Tegund';
            ToolTip = 'Specifies the type of the time sheet usage.', Comment = 'is-IS=Tilgreinir tegund fyrir notkun tímaskýrslu.';
        }
        field(6; "No."; Code[20])
        {
            Caption = 'No.', Comment = 'is-IS=Nr.';
            ToolTip = 'Specifies the no. of the time sheet usage.', Comment = 'is-IS=Tilgreinir nr. fyrir notkun tímaskýrslu.';
        }
        field(7; "Date"; Date)
        {
            Caption = 'Date', Comment = 'is-IS=Dagsetning';
            ToolTip = 'Specifies the date of the time sheet usage.', Comment = 'is-IS=Tilgreinir dagsetning fyrir notkun tímaskýrslu.';
        }
        field(8; "Quantity"; Decimal)
        {
            Caption = 'Quantity', Comment = 'is-IS=Magn';
            ToolTip = 'Specifies the quantity of the time sheet usage.', Comment = 'is-IS=Tilgreinir magn fyrir notkun tímaskýrslu.';
        }
        field(9; "Unit of Measure"; Code[10])
        {
            Caption = 'Unit of Measure', Comment = 'is-IS=Mælieining';
            ToolTip = 'Specifies the unit of measure of the time sheet usage.', Comment = 'is-IS=Tilgreinir mælieining fyrir notkun tímaskýrslu.';
        }
        field(10; "Description"; Text[100])
        {
            Caption = 'Description', Comment = 'is-IS=Lýsing';
            ToolTip = 'Specifies the description of the time sheet usage.', Comment = 'is-IS=Tilgreinir lýsing fyrir notkun tímaskýrslu.';
        }
        field(11; "Status"; Enum "TS Usage Status ori")
        {
            Caption = 'Status', Comment = 'is-IS=Staða';
            ToolTip = 'Specifies the status of the time sheet usage.', Comment = 'is-IS=Tilgreinir staða fyrir notkun tímaskýrslu.';
        }
        field(12; "Reversed"; Boolean)
        {
            Caption = 'Reversed', Comment = 'is-IS=Bakfærð';
            ToolTip = 'Specifies the reversed of the time sheet usage.', Comment = 'is-IS=Tilgreinir bakfærð fyrir notkun tímaskýrslu.';
        }
        field(13; "Approved By"; Code[50])
        {
            Caption = 'Approved By', Comment = 'is-IS=Samþykkt af';
            ToolTip = 'Specifies the approved by of the time sheet usage.', Comment = 'is-IS=Tilgreinir samþykkt af fyrir notkun tímaskýrslu.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(14; "Approved At"; DateTime)
        {
            Caption = 'Approved At', Comment = 'is-IS=Samþykkt kl.';
            ToolTip = 'Specifies the approved at of the time sheet usage.', Comment = 'is-IS=Tilgreinir samþykkt kl. fyrir notkun tímaskýrslu.';
        }
        field(15; "Journal Table No."; Integer)
        {
            Caption = 'Journal Table No.', Comment = 'is-IS=Töflunr. færslubókar';
            ToolTip = 'Specifies the journal table no. of the time sheet usage.', Comment = 'is-IS=Tilgreinir töflunr. færslubókar fyrir notkun tímaskýrslu.';
        }
        field(16; "Journal Template"; Code[10])
        {
            Caption = 'Journal Template', Comment = 'is-IS=Sniðmát færslubókar';
            ToolTip = 'Specifies the journal template of the time sheet usage.', Comment = 'is-IS=Tilgreinir sniðmát færslubókar fyrir notkun tímaskýrslu.';
        }
        field(17; "Journal Batch"; Code[10])
        {
            Caption = 'Journal Batch', Comment = 'is-IS=Keyrsla færslubókar';
            ToolTip = 'Specifies the journal batch of the time sheet usage.', Comment = 'is-IS=Tilgreinir keyrsla færslubókar fyrir notkun tímaskýrslu.';
        }
        field(18; "Journal Line No."; Integer)
        {
            Caption = 'Journal Line No.', Comment = 'is-IS=Línunr. færslubókar';
            ToolTip = 'Specifies the journal line no. of the time sheet usage.', Comment = 'is-IS=Tilgreinir línunr. færslubókar fyrir notkun tímaskýrslu.';
        }
        field(19; "Ledger Entry No."; Integer)
        {
            Caption = 'Ledger Entry No.', Comment = 'is-IS=Númer bókaðrar færslu';
            ToolTip = 'Specifies the ledger entry no. of the time sheet usage.', Comment = 'is-IS=Tilgreinir númer bókaðrar færslu fyrir notkun tímaskýrslu.';
        }
        field(20; "Rejection Comment"; Text[80])
        {
            Caption = 'Rejection Comment', Comment = 'is-IS=Athugasemd höfnunar';
            ToolTip = 'Specifies the rejection comment of the time sheet usage.', Comment = 'is-IS=Tilgreinir athugasemd höfnunar fyrir notkun tímaskýrslu.';
        }
        field(21; "Owner User ID"; Code[50])
        {
            Caption = 'Owner User ID', Comment = 'is-IS=Notandakenni eiganda';
            ToolTip = 'Specifies the owner user id of the time sheet usage.', Comment = 'is-IS=Tilgreinir notandakenni eiganda fyrir notkun tímaskýrslu.';
            DataClassification = EndUserIdentifiableInformation;
        }
    }
    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Sheet; "Time Sheet No.", "Time Sheet Line No.", Status) { }
        key(Owner; "Owner User ID", "Entry No.") { }
        key(Journal; "Journal Table No.", "Journal Template", "Journal Batch", "Journal Line No.") { }
    }
}
