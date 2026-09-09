namespace Origo.Bifrost.Timesheets.Providers.Clockify;

using Origo.Bifrost;

/// <summary>
/// Implementation of the <c>Provider.Clockify.UserGroup.List</c> message type.
/// Lists the user groups defined in a Clockify workspace. The Clockify internal
/// <c>id</c> returned here is the value that must be sent as a member of
/// <c>userGroupIds</c> in the body of <c>Provider.Clockify.Project.Create</c> /
/// <c>Provider.Clockify.Project.Update</c> (project access and default assignees) and in
/// task assignment writes. Group names are not accepted on those write paths.
/// </summary>
codeunit 10036823 "Clockify UserGrpList Impl ori" implements "Msg Interface ori"
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
        exit('Lists the user groups defined in a Clockify workspace.');
    end;

    internal procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit(Enum::"Msg Direction ori"::Outbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "Message Argument ori")
    var
        Help: Codeunit "Clockify Workspace Help ori";
    begin
        Argument.SetResponseMarkdown(Help.GetHelp(Enum::"Message Type ori"::"Provider.Clockify.UserGroup.List", GetDescription()));
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
        RequestMgt.Execute(Argument, 'GET', RequestMgt.AppendQuery(RequestJson, '/workspaces/' + WorkspaceId + '/user-groups'), false, '');
    end;
}
