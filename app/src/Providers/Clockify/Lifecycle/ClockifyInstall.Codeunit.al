namespace Origo.Bifrost.Timesheets.Providers.Clockify;

using Origo.Bifrost;
using System.Upgrade;

/// <summary>
/// Install codeunit for the Bifrost Timesheets connector. Bootstraps the
/// <c>Clockify Setup</c> record (if missing) so the Clockify settings have a
/// home, and registers the initial-release upgrade tag.
/// </summary>
codeunit 10036792 "Clockify Install ori"
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
        RetenPolicy: Codeunit "Clockify Reten. Policy ori";
    begin
        RetenPolicy.AddAllowedTable();
        RetenPolicy.EnableDefaultPolicy();
    end;

    local procedure EnsureSetupRecord()
    var
        ClockifySetup: Record "Clockify Setup ori";
    begin
        if ClockifySetup.Get() then
            exit;
        ClockifySetup.Init();
        ClockifySetup.Insert();
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
        exit('Origo.Bifrost.Timesheets-Initial-20260906');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", OnGetPerCompanyUpgradeTags, '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetInitialReleaseTag());
    end;
}
