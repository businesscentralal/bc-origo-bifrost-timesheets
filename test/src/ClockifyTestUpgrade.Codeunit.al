namespace Origo.Bifrost.Clockify.Test;

/// <summary>
/// Refreshes the CLOCKIFY test suite when the test app is republished, so a new or
/// renamed test codeunit is picked up without uninstalling the app first.
/// </summary>
codeunit 95605 "Clockify Test Upgrade"
{
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    var
        TestInstall: Codeunit "Clockify Test Install";
    begin
        TestInstall.SetupTestSuite();
    end;
}
