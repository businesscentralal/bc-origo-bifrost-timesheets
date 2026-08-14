namespace Origo.PTE.CloudEvents.Clockify;

/// <summary>
/// Full permission set for the Cloud Events Clockify connector. Grants execute
/// rights on every Clockify object: the integration table, the HTTP client,
/// request helper, secret, setup, workspace and retention-policy management,
/// install, the secret dialog, workspace lookup and integration list pages, and
/// all message-type implementation codeunits.
/// </summary>
permissionset 71411 "Clockify Full"
{
    Access = Public;
    Assignable = true;
    Caption = 'Clockify - Full', Comment = 'is-IS=Clockify - Full';

    Permissions =
        tabledata "Clockify Integration" = RIMD,
        tabledata "Clockify Webhook" = RIMD,
        codeunit "Clockify Secret Mgt" = X,
        codeunit "Clockify Setup Mgt" = X,
        codeunit "Clockify Webhook Mgt" = X,
        codeunit "Clockify Webhook Handler" = X,
        codeunit "Clockify Workspace Mgt" = X,
        codeunit "Clockify Reten. Policy" = X,
        codeunit "Clockify Integration Gate" = X,
        codeunit "Clockify Client" = X,
        codeunit "Clockify Request Mgt" = X,
        codeunit "Clockify Help Builder" = X,
        codeunit "Clockify Install" = X,
        codeunit "Clockify Time Entry Sync" = X,
        codeunit "Clockify Event Subscribers" = X,
        codeunit "Clockify Help Get Impl" = X,
        codeunit "Clockify Workspace List Impl" = X,
        codeunit "Clockify User Current Impl" = X,
        codeunit "Clockify User List Impl" = X,
        codeunit "Clockify Client List Impl" = X,
        codeunit "Clockify Client Get Impl" = X,
        codeunit "Clockify Client Create Impl" = X,
        codeunit "Clockify Client Update Impl" = X,
        codeunit "Clockify Client Delete Impl" = X,
        codeunit "Clockify Project List Impl" = X,
        codeunit "Clockify Project Get Impl" = X,
        codeunit "Clockify Project Create Impl" = X,
        codeunit "Clockify Project Update Impl" = X,
        codeunit "Clockify Project Delete Impl" = X,
        codeunit "Clockify Task List Impl" = X,
        codeunit "Clockify Task Create Impl" = X,
        codeunit "Clockify Task Update Impl" = X,
        codeunit "Clockify Task Delete Impl" = X,
        codeunit "Clockify Tag List Impl" = X,
        codeunit "Clockify Tag Create Impl" = X,
        codeunit "Clockify Tag Update Impl" = X,
        codeunit "Clockify Tag Delete Impl" = X,
        codeunit "Clockify TimeEntry List Impl" = X,
        codeunit "Clockify TimeEntry Get Impl" = X,
        codeunit "Clockify TimeEntry Create Impl" = X,
        codeunit "Clockify TimeEntry Update Impl" = X,
        codeunit "Clockify TimeEntry Delete Impl" = X,
        codeunit "Clockify TimeEntry Sync Impl" = X,
        codeunit "Clockify Archive Sync" = X,
        codeunit "Clockify ReqLog Masker" = X,
        page "Clockify Set Secret Dialog" = X,
        page "Clockify Workspace Lookup" = X,
        page "Clockify Integration List" = X,
        page "Clockify Webhooks" = X;
}
