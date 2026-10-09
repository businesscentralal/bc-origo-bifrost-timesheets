namespace Origo.Bifrost.Timesheets.Test;

using Origo.Bifrost;
using Origo.Bifrost.Timesheets;

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
        Argument: Record "Message Argument ori" temporary;
    begin
        // [SCENARIO] TC001 / AC01: the Webhook Receiver URL is write-restricted.

        // [WHEN] the generic data API checks the Webhook Receiver URL for write access
        // [THEN] it is restricted
        LibraryAssert.IsTrue(Argument.IsFieldWriteRestrictedForDataRecords(Database::"Clockify Setup ori", ClockifySetup.FieldNo("Webhook Receiver URL")), 'Webhook Receiver URL (13) should be write-restricted.');
    end;

    /// <summary>Verifies WebhookReceiverUrlNotReadRestricted through Foundation field events.</summary>
    [Test]
    procedure FieldRestrict_WebhookReceiverUrlNotReadRestricted()
    var
        ClockifySetup: Record "Clockify Setup ori";
        Argument: Record "Message Argument ori" temporary;
    begin
        // [SCENARIO] TC002 / AC02: the Webhook Receiver URL stays readable.

        // [WHEN] the generic data API checks the Webhook Receiver URL for read access
        // [THEN] it is not read-restricted
        LibraryAssert.IsFalse(Argument.IsFieldReadRestrictedForDataRecords(Database::"Clockify Setup ori", ClockifySetup.FieldNo("Webhook Receiver URL")), 'Webhook Receiver URL (13) must stay readable.');
    end;

    /// <summary>Verifies NeighbourFieldsNotRestricted through Foundation field events.</summary>
    [Test]
    procedure FieldRestrict_NeighbourFieldsNotRestricted()
    var
        ClockifySetup: Record "Clockify Setup ori";
        Argument: Record "Message Argument ori" temporary;
    begin
        // [SCENARIO] TC003 / AC03: the fields next to the receiver URL are not affected.

        // [WHEN] the generic data API checks the neighbouring fields
        // [THEN] API Version, Default Workspace and Job Jnl. Template are still writable
        LibraryAssert.IsFalse(Argument.IsFieldWriteRestrictedForDataRecords(Database::"Clockify Setup ori", ClockifySetup.FieldNo("API Version")), 'API Version (10) must stay writable.');
        LibraryAssert.IsFalse(Argument.IsFieldWriteRestrictedForDataRecords(Database::"Clockify Setup ori", ClockifySetup.FieldNo("Default Workspace")), 'Default Workspace (11) must stay writable.');
        LibraryAssert.IsFalse(Argument.IsFieldWriteRestrictedForDataRecords(Database::"Clockify Setup ori", ClockifySetup.FieldNo("Job Jnl. Template")), 'Job Jnl. Template (14) must stay writable.');
    end;

    /// <summary>Verifies TableLevelChecksStayFalse through Foundation field events.</summary>
    [Test]
    procedure FieldRestrict_TableLevelChecksStayFalse()
    var
        Argument: Record "Message Argument ori" temporary;
    begin
        // [SCENARIO] TC004 / AC04: the restriction is field-level only.

        // [WHEN] the generic data API checks the table-level access for Clockify Setup ori
        // [THEN] neither the table read nor the table write is restricted
        LibraryAssert.IsFalse(Argument.IsTableReadRestrictedForDataRecords(Database::"Clockify Setup ori"), 'Table read must stay open.');
        LibraryAssert.IsFalse(Argument.IsTableWriteRestrictedForDataRecords(Database::"Clockify Setup ori"), 'Table write must stay open.');
    end;

    /// <summary>Verifies HintForReceiverUrlEmptyForNeighbour through Foundation field events.</summary>
    [Test]
    procedure FieldRestrict_HintForReceiverUrlEmptyForNeighbour()
    var
        ClockifySetup: Record "Clockify Setup ori";
        Argument: Record "Message Argument ori" temporary;
    begin
        // [SCENARIO] TC005 / AC05: the Webhook Receiver URL carries the documented hint; a neighbour does not.

        // [WHEN] the generic data API asks for the dedicated message-type hint
        // [THEN] field 13 returns the setup-page hint and field 14 (Job Jnl. Template) returns ''
        LibraryAssert.AreEqual('the Timesheets setup page (Clockify Setup)', Argument.GetDedicatedMessageTypeHintForField(Database::"Clockify Setup ori", ClockifySetup.FieldNo("Webhook Receiver URL")), 'Webhook Receiver URL (13) hint.');
        LibraryAssert.AreEqual('', Argument.GetDedicatedMessageTypeHintForField(Database::"Clockify Setup ori", ClockifySetup.FieldNo("Job Jnl. Template")), 'Job Jnl. Template (14) must have no hint.');
    end;
}
