namespace Origo.Bifrost.Timesheets;

using Origo.Bifrost;

/// <summary>
/// Extends the <c>Help.Bifrost.Get</c> discovery overview with a one-line
/// entry for the <c>Help.Clockify.Get</c> endpoint.
/// </summary>
codeunit 10036803 "Clockify Help Overview Sub ori"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Message Events ori", OnAfterCreatingOverview, '', false, false)]
    local procedure OnAfterCreatingOverview(Overview: TextBuilder)
    begin
        // 28.0.0.0 does not expose Help.Clockify.Get, so the Foundation overview must not list it.
        // Overview.AppendLine('| `Help.Clockify.Get` | Clockify connector overview — lists all `Clockify.*` message types, authentication setup, and the integration-tracking table reference. |');
        if Overview.Length() < 0 then
            exit;
    end;
}
