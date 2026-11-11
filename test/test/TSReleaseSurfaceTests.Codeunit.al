namespace Origo.Bifrost.Timesheets.Test;

using Origo.Bifrost;
using System.TestLibraries.Utilities;

/// <summary>
/// Issue 87 AC06. Clockify and Help.Clockify.Get are not discoverable. The eleven native
/// Timesheets types remain, and their contracts do not say the old names still work.
/// </summary>
codeunit 95636 "TS Release Surface Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure ClockifyTypes_AreNotDiscoverable()
    var
        Assert: Codeunit "Library Assert";
        MessageType: Enum "Message Type ori";
        Contract: Interface "Msg Contract ori";
        OrdinalPublishedErr: Label 'Clockify ordinal %1 is still published.', Locked = true;
        NativeCount: Integer;
        Ordinal: Integer;
        Name: Text;
        Overview: Text;
    begin
        foreach Ordinal in Enum::"Message Type ori".Ordinals() do begin
            Assert.IsFalse((Ordinal >= 10036785) and (Ordinal <= 10036825), StrSubstNo(OrdinalPublishedErr, Ordinal));
            MessageType := Enum::"Message Type ori".FromInteger(Ordinal);
            Name := Format(MessageType);
            Assert.IsFalse(Name.StartsWith('Clockify.'), 'Discoverable Clockify type ' + Name);
            Assert.AreNotEqual('Help.Clockify.Get', Name, 'Help.Clockify.Get must not be discoverable.');
            if Name.StartsWith('Timesheets.') then
                NativeCount += 1;
        end;
        Assert.AreEqual(11, NativeCount, 'The release surface is the eleven native Timesheets types.');

        MessageType := "Message Type ori"::"Help.Bifrost.Get";
        Contract := MessageType;
        Contract.GetOverview(Overview);
        Assert.IsFalse(Overview.Contains('Help.Clockify.Get'), 'Foundation overview lists Help.Clockify.Get.');
        Assert.IsFalse(Overview.Contains('`Clockify.'), 'Foundation overview lists a Clockify message type.');

        AssertNativeNotesDoNotKeepOldNames("Message Type ori"::"Timesheets.TimeSheet.Reopen");
        AssertNativeNotesDoNotKeepOldNames("Message Type ori"::"Timesheets.TimeSheet.Post");
        AssertNativeNotesDoNotKeepOldNames("Message Type ori"::"Timesheets.TimeSheet.Archive");
    end;

    local procedure AssertNativeNotesDoNotKeepOldNames(MessageType: Enum "Message Type ori")
    var
        Assert: Codeunit "Library Assert";
        Contract: Interface "Msg Contract ori";
        Notes: Text;
    begin
        Contract := MessageType;
        Contract.GetNotes(Notes);
        Assert.IsFalse(Notes.Contains('keeps working'), Format(MessageType) + ' notes keep the old name.');
        Assert.IsFalse(Notes.Contains('still work'), Format(MessageType) + ' notes say the old name still works.');
        Assert.IsFalse(Notes.Contains('still runs'), Format(MessageType) + ' notes say the old name still runs.');
    end;
}
