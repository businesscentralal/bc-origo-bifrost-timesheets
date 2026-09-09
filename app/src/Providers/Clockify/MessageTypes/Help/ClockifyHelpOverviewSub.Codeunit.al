namespace Origo.Bifrost.Timesheets.Providers.Clockify;

using Origo.Bifrost;

/// <summary>
/// Extends the <c>Help.Bifrost.Get</c> discovery overview with a one-line
/// entry for the <c>Provider.Clockify.Help.Get</c> endpoint.
/// </summary>
codeunit 10036803 "Clockify Help Overview Sub ori"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Message Events ori", OnAfterCreatingOverview, '', false, false)]
    local procedure OnAfterCreatingOverview(Overview: TextBuilder)
    begin
        Overview.AppendLine('| `Provider.Clockify.Help.Get` | Clockify connector overview — lists all `Clockify.*` message types, authentication setup, and the integration-tracking table reference. |');
    end;
}
