namespace Origo.Bifrost.Timesheets.Test;

using Microsoft.Projects.Project.Job;
using Microsoft.Projects.TimeSheet;
using Origo.Bifrost;
using Origo.Bifrost.Timesheets;
using System.Environment.Configuration;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;

/// <summary>
/// Issue 70 and 87. The Foundation licence-admin role opens Bifrost Setup and sees this app
/// in the registry, in English and Icelandic, without SUPER or a Timesheets business role.
/// Enumeration must not change connector setup, credentials, HTTP allow flags, time sheets or jobs,
/// and Submit stays refused for that role.
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
        ClockifySetup: Record "Clockify Setup ori";
        Job: Record Job;
        TimeSheetHeader: Record "Time Sheet Header";
        NavAppSetting: Record "NAV App Setting";
        TempArgument: Record "Message Argument ori" temporary;
        TempRegisteredApp: Record "Registered App ori" temporary;
        AppRegistry: Codeunit "App Registry ori";
        SecretMgt: Codeunit "Clockify Secret Mgt ori";
        SubmitImpl: Codeunit "TS Sheet Submit Impl ori";
        LowerPermissions: Codeunit "Library - Lower Permissions";
        Assert: Codeunit "Library Assert";
        Setup: TestPage "Setup ori";
        Response: JsonObject;
        PreviousLanguage: Integer;
        AppId: Guid;
        SheetCount: Integer;
        JobCount: Integer;
        SetupCount: Integer;
        HttpAllowCount: Integer;
        ApiKeyStored: Boolean;
        WebhookUrl: Text;
        WorkspaceId: Text;
        AppNameTok: Label 'Bifrost Timesheets', Locked = true;
    begin
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        LowerPermissions.SetExactPermissionSet('SUPER');
        SheetCount := TimeSheetHeader.Count();
        JobCount := Job.Count();
        SetupCount := ClockifySetup.Count();
        if ClockifySetup.FindFirst() then begin
            WebhookUrl := ClockifySetup."Webhook Receiver URL";
            WorkspaceId := ClockifySetup."Default Workspace";
        end;
        ApiKeyStored := SecretMgt.HasCompanyApiKey();
        HttpAllowCount := CountHttpAllowed(NavAppSetting);

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

        Assert.IsFalse(SubmitImpl.IsEnabled(), 'A licence administrator must not run Timesheets.TimeSheet.Submit.');
        TempArgument.Init();
        TempArgument.ID := CreateGuid();
        TempArgument.Type := "Message Type ori"::"Timesheets.TimeSheet.Submit";
        TempArgument.Version := "Message Version ori"::"1.0";
        TempArgument.Insert();
        SubmitImpl.ExecuteBifrostTask(TempArgument);
        Response := TempArgument.GetResponseJson();
        Assert.AreEqual('PermissionDenied', Response.GetText('code'), 'Submit must stay refused for the licence administrator.');

        LowerPermissions.SetExactPermissionSet('SUPER');
        Assert.AreEqual(SheetCount, TimeSheetHeader.Count(), 'Registry enumeration must not change time sheets.');
        Assert.AreEqual(JobCount, Job.Count(), 'Registry enumeration must not change jobs.');
        Assert.AreEqual(SetupCount, ClockifySetup.Count(), 'Registry enumeration must not change Clockify setup rows.');
        if ClockifySetup.FindFirst() then begin
            Assert.AreEqual(WebhookUrl, ClockifySetup."Webhook Receiver URL", 'Registry enumeration must not change the webhook URL.');
            Assert.AreEqual(WorkspaceId, ClockifySetup."Default Workspace", 'Registry enumeration must not change the workspace.');
        end;
        Assert.AreEqual(ApiKeyStored, SecretMgt.HasCompanyApiKey(), 'Registry enumeration must not change the stored API key.');
        Assert.AreEqual(HttpAllowCount, CountHttpAllowed(NavAppSetting), 'Registry enumeration must not change HTTP allow flags.');
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure CountHttpAllowed(var NavAppSetting: Record "NAV App Setting"): Integer
    var
        Enabled: Integer;
    begin
        if NavAppSetting.FindSet() then
            repeat
                if NavAppSetting."Allow HttpClient Requests" then
                    Enabled += 1;
            until NavAppSetting.Next() = 0;
        exit(Enabled);
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
