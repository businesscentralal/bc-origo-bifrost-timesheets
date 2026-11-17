namespace Origo.Bifrost.Timesheets.Test;

using Origo.Bifrost;
using System.TestLibraries.Utilities;

/// <summary>
/// Issues 87 and 93: neither dormant Clockify types nor the native types moved to
/// Projects are registered by Timesheets. Phone Role Center and connector objects remain.
/// </summary>
codeunit 95636 "TS Release Surface Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    /// <summary>Verifies the withdrawn catalogue in an English session.</summary>
    [Test]
    procedure Scenario_AC02_English_NoTimesheetsOrClockifyTypes()
    begin
        AssertWithdrawnCatalogue(1033);
    end;

    /// <summary>Verifies the withdrawn catalogue in an Icelandic session.</summary>
    [Test]
    procedure Scenario_AC02_Icelandic_NoTimesheetsOrClockifyTypes()
    begin
        AssertWithdrawnCatalogue(1039);
    end;

    local procedure AssertWithdrawnCatalogue(LanguageId: Integer)
    var
        Assert: Codeunit "Library Assert";
        MessageType: Enum "Message Type ori";
        Contract: Interface "Msg Contract ori";
        PreviousLanguage: Integer;
        Ordinal: Integer;
        MessageName: Text;
        Overview: Text;
        OrdinalPublishedErr: Label 'Timesheets ordinal %1 is still published.', Locked = true;
    begin
        // Story #93, AC02 | Time: none | Risk: other feature apps may extend the catalogue.
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        foreach Ordinal in Enum::"Message Type ori".Ordinals() do
            Assert.IsFalse((Ordinal >= 10036785) and (Ordinal <= 10036884), StrSubstNo(OrdinalPublishedErr, Ordinal));
        foreach MessageName in MessageType.Names() do begin
            Assert.IsFalse(MessageName.StartsWith('Clockify.'), 'Discoverable Clockify type ' + MessageName);
            Assert.AreNotEqual('Help.Clockify.Get', MessageName, 'Help.Clockify.Get must not be discoverable.');
            Assert.IsFalse(MessageName.StartsWith('Timesheets.'), 'Moved type is still registered: ' + MessageName);
        end;
        MessageType := "Message Type ori"::"Help.Bifrost.Get";
        Contract := MessageType;
        Contract.GetOverview(Overview);
        Assert.IsFalse(Overview.Contains('Help.Clockify.Get'), 'Foundation overview lists Help.Clockify.Get.');
        Assert.IsFalse(Overview.Contains('`Clockify.'), 'Foundation overview lists a Clockify message type.');
        Assert.IsFalse(Overview.Contains('`Timesheets.'), 'Foundation overview lists a moved Timesheets message type.');
        GlobalLanguage(PreviousLanguage);
    end;
}
