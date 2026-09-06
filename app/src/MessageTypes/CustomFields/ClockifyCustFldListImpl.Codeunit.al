namespace Origo.Bifrost.Clockify;

using Origo.Bifrost;

/// <summary>
/// Implementation of the <c>Clockify.CustomField.List</c> message type.
/// Lists the workspace-level custom field definitions. The Clockify internal
/// <c>id</c> returned here is the value that must be sent as
/// <c>customFieldId</c> in the body of <c>Clockify.TimeEntry.Create</c> /
/// <c>Clockify.TimeEntry.Update</c> and in <c>customFields</c> entries on
/// <c>Clockify.Project.Update</c>. Custom-field <c>name</c> values are not
/// accepted on those write paths.
/// </summary>
codeunit 70009216 "Clockify CustFldList Impl ori" implements "Msg Interface ori"
{
    Access = Internal;

    internal procedure IsEnabled(): Boolean
    var
        ClockifyIntegration: Record "Clockify Integration ori";
        SecretMgt: Codeunit "Clockify Secret Mgt ori";
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

    internal procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit(Enum::"Msg Direction ori"::Outbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "Message Argument ori")
    var
        Help: Codeunit "Clockify Workspace Help ori";
    begin
        Argument.SetResponseMarkdown(Help.GetHelp(Enum::"Message Type ori"::"Clockify.CustomField.List", GetDescription()));
    end;

    internal procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    var
        RequestMgt: Codeunit "Clockify Request Mgt ori";
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
