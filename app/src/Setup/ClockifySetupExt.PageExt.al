namespace Origo.Bifrost.Clockify;

using Origo.Bifrost;

/// <summary>
/// Adds a single navigation action to the Bifröst Setup card that opens
/// <c>Clockify Setup ori</c>. No Clockify fields or action groups are added to
/// Foundation's setup page - everything the connector needs lives on its own card.
/// </summary>
pageextension 70009200 "Clockify Setup Ext ori" extends "Setup ori"
{
    actions
    {
        addlast(Navigation)
        {
            action(ClockifySetupCard)
            {
                ApplicationArea = All;
                Caption = 'Clockify Setup', Comment = 'is-IS=Uppsetning Clockify';
                Image = Setup;
                RunObject = page "Clockify Setup ori";
                ToolTip = 'Opens the Clockify connector setup: API key, default workspace, Job Journal target and real-time webhooks.', Comment = 'is-IS=Opnar uppsetningu Clockify tengingar: API lykil, sjálfgefið vinnusvæði, verkbók og rauntíma vefkróka.';
            }
        }
    }
}
