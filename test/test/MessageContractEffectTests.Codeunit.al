namespace Origo.Bifrost.Timesheets.Test;

using Origo.Bifrost;
using System.TestLibraries.Utilities;

/// <summary>
/// Effect chapter of every writing Clockify message type (issue #39): Clockify API writes and the
/// time sheet post are irreversible, Business Central-only writes stay write.
/// </summary>
codeunit 95611 "Message Contract Effect Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    [Test]
    procedure ClockifyApiWrites_DeclareIrreversible()
    begin
        // [SCENARIO] Create and Update call the Clockify API outside the Business Central transaction.
        AssertEffect("Message Type ori"::"Clockify.Client.Create", 'irreversible');
        AssertEffect("Message Type ori"::"Clockify.Client.Update", 'irreversible');
        AssertEffect("Message Type ori"::"Clockify.Project.Create", 'irreversible');
        AssertEffect("Message Type ori"::"Clockify.Project.Update", 'irreversible');
        AssertEffect("Message Type ori"::"Clockify.Task.Create", 'irreversible');
        AssertEffect("Message Type ori"::"Clockify.Task.Update", 'irreversible');
        AssertEffect("Message Type ori"::"Clockify.Tag.Create", 'irreversible');
        AssertEffect("Message Type ori"::"Clockify.Tag.Update", 'irreversible');
        AssertEffect("Message Type ori"::"Clockify.TimeEntry.Create", 'irreversible');
        AssertEffect("Message Type ori"::"Clockify.TimeEntry.Update", 'irreversible');
    end;

    [Test]
    procedure ClockifyDeletesAndPost_DeclareIrreversible()
    begin
        // [SCENARIO] Deletes in Clockify and the time sheet post cannot be undone.
        AssertEffect("Message Type ori"::"Clockify.Client.Delete", 'irreversible');
        AssertEffect("Message Type ori"::"Clockify.Project.Delete", 'irreversible');
        AssertEffect("Message Type ori"::"Clockify.Task.Delete", 'irreversible');
        AssertEffect("Message Type ori"::"Clockify.Tag.Delete", 'irreversible');
        AssertEffect("Message Type ori"::"Clockify.TimeEntry.Delete", 'irreversible');
        AssertEffect("Message Type ori"::"Clockify.TimeSheet.Post", 'irreversible');
    end;

    [Test]
    procedure BusinessCentralOnlyWrites_StayWrite()
    begin
        // [SCENARIO] Syncs and the time sheet lifecycle write Business Central only and do not commit.
        AssertEffect("Message Type ori"::"Clockify.TimeEntry.Sync", 'write');
        AssertEffect("Message Type ori"::"Clockify.TimeEntry.SyncRange", 'write');
        AssertEffect("Message Type ori"::"Clockify.TimeEntry.SyncAllUsers", 'write');
        AssertEffect("Message Type ori"::"Clockify.TimeEntry.SyncToTimeSheet", 'write');
        AssertEffect("Message Type ori"::"Clockify.TimeEntry.SyncRangeToTimeSheet", 'write');
        AssertEffect("Message Type ori"::"Clockify.TimeSheet.Create", 'write');
        AssertEffect("Message Type ori"::"Clockify.TimeSheet.Approve", 'write');
        AssertEffect("Message Type ori"::"Clockify.TimeSheet.Reject", 'write');
        AssertEffect("Message Type ori"::"Clockify.TimeSheet.Reopen", 'write');
        AssertEffect("Message Type ori"::"Clockify.TimeSheet.Archive", 'write');
    end;

    [Test]
    procedure Reads_StayRead()
    begin
        // [SCENARIO] List, Get and help types change nothing.
        AssertEffect("Message Type ori"::"Clockify.TimeEntry.List", 'read');
        AssertEffect("Message Type ori"::"Clockify.TimeEntry.Get", 'read');
        AssertEffect("Message Type ori"::"Clockify.User.GetCurrent", 'read');
        AssertEffect("Message Type ori"::"Help.Clockify.Get", 'read');
    end;

    local procedure AssertEffect(MessageType: Enum "Message Type ori"; Expected: Text)
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Contract: JsonObject;
        EffectToken: JsonToken;
        ValueToken: JsonToken;
        WrongEffectErr: Label '%1 effect', Locked = true;
    begin
        Assert.IsTrue(ContractMgt.GetContract(MessageType, Contract), StrSubstNo(WrongEffectErr, MessageType));
        Assert.IsTrue(Contract.Get('effect', EffectToken), StrSubstNo(WrongEffectErr, MessageType));
        Assert.IsTrue(EffectToken.AsObject().Get('effect', ValueToken), StrSubstNo(WrongEffectErr, MessageType));
        Assert.AreEqual(Expected, ValueToken.AsValue().AsText(), StrSubstNo(WrongEffectErr, MessageType));
    end;
}
