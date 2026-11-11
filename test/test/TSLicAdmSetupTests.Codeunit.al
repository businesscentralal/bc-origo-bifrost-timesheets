namespace Origo.Bifrost.Timesheets.Test;

using Origo.Bifrost;
using Origo.Bifrost.Timesheets;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;

/// <summary>
/// Issue 87 AC08. The Foundation licence-admin role opens Bifrost Setup and sees this app
/// in the registry, in English and Icelandic, without SUPER or a Timesheets business role.
/// </summary>
codeunit 95635 "TS LicAdm Setup Tests"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    [Test]
    procedure LicAdm_OpensSetup_English()
    begin
        OpenSetupAsLicAdm(1033);
    end;

    [Test]
    procedure LicAdm_OpensSetup_Icelandic()
    begin
        OpenSetupAsLicAdm(1039);
    end;

    local procedure OpenSetupAsLicAdm(LanguageId: Integer)
    var
        TempRegisteredApp: Record "Registered App ori" temporary;
        AppRegistry: Codeunit "App Registry ori";
        LowerPermissions: Codeunit "Library - Lower Permissions";
        Assert: Codeunit "Library Assert";
        Setup: TestPage "Setup ori";
        PreviousLanguage: Integer;
        AppId: Guid;
        AppNameTok: Label 'Bifrost Timesheets', Locked = true;
    begin
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        LowerPermissions.PushPermissionSetWithoutDefaults('BIFROST LicAdm ori');
        Setup.OpenView();
        Setup.Close();
        AppRegistry.GetApps(TempRegisteredApp);
        AppId := GetAppUnderTestId();
        Assert.IsFalse(IsNullGuid(AppId), 'The test app should depend on Bifrost Timesheets.');
        TempRegisteredApp.SetRange("App Id", AppId);
        Assert.AreEqual(1, TempRegisteredApp.Count(), 'Bifrost Timesheets should register once for the licence administrator.');
        Assert.IsTrue(TempRegisteredApp.FindFirst(), 'Bifrost Timesheets should register for the licence administrator.');
        Assert.AreEqual(AppNameTok, TempRegisteredApp."App Name", 'Registered app name.');
        AppRegistry.GetApps(TempRegisteredApp);
        TempRegisteredApp.SetRange("App Id", AppId);
        Assert.AreEqual(1, TempRegisteredApp.Count(), 'A second enumeration must not duplicate Bifrost Timesheets.');
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure GetAppUnderTestId(): Guid
    var
        TestAppInfo: ModuleInfo;
        Dependency: ModuleDependencyInfo;
        EmptyId: Guid;
        AppNameTok: Label 'Bifrost Timesheets', Locked = true;
    begin
        NavApp.GetCurrentModuleInfo(TestAppInfo);
        foreach Dependency in TestAppInfo.Dependencies() do
            if Dependency.Name() = AppNameTok then
                exit(Dependency.Id());
        exit(EmptyId);
    end;
}
