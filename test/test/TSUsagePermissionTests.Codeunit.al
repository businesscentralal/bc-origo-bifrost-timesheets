namespace Origo.Bifrost.Timesheets.Test;

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
}
