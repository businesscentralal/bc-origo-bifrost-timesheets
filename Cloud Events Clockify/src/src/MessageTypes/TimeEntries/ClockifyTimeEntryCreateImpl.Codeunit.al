namespace Origo.PTE.CloudEvents.Clockify;

using Origo.APP.CloudEvents;

/// <summary>
/// Implementation of the <c>Clockify.TimeEntry.Create</c> message type.
/// Creates a time entry for a user from the request's <c>body</c> object.
/// </summary>
codeunit 71444 "Clockify TimeEntry Create Impl" implements "Cloud Event Msg Interface ori"
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
        exit('Creates a time entry for a user in a Clockify workspace from the request body.');
    end;

    internal procedure GetMessageDirection(): Enum "Cloud Event Msg Direction ori"
    begin
        exit(Enum::"Cloud Event Msg Direction ori"::Outbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "CE Message Argument ori")
    var
        HelpBuilder: Codeunit "Clockify Help Builder";
    begin
        HelpBuilder.Init('Clockify.TimeEntry.Create', GetDescription(), 'POST', '/workspaces/{workspaceId}/user/{userId}/time-entries');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Clockify.Workspace.List → id');
        HelpBuilder.AddParam('userId', true, 'string', 'Clockify user ID (NOT the BC user name)', 'Clockify.User.GetCurrent → id or Clockify.User.List → id');
        HelpBuilder.AddParam('body.start', true, 'string', 'Start time in ISO-8601 UTC (e.g. 2026-06-09T08:00:00Z)', '');
        HelpBuilder.AddParam('body.end', false, 'string', 'End time in ISO-8601 UTC. Omit to start a running timer.', '');
        HelpBuilder.AddParam('body.description', false, 'string', 'Free-text description of the work performed', '');
        HelpBuilder.AddParam('body.projectId', false, 'string', 'Clockify project ID (NOT the BC project number)', 'Clockify.Project.List → id');
        HelpBuilder.AddParam('body.taskId', false, 'string', 'Clockify task ID', 'Clockify.Task.List → id');
        HelpBuilder.AddParam('body.tagIds', false, 'array', 'Array of Clockify tag IDs', 'Clockify.Tag.List → id');
        HelpBuilder.AddParam('body.billable', false, 'boolean', 'true = billable (overrides project default)', '');
        HelpBuilder.AddParam('body.type', false, 'string', 'REGULAR (default) or BREAK', '');
        HelpBuilder.AddParam('body.customFields', false, 'array', 'Array of { customFieldId, value }', 'Clockify.CustomField.List → id');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "userId": "63...", "body": { "start": "2026-06-09T08:00:00Z", "end": "2026-06-09T10:00:00Z", "description": "Consulting", "projectId": "60...", "taskId": "61...", "tagIds": [ "62..." ], "billable": true, "customFields": [ { "customFieldId": "64...", "value": "PO-1234" } ] } }');
        HelpBuilder.SetResponseNote('the created time-entry object (includes `id`, `start`, `end`, `duration`, `projectId`, `taskId`)');
        HelpBuilder.AddError(400, 'Overlapping time entry', 'Check existing entries for the same period via `Clockify.TimeEntry.List`');
        HelpBuilder.AddError(404, 'User or workspace not found', 'Verify userId via `Clockify.User.GetCurrent` or `Clockify.User.List`');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Cloud Events Setup');
        HelpBuilder.SetNotes('- `start` must be ISO-8601 UTC. Clockify rejects local-time strings without offset.\' +
            '- Omit `end` to start a **running timer**; send a later `Clockify.TimeEntry.Update` with `end` to stop it.\' +
            '- `projectId`, `taskId`, and `tagIds` entries are Clockify internal IDs — names are silently ignored.\' +
            '- `customFields` format: `{ "customFieldId": "...", "value": ... }`. Get IDs from `Clockify.CustomField.List`.\' +
            '- `userId` in the URL is the Clockify user ID, NOT the BC user name.');
        HelpBuilder.SetRelated('- **Resolve userId:** `Clockify.User.GetCurrent` (API key owner) or `Clockify.User.List`\' +
            '- **Resolve projectId:** `Clockify.Project.List` or Clockify Integration (type=project)\' +
            '- **Resolve taskId:** `Clockify.Task.List` (requires projectId)\' +
            '- **Resolve tagIds:** `Clockify.Tag.List`\' +
            '- **Stop running timer:** `Clockify.TimeEntry.Update` with `end` field\' +
            '- **Sync to BC:** `Clockify.TimeEntry.Sync` (posts to Job Journal)');
        Argument.SetResponseMarkdown(HelpBuilder.Render());
    end;

    internal procedure ExecuteCloudEventTask(var Argument: Record "CE Message Argument ori")
    var
        RequestMgt: Codeunit "Clockify Request Mgt";
        RequestJson: JsonObject;
        WorkspaceId: Text;
        UserId: Text;
        BodyText: Text;
    begin
        Argument.AssertVersion1();
        RequestJson := Argument.GetRequestJson();
        if not RequestMgt.ResolveWorkspaceId(Argument, RequestJson, WorkspaceId) then
            exit;
        if not RequestMgt.RequireParam(Argument, RequestJson, 'userId', UserId) then
            exit;
        if not RequestMgt.RequireBody(Argument, RequestJson, BodyText) then
            exit;
        RequestMgt.Execute(Argument, 'POST', '/workspaces/' + WorkspaceId + '/user/' + UserId + '/time-entries', true, BodyText);
    end;
}
