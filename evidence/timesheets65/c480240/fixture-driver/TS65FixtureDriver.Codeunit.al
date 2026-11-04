namespace Origo.Bifrost.Timesheets.Test;

using Microsoft.Projects.TimeSheet;

/// <summary>Invokes the installed candidate fixture without changing the product or its write guards.</summary>
codeunit 95699 "TS65 Fixture Driver"
{
    Subtype = Test;
    TestPermissions = Disabled;

    /// <summary>Creates owned absence verification data exactly once and retains it for MCP/UI checks.</summary>
    [Test]
    procedure Scenario_AC01_EmptyOwnedKeys_SeedNativeFixture()
    var
        Header: Record "Time Sheet Header";
    begin
        // Story #65, AC01 | Time: fixture uses 2026-11-02..08 | Risk: isolated owned container only.
        // [GIVEN] No prior fixture header exists in the owned verification environment.
        if Header.Get('W2ABS65-MCP') or Header.Get('W2ABS65-MCPN') then
            Error('The owned fixture already exists. Inspect it before any recovery.');
        Commit();
        // [WHEN] Invoke the unchanged fixture from the exact candidate test app.
        Codeunit.Run(95618);
        Commit();
        // [THEN] Both isolated employee-linked and unlinked resource sheets exist.
        Header.Get('W2ABS65-MCP');
        Header.TestField("Resource No.", 'W2A65-MCP');
        Header.Get('W2ABS65-MCPN');
        Header.TestField("Resource No.", 'W2A65-MCPN');
    end;
}
