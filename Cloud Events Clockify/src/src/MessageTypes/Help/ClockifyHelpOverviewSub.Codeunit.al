namespace Origo.PTE.CloudEvents.Clockify;

using Origo.APP.CloudEvents;

/// <summary>
/// Extends the <c>Help.CloudEvents.Get</c> discovery overview with a one-line
/// entry for the <c>Help.Clockify.Get</c> endpoint.
/// </summary>
codeunit 71447 "Clockify Help Overview Sub"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Cloud Event Message Events ori", OnAfterCreatingOverview, '', false, false)]
    local procedure OnAfterCreatingOverview(Overview: TextBuilder)
    begin
        Overview.AppendLine('| `Help.Clockify.Get` | Clockify connector overview — lists all `Clockify.*` message types, authentication setup, and the integration-tracking table reference. |');
    end;
}
