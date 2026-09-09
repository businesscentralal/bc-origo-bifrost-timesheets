namespace Origo.Bifrost.Timesheets.Providers.Clockify;

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
    value(10036785; "Provider.Clockify.Help.Get")
    {
        Caption = 'Provider.Clockify.Help.Get', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify Help Get Impl ori";
    }
    /// <summary>Lists the workspaces the API key can access.</summary>
    value(10036786; "Provider.Clockify.Workspace.List")
    {
        Caption = 'Provider.Clockify.Workspace.List', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify WrkspaceList Impl ori";
    }
    /// <summary>Returns the currently authenticated Clockify user.</summary>
    value(10036787; "Provider.Clockify.User.GetCurrent")
    {
        Caption = 'Provider.Clockify.User.GetCurrent', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify User Current Impl ori";
    }
    /// <summary>Lists the users in a workspace.</summary>
    value(10036788; "Provider.Clockify.User.List")
    {
        Caption = 'Provider.Clockify.User.List', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify User List Impl ori";
    }
    /// <summary>Lists the clients in a workspace.</summary>
    value(10036789; "Provider.Clockify.Client.List")
    {
        Caption = 'Provider.Clockify.Client.List', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify Client List Impl ori";
    }
    /// <summary>Retrieves a single client by ID.</summary>
    value(10036790; "Provider.Clockify.Client.Get")
    {
        Caption = 'Provider.Clockify.Client.Get', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify Client Get Impl ori";
    }
    /// <summary>Creates a client in a workspace.</summary>
    value(10036791; "Provider.Clockify.Client.Create")
    {
        Caption = 'Provider.Clockify.Client.Create', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify ClientCreate Impl ori";
    }
    /// <summary>Updates an existing client.</summary>
    value(10036792; "Provider.Clockify.Client.Update")
    {
        Caption = 'Provider.Clockify.Client.Update', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify ClientUpdate Impl ori";
    }
    /// <summary>Deletes a client.</summary>
    value(10036793; "Provider.Clockify.Client.Delete")
    {
        Caption = 'Provider.Clockify.Client.Delete', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify ClientDelete Impl ori";
    }
    /// <summary>Lists the projects in a workspace.</summary>
    value(10036794; "Provider.Clockify.Project.List")
    {
        Caption = 'Provider.Clockify.Project.List', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify Project List Impl ori";
    }
    /// <summary>Retrieves a single project by ID.</summary>
    value(10036795; "Provider.Clockify.Project.Get")
    {
        Caption = 'Provider.Clockify.Project.Get', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify Project Get Impl ori";
    }
    /// <summary>Creates a project in a workspace.</summary>
    value(10036796; "Provider.Clockify.Project.Create")
    {
        Caption = 'Provider.Clockify.Project.Create', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify ProjCreate Impl ori";
    }
    /// <summary>Updates an existing project.</summary>
    value(10036797; "Provider.Clockify.Project.Update")
    {
        Caption = 'Provider.Clockify.Project.Update', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify ProjUpdate Impl ori";
    }
    /// <summary>Deletes a project.</summary>
    value(10036798; "Provider.Clockify.Project.Delete")
    {
        Caption = 'Provider.Clockify.Project.Delete', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify ProjDelete Impl ori";
    }
    /// <summary>Lists the tasks of a project.</summary>
    value(10036799; "Provider.Clockify.Task.List")
    {
        Caption = 'Provider.Clockify.Task.List', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify Task List Impl ori";
    }
    /// <summary>Creates a task in a project.</summary>
    value(10036800; "Provider.Clockify.Task.Create")
    {
        Caption = 'Provider.Clockify.Task.Create', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify Task Create Impl ori";
    }
    /// <summary>Updates an existing task.</summary>
    value(10036801; "Provider.Clockify.Task.Update")
    {
        Caption = 'Provider.Clockify.Task.Update', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify Task Update Impl ori";
    }
    /// <summary>Deletes a task.</summary>
    value(10036802; "Provider.Clockify.Task.Delete")
    {
        Caption = 'Provider.Clockify.Task.Delete', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify Task Delete Impl ori";
    }
    /// <summary>Lists the tags in a workspace.</summary>
    value(10036803; "Provider.Clockify.Tag.List")
    {
        Caption = 'Provider.Clockify.Tag.List', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify Tag List Impl ori";
    }
    /// <summary>Creates a tag in a workspace.</summary>
    value(10036804; "Provider.Clockify.Tag.Create")
    {
        Caption = 'Provider.Clockify.Tag.Create', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify Tag Create Impl ori";
    }
    /// <summary>Updates an existing tag.</summary>
    value(10036805; "Provider.Clockify.Tag.Update")
    {
        Caption = 'Provider.Clockify.Tag.Update', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify Tag Update Impl ori";
    }
    /// <summary>Deletes a tag.</summary>
    value(10036806; "Provider.Clockify.Tag.Delete")
    {
        Caption = 'Provider.Clockify.Tag.Delete', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify Tag Delete Impl ori";
    }
    /// <summary>Lists a user's time entries in a workspace.</summary>
    value(10036807; "Provider.Clockify.TimeEntry.List")
    {
        Caption = 'Provider.Clockify.TimeEntry.List', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify TEntryList Impl ori";
    }
    /// <summary>Retrieves a single time entry by ID.</summary>
    value(10036808; "Provider.Clockify.TimeEntry.Get")
    {
        Caption = 'Provider.Clockify.TimeEntry.Get', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify TEntryGet Impl ori";
    }
    /// <summary>Creates a time entry for a user.</summary>
    value(10036809; "Provider.Clockify.TimeEntry.Create")
    {
        Caption = 'Provider.Clockify.TimeEntry.Create', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify TEntryCreate Impl ori";
    }
    /// <summary>Updates an existing time entry.</summary>
    value(10036810; "Provider.Clockify.TimeEntry.Update")
    {
        Caption = 'Provider.Clockify.TimeEntry.Update', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify TEntryUpdate Impl ori";
    }
    /// <summary>Deletes a time entry.</summary>
    value(10036811; "Provider.Clockify.TimeEntry.Delete")
    {
        Caption = 'Provider.Clockify.TimeEntry.Delete', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify TEntryDelete Impl ori";
    }
    /// <summary>Lists the currencies defined in a workspace; returns the internal currencyId values needed when creating or updating clients.</summary>
    value(10036812; "Provider.Clockify.Currency.List")
    {
        Caption = 'Provider.Clockify.Currency.List', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify CurrencyList Impl ori";
    }
    /// <summary>Lists the user groups defined in a workspace; returns the internal user-group IDs needed for project access and assignment writes.</summary>
    value(10036813; "Provider.Clockify.UserGroup.List")
    {
        Caption = 'Provider.Clockify.UserGroup.List', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify UserGrpList Impl ori";
    }
    /// <summary>Lists the workspace-level custom field definitions; returns the customFieldId values needed when writing custom field values on time entries and projects.</summary>
    value(10036814; "Provider.Clockify.CustomField.List")
    {
        Caption = 'Provider.Clockify.CustomField.List', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify CustFldList Impl ori";
    }
    /// <summary>Syncs a Clockify time entry to a BC Job Journal Line with deduplication, update detection, and correction posting.</summary>
    value(10036815; "Timesheets.JobJournal.SyncFromClockify")
    {
        Caption = 'Timesheets.JobJournal.SyncFromClockify', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify TEntrySync Impl ori";
    }
    /// <summary>Syncs all of a user's finished Clockify time entries in a date range to BC Job Journal Lines in one call.</summary>
    value(10036816; "Timesheets.JobJournal.SyncRangeFromClockify")
    {
        Caption = 'Timesheets.JobJournal.SyncRangeFromClockify', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify TEntryRange Impl ori";
    }
    /// <summary>Creates upcoming weekly time sheets for every time-sheet resource (BC-side).</summary>
    value(10036817; "Timesheets.TimeSheet.Create")
    {
        Caption = 'Timesheets.TimeSheet.Create', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify TSheetCreate Impl ori";
    }
    /// <summary>Submits and approves open time-sheet lines up to a cut-off date (BC-side).</summary>
    value(10036818; "Timesheets.TimeSheet.Approve")
    {
        Caption = 'Timesheets.TimeSheet.Approve', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify TSheetApprv Impl ori";
    }
    /// <summary>Transfers approved time-sheet detail to a Job Journal batch and posts it (BC-side).</summary>
    value(10036819; "Timesheets.TimeSheet.Post")
    {
        Caption = 'Timesheets.TimeSheet.Post', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify TSheetPost Impl ori";
    }
    /// <summary>Archives fully posted time sheets and removes empty posted sheets (BC-side).</summary>
    value(10036820; "Timesheets.TimeSheet.Archive")
    {
        Caption = 'Timesheets.TimeSheet.Archive', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify TSheetArch Impl ori";
    }
    /// <summary>Syncs a Clockify time entry to the resource's open BC Time Sheet (line + detail).</summary>
    value(10036821; "Timesheets.TimeSheet.SyncFromClockify")
    {
        Caption = 'Timesheets.TimeSheet.SyncFromClockify', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify TSheetSync Impl ori";
    }
    /// <summary>Syncs all of a user's finished Clockify time entries in a date range to their open BC Time Sheets.</summary>
    value(10036822; "Timesheets.TimeSheet.SyncRangeFromClockify")
    {
        Caption = 'Timesheets.TimeSheet.SyncRangeFromClockify', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify TSheetRange Impl ori";
    }
    /// <summary>Rejects submitted time-sheet lines up to a cut-off date (BC-side).</summary>
    value(10036823; "Timesheets.TimeSheet.Reject")
    {
        Caption = 'Timesheets.TimeSheet.Reject', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify TSheetReject Impl ori";
    }
    /// <summary>Reopens submitted or approved time-sheet lines back to Open (BC-side).</summary>
    value(10036824; "Timesheets.TimeSheet.Reopen")
    {
        Caption = 'Timesheets.TimeSheet.Reopen', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify TSheetReopen Impl ori";
    }
    /// <summary>Syncs finished entries in a date range for every mapped user (time sheet or journal).</summary>
    value(10036825; "Timesheets.SyncAllUsersFromClockify")
    {
        Caption = 'Timesheets.SyncAllUsersFromClockify', Locked = true;
        Implementation = "Msg Interface ori" = "Clockify SyncAllUsers Impl ori";
    }
}
