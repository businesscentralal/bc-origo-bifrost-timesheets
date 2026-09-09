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
    /// (95600-95699). Safe to call repeatedly.
    /// </summary>
    procedure SetupTestSuite()
    var
        ALTestSuite: Record "AL Test Suite";
        TestSuiteMgt: Codeunit "Test Suite Mgt.";
        SuiteName: Code[10];
    begin
        SuiteName := 'TIMESHEETS';
        if ALTestSuite.Get(SuiteName) then
            ALTestSuite.Delete(true);

        TestSuiteMgt.CreateTestSuite(SuiteName);
        Commit();
        ALTestSuite.Get(SuiteName);
        TestSuiteMgt.SelectTestMethodsByRange(ALTestSuite, '95600..95699');
    end;
}
