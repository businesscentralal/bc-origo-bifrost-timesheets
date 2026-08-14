namespace Origo.PTE.CloudEvents.Clockify;

using Origo.APP.CloudEvents;

/// <summary>
/// Implementation of the <c>Clockify.CustomField.List</c> message type.
/// Lists the workspace-level custom field definitions. The Clockify internal
/// <c>id</c> returned here is the value that must be sent as
/// <c>customFieldId</c> in the body of <c>Clockify.TimeEntry.Create</c> /
/// <c>Clockify.TimeEntry.Update</c> and in <c>customFields</c> entries on
/// <c>Clockify.Project.Update</c>. Custom-field <c>name</c> values are not
/// accepted on those write paths.
/// </summary>
codeunit 71450 "Clockify CustomField List Impl" implements "Cloud Event Msg Interface ori"
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
        exit('Lists the workspace-level custom field definitions in a Clockify workspace.');
    end;

    internal procedure GetMessageDirection(): Enum "Cloud Event Msg Direction ori"
    begin
        exit(Enum::"Cloud Event Msg Direction ori"::Outbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "CE Message Argument ori")
    var
        HelpBuilder: Codeunit "Clockify Help Builder";
    begin
        HelpBuilder.Init('Clockify.CustomField.List', GetDescription(), 'GET', '/workspaces/{workspaceId}/custom-fields');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Clockify.Workspace.List → id');
        HelpBuilder.AddParam('query.page-size', false, 'integer', 'Results per page (default 50, max 5000)', '');
        HelpBuilder.AddParam('query.page', false, 'integer', 'Page number (1-based)', '');
        HelpBuilder.AddParam('query.status', false, 'string', 'Filter: VISIBLE or INVISIBLE', '');
        HelpBuilder.AddParam('query.name', false, 'string', 'Filter: partial name match', '');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "query": { "page-size": 50, "page": 1, "status": "VISIBLE" } }');
        HelpBuilder.SetResponseNote('an array of custom-field definition objects (each with `id`, `name`, `type`, `allowedValues`, `status`)');
        HelpBuilder.SetAfterSuccess('No tracking action required — this is a read operation. Use `id` as `customFieldId` in time-entry and project operations.');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Cloud Events Setup');
        HelpBuilder.SetNotes('- Field `type` values: `TXT`, `NUMBER`, `DROPDOWN_SINGLE`, `DROPDOWN_MULTIPLE`, `CHECKBOX`, `LINK`.\' +
            '- Use the `id` value as `customFieldId` in `Clockify.TimeEntry.Create/Update` and `Clockify.Project.Update` bodies.\' +
            '- For per-project enablement and defaults, send `customFieldId` inside the `customFields` array on `Clockify.Project.Update`.\' +
            '- This endpoint returns **workspace-level** definitions only. Project-scoped overrides (enabled/disabled, project-level defaults) surface inside `Clockify.Project.Get`.');
        HelpBuilder.SetRelated('- **Use on time entries:** `Clockify.TimeEntry.Create/Update` (body.customFields)\' +
            '- **Enable per project:** `Clockify.Project.Update` (body.customFields)\' +
            '- **See project overrides:** `Clockify.Project.Get` (response.customFields)');
        Argument.SetResponseMarkdown(HelpBuilder.Render());
    end;

    internal procedure ExecuteCloudEventTask(var Argument: Record "CE Message Argument ori")
    var
        RequestMgt: Codeunit "Clockify Request Mgt";
        RequestJson: JsonObject;
        WorkspaceId: Text;
    begin
        Argument.AssertVersion1();
        RequestJson := Argument.GetRequestJson();
        if not RequestMgt.ResolveWorkspaceId(Argument, RequestJson, WorkspaceId) then
            exit;
        RequestMgt.Execute(Argument, 'GET', RequestMgt.AppendQuery(RequestJson, '/workspaces/' + WorkspaceId + '/custom-fields'), false, '');
    end;
}
