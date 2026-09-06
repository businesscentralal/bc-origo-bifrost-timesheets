namespace Origo.Bifrost.Timesheets;

using Origo.Bifrost;

/// <summary>
/// Extends the Bifrost Foundation <c>Bifrost Message Type</c> enum with the
/// Clockify connector message types. Each value binds the <c>Bifrost Msg
/// Interface</c> to a dedicated <c>*Impl</c> codeunit that calls the Clockify REST
/// API. Captions are <c>Locked = true</c> because Bifrost message identifiers
/// are part of the public wire contract.
/// </summary>
enumextension 10036785 "Clockify Msg Type ori" extends "Message Type ori"
{
    /// <summary>Returns a Markdown overview of the Clockify connector and all its message types.</summary>
    value(10036785; "Help.Clockify.Get")
    {
        Caption = 'Help.Clockify.Get', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify Help Get Impl ori";
    }
    /// <summary>Lists the workspaces the API key can access.</summary>
    value(10036786; "Clockify.Workspace.List")
    {
        Caption = 'Clockify.Workspace.List', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify WrkspaceList Impl ori";
    }
    /// <summary>Returns the currently authenticated Clockify user.</summary>
    value(10036787; "Clockify.User.GetCurrent")
    {
        Caption = 'Clockify.User.GetCurrent', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify User Current Impl ori";
    }
    /// <summary>Lists the users in a workspace.</summary>
    value(10036788; "Clockify.User.List")
    {
        Caption = 'Clockify.User.List', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify User List Impl ori";
    }
    /// <summary>Lists the clients in a workspace.</summary>
    value(10036789; "Clockify.Client.List")
    {
        Caption = 'Clockify.Client.List', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify Client List Impl ori";
    }
    /// <summary>Retrieves a single client by ID.</summary>
    value(10036790; "Clockify.Client.Get")
    {
        Caption = 'Clockify.Client.Get', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify Client Get Impl ori";
    }
    /// <summary>Creates a client in a workspace.</summary>
    value(10036791; "Clockify.Client.Create")
    {
        Caption = 'Clockify.Client.Create', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify ClientCreate Impl ori";
    }
    /// <summary>Updates an existing client.</summary>
    value(10036792; "Clockify.Client.Update")
    {
        Caption = 'Clockify.Client.Update', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify ClientUpdate Impl ori";
    }
    /// <summary>Deletes a client.</summary>
    value(10036793; "Clockify.Client.Delete")
    {
        Caption = 'Clockify.Client.Delete', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify ClientDelete Impl ori";
    }
    /// <summary>Lists the projects in a workspace.</summary>
    value(10036794; "Clockify.Project.List")
    {
        Caption = 'Clockify.Project.List', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify Project List Impl ori";
    }
    /// <summary>Retrieves a single project by ID.</summary>
    value(10036795; "Clockify.Project.Get")
    {
        Caption = 'Clockify.Project.Get', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify Project Get Impl ori";
    }
    /// <summary>Creates a project in a workspace.</summary>
    value(10036796; "Clockify.Project.Create")
    {
        Caption = 'Clockify.Project.Create', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify ProjCreate Impl ori";
    }
    /// <summary>Updates an existing project.</summary>
    value(10036797; "Clockify.Project.Update")
    {
        Caption = 'Clockify.Project.Update', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify ProjUpdate Impl ori";
    }
    /// <summary>Deletes a project.</summary>
    value(10036798; "Clockify.Project.Delete")
    {
        Caption = 'Clockify.Project.Delete', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify ProjDelete Impl ori";
    }
    /// <summary>Lists the tasks of a project.</summary>
    value(10036799; "Clockify.Task.List")
    {
        Caption = 'Clockify.Task.List', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify Task List Impl ori";
    }
    /// <summary>Creates a task in a project.</summary>
    value(10036800; "Clockify.Task.Create")
    {
        Caption = 'Clockify.Task.Create', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify Task Create Impl ori";
    }
    /// <summary>Updates an existing task.</summary>
    value(10036801; "Clockify.Task.Update")
    {
        Caption = 'Clockify.Task.Update', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify Task Update Impl ori";
    }
    /// <summary>Deletes a task.</summary>
    value(10036802; "Clockify.Task.Delete")
    {
        Caption = 'Clockify.Task.Delete', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify Task Delete Impl ori";
    }
    /// <summary>Lists the tags in a workspace.</summary>
    value(10036803; "Clockify.Tag.List")
    {
        Caption = 'Clockify.Tag.List', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify Tag List Impl ori";
    }
    /// <summary>Creates a tag in a workspace.</summary>
    value(10036804; "Clockify.Tag.Create")
    {
        Caption = 'Clockify.Tag.Create', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify Tag Create Impl ori";
    }
    /// <summary>Updates an existing tag.</summary>
    value(10036805; "Clockify.Tag.Update")
    {
        Caption = 'Clockify.Tag.Update', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify Tag Update Impl ori";
    }
    /// <summary>Deletes a tag.</summary>
    value(10036806; "Clockify.Tag.Delete")
    {
        Caption = 'Clockify.Tag.Delete', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify Tag Delete Impl ori";
    }
    /// <summary>Lists a user's time entries in a workspace.</summary>
    value(10036807; "Clockify.TimeEntry.List")
    {
        Caption = 'Clockify.TimeEntry.List', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify TEntryList Impl ori";
    }
    /// <summary>Retrieves a single time entry by ID.</summary>
    value(10036808; "Clockify.TimeEntry.Get")
    {
        Caption = 'Clockify.TimeEntry.Get', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify TEntryGet Impl ori";
    }
    /// <summary>Creates a time entry for a user.</summary>
    value(10036809; "Clockify.TimeEntry.Create")
    {
        Caption = 'Clockify.TimeEntry.Create', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify TEntryCreate Impl ori";
    }
    /// <summary>Updates an existing time entry.</summary>
    value(10036810; "Clockify.TimeEntry.Update")
    {
        Caption = 'Clockify.TimeEntry.Update', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify TEntryUpdate Impl ori";
    }
    /// <summary>Deletes a time entry.</summary>
    value(10036811; "Clockify.TimeEntry.Delete")
    {
        Caption = 'Clockify.TimeEntry.Delete', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify TEntryDelete Impl ori";
    }
    /// <summary>Lists the currencies defined in a workspace; returns the internal currencyId values needed when creating or updating clients.</summary>
    value(10036812; "Clockify.Currency.List")
    {
        Caption = 'Clockify.Currency.List', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify CurrencyList Impl ori";
    }
    /// <summary>Lists the user groups defined in a workspace; returns the internal user-group IDs needed for project access and assignment writes.</summary>
    value(10036813; "Clockify.UserGroup.List")
    {
        Caption = 'Clockify.UserGroup.List', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify UserGrpList Impl ori";
    }
    /// <summary>Lists the workspace-level custom field definitions; returns the customFieldId values needed when writing custom field values on time entries and projects.</summary>
    value(10036814; "Clockify.CustomField.List")
    {
        Caption = 'Clockify.CustomField.List', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify CustFldList Impl ori";
    }
    /// <summary>Syncs a Clockify time entry to a BC Job Journal Line with deduplication, update detection, and correction posting.</summary>
    value(10036815; "Clockify.TimeEntry.Sync")
    {
        Caption = 'Clockify.TimeEntry.Sync', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify TEntrySync Impl ori";
    }
    /// <summary>Syncs all of a user's finished Clockify time entries in a date range to BC Job Journal Lines in one call.</summary>
    value(10036816; "Clockify.TimeEntry.SyncRange")
    {
        Caption = 'Clockify.TimeEntry.SyncRange', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify TEntryRange Impl ori";
    }
    /// <summary>Creates upcoming weekly time sheets for every time-sheet resource (BC-side).</summary>
    value(10036817; "Clockify.TimeSheet.Create")
    {
        Caption = 'Clockify.TimeSheet.Create', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify TSheetCreate Impl ori";
    }
    /// <summary>Submits and approves open time-sheet lines up to a cut-off date (BC-side).</summary>
    value(10036818; "Clockify.TimeSheet.Approve")
    {
        Caption = 'Clockify.TimeSheet.Approve', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify TSheetApprv Impl ori";
    }
    /// <summary>Transfers approved time-sheet detail to a Job Journal batch and posts it (BC-side).</summary>
    value(10036819; "Clockify.TimeSheet.Post")
    {
        Caption = 'Clockify.TimeSheet.Post', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify TSheetPost Impl ori";
    }
    /// <summary>Archives fully posted time sheets and removes empty posted sheets (BC-side).</summary>
    value(10036820; "Clockify.TimeSheet.Archive")
    {
        Caption = 'Clockify.TimeSheet.Archive', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify TSheetArch Impl ori";
    }
    /// <summary>Syncs a Clockify time entry to the resource's open BC Time Sheet (line + detail).</summary>
    value(10036821; "Clockify.TimeEntry.SyncToTimeSheet")
    {
        Caption = 'Clockify.TimeEntry.SyncToTimeSheet', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify TSheetSync Impl ori";
    }
    /// <summary>Syncs all of a user's finished Clockify time entries in a date range to their open BC Time Sheets.</summary>
    value(10036822; "Clockify.TimeEntry.SyncRangeToTimeSheet")
    {
        Caption = 'Clockify.TimeEntry.SyncRangeToTimeSheet', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify TSheetRange Impl ori";
    }
    /// <summary>Rejects submitted time-sheet lines up to a cut-off date (BC-side).</summary>
    value(10036823; "Clockify.TimeSheet.Reject")
    {
        Caption = 'Clockify.TimeSheet.Reject', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify TSheetReject Impl ori";
    }
    /// <summary>Reopens submitted or approved time-sheet lines back to Open (BC-side).</summary>
    value(10036824; "Clockify.TimeSheet.Reopen")
    {
        Caption = 'Clockify.TimeSheet.Reopen', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify TSheetReopen Impl ori";
    }
    /// <summary>Syncs finished entries in a date range for every mapped user (time sheet or journal).</summary>
    value(10036825; "Clockify.TimeEntry.SyncAllUsers")
    {
        Caption = 'Clockify.TimeEntry.SyncAllUsers', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify SyncAllUsers Impl ori";
    }
}
