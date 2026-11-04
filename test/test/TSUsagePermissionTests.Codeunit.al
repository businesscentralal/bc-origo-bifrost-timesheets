namespace Origo.Bifrost.Timesheets.Test;

using Microsoft.Projects.Resources.Journal;
using Origo.Bifrost;
using Origo.Bifrost.Timesheets;
using System.TestLibraries.Utilities;

/// <summary>Verifies usage discovery and execution under actual restrictive permission sets.</summary>
codeunit 95636 "TS Usage Permission Tests"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    /// <summary>A read-only usage role can discover List but cannot discover or execute Register.</summary>
    [Test]
    procedure ReadOnlyRoleListsButCannotRegister()
    var
        TempArgument: Record "Message Argument ori" temporary;
        ListImpl: Codeunit "TS Usage List ori";
        RegisterImpl: Codeunit "TS Usage Register ori";
        LowerPermissions: Codeunit "Library - Lower Permissions";
        Assert: Codeunit "Library Assert";
        Request: JsonObject;
        Response: JsonObject;
    begin
        LowerPermissions.PushPermissionSetWithoutDefaults('TS Usage Read ori');
        Assert.IsTrue(ListImpl.IsEnabled(), 'Usage read role enables only the read query.');
        Assert.IsFalse(RegisterImpl.IsEnabled(), 'Usage read role has no usage write permission.');
        TempArgument.ID := CreateGuid();
        TempArgument.Version := TempArgument.Version::"1.0";
        TempArgument.Insert();
        TempArgument.SetRequestJson(Request);
        ListImpl.ExecuteBifrostTask(TempArgument);
        Response := TempArgument.GetResponseJson();
        Assert.AreEqual('Success', Response.GetText('status'), 'Read-only List succeeds.');
        RegisterImpl.ExecuteBifrostTask(TempArgument);
        Response := TempArgument.GetResponseJson();
        Assert.AreEqual('PermissionDenied', Response.GetText('code'), 'Register refuses before reading or writing records.');
    end;

    /// <summary>A role with no native usage reads gets a structured refusal, never a platform permission error.</summary>
    [Test]
    procedure MissingUsageReadRefusesCleanly()
    var
        TempArgument: Record "Message Argument ori" temporary;
        ListImpl: Codeunit "TS Usage List ori";
        LowerPermissions: Codeunit "Library - Lower Permissions";
        Assert: Codeunit "Library Assert";
        Request: JsonObject;
        Response: JsonObject;
    begin
        LowerPermissions.PushPermissionSetWithoutDefaults('BIFROST Read ori');
        Assert.IsFalse(ListImpl.IsEnabled(), 'Missing native reads disable discovery.');
        TempArgument.ID := CreateGuid();
        TempArgument.Version := TempArgument.Version::"1.0";
        TempArgument.Insert();
        TempArgument.SetRequestJson(Request);
        ListImpl.ExecuteBifrostTask(TempArgument);
        Response := TempArgument.GetResponseJson();
        Assert.AreEqual('PermissionDenied', Response.GetText('code'), 'Missing native reads refuse cleanly.');
    end;
    /// <summary>Usage maintenance alone cannot create a destination journal; the refusal leaves no link or journal.</summary>
    [Test]
    procedure UsageWriterWithoutJournalWriteIsRefused()
    var
        Usage: Record "TS Usage Line ori";
        Journal: Record "Res. Journal Line";
        LowerPermissions: Codeunit "Library - Lower Permissions";
        Assert: Codeunit "Library Assert";
        FixtureRequest: JsonObject;
        Request: JsonObject;
        Fixture: JsonObject;
        Response: JsonObject;
        LineToken: JsonToken;
        Nonce: Text;
        EntryNo: Integer;
    begin
        // Permissions Mock grants fixture setup only; the operation itself runs under the explicit restricted role.
        LowerPermissions.SetExactPermissionSet('SUPER');
        Nonce := CopyStr(DelChr(Format(CreateGuid(), 0, 4), '=', '{}-'), 1, 10);
        FixtureRequest.Add('action', 'seed');
        FixtureRequest.Add('nonce', Nonce);
        Fixture := Execute("Message Type ori"::"Test.UsageFixture.Manage", FixtureRequest);
        Assert.AreEqual('Success', Fixture.GetText('status'), 'Own permission fixture seeded.');
        Request.Add('timeSheetNo', Fixture.GetText('timeSheetNo'));
        Request.Add('lineNo', 10000);
        Request.Add('type', 'Resource');
        Request.Add('no', Fixture.GetText('resourceNo'));
        Request.Add('date', '2026-11-04');
        Request.Add('quantity', 1);
        Response := Execute("Message Type ori"::"Timesheets.Usage.Register", Request);
        Assert.AreEqual('Success', Response.GetText('status'), 'Own usage registered.');
        Response.Get('line', LineToken);
        EntryNo := LineToken.AsObject().GetInteger('entryNo');
        Clear(Request);
        Request.Add('entryNo', EntryNo);
        Response := Execute("Message Type ori"::"Timesheets.Usage.Submit", Request);
        Assert.AreEqual('Success', Response.GetText('status'), 'Own usage submitted.');
        FixtureRequest.Replace('action', 'handover');
        Response := Execute("Message Type ori"::"Test.UsageFixture.Manage", FixtureRequest);
        Assert.AreEqual('Success', Response.GetText('status'), 'Independent actor fixture prepared.');
        Response := Execute("Message Type ori"::"Timesheets.Usage.Approve", Request);
        Assert.AreEqual('Success', Response.GetText('status'), 'Independent approver approved fixture.');
        LowerPermissions.PushPermissionSetWithoutDefaults('TS USAGE NO JNL');
        Assert.IsTrue(Usage.WritePermission(), 'Caller really has usage write permission.');
        Assert.IsFalse(Journal.WritePermission(), 'Caller really lacks destination journal write permission.');
        Request.Add('journalTemplate', Fixture.GetText('journalTemplate'));
        Request.Add('journalBatch', Fixture.GetText('journalBatch'));
        Response := Execute("Message Type ori"::"Timesheets.Usage.Transfer", Request);
        Assert.AreEqual('PermissionDenied', Response.GetText('code'), 'Journal access is checked before insertion.');
        Assert.AreEqual('journalTemplate', Response.GetText('parameter'), 'Refusal names the destination.');
        Assert.IsTrue(Response.GetText('nextStep').Contains('permissions'), 'Refusal gives a permission correction.');
        Usage.Get(EntryNo);
        Assert.AreEqual(Usage.Status::Approved, Usage.Status, 'Refusal preserves Approved state.');
        Assert.AreEqual(0, Usage."Journal Line No.", 'Refusal leaves no journal link.');
        Journal.SetRange("Journal Template Name", Fixture.GetText('journalTemplate'));
        Journal.SetRange("Journal Batch Name", Fixture.GetText('journalBatch'));
        Assert.IsTrue(Journal.IsEmpty(), 'Refusal leaves no journal.');
        LowerPermissions.SetExactPermissionSet('SUPER');
        FixtureRequest.Replace('action', 'cleanup');
        Response := Execute("Message Type ori"::"Test.UsageFixture.Manage", FixtureRequest);
        Assert.AreEqual('Success', Response.GetText('status'), 'Own permission fixture cleaned.');
    end;

    local procedure Execute(MessageType: Enum "Message Type ori"; Request: JsonObject): JsonObject
    var
        TempArgument: Record "Message Argument ori" temporary;
        Implementation: Interface "Msg Interface ori";
    begin
        TempArgument.ID := CreateGuid();
        TempArgument.Type := MessageType;
        TempArgument.Version := TempArgument.Version::"1.0";
        TempArgument.Insert();
        TempArgument.SetRequestJson(Request);
        Implementation := TempArgument.GetMessageTypeInterface();
        Implementation.ExecuteBifrostTask(TempArgument);
        exit(TempArgument.GetResponseJson());
    end;
}
