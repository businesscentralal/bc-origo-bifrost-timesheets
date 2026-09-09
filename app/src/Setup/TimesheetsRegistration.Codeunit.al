namespace Origo.Bifrost.Timesheets;

using Origo.Bifrost;

/// <summary>
/// Makes the Bifrost Timesheets connector known to Bifröst Foundation's app registry,
/// so the shared Bifröst Setup card can list the app and open its setup card. Setup
/// notifications live on Bifröst Setup only - this app raises none of its own.
/// </summary>
codeunit 10036854 "Timesheets Registration ori"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"App Registry ori", OnRegisterApps, '', false, false)]
    local procedure RegisterApp(var Apps: Record "Registered App ori" temporary)
    var
        AppRegistry: Codeunit "App Registry ori";
        AppInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(AppInfo);
        AppRegistry.AddApp(Apps, AppInfo.Id(), CopyStr(AppInfo.Name(), 1, 250), Page::"Timesheets Setup ori");
    end;
}
