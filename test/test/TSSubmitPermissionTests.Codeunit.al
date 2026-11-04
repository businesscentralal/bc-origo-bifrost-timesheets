namespace Origo.Bifrost.Timesheets;

using Origo.Bifrost;
using System.TestLibraries.Utilities;

/// <summary>Submit is hidden and refused for a read-only caller before any write.</summary>
codeunit 95617 "TS Submit Permission Tests"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    [Test]
    procedure Scenario_AC07_ReadOnly_DisabledAndDenied()
    var
        TempArgument: Record "Message Argument ori" temporary;
        LowerPermissions: Codeunit "Library - Lower Permissions";
        Assert: Codeunit "Library Assert";
        Impl: Codeunit "TS Sheet Submit Impl ori";
        Response: JsonObject;
    begin
        // [GIVEN] The read role has read rights but no line write permission.
        LowerPermissions.PushPermissionSetWithoutDefaults('BIFROST Read ori');
        TempArgument.Type := "Message Type ori"::"Timesheets.TimeSheet.Submit";
        TempArgument.Version := "Message Version ori"::"1.0";
        TempArgument.ID := CreateGuid();
        TempArgument.Insert();
        // [WHEN] Discovery and execution check the actual restricted caller.
        Assert.IsFalse(Impl.IsEnabled(), 'Read-only caller must not see Submit enabled.');
        Impl.ExecuteBifrostTask(TempArgument);
        Response := TempArgument.GetResponseJson();
        // [THEN] The refusal identifies the permission set, before resolving any input.
        Assert.AreEqual('PermissionDenied', Response.GetText('code'), 'Read role must be denied.');
        Assert.AreEqual('Assign the BIFROST Timeshts ori permission set.', Response.GetText('nextStep'), 'Name the assignable feature set.');
    end;
}
