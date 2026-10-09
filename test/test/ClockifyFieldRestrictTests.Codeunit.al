namespace Origo.Bifrost.Timesheets.Test;

using Origo.Bifrost;
using Origo.Bifrost.Timesheets;
using System.TestLibraries.Utilities;

/// <summary>
/// Tests for the Data.Records field-write restriction on Clockify Setup ori's Webhook Receiver
/// URL (field 13) added by "Clockify Field Restrict ori" (timesheets#41, core#344). That URL is
/// where Clockify is told to deliver real-time time-entry webhooks, so the generic data API must
/// not let a caller point it elsewhere. Reading stays open and the neighbouring fields are
/// untouched.
/// </summary>
codeunit 95612 "Clockify Field Restrict Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryAssert: Codeunit "Library Assert";

    /// <summary>Verifies WebhookReceiverUrlWriteRestricted through Foundation field events.</summary>
    [Test]
    procedure FieldRestrict_WebhookReceiverUrlWriteRestricted()
    var
        ClockifySetup: Record "Clockify Setup ori";
    begin
        // [SCENARIO] TC001 / AC01: the Webhook Receiver URL is write-restricted.

        // [WHEN] the generic data API checks the Webhook Receiver URL for write access
        // [THEN] it is restricted
        LibraryAssert.IsTrue(IsFieldRestricted(ClockifySetup.FieldNo("Webhook Receiver URL"), 'writeRestricted'), 'Webhook Receiver URL (13) should be write-restricted.');
    end;

    /// <summary>Verifies WebhookReceiverUrlNotReadRestricted through Foundation field events.</summary>
    [Test]
    procedure FieldRestrict_WebhookReceiverUrlNotReadRestricted()
    var
        ClockifySetup: Record "Clockify Setup ori";
    begin
        // [SCENARIO] TC002 / AC02: the Webhook Receiver URL stays readable.

        // [WHEN] the generic data API checks the Webhook Receiver URL for read access
        // [THEN] it is not read-restricted
        LibraryAssert.IsFalse(IsFieldRestricted(ClockifySetup.FieldNo("Webhook Receiver URL"), 'readRestricted'), 'Webhook Receiver URL (13) must stay readable.');
    end;

    /// <summary>Verifies NeighbourFieldsNotRestricted through Foundation field events.</summary>
    [Test]
    procedure FieldRestrict_NeighbourFieldsNotRestricted()
    var
        ClockifySetup: Record "Clockify Setup ori";
    begin
        // [SCENARIO] TC003 / AC03: the fields next to the receiver URL are not affected.

        // [WHEN] the generic data API checks the neighbouring fields
        // [THEN] API Version, Default Workspace and Job Jnl. Template are still writable
        LibraryAssert.IsFalse(IsFieldRestricted(ClockifySetup.FieldNo("API Version"), 'writeRestricted'), 'API Version (10) must stay writable.');
        LibraryAssert.IsFalse(IsFieldRestricted(ClockifySetup.FieldNo("Default Workspace"), 'writeRestricted'), 'Default Workspace (11) must stay writable.');
        LibraryAssert.IsFalse(IsFieldRestricted(ClockifySetup.FieldNo("Job Jnl. Template"), 'writeRestricted'), 'Job Jnl. Template (14) must stay writable.');
    end;

    /// <summary>Verifies TableLevelChecksStayFalse through Foundation field events.</summary>
    [Test]
    procedure FieldRestrict_TableLevelChecksStayFalse()
    var
        TempArgument: Record "Message Argument ori" temporary;
    begin
        // [SCENARIO] TC004 / AC04: the restriction is field-level only.

        // [WHEN] the generic data API checks the table-level access for Clockify Setup ori
        // [THEN] neither the table read nor the table write is restricted
        LibraryAssert.IsFalse(TempArgument.IsTableReadRestrictedForDataRecords(Database::"Clockify Setup ori"), 'Table read must stay open.');
        LibraryAssert.IsFalse(TempArgument.IsTableWriteRestrictedForDataRecords(Database::"Clockify Setup ori", false), 'Table write must stay open.');
    end;

    /// <summary>Verifies HintForReceiverUrlEmptyForNeighbour through Foundation field events.</summary>
    [Test]
    procedure FieldRestrict_HintForReceiverUrlEmptyForNeighbour()
    var
        ClockifySetup: Record "Clockify Setup ori";
        TempArgument: Record "Message Argument ori" temporary;
    begin
        // [SCENARIO] TC005 / AC05: the Webhook Receiver URL carries the documented hint; a neighbour does not.

        // [WHEN] the generic data API asks for the dedicated message-type hint
        // [THEN] field 13 returns the setup-page hint and field 14 (Job Jnl. Template) returns ''
        LibraryAssert.AreEqual('the Timesheets setup page (Clockify Setup)', TempArgument.GetDedicatedMessageTypeHintForField(Database::"Clockify Setup ori", ClockifySetup.FieldNo("Webhook Receiver URL")), 'Webhook Receiver URL (13) hint.');
        LibraryAssert.AreEqual('', TempArgument.GetDedicatedMessageTypeHintForField(Database::"Clockify Setup ori", ClockifySetup.FieldNo("Job Jnl. Template")), 'Job Jnl. Template (14) must have no hint.');
    end;

    local procedure IsFieldRestricted(FieldNumber: Integer; RestrictionName: Text): Boolean
    var
        TempArgument: Record "Message Argument ori" temporary;
        MessageImplementation: Interface "Msg Interface ori";
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
        FieldJson: JsonObject;
        FieldNumbers: JsonArray;
        Fields: JsonArray;
        Token: JsonToken;
    begin
        // Help.Fields.Get uses the same field-access checks as Data.Records.Get/Set.
        // Invoke the public interface to exercise Foundation's private checks and our subscriber.
        TempArgument.Init();
        TempArgument."Type" := TempArgument."Type"::"Help.Fields.Get";
        TempArgument."Version" := TempArgument."Version"::"1.0";
        // Persist the temporary row so SetRequestJson/CalcFields retain the request BLOB.
        TempArgument.Insert();
        RequestJson.Add('tableId', Database::"Clockify Setup ori");
        FieldNumbers.Add(FieldNumber);
        RequestJson.Add('fieldNumbers', FieldNumbers);
        TempArgument.SetRequestJson(RequestJson);
        RequestJson := TempArgument.GetRequestJson();
        LibraryAssert.IsTrue(RequestJson.Get('tableId', Token), 'Stored request must retain the table selector.');
        LibraryAssert.AreEqual(Database::"Clockify Setup ori", Token.AsValue().AsInteger(), 'Stored request must target Clockify Setup.');
        LibraryAssert.IsTrue(RequestJson.Get('fieldNumbers', Token), 'Stored request must retain the field selector.');
        FieldNumbers := Token.AsArray();
        LibraryAssert.AreEqual(1, FieldNumbers.Count(), 'Stored request must select exactly one field.');
        FieldNumbers.Get(0, Token);
        LibraryAssert.AreEqual(FieldNumber, Token.AsValue().AsInteger(), 'Stored request must select the requested field.');
        MessageImplementation := TempArgument.GetMessageTypeInterface();
        MessageImplementation.ExecuteBifrostTask(TempArgument);
        ResponseJson := TempArgument.GetResponseJson();
        LibraryAssert.IsTrue(ResponseJson.Get('status', Token), 'Field metadata response must include status.');
        LibraryAssert.AreEqual('Success', Token.AsValue().AsText(), 'Field metadata request must succeed.');
        LibraryAssert.IsTrue(ResponseJson.Get('result', Token), 'Field metadata response must include result.');
        Fields := Token.AsArray();
        LibraryAssert.AreEqual(1, Fields.Count(), 'Exactly the requested field must be returned.');
        Fields.Get(0, Token);
        FieldJson := Token.AsObject();
        FieldJson.Get('id', Token);
        LibraryAssert.AreEqual(FieldNumber, Token.AsValue().AsInteger(), 'Metadata must identify the requested field.');
        LibraryAssert.IsTrue(FieldJson.Get(RestrictionName, Token), 'Field metadata must include ' + RestrictionName + '.');
        exit(Token.AsValue().AsBoolean());
    end;
}
