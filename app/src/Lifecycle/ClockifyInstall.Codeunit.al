namespace Origo.Bifrost.Timesheets;

using Origo.Bifrost;
using System.DataAdministration;
using System.Upgrade;

/// <summary>
/// Install codeunit for the Bifrost Timesheets connector. Bootstraps the
/// <c>Clockify Setup</c> record (if missing) so the Clockify settings have a
/// home, and registers the initial-release upgrade tag.
/// Each table access is permission-checked first; a missing permission skips
/// that step quietly so the install is not rolled back.
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
        RetentionPolicySetup: Record "Retention Policy Setup";
        RetenPolicy: Codeunit "Clockify Reten. Policy ori";
    begin
        RetenPolicy.AddAllowedTable();

        // Probe outside the codeunit whose Permissions property grants RI. That
        // property only promotes an existing indirect grant; with none at all,
        // ReadPermission inside the codeunit can still look allowed and Get throws.
        if not RetentionPolicySetup.ReadPermission() then
            exit;
        if not RetentionPolicySetup.WritePermission() then
            exit;
        RetenPolicy.EnableDefaultPolicy();
    end;

    local procedure EnsureSetupRecord()
    var
        ClockifySetup: Record "Clockify Setup ori";
    begin
        if not ClockifySetup.ReadPermission() then
            exit;
        if ClockifySetup.Get() then
            exit;
        if not ClockifySetup.WritePermission() then
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
    procedure GetInitialReleaseTag(): Code[250]
    begin
        exit('Origo.Bifrost.Timesheets-Initial-20260906');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", OnGetPerCompanyUpgradeTags, '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetInitialReleaseTag());
    end;
}
