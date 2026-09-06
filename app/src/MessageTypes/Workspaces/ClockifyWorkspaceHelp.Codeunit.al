namespace Origo.Bifrost.Timesheets;

using Origo.Bifrost;

/// <summary>
/// Builds the Markdown help documents for the workspace-scoped reference lists (workspaces, users, user groups, currencies and custom fields),
/// keeping the help text out of the individual <c>*Impl ori</c> codeunits. Every
/// implementation of the domain calls <see cref="GetHelp"/> from
/// <c>GetMessageHelpAsMarkdownDocument</c>, so <c>Help.Implementation.Get</c> still
/// answers per message type.
/// </summary>
codeunit 70009262 "Clockify Workspace Help ori"
{
    Access = Internal;

    /// <summary>Returns the Markdown help document for one message type of this domain.</summary>
    /// <param name="MessageType">The message type to document.</param>
    /// <param name="Description">The message type description shown in the help header.</param>
    /// <returns>The rendered Markdown document, or an empty string for a message type this codeunit does not own.</returns>
    procedure GetHelp(MessageType: Enum "Message Type ori"; Description: Text): Text
    begin
        case MessageType of
            MessageType::"Clockify.Workspace.List":
                exit(GetWorkspaceListHelp(Description));
            MessageType::"Clockify.User.GetCurrent":
                exit(GetUserGetCurrentHelp(Description));
            MessageType::"Clockify.User.List":
                exit(GetUserListHelp(Description));
            MessageType::"Clockify.Currency.List":
                exit(GetCurrencyListHelp(Description));
            MessageType::"Clockify.UserGroup.List":
                exit(GetUserGroupListHelp(Description));
            MessageType::"Clockify.CustomField.List":
                exit(GetCustomFieldListHelp(Description));
        end;
        exit('');
    end;

    /// <summary>Returns the help document for <c>Clockify.Workspace.List</c>.</summary>
    /// <param name="Description">The message type description shown in the help header.</param>
    local procedure GetWorkspaceListHelp(Description: Text): Text
    var
        HelpBuilder: Codeunit "Clockify Help Builder ori";
    begin
        HelpBuilder.Init('Clockify.Workspace.List', Description, 'GET', '/workspaces');
        HelpBuilder.SetRequestExample('{ }');
        HelpBuilder.SetResponseNote('an array of workspace objects (each with `id`, `name`, `memberships`)');
        HelpBuilder.SetAfterSuccess('No tracking action required — this is a read operation. Use the returned `id` as `workspaceId` in all other Clockify calls.');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Clockify Setup');
        HelpBuilder.SetNotes('- No parameters needed — returns all workspaces accessible by the API key.\' +
            '- Most Clockify operations require a `workspaceId`. Call this first to resolve it.\' +
            '- The Clockify Setup stores a default workspace; this call is only needed to discover alternatives or verify the configured one.');
        HelpBuilder.SetRelated('- **Get current user:** `Clockify.User.GetCurrent` (also returns `activeWorkspace`)\' +
            '- **All other operations:** Pass workspace `id` as `workspaceId` parameter');
        exit(HelpBuilder.Render());
    end;

    /// <summary>Returns the help document for <c>Clockify.User.GetCurrent</c>.</summary>
    /// <param name="Description">The message type description shown in the help header.</param>
    local procedure GetUserGetCurrentHelp(Description: Text): Text
    var
        HelpBuilder: Codeunit "Clockify Help Builder ori";
    begin
        HelpBuilder.Init('Clockify.User.GetCurrent', Description, 'GET', '/user');
        HelpBuilder.SetRequestExample('{ }');
        HelpBuilder.SetResponseNote('the authenticated user object (includes `id`, `name`, `email`, `activeWorkspace`, `defaultWorkspace`)');
        HelpBuilder.SetAfterSuccess('No tracking action required — this is a read operation. Use the returned `id` as `userId` in time-entry operations.');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Clockify Setup');
        HelpBuilder.SetNotes('- No parameters needed — returns the user who owns the API key.\' +
            '- The `id` field is the `userId` required by `Clockify.TimeEntry.Create`, `Clockify.TimeEntry.List`, etc.\' +
            '- `activeWorkspace` is the user''s currently selected workspace ID.');
        HelpBuilder.SetRelated('- **List all users in workspace:** `Clockify.User.List`\' +
            '- **Use userId for time entries:** `Clockify.TimeEntry.Create`, `Clockify.TimeEntry.List`');
        exit(HelpBuilder.Render());
    end;

    /// <summary>Returns the help document for <c>Clockify.User.List</c>.</summary>
    /// <param name="Description">The message type description shown in the help header.</param>
    local procedure GetUserListHelp(Description: Text): Text
    var
        HelpBuilder: Codeunit "Clockify Help Builder ori";
    begin
        HelpBuilder.Init('Clockify.User.List', Description, 'GET', '/workspaces/{workspaceId}/users');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Clockify.Workspace.List → id');
        HelpBuilder.AddParam('query.page-size', false, 'integer', 'Results per page (default 50, max 5000)', '');
        HelpBuilder.AddParam('query.page', false, 'integer', 'Page number (1-based)', '');
        HelpBuilder.AddParam('query.email', false, 'string', 'Filter: exact email match', '');
        HelpBuilder.AddParam('query.name', false, 'string', 'Filter: partial name match', '');
        HelpBuilder.AddParam('query.status', false, 'string', 'Filter: ACTIVE, PENDING, DECLINED, INACTIVE', '');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "query": { "page-size": 50, "page": 1 } }');
        HelpBuilder.SetResponseNote('an array of user objects (each with `id`, `name`, `email`, `status`)');
        HelpBuilder.SetAfterSuccess('No tracking action required — this is a read operation. Use returned `id` values for time-entry and assignment operations.');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Clockify Setup');
        HelpBuilder.SetNotes('- Returns all members of the workspace, including pending invitations.\' +
            '- The `id` field is the `userId` needed for `Clockify.TimeEntry.Create/List` and `memberships` in project/task operations.');
        HelpBuilder.SetRelated('- **Get API key owner only:** `Clockify.User.GetCurrent`\' +
            '- **Assign to projects:** Use `id` in `memberships` array of `Clockify.Project.Create/Update`\' +
            '- **Map to BC Resource:** Store mapping in Clockify Integration table (type=user)');
        exit(HelpBuilder.Render());
    end;

    /// <summary>Returns the help document for <c>Clockify.Currency.List</c>.</summary>
    /// <param name="Description">The message type description shown in the help header.</param>
    local procedure GetCurrencyListHelp(Description: Text): Text
    var
        HelpBuilder: Codeunit "Clockify Help Builder ori";
    begin
        HelpBuilder.Init('Clockify.Currency.List', Description, 'GET', '/workspaces (inline `currencies` from workspace object)');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Clockify.Workspace.List → id');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f..." }');
        HelpBuilder.SetResponseNote('an array of currency objects (each with `id`, `code`, and the workspace default flag)');
        HelpBuilder.SetAfterSuccess('No tracking action required — this is a read operation. Use `id` as `currencyId` in client operations.');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Clockify Setup');
        HelpBuilder.SetNotes('- Clockify has no standalone currencies endpoint. This message type reads `GET /workspaces` and extracts the requested workspace''s `currencies` array.\' +
            '- Each item has an internal `id` (Clockify currency ID) and a 3-letter `code` (e.g. `ISK`, `USD`).\' +
            '- Use the `id` value (NOT the `code`) as `currencyId` in `Clockify.Client.Create` / `Clockify.Client.Update`. Passing `currencyCode` is silently ignored.\' +
            '- The list is per-workspace — the same currency code can have different IDs in different workspaces.');
        HelpBuilder.SetRelated('- **Use currencyId:** `Clockify.Client.Create` and `Clockify.Client.Update` (body.currencyId)\' +
            '- **Workspace info:** `Clockify.Workspace.List` returns the full workspace object including currencies');
        exit(HelpBuilder.Render());
    end;

    /// <summary>Returns the help document for <c>Clockify.UserGroup.List</c>.</summary>
    /// <param name="Description">The message type description shown in the help header.</param>
    local procedure GetUserGroupListHelp(Description: Text): Text
    var
        HelpBuilder: Codeunit "Clockify Help Builder ori";
    begin
        HelpBuilder.Init('Clockify.UserGroup.List', Description, 'GET', '/workspaces/{workspaceId}/user-groups');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Clockify.Workspace.List → id');
        HelpBuilder.AddParam('query.page-size', false, 'integer', 'Results per page (default 50, max 5000)', '');
        HelpBuilder.AddParam('query.page', false, 'integer', 'Page number (1-based)', '');
        HelpBuilder.AddParam('query.name', false, 'string', 'Filter: partial name match', '');
        HelpBuilder.AddParam('query.projectId', false, 'string', 'Filter: groups assigned to this project', 'Clockify.Project.List → id');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "query": { "page-size": 50, "page": 1 } }');
        HelpBuilder.SetResponseNote('an array of user-group objects (each with `id`, `name`, `workspaceId`, `userIds`)');
        HelpBuilder.SetAfterSuccess('No tracking action required — this is a read operation. Use `id` values for project `userGroupIds`.');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Clockify Setup');
        HelpBuilder.SetNotes('- Each group has a `userIds` array listing member Clockify user IDs.\' +
            '- Use the `id` value as a member of `userGroupIds` in `Clockify.Project.Create` / `Clockify.Project.Update`. Group **names** are not accepted on those write paths.');
        HelpBuilder.SetRelated('- **Assign group to project:** `Clockify.Project.Create` or `Clockify.Project.Update` (body.userGroupIds)\' +
            '- **List group members:** Check `userIds` array in response; resolve to names via `Clockify.User.List`');
        exit(HelpBuilder.Render());
    end;

    /// <summary>Returns the help document for <c>Clockify.CustomField.List</c>.</summary>
    /// <param name="Description">The message type description shown in the help header.</param>
    local procedure GetCustomFieldListHelp(Description: Text): Text
    var
        HelpBuilder: Codeunit "Clockify Help Builder ori";
    begin
        HelpBuilder.Init('Clockify.CustomField.List', Description, 'GET', '/workspaces/{workspaceId}/custom-fields');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Clockify.Workspace.List → id');
        HelpBuilder.AddParam('query.page-size', false, 'integer', 'Results per page (default 50, max 5000)', '');
        HelpBuilder.AddParam('query.page', false, 'integer', 'Page number (1-based)', '');
        HelpBuilder.AddParam('query.status', false, 'string', 'Filter: VISIBLE or INVISIBLE', '');
        HelpBuilder.AddParam('query.name', false, 'string', 'Filter: partial name match', '');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "query": { "page-size": 50, "page": 1, "status": "VISIBLE" } }');
        HelpBuilder.SetResponseNote('an array of custom-field definition objects (each with `id`, `name`, `type`, `allowedValues`, `status`)');
        HelpBuilder.SetAfterSuccess('No tracking action required — this is a read operation. Use `id` as `customFieldId` in time-entry and project operations.');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Clockify Setup');
        HelpBuilder.SetNotes('- Field `type` values: `TXT`, `NUMBER`, `DROPDOWN_SINGLE`, `DROPDOWN_MULTIPLE`, `CHECKBOX`, `LINK`.\' +
            '- Use the `id` value as `customFieldId` in `Clockify.TimeEntry.Create/Update` and `Clockify.Project.Update` bodies.\' +
            '- For per-project enablement and defaults, send `customFieldId` inside the `customFields` array on `Clockify.Project.Update`.\' +
            '- This endpoint returns **workspace-level** definitions only. Project-scoped overrides (enabled/disabled, project-level defaults) surface inside `Clockify.Project.Get`.');
        HelpBuilder.SetRelated('- **Use on time entries:** `Clockify.TimeEntry.Create/Update` (body.customFields)\' +
            '- **Enable per project:** `Clockify.Project.Update` (body.customFields)\' +
            '- **See project overrides:** `Clockify.Project.Get` (response.customFields)');
        exit(HelpBuilder.Render());
    end;
}
