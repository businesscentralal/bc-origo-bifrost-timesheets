namespace Origo.Bifrost.Clockify;

using Origo.Bifrost;

/// <summary>
/// Adds the Bifröst Clockify setup action to the Bifröst Setup page. Following the
/// Foundation rule for dependent applications, this is the connector's entire
/// footprint on that page: one action in the <c>Apps</c> group and its promoted
/// reference. Every Clockify field, list and action lives on
/// <c>Clockify Setup ori</c>.
/// </summary>
pageextension 70009200 "Clockify Setup Ext ori" extends "Setup ori"
{
    actions
    {
        addlast(Apps)
        {
            action(ClockifySetupCard)
            {
                ApplicationArea = All;
                Caption = 'Clockify', Comment = 'is-IS=Clockify';
                Image = Timesheet;
                RunObject = page "Clockify Setup ori";
                ToolTip = 'Open the setup of the Bifröst Clockify connector: API key, default workspace, Job Journal target and real-time webhooks.', Comment = 'is-IS=Opna uppsetningu Bifröst Clockify tengingar: API lykil, sjálfgefið vinnusvæði, verkbók og rauntíma vefkróka.';
            }
        }
        addlast(Category_Apps)
        {
            actionref(ClockifySetupCardPromoted; ClockifySetupCard)
            {
            }
        }
    }
}
