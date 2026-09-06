namespace Origo.PTE.CloudEvents.Clockify;

using Origo.APP.CloudEvents;

/// <summary>
/// Implementation of the <c>Clockify.Tag.Create</c> message type.
/// Creates a tag in a workspace from the request's <c>body</c> object.
/// </summary>
codeunit 70009224 "Clockify Tag Create Impl" implements "Cloud Event Msg Interface ori"
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
        exit('Creates a tag in a Clockify workspace from the request body.');
    end;

    internal procedure GetMessageDirection(): Enum "Cloud Event Msg Direction ori"
    begin
        exit(Enum::"Cloud Event Msg Direction ori"::Outbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "CE Message Argument ori")
    var
        HelpBuilder: Codeunit "Clockify Help Builder";
    begin
        HelpBuilder.Init('Clockify.Tag.Create', GetDescription(), 'POST', '/workspaces/{workspaceId}/tags');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Clockify.Workspace.List → id');
        HelpBuilder.AddParam('body.name', true, 'string', 'Tag display name (must be unique in workspace)', '');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "body": { "name": "Billable" } }');
        HelpBuilder.SetResponseNote('the created tag object (includes `id`, `name`, `workspaceId`)');
        HelpBuilder.AddError(400, 'Tag name already exists', 'Use `Clockify.Tag.List` to find existing tag');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Cloud Events Setup');
        HelpBuilder.SetNotes('- Tags are workspace-scoped (not project-scoped). One tag can be used across all projects.\' +
            '- Use tag `id` (not name) when attaching to time entries via `tagIds` array.');
        HelpBuilder.SetRelated('- **List existing tags:** `Clockify.Tag.List`\' +
            '- **Use in time entries:** Pass tag `id` in `tagIds` array of `Clockify.TimeEntry.Create`/`Update`\' +
            '- **Delete later:** `Clockify.Tag.Delete` (no archive step needed)');
        Argument.SetResponseMarkdown(HelpBuilder.Render());
    end;

    internal procedure ExecuteCloudEventTask(var Argument: Record "CE Message Argument ori")
    var
        RequestMgt: Codeunit "Clockify Request Mgt";
        RequestJson: JsonObject;
        WorkspaceId: Text;
        BodyText: Text;
    begin
        Argument.AssertVersion1();
        RequestJson := Argument.GetRequestJson();
        if not RequestMgt.ResolveWorkspaceId(Argument, RequestJson, WorkspaceId) then
            exit;
        if not RequestMgt.RequireBody(Argument, RequestJson, BodyText) then
            exit;
        RequestMgt.Execute(Argument, 'POST', '/workspaces/' + WorkspaceId + '/tags', true, BodyText);
    end;
}
