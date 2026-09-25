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
    /// (95600-95699). Safe to call repeatedly. A missing
    /// <c>ReadPermission</c> or <c>WritePermission</c> on <c>AL Test Suite</c> or
    /// <c>Test Method Line</c> logs warning <c>CLK0014</c> and skips, so install
    /// and upgrade are not rolled back. Record has no separate insert or delete
    /// probe. Upgrade calls this again; there is no product page to retry it.
    /// </summary>
    procedure SetupTestSuite()
    var
        ALTestSuite: Record "AL Test Suite";
        TestMethodLine: Record "Test Method Line";
        TestSuiteMgt: Codeunit "Test Suite Mgt.";
        SuiteName: Code[10];
        SuitePermissionSkipMsg: Label 'TIMESHEETS test suite was not rebuilt because the %1 permission on %2 is missing. Republish the test app with that permission.', Locked = true;
    begin
        // All checks happen before any write. A later missing permission must not
        // leave the suite deleted.
        if not ALTestSuite.ReadPermission() then begin
            LogSuiteSkip(SuitePermissionSkipMsg, 'Read', ALTestSuite.TableName());
            exit;
        end;
        if not ALTestSuite.WritePermission() then begin
            LogSuiteSkip(SuitePermissionSkipMsg, 'Write', ALTestSuite.TableName());
            exit;
        end;
        if not TestMethodLine.ReadPermission() then begin
            LogSuiteSkip(SuitePermissionSkipMsg, 'Read', TestMethodLine.TableName());
            exit;
        end;
        if not TestMethodLine.WritePermission() then begin
            LogSuiteSkip(SuitePermissionSkipMsg, 'Write', TestMethodLine.TableName());
            exit;
        end;

        SuiteName := 'TIMESHEETS';
        if ALTestSuite.Get(SuiteName) then
            ALTestSuite.Delete(true);

        TestSuiteMgt.CreateTestSuite(SuiteName);
        Commit();
        ALTestSuite.Get(SuiteName);
        TestSuiteMgt.SelectTestMethodsByRange(ALTestSuite, '95600..95699');
    end;

    local procedure LogSuiteSkip(SuitePermissionSkipMsg: Text; MissingPermission: Text; SkippedTable: Text)
    begin
        Session.LogMessage(
            'CLK0014',
            StrSubstNo(SuitePermissionSkipMsg, MissingPermission, SkippedTable),
            Verbosity::Warning,
            DataClassification::SystemMetadata,
            TelemetryScope::ExtensionPublisher,
            'Table', SkippedTable,
            'MissingPermission', MissingPermission);
    end;
}
