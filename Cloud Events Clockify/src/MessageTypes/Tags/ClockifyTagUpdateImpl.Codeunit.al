namespace Origo.PTE.CloudEvents.Clockify;

using Origo.APP.CloudEvents;

/// <summary>
/// Implementation of the <c>Clockify.Tag.Update</c> message type.
/// Updates an existing tag from the request's <c>body</c> object.
/// </summary>
codeunit 70009227 "Clockify Tag Update Impl" implements "Cloud Event Msg Interface ori"
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
        exit('Updates an existing Clockify tag from the request body.');
    end;

    internal procedure GetMessageDirection(): Enum "Cloud Event Msg Direction ori"
    begin
        exit(Enum::"Cloud Event Msg Direction ori"::Outbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "CE Message Argument ori")
    var
        HelpBuilder: Codeunit "Clockify Help Builder";
    begin
        HelpBuilder.Init('Clockify.Tag.Update', GetDescription(), 'PUT', '/workspaces/{workspaceId}/tags/{tagId}');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Clockify.Workspace.List → id');
        HelpBuilder.AddParam('tagId', true, 'string', 'The tag ID to update', 'Clockify.Tag.List → id');
        HelpBuilder.AddParam('body.name', false, 'string', 'Tag display name', '');
        HelpBuilder.AddParam('body.archived', false, 'boolean', 'Set true to archive, false to unarchive', '');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "tagId": "62...", "body": { "name": "Non-billable", "archived": false } }');
        HelpBuilder.SetResponseNote('the updated tag object');
        HelpBuilder.AddError(400, 'Tag name already exists', 'Choose a different name');
        HelpBuilder.AddError(404, 'Tag not found', 'Verify tagId via `Clockify.Tag.List`');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Cloud Events Setup');
        HelpBuilder.SetNotes('- Send only fields you want to change; omitted fields retain current values.\' +
            '- Unlike clients/projects, archiving a tag is NOT required before `Clockify.Tag.Delete`.');
        HelpBuilder.SetRelated('- **Resolve tagId:** `Clockify.Tag.List` or Clockify Integration (type=tag)\' +
            '- **Delete tag:** `Clockify.Tag.Delete` (no archive step needed)');
        Argument.SetResponseMarkdown(HelpBuilder.Render());
    end;

    internal procedure ExecuteCloudEventTask(var Argument: Record "CE Message Argument ori")
    var
        RequestMgt: Codeunit "Clockify Request Mgt";
        RequestJson: JsonObject;
        WorkspaceId: Text;
        TagId: Text;
        BodyText: Text;
    begin
        Argument.AssertVersion1();
        RequestJson := Argument.GetRequestJson();
        if not RequestMgt.ResolveWorkspaceId(Argument, RequestJson, WorkspaceId) then
            exit;
        if not RequestMgt.RequireParam(Argument, RequestJson, 'tagId', TagId) then
            exit;
        if not RequestMgt.RequireBody(Argument, RequestJson, BodyText) then
            exit;
        RequestMgt.Execute(Argument, 'PUT', '/workspaces/' + WorkspaceId + '/tags/' + TagId, true, BodyText);
    end;
}
