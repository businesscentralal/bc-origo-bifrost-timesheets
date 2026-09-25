namespace Origo.Bifrost.Timesheets.Test;

using System.TestTools.TestRunner;

/// <summary>
/// Registers the Bifrost Timesheets test codeunits in their own AL Test Suite so a test
/// run can select them without touching the shared DEFAULT suite of the container,
/// where several Bifröst and Cloud Events test apps are installed side by side.
/// Runs on install and on upgrade, so republishing the test app refreshes the suite.
/// </summary>
codeunit 95600 "Clockify Test Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    begin
        SetupTestSuite();
    end;

    /// <summary>
    /// Rebuilds the <c>TIMESHEETS</c> test suite from the test app's own object range
    /// (95600-95699). Safe to call repeatedly. Exits quietly when read, insert,
    /// modify or delete permission is missing on <c>AL Test Suite</c> or
    /// <c>Test Method Line</c>, so install and upgrade are not rolled back.
    /// </summary>
    procedure SetupTestSuite()
    var
        ALTestSuite: Record "AL Test Suite";
        TestMethodLine: Record "Test Method Line";
        TestSuiteMgt: Codeunit "Test Suite Mgt.";
        SuiteName: Code[10];
    begin
        // All checks happen before any write. A later missing permission must not
        // leave the suite deleted.
        if not ALTestSuite.ReadPermission() then
            exit;
        if not ALTestSuite.InsertPermission() then
            exit;
        if not ALTestSuite.WritePermission() then
            exit;
        if not ALTestSuite.DeletePermission() then
            exit;
        if not TestMethodLine.ReadPermission() then
            exit;
        if not TestMethodLine.InsertPermission() then
            exit;
        if not TestMethodLine.WritePermission() then
            exit;
        if not TestMethodLine.DeletePermission() then
            exit;

        SuiteName := 'TIMESHEETS';
        if ALTestSuite.Get(SuiteName) then
            ALTestSuite.Delete(true);

        TestSuiteMgt.CreateTestSuite(SuiteName);
        Commit();
        ALTestSuite.Get(SuiteName);
        TestSuiteMgt.SelectTestMethodsByRange(ALTestSuite, '95600..95699');
    end;
}
