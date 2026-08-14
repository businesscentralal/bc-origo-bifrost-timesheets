namespace Origo.PTE.CloudEvents.Clockify;

using Origo.APP.CloudEvents;

/// <summary>
/// Implementation of the <c>Clockify.TimeEntry.List</c> message type.
/// Lists a user's time entries in a workspace. Use the <c>query</c> object for
/// Clockify filters such as <c>start</c>, <c>end</c>, <c>project</c>, <c>page</c>
/// and <c>page-size</c>.
/// </summary>
codeunit 70009235 "Clockify TimeEntry List Impl" implements "Cloud Event Msg Interface ori"
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
        exit('Lists a user''s time entries in a Clockify workspace, with optional date/project filters via the query object.');
    end;

    internal procedure GetMessageDirection(): Enum "Cloud Event Msg Direction ori"
    begin
        exit(Enum::"Cloud Event Msg Direction ori"::Outbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "CE Message Argument ori")
    var
        HelpBuilder: Codeunit "Clockify Help Builder";
    begin
        HelpBuilder.Init('Clockify.TimeEntry.List', GetDescription(), 'GET', '/workspaces/{workspaceId}/user/{userId}/time-entries');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Clockify.Workspace.List → id');
        HelpBuilder.AddParam('userId', true, 'string', 'Clockify user ID whose entries to list', 'Clockify.User.GetCurrent → id or Clockify.User.List → id');
        HelpBuilder.AddParam('query.page-size', false, 'integer', 'Results per page (default 50, max 5000)', '');
        HelpBuilder.AddParam('query.page', false, 'integer', 'Page number (1-based)', '');
        HelpBuilder.AddParam('query.start', false, 'string', 'Filter: entries starting at or after this ISO-8601 UTC timestamp', '');
        HelpBuilder.AddParam('query.end', false, 'string', 'Filter: entries ending at or before this ISO-8601 UTC timestamp', '');
        HelpBuilder.AddParam('query.project', false, 'string', 'Filter: Clockify project ID', 'Clockify.Project.List → id');
        HelpBuilder.AddParam('query.task', false, 'string', 'Filter: Clockify task ID', 'Clockify.Task.List → id');
        HelpBuilder.AddParam('query.in-progress', false, 'boolean', 'Filter: true returns running timers only (`end` = null), false returns finished entries only (`end` is set).', '');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "userId": "63...", "query": { "start": "2026-06-01T00:00:00Z", "end": "2026-06-30T23:59:59Z", "in-progress": false, "page-size": 50, "page": 1 } }');
        HelpBuilder.SetResponseNote('an array of time-entry objects (each with `id`, `start`, `end`, `duration`, `projectId`, `taskId`, `tagIds`)');
        HelpBuilder.SetAfterSuccess('No tracking action required — this is a read operation. Use `id` values for Get/Update/Delete/Sync.');
        HelpBuilder.AddError(404, 'User not found', 'Verify userId via `Clockify.User.GetCurrent` or `Clockify.User.List`');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Cloud Events Setup');
        HelpBuilder.SetNotes('- Time entries are **per-user** — you must specify whose entries to list.\' +
            '- Use `start` and `end` filters to scope to a date range (ISO-8601 UTC).\' +
                '- `query.in-progress = true` returns only running timers (`end` = null).\' +
                '- `query.in-progress = false` returns only finished entries (`end` has a value).\' +
                '- For `Clockify.TimeEntry.Sync`, prefer finished entries only (set `query.in-progress = false`).');
        HelpBuilder.SetRelated('- **Resolve userId:** `Clockify.User.GetCurrent` (API key owner) or `Clockify.User.List`\' +
            '- **Get single entry:** `Clockify.TimeEntry.Get`\' +
            '- **Sync entries to BC:** `Clockify.TimeEntry.Sync`');
        Argument.SetResponseMarkdown(HelpBuilder.Render());
    end;

    internal procedure ExecuteCloudEventTask(var Argument: Record "CE Message Argument ori")
    var
        RequestMgt: Codeunit "Clockify Request Mgt";
        RequestJson: JsonObject;
        WorkspaceId: Text;
        UserId: Text;
    begin
        Argument.AssertVersion1();
        RequestJson := Argument.GetRequestJson();
        if not RequestMgt.ResolveWorkspaceId(Argument, RequestJson, WorkspaceId) then
            exit;
        if not RequestMgt.RequireParam(Argument, RequestJson, 'userId', UserId) then
            exit;
        RequestMgt.Execute(Argument, 'GET', RequestMgt.AppendQuery(RequestJson, '/workspaces/' + WorkspaceId + '/user/' + UserId + '/time-entries'), false, '');
    end;
}
