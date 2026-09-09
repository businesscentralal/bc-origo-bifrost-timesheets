namespace Origo.Bifrost.Timesheets.Providers.Clockify;

using Origo.Bifrost;

/// <summary>
/// Implementation of the <c>Provider.Clockify.TimeEntry.List</c> message type.
/// Lists a user's time entries in a workspace. Use the <c>query</c> object for
/// Clockify filters such as <c>start</c>, <c>end</c>, <c>project</c>, <c>page</c>
/// and <c>page-size</c>.
/// </summary>
codeunit 10036820 "Clockify TEntryList Impl ori" implements "Msg Interface ori"
{
    Access = Internal;

    procedure IsEnabled(): Boolean
    var
        ClockifyIntegration: Record "Clockify Integration ori";
        SecretMgt: Codeunit "Clockify Secret Mgt ori";
    begin
        if not ClockifyIntegration.WritePermission() then
            exit(false);
        exit(SecretMgt.HasCompanyApiKey());
    end;

    procedure GetFilterTableNo(): Integer
    begin
        exit(0);
    end;

    procedure GetDescription(): Text[250]
    begin
        exit('Lists a user''s time entries in a Clockify workspace, with optional date/project filters via the query object.');
    end;

    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit(Enum::"Msg Direction ori"::Outbound);
    end;

    procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "Message Argument ori")
    var
        Help: Codeunit "Clockify TimeEntry Help ori";
    begin
        Argument.SetResponseMarkdown(Help.GetHelp(Enum::"Message Type ori"::"Provider.Clockify.TimeEntry.List", GetDescription()));
    end;

    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    var
        RequestMgt: Codeunit "Clockify Request Mgt ori";
        RequestJson: JsonObject;
        WorkspaceId: Text;
        UserId: Text;
    begin
        Argument.AssertVersion1();
        RequestJson := Argument.GetRequestJson();
        if not RequestMgt.ResolveWorkspaceId(Argument, RequestJson, WorkspaceId) then
            exit;
        if not RequestMgt.RequireParam(Argument, RequestJson, 'userId', UserId) then
            exit;
        RequestMgt.Execute(Argument, 'GET', RequestMgt.AppendQuery(RequestJson, '/workspaces/' + WorkspaceId + '/user/' + UserId + '/time-entries'), false, '');
    end;
}
