namespace Origo.Bifrost.Timesheets;

using Origo.Bifrost;
using System.DataAdministration;
using System.Upgrade;

/// <summary>
/// Install codeunit for the Bifrost Timesheets connector. Bootstraps the
/// <c>Clockify Setup</c> record (if missing) so the Clockify settings have a
/// home, and registers the initial-release upgrade tag.
/// Each table access is permission-checked first. A missing permission logs a
/// warning and skips that step so the install is not rolled back.
/// <c>Clockify Setup.GetSetup</c> retries both steps when Timesheets Setup opens.
/// <c>AddAllowedTable</c> runs only after the Retention Policy Setup probe.
/// The allowed-table subscriber and the setup-line insert inside <c>Insert(true)</c>
/// are not probed here.
/// </summary>
codeunit 10036792 "Clockify Install ori"
{
    Subtype = Install;
    Access = Internal;

    var
        SetupPermissionSkipMsg: Label 'Clockify Setup was not created because the %1 permission is missing. The record is created when Timesheets Setup is opened by a user who has it.', Locked = true;
        RetentionPermissionSkipMsg: Label 'The default retention policy for Clockify Integration was not created because the %1 permission on Retention Policy Setup is missing. Open Timesheets Setup with that permission to retry, reinstall with an elevated identity, or create the policy in Retention Policies.', Locked = true;

    trigger OnInstallAppPerCompany()
    begin
        EnsureSetupRecord();
        SetUpgradeTags();
        EnsureRetentionPolicy();
    end;

    /// <summary>
    /// Creates the Clockify Setup record when it is missing. Skips with warning
    /// <c>CLK0012</c> when read or write permission is missing. Opening Timesheets
    /// Setup calls this again.
    /// </summary>
    procedure EnsureSetupRecord()
    var
        ClockifySetup: Record "Clockify Setup ori";
    begin
        if not ClockifySetup.ReadPermission() then begin
            LogPermissionSkip('CLK0012', ClockifySetup.TableName(), 'Read', StrSubstNo(SetupPermissionSkipMsg, 'Read'));
            exit;
        end;
        if ClockifySetup.Get() then
            exit;
        if not ClockifySetup.WritePermission() then begin
            LogPermissionSkip('CLK0012', ClockifySetup.TableName(), 'Write', StrSubstNo(SetupPermissionSkipMsg, 'Write'));
            exit;
        end;
        ClockifySetup.Init();
        if not ClockifySetup.Insert() then
            ClockifySetup.Get();
    end;

    /// <summary>
    /// Registers the allowed retention table and enables the default policy when
    /// read and write permission exist on Retention Policy Setup. The probe stays
    /// outside <c>Clockify Reten. Policy ori</c>, whose <c>Permissions</c> property
    /// only promotes an existing indirect grant. A missing permission logs warning
    /// <c>CLK0013</c> and skips. Safe to call again from Timesheets Setup.
    /// </summary>
    procedure EnsureRetentionPolicy()
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
        RetenPolicy: Codeunit "Clockify Reten. Policy ori";
    begin
        // Probe outside the codeunit whose Permissions property grants RI. That
        // property only promotes an existing indirect grant; with none at all,
        // ReadPermission inside the codeunit can still look allowed and Get throws.
        if not RetentionPolicySetup.ReadPermission() then begin
            LogPermissionSkip('CLK0013', RetentionPolicySetup.TableName(), 'Read', StrSubstNo(RetentionPermissionSkipMsg, 'Read'));
            exit;
        end;
        if not RetentionPolicySetup.WritePermission() then begin
            LogPermissionSkip('CLK0013', RetentionPolicySetup.TableName(), 'Write', StrSubstNo(RetentionPermissionSkipMsg, 'Write'));
            exit;
        end;

        RetenPolicy.AddAllowedTable();
        RetenPolicy.EnableDefaultPolicy();
    end;

    local procedure LogPermissionSkip(EventId: Text; SkippedTable: Text; MissingPermission: Text; Message: Text)
    begin
        Session.LogMessage(
            EventId,
            Message,
            Verbosity::Warning,
            DataClassification::SystemMetadata,
            TelemetryScope::ExtensionPublisher,
            'Table', SkippedTable,
            'MissingPermission', MissingPermission);
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
