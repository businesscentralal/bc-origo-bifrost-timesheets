namespace Origo.PTE.CloudEvents.Clockify;

using Origo.APP.CloudEvents;

/// <summary>
/// Implementation of the <c>Clockify.Tag.Delete</c> message type.
/// Deletes a tag by ID.
/// </summary>
codeunit 71441 "Clockify Tag Delete Impl" implements "Cloud Event Msg Interface ori"
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
        exit('Deletes a Clockify tag by ID.');
    end;

    internal procedure GetMessageDirection(): Enum "Cloud Event Msg Direction ori"
    begin
        exit(Enum::"Cloud Event Msg Direction ori"::Outbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "CE Message Argument ori")
    var
        HelpBuilder: Codeunit "Clockify Help Builder";
    begin
        HelpBuilder.Init('Clockify.Tag.Delete', GetDescription(), 'DELETE', '/workspaces/{workspaceId}/tags/{tagId}');
        HelpBuilder.AddParam('workspaceId', true, 'string', 'Target workspace ID', 'Clockify.Workspace.List → id');
        HelpBuilder.AddParam('tagId', true, 'string', 'The tag ID to delete', 'Clockify.Tag.List → id');
        HelpBuilder.SetRequestExample('{ "workspaceId": "5f...", "tagId": "62..." }');
        HelpBuilder.SetResponseNote('the deleted tag object');
        HelpBuilder.AddError(404, 'Tag not found', 'Verify tagId via `Clockify.Tag.List`');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Cloud Events Setup');
        HelpBuilder.SetNotes('- Unlike clients and projects, tags do NOT require archiving before delete.\' +
            '- Time entries referencing this tag retain their data but the tag link becomes orphaned.');
        HelpBuilder.SetRelated('- **Alternative to delete:** Archive via `Clockify.Tag.Update` with `{ "archived": true }`\' +
            '- **After delete:** `Data.Records.Set` on Clockify Integration → `Reversed` = true');
        Argument.SetResponseMarkdown(HelpBuilder.Render());
    end;

    internal procedure ExecuteCloudEventTask(var Argument: Record "CE Message Argument ori")
    var
        RequestMgt: Codeunit "Clockify Request Mgt";
        RequestJson: JsonObject;
        WorkspaceId: Text;
        TagId: Text;
    begin
        Argument.AssertVersion1();
        RequestJson := Argument.GetRequestJson();
        if not RequestMgt.ResolveWorkspaceId(Argument, RequestJson, WorkspaceId) then
            exit;
        if not RequestMgt.RequireParam(Argument, RequestJson, 'tagId', TagId) then
            exit;
        RequestMgt.Execute(Argument, 'DELETE', '/workspaces/' + WorkspaceId + '/tags/' + TagId, false, '');
    end;
}
