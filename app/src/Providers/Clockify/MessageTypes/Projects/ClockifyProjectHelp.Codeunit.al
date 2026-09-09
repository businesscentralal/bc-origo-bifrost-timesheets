namespace Origo.Bifrost.Timesheets.Providers.Clockify;

using Origo.Bifrost;

/// <summary>
/// Builds the Markdown help documents for the Clockify project message types,
/// keeping the help text out of the individual <c>*Impl ori</c> codeunits. Every
/// implementation of the domain calls <see cref="GetHelp"/> from
/// <c>GetMessageHelpAsMarkdownDocument</c>, so <c>Help.Implementation.Get</c> still
/// answers per message type.
/// </summary>
codeunit 10036849 "Clockify Project Help ori"
{
    Access = Internal;

    /// <summary>Returns the Markdown help document for one message type of this domain.</summary>
    /// <param name="MessageType">The message type to document.</param>
    /// <param name="Description">The message type description shown in the help header.</param>
    /// <returns>The rendered Markdown document, or an empty string for a message type this codeunit does not own.</returns>
    procedure GetHelp(MessageType: Enum "Message Type ori"; Description: Text): Text
    begin
        case MessageType of
            MessageType::"Provider.Clockify.Project.List":
                exit(GetProjectListHelp(Description));
            MessageType::"Provider.Clockify.Project.Get":
                exit(GetProjectGetHelp(Description));
            MessageType::"Provider.Clockify.Project.Create":
                exit(GetProjectCreateHelp(Description));
            MessageType::"Provider.Clockify.Project.Update":
                exit(GetProjectUpdateHelp(Description));
            MessageType::"Provider.Clockify.Project.Delete":
                exit(GetProjectDeleteHelp(Description));
        end;
        exit('');
    end;

    /// <summary>Returns the help document for <c>Provider.Clockify.Project.List</c>.</summary>
    /// <param name="Description">The message type description shown in the help header.</param>
    local procedure GetProjectListHelp(Description: Text): Text
    var
        HelpBuilder: Codeunit "Clockify Help Builder ori";
    begin
        HelpBuilder.Init('Provider.Clockify.Project.List', Description, 'GET', '/workspaces/{workspaceId}/projects');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Provider.Clockify.Workspace.List → id');
        HelpBuilder.AddParam('query.page-size', false, 'integer', 'Results per page (default 50, max 5000)', '');
        HelpBuilder.AddParam('query.page', false, 'integer', 'Page number (1-based)', '');
        HelpBuilder.AddParam('query.archived', false, 'boolean', 'Filter: true=archived only, false=active only, omit=all', '');
        HelpBuilder.AddParam('query.name', false, 'string', 'Filter: partial name match (case-insensitive)', '');
        HelpBuilder.AddParam('query.clients', false, 'string', 'Filter: comma-separated client IDs', 'Provider.Clockify.Client.List → id');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "query": { "page-size": 50, "page": 1, "archived": false } }');
        HelpBuilder.SetResponseNote('an array of project objects (each with `id`, `name`, `clientId`, `archived`)');
        HelpBuilder.SetAfterSuccess('No tracking action required — this is a read operation. Use the returned `id` values for task/timeEntry operations.');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Clockify Setup');
        HelpBuilder.SetRelated('- **Get single project:** `Provider.Clockify.Project.Get`\' +
            '- **Create project:** `Provider.Clockify.Project.Create`\' +
            '- **List tasks under project:** `Provider.Clockify.Task.List` (requires projectId from this response)');
        exit(HelpBuilder.Render());
    end;

    /// <summary>Returns the help document for <c>Provider.Clockify.Project.Get</c>.</summary>
    /// <param name="Description">The message type description shown in the help header.</param>
    local procedure GetProjectGetHelp(Description: Text): Text
    var
        HelpBuilder: Codeunit "Clockify Help Builder ori";
    begin
        HelpBuilder.Init('Provider.Clockify.Project.Get', Description, 'GET', '/workspaces/{workspaceId}/projects/{projectId}');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Provider.Clockify.Workspace.List → id');
        HelpBuilder.AddParam('projectId', true, 'string', 'The Clockify project ID to retrieve', 'Clockify Integration table → Clockify Id (type=project)');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "projectId": "60..." }');
        HelpBuilder.SetResponseNote('the project object (includes `id`, `name`, `clientId`, `memberships`, `archived`, `customFields`)');
        HelpBuilder.SetAfterSuccess('No tracking action required — this is a read operation.');
        HelpBuilder.AddError(404, 'Project not found', 'Verify projectId exists via `Provider.Clockify.Project.List`');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Clockify Setup');
        HelpBuilder.SetRelated('- **Find projectId:** `Provider.Clockify.Project.List` or `Data.Records.Get` on Clockify Integration (type=project)\' +
            '- **List tasks under this project:** `Provider.Clockify.Task.List` (requires projectId)\' +
            '- **Update this project:** `Provider.Clockify.Project.Update`');
        exit(HelpBuilder.Render());
    end;

    /// <summary>Returns the help document for <c>Provider.Clockify.Project.Create</c>.</summary>
    /// <param name="Description">The message type description shown in the help header.</param>
    local procedure GetProjectCreateHelp(Description: Text): Text
    var
        HelpBuilder: Codeunit "Clockify Help Builder ori";
    begin
        HelpBuilder.Init('Provider.Clockify.Project.Create', Description, 'POST', '/workspaces/{workspaceId}/projects');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Provider.Clockify.Workspace.List → id');
        HelpBuilder.AddParam('body.name', true, 'string', 'Project display name (must be unique in workspace)', '');
        HelpBuilder.AddParam('body.clientId', false, 'string', 'Clockify client ID to associate (NOT the BC customer number)', 'Provider.Clockify.Client.List → id');
        HelpBuilder.AddParam('body.isPublic', false, 'boolean', 'true = visible to all workspace members (default true)', '');
        HelpBuilder.AddParam('body.billable', false, 'boolean', 'true = time entries default to billable', '');
        HelpBuilder.AddParam('body.color', false, 'string', 'Hex colour code (e.g. #f44336)', '');
        HelpBuilder.AddParam('body.note', false, 'string', 'Free-text project description', '');
        HelpBuilder.AddParam('body.hourlyRate', false, 'object', '{ "amount": <cents>, "currency": "USD" }', '');
        HelpBuilder.AddParam('body.userGroupIds', false, 'array', 'Array of Clockify user-group IDs', 'Provider.Clockify.UserGroup.List → id');
        HelpBuilder.AddParam('body.memberships', false, 'array', 'Array of { "userId": "...", "hourlyRate": {...} }', 'Provider.Clockify.User.List → id');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "body": { "name": "Implementation", "clientId": "60...", "isPublic": false, "billable": true, "color": "#f44336", "userGroupIds": [ "61..." ] } }');
        HelpBuilder.SetResponseNote('the created project object (includes `id`, `name`, `clientId`, `workspaceId`)');
        HelpBuilder.AddError(400, 'Project name already exists', 'Use `Provider.Clockify.Project.List` to find existing, or choose a different name');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Clockify Setup');
        HelpBuilder.AddError(403, 'Forbidden', 'API key user lacks workspace admin role');
        HelpBuilder.SetNotes('- `clientId` must be the Clockify internal ID (from `Provider.Clockify.Client.List`), not a BC customer number.\' +
            '- `userGroupIds` requires Clockify group IDs; group names are silently ignored.\' +
            '- Custom field defaults cannot be set at creation — create the project first, then call `Provider.Clockify.Project.Update` with `customFields` array.');
        HelpBuilder.SetRelated('- **Resolve clientId:** `Provider.Clockify.Client.List` or Clockify Integration (type=client)\' +
            '- **Resolve userGroupIds:** `Provider.Clockify.UserGroup.List` → `id`\' +
            '- **Set custom fields after create:** `Provider.Clockify.Project.Update` with `customFields`\' +
            '- **Add tasks:** `Provider.Clockify.Task.Create` (requires project `id` from response)\' +
            '- **To delete later:** Archive first (`Provider.Clockify.Project.Update` → `archived: true`), then `Provider.Clockify.Project.Delete`');
        exit(HelpBuilder.Render());
    end;

    /// <summary>Returns the help document for <c>Provider.Clockify.Project.Update</c>.</summary>
    /// <param name="Description">The message type description shown in the help header.</param>
    local procedure GetProjectUpdateHelp(Description: Text): Text
    var
        HelpBuilder: Codeunit "Clockify Help Builder ori";
    begin
        HelpBuilder.Init('Provider.Clockify.Project.Update', Description, 'PUT', '/workspaces/{workspaceId}/projects/{projectId}');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Provider.Clockify.Workspace.List → id');
        HelpBuilder.AddParam('projectId', true, 'string', 'The Clockify project ID to update', 'Clockify Integration table → Clockify Id (type=project)');
        HelpBuilder.AddParam('body.name', false, 'string', 'Project display name', '');
        HelpBuilder.AddParam('body.clientId', false, 'string', 'Clockify client ID', 'Provider.Clockify.Client.List → id');
        HelpBuilder.AddParam('body.isPublic', false, 'boolean', 'Visibility to all workspace members', '');
        HelpBuilder.AddParam('body.billable', false, 'boolean', 'Default billable status for time entries', '');
        HelpBuilder.AddParam('body.color', false, 'string', 'Hex colour code', '');
        HelpBuilder.AddParam('body.note', false, 'string', 'Free-text description', '');
        HelpBuilder.AddParam('body.archived', false, 'boolean', 'Set true to archive (required before delete)', '');
        HelpBuilder.AddParam('body.userGroupIds', false, 'array', 'Array of Clockify user-group IDs', 'Provider.Clockify.UserGroup.List → id');
        HelpBuilder.AddParam('body.customFields', false, 'array', 'Array of { customFieldId, status, defaultValue }', 'Provider.Clockify.CustomField.List → id');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "projectId": "60...", "body": { "name": "Implementation 2026", "archived": false, "billable": true, "customFields": [ { "customFieldId": "62...", "status": "VISIBLE", "defaultValue": "Iceland" } ] } }');
        HelpBuilder.SetResponseNote('the updated project object');
        HelpBuilder.AddError(400, 'Project name already exists', 'Choose a different name');
        HelpBuilder.AddError(404, 'Project not found', 'Verify projectId via `Provider.Clockify.Project.List`');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Clockify Setup');
        HelpBuilder.SetNotes('- `clientId` and `userGroupIds` require Clockify IDs — names and BC keys are silently ignored.\' +
            '- `customFields` format: `{ "customFieldId": "...", "status": "VISIBLE"|"INVISIBLE", "defaultValue": ... }`. Get `customFieldId` from `Provider.Clockify.CustomField.List`.\' +
            '- Setting `archived: true` is the **required first step** before `Provider.Clockify.Project.Delete`.\' +
            '- Send only fields you want to change; omitted fields retain current values.');
        HelpBuilder.SetRelated('- **Archive before delete:** Set `body.archived` = true, then `Provider.Clockify.Project.Delete`\' +
            '- **Resolve customFieldId:** `Provider.Clockify.CustomField.List` → `id`\' +
            '- **Resolve clientId:** `Provider.Clockify.Client.List` or Clockify Integration (type=client)');
        exit(HelpBuilder.Render());
    end;

    /// <summary>Returns the help document for <c>Provider.Clockify.Project.Delete</c>.</summary>
    /// <param name="Description">The message type description shown in the help header.</param>
    local procedure GetProjectDeleteHelp(Description: Text): Text
    var
        HelpBuilder: Codeunit "Clockify Help Builder ori";
    begin
        HelpBuilder.Init('Provider.Clockify.Project.Delete', Description, 'DELETE', '/workspaces/{workspaceId}/projects/{projectId}');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Provider.Clockify.Workspace.List → id');
        HelpBuilder.AddParam('projectId', true, 'string', 'The Clockify project ID to delete', 'Clockify Integration table → Clockify Id (type=project)');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "projectId": "60..." }');
        HelpBuilder.SetResponseNote('the deleted project object');
        HelpBuilder.SetPreconditions('1. The project **must be archived first** — call `Provider.Clockify.Project.Update` with body `{ "archived": true }`.\' +
            '2. Clockify rejects delete on active projects with HTTP 400.');
        HelpBuilder.AddError(400, 'Cannot delete an active project', 'Archive first: `Provider.Clockify.Project.Update` with `{ "archived": true }`');
        HelpBuilder.AddError(404, 'Project not found', 'Verify projectId via `Provider.Clockify.Project.List`');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Clockify Setup');
        HelpBuilder.SetNotes('- Two-step delete pattern: archive → delete. This is a Clockify platform requirement.\' +
            '- After delete, mark the `Clockify Integration` row as reversed (do NOT delete it).\' +
            '- Tasks under this project are also deleted by Clockify.');
        HelpBuilder.SetRelated('- **Step 1 (archive):** `Provider.Clockify.Project.Update` with `{ "archived": true }`\' +
            '- **Step 2 (delete):** This message type\' +
            '- **Step 3 (unlink):** `Data.Records.Set` on Clockify Integration → `Reversed` = true');
        exit(HelpBuilder.Render());
    end;
}
