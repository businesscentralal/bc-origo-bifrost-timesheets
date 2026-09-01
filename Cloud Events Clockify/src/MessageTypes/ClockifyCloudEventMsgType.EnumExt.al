namespace Origo.PTE.CloudEvents.Clockify;

using Origo.APP.CloudEvents;

/// <summary>
/// Extends the Cloud Events Base <c>Cloud Event Message Type</c> enum with the
/// Clockify connector message types. Each value binds the <c>Cloud Event Msg
/// Interface</c> to a dedicated <c>*Impl</c> codeunit that calls the Clockify REST
/// API. Captions are <c>Locked = true</c> because Cloud Events message identifiers
/// are part of the public wire contract.
/// </summary>
enumextension 70009200 "Clockify Cloud Event Msg Type" extends "Cloud Event Message Type ori"
{
    /// <summary>Returns a Markdown overview of the Clockify connector and all its message types.</summary>
    value(70009200; "Help.Clockify.Get")
    {
        Caption = 'Help.Clockify.Get', Locked = true;
        Implementation = "Cloud Event Msg Interface ori" = "Clockify Help Get Impl";
    }
    /// <summary>Lists the workspaces the API key can access.</summary>
    value(70009201; "Clockify.Workspace.List")
    {
        Caption = 'Clockify.Workspace.List', Locked = true;
        Implementation = "Cloud Event Msg Interface ori" = "Clockify Workspace List Impl";
    }
    /// <summary>Returns the currently authenticated Clockify user.</summary>
    value(70009202; "Clockify.User.GetCurrent")
    {
        Caption = 'Clockify.User.GetCurrent', Locked = true;
        Implementation = "Cloud Event Msg Interface ori" = "Clockify User Current Impl";
    }
    /// <summary>Lists the users in a workspace.</summary>
    value(70009203; "Clockify.User.List")
    {
        Caption = 'Clockify.User.List', Locked = true;
        Implementation = "Cloud Event Msg Interface ori" = "Clockify User List Impl";
    }
    /// <summary>Lists the clients in a workspace.</summary>
    value(70009204; "Clockify.Client.List")
    {
        Caption = 'Clockify.Client.List', Locked = true;
        Implementation = "Cloud Event Msg Interface ori" = "Clockify Client List Impl";
    }
    /// <summary>Retrieves a single client by ID.</summary>
    value(70009205; "Clockify.Client.Get")
    {
        Caption = 'Clockify.Client.Get', Locked = true;
        Implementation = "Cloud Event Msg Interface ori" = "Clockify Client Get Impl";
    }
    /// <summary>Creates a client in a workspace.</summary>
    value(70009206; "Clockify.Client.Create")
    {
        Caption = 'Clockify.Client.Create', Locked = true;
        Implementation = "Cloud Event Msg Interface ori" = "Clockify Client Create Impl";
    }
    /// <summary>Updates an existing client.</summary>
    value(70009207; "Clockify.Client.Update")
    {
        Caption = 'Clockify.Client.Update', Locked = true;
        Implementation = "Cloud Event Msg Interface ori" = "Clockify Client Update Impl";
    }
    /// <summary>Deletes a client.</summary>
    value(70009208; "Clockify.Client.Delete")
    {
        Caption = 'Clockify.Client.Delete', Locked = true;
        Implementation = "Cloud Event Msg Interface ori" = "Clockify Client Delete Impl";
    }
    /// <summary>Lists the projects in a workspace.</summary>
    value(70009209; "Clockify.Project.List")
    {
        Caption = 'Clockify.Project.List', Locked = true;
        Implementation = "Cloud Event Msg Interface ori" = "Clockify Project List Impl";
    }
    /// <summary>Retrieves a single project by ID.</summary>
    value(70009210; "Clockify.Project.Get")
    {
        Caption = 'Clockify.Project.Get', Locked = true;
        Implementation = "Cloud Event Msg Interface ori" = "Clockify Project Get Impl";
    }
    /// <summary>Creates a project in a workspace.</summary>
    value(70009211; "Clockify.Project.Create")
    {
        Caption = 'Clockify.Project.Create', Locked = true;
        Implementation = "Cloud Event Msg Interface ori" = "Clockify Project Create Impl";
    }
    /// <summary>Updates an existing project.</summary>
    value(70009212; "Clockify.Project.Update")
    {
        Caption = 'Clockify.Project.Update', Locked = true;
        Implementation = "Cloud Event Msg Interface ori" = "Clockify Project Update Impl";
    }
    /// <summary>Deletes a project.</summary>
    value(70009213; "Clockify.Project.Delete")
    {
        Caption = 'Clockify.Project.Delete', Locked = true;
        Implementation = "Cloud Event Msg Interface ori" = "Clockify Project Delete Impl";
    }
    /// <summary>Lists the tasks of a project.</summary>
    value(70009214; "Clockify.Task.List")
    {
        Caption = 'Clockify.Task.List', Locked = true;
        Implementation = "Cloud Event Msg Interface ori" = "Clockify Task List Impl";
    }
    /// <summary>Creates a task in a project.</summary>
    value(70009215; "Clockify.Task.Create")
    {
        Caption = 'Clockify.Task.Create', Locked = true;
        Implementation = "Cloud Event Msg Interface ori" = "Clockify Task Create Impl";
    }
    /// <summary>Updates an existing task.</summary>
    value(70009216; "Clockify.Task.Update")
    {
        Caption = 'Clockify.Task.Update', Locked = true;
        Implementation = "Cloud Event Msg Interface ori" = "Clockify Task Update Impl";
    }
    /// <summary>Deletes a task.</summary>
    value(70009217; "Clockify.Task.Delete")
    {
        Caption = 'Clockify.Task.Delete', Locked = true;
        Implementation = "Cloud Event Msg Interface ori" = "Clockify Task Delete Impl";
    }
    /// <summary>Lists the tags in a workspace.</summary>
    value(70009218; "Clockify.Tag.List")
    {
        Caption = 'Clockify.Tag.List', Locked = true;
        Implementation = "Cloud Event Msg Interface ori" = "Clockify Tag List Impl";
    }
    /// <summary>Creates a tag in a workspace.</summary>
    value(70009219; "Clockify.Tag.Create")
    {
        Caption = 'Clockify.Tag.Create', Locked = true;
        Implementation = "Cloud Event Msg Interface ori" = "Clockify Tag Create Impl";
    }
    /// <summary>Updates an existing tag.</summary>
    value(70009220; "Clockify.Tag.Update")
    {
        Caption = 'Clockify.Tag.Update', Locked = true;
        Implementation = "Cloud Event Msg Interface ori" = "Clockify Tag Update Impl";
    }
    /// <summary>Deletes a tag.</summary>
    value(70009221; "Clockify.Tag.Delete")
    {
        Caption = 'Clockify.Tag.Delete', Locked = true;
        Implementation = "Cloud Event Msg Interface ori" = "Clockify Tag Delete Impl";
    }
    /// <summary>Lists a user's time entries in a workspace.</summary>
    value(70009222; "Clockify.TimeEntry.List")
    {
        Caption = 'Clockify.TimeEntry.List', Locked = true;
        Implementation = "Cloud Event Msg Interface ori" = "Clockify TimeEntry List Impl";
    }
    /// <summary>Retrieves a single time entry by ID.</summary>
    value(70009223; "Clockify.TimeEntry.Get")
    {
        Caption = 'Clockify.TimeEntry.Get', Locked = true;
        Implementation = "Cloud Event Msg Interface ori" = "Clockify TimeEntry Get Impl";
    }
    /// <summary>Creates a time entry for a user.</summary>
    value(70009224; "Clockify.TimeEntry.Create")
    {
        Caption = 'Clockify.TimeEntry.Create', Locked = true;
        Implementation = "Cloud Event Msg Interface ori" = "Clockify TimeEntry Create Impl";
    }
    /// <summary>Updates an existing time entry.</summary>
    value(70009225; "Clockify.TimeEntry.Update")
    {
        Caption = 'Clockify.TimeEntry.Update', Locked = true;
        Implementation = "Cloud Event Msg Interface ori" = "Clockify TimeEntry Update Impl";
    }
    /// <summary>Deletes a time entry.</summary>
    value(70009226; "Clockify.TimeEntry.Delete")
    {
        Caption = 'Clockify.TimeEntry.Delete', Locked = true;
        Implementation = "Cloud Event Msg Interface ori" = "Clockify TimeEntry Delete Impl";
    }
    /// <summary>Lists the currencies defined in a workspace; returns the internal currencyId values needed when creating or updating clients.</summary>
    value(70009227; "Clockify.Currency.List")
    {
        Caption = 'Clockify.Currency.List', Locked = true;
        Implementation = "Cloud Event Msg Interface ori" = "Clockify Currency List Impl";
    }
    /// <summary>Lists the user groups defined in a workspace; returns the internal user-group IDs needed for project access and assignment writes.</summary>
    value(70009228; "Clockify.UserGroup.List")
    {
        Caption = 'Clockify.UserGroup.List', Locked = true;
        Implementation = "Cloud Event Msg Interface ori" = "Clockify UserGroup List Impl";
    }
    /// <summary>Lists the workspace-level custom field definitions; returns the customFieldId values needed when writing custom field values on time entries and projects.</summary>
    value(70009229; "Clockify.CustomField.List")
    {
        Caption = 'Clockify.CustomField.List', Locked = true;
        Implementation = "Cloud Event Msg Interface ori" = "Clockify CustomField List Impl";
    }
    /// <summary>Syncs a Clockify time entry to a BC Job Journal Line with deduplication, update detection, and correction posting.</summary>
    value(70009230; "Clockify.TimeEntry.Sync")
    {
        Caption = 'Clockify.TimeEntry.Sync', Locked = true;
        Implementation = "Cloud Event Msg Interface ori" = "Clockify TimeEntry Sync Impl";
    }
    /// <summary>Syncs all of a user's finished Clockify time entries in a date range to BC Job Journal Lines in one call.</summary>
    value(70009231; "Clockify.TimeEntry.SyncRange")
    {
        Caption = 'Clockify.TimeEntry.SyncRange', Locked = true;
        Implementation = "Cloud Event Msg Interface ori" = "Clockify TimeEntrySyncRng Impl";
    }
}
