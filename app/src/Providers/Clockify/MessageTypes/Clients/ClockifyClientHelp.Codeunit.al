namespace Origo.Bifrost.Timesheets.Providers.Clockify;

using Origo.Bifrost;

/// <summary>
/// Builds the Markdown help documents for the Clockify client message types,
/// keeping the help text out of the individual <c>*Impl ori</c> codeunits. Every
/// implementation of the domain calls <see cref="GetHelp"/> from
/// <c>GetMessageHelpAsMarkdownDocument</c>, so <c>Help.Implementation.Get</c> still
/// answers per message type.
/// </summary>
codeunit 10036848 "Clockify Client Help ori"
{
    Access = Internal;

    /// <summary>Returns the Markdown help document for one message type of this domain.</summary>
    /// <param name="MessageType">The message type to document.</param>
    /// <param name="Description">The message type description shown in the help header.</param>
    /// <returns>The rendered Markdown document, or an empty string for a message type this codeunit does not own.</returns>
    procedure GetHelp(MessageType: Enum "Message Type ori"; Description: Text): Text
    begin
        case MessageType of
            MessageType::"Provider.Clockify.Client.List":
                exit(GetClientListHelp(Description));
            MessageType::"Provider.Clockify.Client.Get":
                exit(GetClientGetHelp(Description));
            MessageType::"Provider.Clockify.Client.Create":
                exit(GetClientCreateHelp(Description));
            MessageType::"Provider.Clockify.Client.Update":
                exit(GetClientUpdateHelp(Description));
            MessageType::"Provider.Clockify.Client.Delete":
                exit(GetClientDeleteHelp(Description));
        end;
        exit('');
    end;

    /// <summary>Returns the help document for <c>Provider.Clockify.Client.List</c>.</summary>
    /// <param name="Description">The message type description shown in the help header.</param>
    local procedure GetClientListHelp(Description: Text): Text
    var
        HelpBuilder: Codeunit "Clockify Help Builder ori";
    begin
        HelpBuilder.Init('Provider.Clockify.Client.List', Description, 'GET', '/workspaces/{workspaceId}/clients');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Provider.Clockify.Workspace.List → id');
        HelpBuilder.AddParam('query.page-size', false, 'integer', 'Results per page (default 50, max 5000)', '');
        HelpBuilder.AddParam('query.page', false, 'integer', 'Page number (1-based)', '');
        HelpBuilder.AddParam('query.archived', false, 'boolean', 'Filter: true=archived only, false=active only, omit=all', '');
        HelpBuilder.AddParam('query.name', false, 'string', 'Filter: partial name match (case-insensitive)', '');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "query": { "page-size": 50, "page": 1, "archived": false } }');
        HelpBuilder.SetResponseNote('an array of client objects (each with `id`, `name`, `workspaceId`, `archived`)');
        HelpBuilder.SetAfterSuccess('No tracking action required — this is a read operation. Use the returned `id` values for subsequent create/update/delete calls.');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Clockify Setup');
        HelpBuilder.AddError(403, 'Forbidden', 'API key user lacks workspace access');
        HelpBuilder.SetRelated('- **Get single client:** `Provider.Clockify.Client.Get` (when you have the ID)\' +
            '- **Create new client:** `Provider.Clockify.Client.Create`\' +
            '- **Use for ID resolution:** Match response `name` to BC Customer Name → extract `id` for write operations');
        exit(HelpBuilder.Render());
    end;

    /// <summary>Returns the help document for <c>Provider.Clockify.Client.Get</c>.</summary>
    /// <param name="Description">The message type description shown in the help header.</param>
    local procedure GetClientGetHelp(Description: Text): Text
    var
        HelpBuilder: Codeunit "Clockify Help Builder ori";
    begin
        HelpBuilder.Init('Provider.Clockify.Client.Get', Description, 'GET', '/workspaces/{workspaceId}/clients/{clientId}');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Provider.Clockify.Workspace.List → id');
        HelpBuilder.AddParam('clientId', true, 'string', 'The Clockify client ID to retrieve', 'Clockify Integration table → Clockify Id (type=client)');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "clientId": "60..." }');
        HelpBuilder.SetResponseNote('the client object (includes `id`, `name`, `workspaceId`, `archived`, `currencyId`)');
        HelpBuilder.SetAfterSuccess('No tracking action required — this is a read operation.');
        HelpBuilder.AddError(404, 'Client not found', 'Verify clientId exists via `Provider.Clockify.Client.List` or check Clockify Integration table');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Clockify Setup');
        HelpBuilder.SetRelated('- **Find clientId:** `Provider.Clockify.Client.List` or `Data.Records.Get` on Clockify Integration (type=client)\' +
            '- **Update this client:** `Provider.Clockify.Client.Update`\' +
            '- **Delete this client:** Archive first, then `Provider.Clockify.Client.Delete`');
        exit(HelpBuilder.Render());
    end;

    /// <summary>Returns the help document for <c>Provider.Clockify.Client.Create</c>.</summary>
    /// <param name="Description">The message type description shown in the help header.</param>
    local procedure GetClientCreateHelp(Description: Text): Text
    var
        HelpBuilder: Codeunit "Clockify Help Builder ori";
    begin
        HelpBuilder.Init('Provider.Clockify.Client.Create', Description, 'POST', '/workspaces/{workspaceId}/clients');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Provider.Clockify.Workspace.List → id');
        HelpBuilder.AddParam('body.name', true, 'string', 'Client display name (must be unique in workspace)', '');
        HelpBuilder.AddParam('body.address', false, 'string', 'Single-line address (concatenate BC Address + Address 2 + Post Code + City + Country)', '');
        HelpBuilder.AddParam('body.email', false, 'string', 'Client contact email', '');
        HelpBuilder.AddParam('body.note', false, 'string', 'Free-text note', '');
        HelpBuilder.AddParam('body.currencyId', false, 'string', 'Clockify currency ID (NOT the ISO code). Omit for workspace default', 'Provider.Clockify.Currency.List → id');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "body": { "name": "Acme Inc.", "address": "Main St 1, 101 Reykjavik, IS", "currencyId": "6a..." } }');
        HelpBuilder.SetResponseNote('the created client object (includes `id`, `name`, `workspaceId`)');
        HelpBuilder.AddError(400, 'Client name already exists in workspace', 'Use `Provider.Clockify.Client.List` to find existing client, or choose a different name');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Clockify Setup');
        HelpBuilder.AddError(403, 'Forbidden', 'API key user lacks workspace admin role');
        HelpBuilder.SetNotes('- `currencyCode` is **silently ignored** — Clockify returns 201 but uses workspace default. Always use `currencyId`.\' +
            '- `address` is a single free-text field; concatenate multi-line BC address fields before sending.');
        HelpBuilder.SetRelated('- **Resolve currencyId:** `Provider.Clockify.Currency.List` → match on `code` → use `id`\' +
            '- **After creating:** Record integration link, then optionally create projects under this client\' +
            '- **To update later:** `Provider.Clockify.Client.Update` (requires `clientId` from create response)\' +
            '- **To delete later:** First archive (`Provider.Clockify.Client.Update` body `{ "archived": true }`), then `Provider.Clockify.Client.Delete`');
        exit(HelpBuilder.Render());
    end;

    /// <summary>Returns the help document for <c>Provider.Clockify.Client.Update</c>.</summary>
    /// <param name="Description">The message type description shown in the help header.</param>
    local procedure GetClientUpdateHelp(Description: Text): Text
    var
        HelpBuilder: Codeunit "Clockify Help Builder ori";
    begin
        HelpBuilder.Init('Provider.Clockify.Client.Update', Description, 'PUT', '/workspaces/{workspaceId}/clients/{clientId}');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Provider.Clockify.Workspace.List → id');
        HelpBuilder.AddParam('clientId', true, 'string', 'The Clockify client ID to update', 'Clockify Integration table → Clockify Id (type=client)');
        HelpBuilder.AddParam('body.name', false, 'string', 'Client display name', '');
        HelpBuilder.AddParam('body.address', false, 'string', 'Single-line address', '');
        HelpBuilder.AddParam('body.email', false, 'string', 'Client contact email', '');
        HelpBuilder.AddParam('body.note', false, 'string', 'Free-text note', '');
        HelpBuilder.AddParam('body.currencyId', false, 'string', 'Clockify currency ID (NOT the ISO code)', 'Provider.Clockify.Currency.List → id');
        HelpBuilder.AddParam('body.archived', false, 'boolean', 'Set true to archive, false to unarchive', '');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "clientId": "60...", "body": { "name": "Acme Ltd.", "currencyId": "6a...", "archived": false } }');
        HelpBuilder.SetResponseNote('the updated client object');
        HelpBuilder.AddError(400, 'Client name already exists', 'Choose a different name or use existing client');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Clockify Setup');
        HelpBuilder.AddError(404, 'Client not found', 'Verify clientId via `Provider.Clockify.Client.List`');
        HelpBuilder.SetNotes('- `currencyCode` is **silently ignored** — Clockify returns 200 but the currency is unchanged. Always use `currencyId`.\' +
            '- Setting `archived: true` is the **required first step** before `Provider.Clockify.Client.Delete`.\' +
            '- Send only the fields you want to change; omitted fields retain their current values.');
        HelpBuilder.SetRelated('- **Archive before delete:** Set `body.archived` = true, then call `Provider.Clockify.Client.Delete`\' +
            '- **Resolve currencyId:** `Provider.Clockify.Currency.List` → match on `code` → use `id`\' +
            '- **Unarchive:** Set `body.archived` = false');
        exit(HelpBuilder.Render());
    end;

    /// <summary>Returns the help document for <c>Provider.Clockify.Client.Delete</c>.</summary>
    /// <param name="Description">The message type description shown in the help header.</param>
    local procedure GetClientDeleteHelp(Description: Text): Text
    var
        HelpBuilder: Codeunit "Clockify Help Builder ori";
    begin
        HelpBuilder.Init('Provider.Clockify.Client.Delete', Description, 'DELETE', '/workspaces/{workspaceId}/clients/{clientId}');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Provider.Clockify.Workspace.List → id');
        HelpBuilder.AddParam('clientId', true, 'string', 'The Clockify client ID to delete', 'Clockify Integration table → Clockify Id (type=client)');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "clientId": "60..." }');
        HelpBuilder.SetResponseNote('the deleted client object');
        HelpBuilder.SetPreconditions('1. The client **must be archived first** — call `Provider.Clockify.Client.Update` with body `{ "archived": true }`.\' +
            '2. Clockify rejects delete on active clients with HTTP 400.');
        HelpBuilder.AddError(400, 'Cannot delete an active client', 'Archive first: `Provider.Clockify.Client.Update` with `{ "archived": true }`');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Clockify Setup');
        HelpBuilder.AddError(404, 'Client not found', 'Verify clientId via `Provider.Clockify.Client.List`');
        HelpBuilder.SetNotes('- Two-step delete pattern: archive → delete. This is a Clockify platform requirement.\' +
            '- After delete, mark the `Clockify Integration` row as reversed (do NOT delete it).');
        HelpBuilder.SetRelated('- **Step 1 (archive):** `Provider.Clockify.Client.Update` with `{ "archived": true }`\' +
            '- **Step 2 (delete):** This message type\' +
            '- **Step 3 (unlink):** `Data.Records.Set` on Clockify Integration → `Reversed` = true');
        exit(HelpBuilder.Render());
    end;
}
