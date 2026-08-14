namespace Origo.PTE.CloudEvents.Clockify;

using Origo.APP.CloudEvents;

/// <summary>
/// Implementation of the <c>Clockify.TimeEntry.Update</c> message type.
/// Updates an existing time entry from the request's <c>body</c> object.
/// </summary>
codeunit 70009237 "Clockify TimeEntry Update Impl" implements "Cloud Event Msg Interface ori"
{
    Access = Internal;

    internal procedure IsEnabled(): Boolean
    var
        ClockifyIntegration: Record "Clockify Integration";
        SecretMgt: Codeunit "Clockify Secret Mgt";
    begin
        if not ClockifyIntegration.WritePermission() then
            exit(false);
        exit(SecretMgt.HasCompanyApiKey());
    end;

    internal procedure GetFilterTableNo(): Integer
    begin
        exit(0);
    end;

    internal procedure GetDescription(): Text[250]
    begin
        exit('Updates an existing Clockify time entry from the request body.');
    end;

    internal procedure GetMessageDirection(): Enum "Cloud Event Msg Direction ori"
    begin
        exit(Enum::"Cloud Event Msg Direction ori"::Outbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "CE Message Argument ori")
    var
        HelpBuilder: Codeunit "Clockify Help Builder";
    begin
        HelpBuilder.Init('Clockify.TimeEntry.Update', GetDescription(), 'PUT', '/workspaces/{workspaceId}/time-entries/{timeEntryId}');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Clockify.Workspace.List → id');
        HelpBuilder.AddParam('timeEntryId', true, 'string', 'The time entry ID to update', 'Clockify.TimeEntry.List → id');
        HelpBuilder.AddParam('body.start', false, 'string', 'Start time (ISO-8601 UTC)', '');
        HelpBuilder.AddParam('body.end', false, 'string', 'End time (ISO-8601 UTC). Setting this on an open entry **stops the timer**.', '');
        HelpBuilder.AddParam('body.description', false, 'string', 'Free-text description', '');
        HelpBuilder.AddParam('body.projectId', false, 'string', 'Clockify project ID', 'Clockify.Project.List → id');
        HelpBuilder.AddParam('body.taskId', false, 'string', 'Clockify task ID', 'Clockify.Task.List → id');
        HelpBuilder.AddParam('body.tagIds', false, 'array', 'Array of tag IDs. **Empty array clears all tags**; omit to keep current.', 'Clockify.Tag.List → id');
        HelpBuilder.AddParam('body.billable', false, 'boolean', 'Override billable status', '');
        HelpBuilder.AddParam('body.customFields', false, 'array', 'Array of { customFieldId, value }', 'Clockify.CustomField.List → id');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "timeEntryId": "64...", "body": { "start": "2026-06-09T08:00:00Z", "end": "2026-06-09T11:00:00Z", "description": "Consulting (revised)", "billable": true, "customFields": [ { "customFieldId": "65...", "value": "PO-1234" } ] } }');
        HelpBuilder.SetResponseNote('the updated time-entry object');
        HelpBuilder.AddError(400, 'Overlapping time entry', 'Adjust start/end to avoid overlap with existing entries');
        HelpBuilder.AddError(404, 'Time entry not found', 'Verify timeEntryId via `Clockify.TimeEntry.List`');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Cloud Events Setup');
        HelpBuilder.SetNotes('- Setting `end` on an entry with no end **stops the running timer**.\' +
            '- `tagIds: []` (empty array) **clears all tags**; omitting `tagIds` entirely leaves existing tags unchanged.\' +
            '- Send only fields you want to change; omitted fields retain current values.\' +
            '- `customFields` format: `{ "customFieldId": "...", "value": ... }`. Get IDs from `Clockify.CustomField.List`.');
        HelpBuilder.SetRelated('- **Stop running timer:** Send `{ "end": "<ISO-8601 UTC>" }`\' +
            '- **Delete instead:** `Clockify.TimeEntry.Delete`\' +
            '- **Sync updated entry to BC:** `Clockify.TimeEntry.Sync`');
        Argument.SetResponseMarkdown(HelpBuilder.Render());
    end;

    internal procedure ExecuteCloudEventTask(var Argument: Record "CE Message Argument ori")
    var
        RequestMgt: Codeunit "Clockify Request Mgt";
        RequestJson: JsonObject;
        WorkspaceId: Text;
        TimeEntryId: Text;
        BodyText: Text;
    begin
        Argument.AssertVersion1();
        RequestJson := Argument.GetRequestJson();
        if not RequestMgt.ResolveWorkspaceId(Argument, RequestJson, WorkspaceId) then
            exit;
        if not RequestMgt.RequireParam(Argument, RequestJson, 'timeEntryId', TimeEntryId) then
            exit;
        if not RequestMgt.RequireBody(Argument, RequestJson, BodyText) then
            exit;
        RequestMgt.Execute(Argument, 'PUT', '/workspaces/' + WorkspaceId + '/time-entries/' + TimeEntryId, true, BodyText);
    end;
}
