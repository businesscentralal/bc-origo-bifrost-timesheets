namespace Origo.Bifrost.Timesheets;

using Origo.Bifrost;

/// <summary>
/// Implementation of the <c>Clockify.Task.Update</c> message type.
/// Updates an existing task from the request's <c>body</c> object.
/// </summary>
codeunit 10036816 "Clockify Task Update Impl ori" implements "Msg Interface ori"
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
        exit('Updates an existing Clockify task from the request body.');
    end;

    internal procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit(Enum::"Msg Direction ori"::Outbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "Message Argument ori")
    var
        Help: Codeunit "Clockify Task Help ori";
    begin
        Argument.SetResponseMarkdown(Help.GetHelp(Enum::"Message Type ori"::"Clockify.Task.Update", GetDescription()));
    end;

    internal procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    var
        RequestMgt: Codeunit "Clockify Request Mgt ori";
        RequestJson: JsonObject;
        WorkspaceId: Text;
        ProjectId: Text;
        TaskId: Text;
        BodyText: Text;
    begin
        Argument.AssertVersion1();
        RequestJson := Argument.GetRequestJson();
        if not RequestMgt.ResolveWorkspaceId(Argument, RequestJson, WorkspaceId) then
            exit;
        if not RequestMgt.RequireParam(Argument, RequestJson, 'projectId', ProjectId) then
            exit;
        if not RequestMgt.RequireParam(Argument, RequestJson, 'taskId', TaskId) then
            exit;
        if not RequestMgt.RequireBody(Argument, RequestJson, BodyText) then
            exit;
        RequestMgt.Execute(Argument, 'PUT', '/workspaces/' + WorkspaceId + '/projects/' + ProjectId + '/tasks/' + TaskId, true, BodyText);
    end;
}
