namespace Origo.Bifrost.Clockify;

/// <summary>
/// Administrative view of the <see cref="Table.ClockifyIntegration"/> links between
/// Business Central records and Clockify objects. Read-oriented: links are created
/// and maintained by integrators through the base <c>Data.Records.Get</c> /
/// <c>Data.Records.Set</c> message types, not edited here.
/// </summary>
page 70009200 "Clockify Integration List ori"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "Clockify Integration ori";
    Caption = 'Clockify Integration', Comment = 'is-IS=Clockify tengingar';
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Links)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ToolTip = 'Specifies the entry number of the integration link.', Comment = 'is-IS=Tilgreinir færslunúmer tengingarinnar.';
                }
                field("BC Table No."; Rec."BC Table No.")
                {
                    ToolTip = 'Specifies the Business Central table the linked record belongs to.', Comment = 'is-IS=Tilgreinir BC töfluna sem tengda færslan tilheyrir.';
                }
                field("BC Code"; Rec."BC Code")
                {
                    ToolTip = 'Specifies the human-readable key of the Business Central record.', Comment = 'is-IS=Tilgreinir læsilegan lykil BC færslunnar.';
                }
                field("BC SystemId"; Rec."BC SystemId")
                {
                    ToolTip = 'Specifies the SystemId of the linked Business Central record.', Comment = 'is-IS=Tilgreinir kerfiskenni tengdu BC færslunnar.';
                    Visible = false;
                }
                field("Clockify Type"; Rec."Clockify Type")
                {
                    ToolTip = 'Specifies the kind of Clockify object the record is linked to.', Comment = 'is-IS=Tilgreinir tegund Clockify hlutarins sem fært er tengt við.';
                }
                field("Clockify Name"; Rec."Clockify Name")
                {
                    ToolTip = 'Specifies the display name of the linked Clockify object.', Comment = 'is-IS=Tilgreinir heiti tengda Clockify hlutarins.';
                }
                field("Clockify Id"; Rec."Clockify Id")
                {
                    ToolTip = 'Specifies the identifier of the linked Clockify object.', Comment = 'is-IS=Tilgreinir kenni tengda Clockify hlutarins.';
                }
                field("Clockify Workspace Id"; Rec."Clockify Workspace Id")
                {
                    ToolTip = 'Specifies the Clockify workspace the object lives in.', Comment = 'is-IS=Tilgreinir Clockify vinnusvæðið sem hluturinn tilheyrir.';
                    Visible = false;
                }
                field("Reversed"; Rec."Reversed")
                {
                    ToolTip = 'Specifies whether the link has been broken. Reversed links are purged about one month after reversal.', Comment = 'is-IS=Tilgreinir hvort tengingin hafi verið rofin. Afturkallaðar tengingar eru hreinsaðar um mánuði eftir afturköllun.';
                }
                field("Reversed At"; Rec."Reversed At")
                {
                    ToolTip = 'Specifies when the link was reversed.', Comment = 'is-IS=Tilgreinir hvenær tengingin var afturkölluð.';
                }
            }
        }
    }
}
