namespace Origo.Bifrost.Timesheets;

using Origo.Bifrost;

/// <summary>
/// Builds the Markdown help documents for the Clockify task message types,
/// keeping the help text out of the individual <c>*Impl ori</c> codeunits. Every
/// implementation of the domain calls <see cref="GetHelp"/> from
/// <c>GetMessageHelpAsMarkdownDocument</c>, so <c>Help.Implementation.Get</c> still
/// answers per message type.
/// </summary>
codeunit 10036850 "Clockify Task Help ori"
{
    Access = Internal;

    /// <summary>Returns the Markdown help document for one message type of this domain.</summary>
    /// <param name="MessageType">The message type to document.</param>
    /// <param name="Description">The message type description shown in the help header.</param>
    /// <returns>The rendered Markdown document, or an empty string for a message type this codeunit does not own.</returns>
    procedure GetHelp(MessageType: Enum "Message Type ori"; Description: Text): Text
    begin
        case MessageType of
            MessageType::"Clockify.Task.List":
                exit(GetTaskListHelp(Description));
            MessageType::"Clockify.Task.Create":
                exit(GetTaskCreateHelp(Description));
            MessageType::"Clockify.Task.Update":
                exit(GetTaskUpdateHelp(Description));
            MessageType::"Clockify.Task.Delete":
                exit(GetTaskDeleteHelp(Description));
        end;
        exit('');
    end;

    /// <summary>Returns the help document for <c>Clockify.Task.List</c>.</summary>
    /// <param name="Description">The message type description shown in the help header.</param>
    local procedure GetTaskListHelp(Description: Text): Text
    var
        HelpBuilder: Codeunit "Clockify Help Builder ori";
    begin
        HelpBuilder.Init('Clockify.Task.List', Description, 'GET', '/workspaces/{workspaceId}/projects/{projectId}/tasks');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Clockify.Workspace.List → id');
        HelpBuilder.AddParam('projectId', true, 'string', 'Parent project ID', 'Clockify.Project.List → id');
        HelpBuilder.AddParam('query.page-size', false, 'integer', 'Results per page (default 50, max 5000)', '');
        HelpBuilder.AddParam('query.page', false, 'integer', 'Page number (1-based)', '');
        HelpBuilder.AddParam('query.is-active', false, 'boolean', 'Filter: true=active only, false=done only', '');
        HelpBuilder.AddParam('query.name', false, 'string', 'Filter: partial name match', '');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "projectId": "60...", "query": { "page-size": 50, "page": 1 } }');
        HelpBuilder.SetResponseNote('an array of task objects (each with `id`, `name`, `projectId`, `status`)');
        HelpBuilder.SetAfterSuccess('No tracking action required — this is a read operation. Use returned `id` values for time-entry or update calls.');
        HelpBuilder.AddError(404, 'Project not found', 'Verify projectId via `Clockify.Project.List`');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Clockify Setup');
        HelpBuilder.SetRelated('- **Create task:** `Clockify.Task.Create`\' +
            '- **Use in time entries:** Pass task `id` as `taskId` in `Clockify.TimeEntry.Create`\' +
            '- **Update task:** `Clockify.Task.Update`');
        exit(HelpBuilder.Render());
    end;

    /// <summary>Returns the help document for <c>Clockify.Task.Create</c>.</summary>
    /// <param name="Description">The message type description shown in the help header.</param>
    local procedure GetTaskCreateHelp(Description: Text): Text
    var
        HelpBuilder: Codeunit "Clockify Help Builder ori";
    begin
        HelpBuilder.Init('Clockify.Task.Create', Description, 'POST', '/workspaces/{workspaceId}/projects/{projectId}/tasks');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Clockify.Workspace.List → id');
        HelpBuilder.AddParam('projectId', true, 'string', 'Parent project ID (tasks belong to a project)', 'Clockify.Project.List → id');
        HelpBuilder.AddParam('body.name', true, 'string', 'Task display name (must be unique within the project)', '');
        HelpBuilder.AddParam('body.status', false, 'string', 'ACTIVE (default) or DONE', '');
        HelpBuilder.AddParam('body.assigneeIds', false, 'array', 'Array of user IDs to assign', 'Clockify.User.List → id');
        HelpBuilder.AddParam('body.billable', false, 'boolean', 'Override project billable default', '');
        HelpBuilder.AddParam('body.hourlyRate', false, 'object', '{ "amount": <cents>, "currency": "USD" }', '');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "projectId": "60...", "body": { "name": "Design" } }');
        HelpBuilder.SetResponseNote('the created task object (includes `id`, `name`, `projectId`, `status`)');
        HelpBuilder.AddError(400, 'Task name already exists in project', 'Choose a different name or find existing via `Clockify.Task.List`');
        HelpBuilder.AddError(404, 'Project not found', 'Verify projectId via `Clockify.Project.List`');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Clockify Setup');
        HelpBuilder.SetNotes('- Tasks are scoped to a project — you always need both workspaceId and projectId.\' +
            '- Task names must be unique within a project but can repeat across projects.');
        HelpBuilder.SetRelated('- **Resolve projectId:** `Clockify.Project.List` or Clockify Integration (type=PROJECT)\' +
            '- **List existing tasks:** `Clockify.Task.List`\' +
            '- **Use in time entries:** Pass task `id` as `taskId` in `Clockify.TimeEntry.Create`');
        exit(HelpBuilder.Render());
    end;

    /// <summary>Returns the help document for <c>Clockify.Task.Update</c>.</summary>
    /// <param name="Description">The message type description shown in the help header.</param>
    local procedure GetTaskUpdateHelp(Description: Text): Text
    var
        HelpBuilder: Codeunit "Clockify Help Builder ori";
    begin
        HelpBuilder.Init('Clockify.Task.Update', Description, 'PUT', '/workspaces/{workspaceId}/projects/{projectId}/tasks/{taskId}');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Clockify.Workspace.List → id');
        HelpBuilder.AddParam('projectId', true, 'string', 'Parent project ID', 'Clockify.Project.List → id');
        HelpBuilder.AddParam('taskId', true, 'string', 'The task ID to update', 'Clockify.Task.List → id');
        HelpBuilder.AddParam('body.name', false, 'string', 'Task display name', '');
        HelpBuilder.AddParam('body.status', false, 'string', 'ACTIVE or DONE', '');
        HelpBuilder.AddParam('body.assigneeIds', false, 'array', 'Array of user IDs', 'Clockify.User.List → id');
        HelpBuilder.AddParam('body.billable', false, 'boolean', 'Override project billable default', '');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "projectId": "60...", "taskId": "61...", "body": { "name": "Design v2", "status": "ACTIVE" } }');
        HelpBuilder.SetResponseNote('the updated task object');
        HelpBuilder.AddError(400, 'Task name already exists in project', 'Choose a different name');
        HelpBuilder.AddError(404, 'Task or project not found', 'Verify IDs via `Clockify.Task.List`');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Clockify Setup');
        HelpBuilder.SetNotes('- Send only fields you want to change; omitted fields retain current values.\' +
            '- To mark a task complete, set `status` to `DONE`.');
        HelpBuilder.SetRelated('- **Resolve taskId:** `Clockify.Task.List` or Clockify Integration (type=TASK)\' +
            '- **Delete task:** `Clockify.Task.Delete` (no archive step needed for tasks)');
        exit(HelpBuilder.Render());
    end;

    /// <summary>Returns the help document for <c>Clockify.Task.Delete</c>.</summary>
    /// <param name="Description">The message type description shown in the help header.</param>
    local procedure GetTaskDeleteHelp(Description: Text): Text
    var
        HelpBuilder: Codeunit "Clockify Help Builder ori";
    begin
        HelpBuilder.Init('Clockify.Task.Delete', Description, 'DELETE', '/workspaces/{workspaceId}/projects/{projectId}/tasks/{taskId}');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Clockify.Workspace.List → id');
        HelpBuilder.AddParam('projectId', true, 'string', 'Parent project ID', 'Clockify.Project.List → id');
        HelpBuilder.AddParam('taskId', true, 'string', 'The task ID to delete', 'Clockify.Task.List → id');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "projectId": "60...", "taskId": "61..." }');
        HelpBuilder.SetResponseNote('the deleted task object');
        HelpBuilder.AddError(404, 'Task or project not found', 'Verify IDs via `Clockify.Task.List`');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Clockify Setup');
        HelpBuilder.SetNotes('- Unlike clients and projects, tasks do NOT require archiving before delete.\' +
            '- Time entries referencing this task retain their data but the task link becomes orphaned.');
        HelpBuilder.SetRelated('- **Alternative to delete:** Set status to DONE via `Clockify.Task.Update`\' +
            '- **After delete:** `Data.Records.Set` on Clockify Integration → `Reversed` = true');
        exit(HelpBuilder.Render());
    end;
}
