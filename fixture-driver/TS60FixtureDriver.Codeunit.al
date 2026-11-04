namespace Origo.Bifrost.Timesheets.Test;

using Microsoft.Projects.TimeSheet;
using Origo.Bifrost.Timesheets;

/// <summary>Calls the candidate Submit fixture page in an individually owned verification environment.</summary>
codeunit 95699 "TS60 Fixture Driver"
{
    Subtype = Test;
    TestPermissions = Disabled;

    /// <summary>Seeds exactly the four named owned sheets for later real MCP and UI calls.</summary>
    [Test]
    procedure Scenario_AC01_EmptyOwnedKeys_SeedSubmitFixture()
    var
        Header: Record "Time Sheet Header";
        Fixture: TestPage "TS Submit Fixtures";
    begin
        // [GIVEN] No previous owned sheet is present. Never replay a successful seed.
        if Header.Get('XSINDRI60-OK') or Header.Get('XSINDRI60-BAD') or
           Header.Get('XSINDRI60-OWNER') or Header.Get('XSINDRI60-EMPTY') then
            Error('Owned sheets already exist. Inspect before recovery.');
        Commit();
        // [WHEN] The existing exact-candidate fixture action creates all its own records.
        Fixture.OpenView();
        Fixture.CreateOwnedFixtures.Invoke();
        Fixture.Close();
        Commit();
        // [THEN] All four sheets belong to the exact isolated resource.
        Header.Get('XSINDRI60-OK');
        Header.TestField("Resource No.", 'XSINDRI60');
        Header.Get('XSINDRI60-BAD');
        Header.TestField("Resource No.", 'XSINDRI60');
        Header.Get('XSINDRI60-OWNER');
        Header.TestField("Resource No.", 'XSINDRI60');
        Header.Get('XSINDRI60-EMPTY');
        Header.TestField("Resource No.", 'XSINDRI60');
    end;
}
