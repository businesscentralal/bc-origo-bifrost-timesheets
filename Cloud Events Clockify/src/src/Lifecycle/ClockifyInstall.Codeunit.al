namespace Origo.PTE.CloudEvents.Clockify;

using Origo.APP.CloudEvents;
using System.Upgrade;

/// <summary>
/// Install codeunit for the Cloud Events Clockify connector. Bootstraps the
/// <c>Cloud Events Setup</c> record (if missing) so the Clockify settings have a
/// home, and registers the initial-release upgrade tag.
/// </summary>
codeunit 71409 "Clockify Install"
{
    Subtype = Install;
    Access = Internal;

    trigger OnInstallAppPerCompany()
    begin
        EnsureSetupRecord();
        SetUpgradeTags();
        SetUpRetentionPolicy();
    end;

    local procedure SetUpRetentionPolicy()
    var
        RetenPolicy: Codeunit "Clockify Reten. Policy";
    begin
        RetenPolicy.AddAllowedTable();
        RetenPolicy.EnableDefaultPolicy();
    end;

    local procedure EnsureSetupRecord()
    var
        CloudEventsSetup: Record "Cloud Events Setup ori";
    begin
        if CloudEventsSetup.Get() then
            exit;
        CloudEventsSetup.Init();
        CloudEventsSetup.Insert();
    end;

    local procedure SetUpgradeTags()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag(GetInitialReleaseTag()) then
            UpgradeTag.SetUpgradeTag(GetInitialReleaseTag());
    end;

    /// <summary>Returns the per-company upgrade tag for the initial Clockify connector release.</summary>
    internal procedure GetInitialReleaseTag(): Code[250]
    begin
        exit('Origo.PTE.CloudEvents.Clockify-Initial-20260609');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", OnGetPerCompanyUpgradeTags, '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetInitialReleaseTag());
    end;
}
