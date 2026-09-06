namespace Origo.Bifrost.Timesheets;

using Origo.Bifrost;

/// <summary>
/// Builds the Markdown help documents for the Clockify tag message types,
/// keeping the help text out of the individual <c>*Impl ori</c> codeunits. Every
/// implementation of the domain calls <see cref="GetHelp"/> from
/// <c>GetMessageHelpAsMarkdownDocument</c>, so <c>Help.Implementation.Get</c> still
/// answers per message type.
/// </summary>
codeunit 70009266 "Clockify Tag Help ori"
{
    Access = Internal;

    /// <summary>Returns the Markdown help document for one message type of this domain.</summary>
    /// <param name="MessageType">The message type to document.</param>
    /// <param name="Description">The message type description shown in the help header.</param>
    /// <returns>The rendered Markdown document, or an empty string for a message type this codeunit does not own.</returns>
    procedure GetHelp(MessageType: Enum "Message Type ori"; Description: Text): Text
    begin
        case MessageType of
            MessageType::"Clockify.Tag.List":
                exit(GetTagListHelp(Description));
            MessageType::"Clockify.Tag.Create":
                exit(GetTagCreateHelp(Description));
            MessageType::"Clockify.Tag.Update":
                exit(GetTagUpdateHelp(Description));
            MessageType::"Clockify.Tag.Delete":
                exit(GetTagDeleteHelp(Description));
        end;
        exit('');
    end;

    /// <summary>Returns the help document for <c>Clockify.Tag.List</c>.</summary>
    /// <param name="Description">The message type description shown in the help header.</param>
    local procedure GetTagListHelp(Description: Text): Text
    var
        HelpBuilder: Codeunit "Clockify Help Builder ori";
    begin
        HelpBuilder.Init('Clockify.Tag.List', Description, 'GET', '/workspaces/{workspaceId}/tags');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Clockify.Workspace.List → id');
        HelpBuilder.AddParam('query.page-size', false, 'integer', 'Results per page (default 50, max 5000)', '');
        HelpBuilder.AddParam('query.page', false, 'integer', 'Page number (1-based)', '');
        HelpBuilder.AddParam('query.archived', false, 'boolean', 'Filter: true=archived only, false=active only, omit=all', '');
        HelpBuilder.AddParam('query.name', false, 'string', 'Filter: partial name match', '');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "query": { "page-size": 50, "page": 1 } }');
        HelpBuilder.SetResponseNote('an array of tag objects (each with `id`, `name`, `workspaceId`, `archived`)');
        HelpBuilder.SetAfterSuccess('No tracking action required — this is a read operation. Use returned `id` values for time-entry `tagIds`.');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Clockify Setup');
        HelpBuilder.SetRelated('- **Create tag:** `Clockify.Tag.Create`\' +
            '- **Use in time entries:** Pass `id` values in `tagIds` array of `Clockify.TimeEntry.Create`/`Update`\' +
            '- **ID resolution:** Match on `name` to find the `id` needed for write operations');
        exit(HelpBuilder.Render());
    end;

    /// <summary>Returns the help document for <c>Clockify.Tag.Create</c>.</summary>
    /// <param name="Description">The message type description shown in the help header.</param>
    local procedure GetTagCreateHelp(Description: Text): Text
    var
        HelpBuilder: Codeunit "Clockify Help Builder ori";
    begin
        HelpBuilder.Init('Clockify.Tag.Create', Description, 'POST', '/workspaces/{workspaceId}/tags');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Clockify.Workspace.List → id');
        HelpBuilder.AddParam('body.name', true, 'string', 'Tag display name (must be unique in workspace)', '');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "body": { "name": "Billable" } }');
        HelpBuilder.SetResponseNote('the created tag object (includes `id`, `name`, `workspaceId`)');
        HelpBuilder.AddError(400, 'Tag name already exists', 'Use `Clockify.Tag.List` to find existing tag');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Clockify Setup');
        HelpBuilder.SetNotes('- Tags are workspace-scoped (not project-scoped). One tag can be used across all projects.\' +
            '- Use tag `id` (not name) when attaching to time entries via `tagIds` array.');
        HelpBuilder.SetRelated('- **List existing tags:** `Clockify.Tag.List`\' +
            '- **Use in time entries:** Pass tag `id` in `tagIds` array of `Clockify.TimeEntry.Create`/`Update`\' +
            '- **Delete later:** `Clockify.Tag.Delete` (no archive step needed)');
        exit(HelpBuilder.Render());
    end;

    /// <summary>Returns the help document for <c>Clockify.Tag.Update</c>.</summary>
    /// <param name="Description">The message type description shown in the help header.</param>
    local procedure GetTagUpdateHelp(Description: Text): Text
    var
        HelpBuilder: Codeunit "Clockify Help Builder ori";
    begin
        HelpBuilder.Init('Clockify.Tag.Update', Description, 'PUT', '/workspaces/{workspaceId}/tags/{tagId}');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Clockify.Workspace.List → id');
        HelpBuilder.AddParam('tagId', true, 'string', 'The tag ID to update', 'Clockify.Tag.List → id');
        HelpBuilder.AddParam('body.name', false, 'string', 'Tag display name', '');
        HelpBuilder.AddParam('body.archived', false, 'boolean', 'Set true to archive, false to unarchive', '');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "tagId": "62...", "body": { "name": "Non-billable", "archived": false } }');
        HelpBuilder.SetResponseNote('the updated tag object');
        HelpBuilder.AddError(400, 'Tag name already exists', 'Choose a different name');
        HelpBuilder.AddError(404, 'Tag not found', 'Verify tagId via `Clockify.Tag.List`');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Clockify Setup');
        HelpBuilder.SetNotes('- Send only fields you want to change; omitted fields retain current values.\' +
            '- Unlike clients/projects, archiving a tag is NOT required before `Clockify.Tag.Delete`.');
        HelpBuilder.SetRelated('- **Resolve tagId:** `Clockify.Tag.List` or Clockify Integration (type=tag)\' +
            '- **Delete tag:** `Clockify.Tag.Delete` (no archive step needed)');
        exit(HelpBuilder.Render());
    end;

    /// <summary>Returns the help document for <c>Clockify.Tag.Delete</c>.</summary>
    /// <param name="Description">The message type description shown in the help header.</param>
    local procedure GetTagDeleteHelp(Description: Text): Text
    var
        HelpBuilder: Codeunit "Clockify Help Builder ori";
    begin
        HelpBuilder.Init('Clockify.Tag.Delete', Description, 'DELETE', '/workspaces/{workspaceId}/tags/{tagId}');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Clockify.Workspace.List → id');
        HelpBuilder.AddParam('tagId', true, 'string', 'The tag ID to delete', 'Clockify.Tag.List → id');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "tagId": "62..." }');
        HelpBuilder.SetResponseNote('the deleted tag object');
        HelpBuilder.AddError(404, 'Tag not found', 'Verify tagId via `Clockify.Tag.List`');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Clockify Setup');
        HelpBuilder.SetNotes('- Unlike clients and projects, tags do NOT require archiving before delete.\' +
            '- Time entries referencing this tag retain their data but the tag link becomes orphaned.');
        HelpBuilder.SetRelated('- **Alternative to delete:** Archive via `Clockify.Tag.Update` with `{ "archived": true }`\' +
            '- **After delete:** `Data.Records.Set` on Clockify Integration → `Reversed` = true');
        exit(HelpBuilder.Render());
    end;
}
