namespace Origo.Bifrost.Timesheets.Test;

using Origo.Bifrost;
using Origo.Bifrost.Timesheets;
using Origo.Bifrost.Timesheets.Providers.Clockify;
using System.TestLibraries.Utilities;

/// <summary>
/// Verifies that the Bifrost Timesheets connector registers itself with Bifröst
/// Foundation's app registry, so the shared Bifröst Setup card can list the app and
/// open its setup card. Setup notifications live on Bifröst Setup only, which is why
/// the connector raises none of its own.
/// </summary>
codeunit 95606 "Timesheets Registration Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryAssert: Codeunit "Library Assert";
        AppNameTok: Label 'Bifrost Timesheets', Locked = true;

    [Test]
    procedure AppRegistersItselfWithFoundation()
    var
        TempRegisteredApp: Record "Registered App ori" temporary;
        AppRegistry: Codeunit "App Registry ori";
        AppId: Guid;
        NoAppIdErr: Label 'The test app should depend on Bifrost Timesheets.';
        NotRegisteredErr: Label 'Bifrost Timesheets should register itself in the Foundation app registry.';
    begin
        // [SCENARIO] The connector answers Foundation's OnRegisterApps with its own app id and setup page.
        Initialize();

        // [GIVEN] The app id of the Bifrost Timesheets app under test.
        AppId := GetAppUnderTestId();
        LibraryAssert.IsFalse(IsNullGuid(AppId), NoAppIdErr);

        // [WHEN] Foundation collects the registered apps.
        AppRegistry.GetApps(TempRegisteredApp);

        // [THEN] Bifrost Timesheets is present with its own setup card.
        LibraryAssert.IsTrue(TempRegisteredApp.Get(AppId), NotRegisteredErr);
        LibraryAssert.AreEqual(Page::"Timesheets Setup ori", TempRegisteredApp."Setup Page Id", 'Registered setup page should be the Timesheets setup card.');
        LibraryAssert.AreEqual(AppNameTok, TempRegisteredApp."App Name", 'Registered app name should be the app under test.');
    end;

    local procedure Initialize()
    begin
        Clear(LibraryAssert);
    end;

    local procedure GetAppUnderTestId(): Guid
    var
        TestAppInfo: ModuleInfo;
        Dependency: ModuleDependencyInfo;
        EmptyId: Guid;
    begin
        NavApp.GetCurrentModuleInfo(TestAppInfo);
        foreach Dependency in TestAppInfo.Dependencies() do
            if Dependency.Name() = AppNameTok then
                exit(Dependency.Id());
        exit(EmptyId);
    end;
}
