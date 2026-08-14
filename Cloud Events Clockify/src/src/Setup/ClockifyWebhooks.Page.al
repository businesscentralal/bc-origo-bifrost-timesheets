namespace Origo.PTE.CloudEvents.Clockify;

/// <summary>
/// Administrative view of the Clockify webhooks the connector has registered for
/// real-time time-entry sync (see <see cref="Table.ClockifyWebhook"/>). Read-only:
/// webhooks are created and removed through the actions on the
/// <c>Cloud Events Setup</c> card, not edited here.
/// </summary>
page 71456 "Clockify Webhooks"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "Clockify Webhook";
    Caption = 'Clockify Webhooks', Comment = 'is-IS=Clockify vefkrókar';
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Webhooks)
            {
                field("Event"; Rec."Event")
                {
                    ToolTip = 'Specifies the Clockify event the webhook fires on.', Comment = 'is-IS=Tilgreinir Clockify atburðinn sem vefkrókurinn bregst við.';
                }
                field("Webhook Name"; Rec."Webhook Name")
                {
                    ToolTip = 'Specifies the name the connector gave the webhook in Clockify.', Comment = 'is-IS=Tilgreinir heitið sem tengingin gaf vefkróknum í Clockify.';
                }
                field("Webhook Id"; Rec."Webhook Id")
                {
                    ToolTip = 'Specifies the identifier Clockify assigned to the webhook.', Comment = 'is-IS=Tilgreinir kennið sem Clockify úthlutaði vefkróknum.';
                }
                field("Workspace Id"; Rec."Workspace Id")
                {
                    ToolTip = 'Specifies the Clockify workspace the webhook belongs to.', Comment = 'is-IS=Tilgreinir Clockify vinnusvæðið sem vefkrókurinn tilheyrir.';
                }
                field("Url"; Rec."Url")
                {
                    ToolTip = 'Specifies the receiver URL the webhook posts to.', Comment = 'is-IS=Tilgreinir móttökuslóðina sem vefkrókurinn sendir á.';
                }
                field("Registered At"; Rec."Registered At")
                {
                    ToolTip = 'Specifies when the connector registered the webhook.', Comment = 'is-IS=Tilgreinir hvenær tengingin skráði vefkrókinn.';
                }
            }
        }
    }
}
