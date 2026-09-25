namespace Origo.Bifrost.Timesheets.Test;

using Origo.Bifrost.Timesheets;

/// <summary>
/// Counts <c>CLK0013</c> permission-skip telemetry while bound to a test.
/// </summary>
codeunit 95609 "Clockify Skip Listener"
{
    EventSubscriberInstance = Manual;

    var
        Clk0013Count: Integer;

    /// <summary>Returns how many <c>CLK0013</c> skips were logged while this listener was bound.</summary>
    procedure GetClk0013Count(): Integer
    begin
        exit(Clk0013Count);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Clockify Install ori", OnPermissionSkipLogged, '', false, false)]
    local procedure CountPermissionSkip(EventId: Text)
    begin
        if EventId = 'CLK0013' then
            Clk0013Count += 1;
    end;
}
