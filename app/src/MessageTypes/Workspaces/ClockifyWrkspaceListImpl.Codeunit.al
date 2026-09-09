namespace Origo.Bifrost.Timesheets;

using Origo.Bifrost;

/// <summary>
/// Implementation of the <c>Clockify.Workspace.List</c> message type.
/// Lists the Clockify workspaces the configured API key can access.
/// </summary>
codeunit 10036826 "Clockify WrkspaceList Impl ori" implements "Msg Interface ori"
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
        exit('Lists the Clockify workspaces the configured API key can access.');
    end;

    internal procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit(Enum::"Msg Direction ori"::Outbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "Message Argument ori")
    var
        Help: Codeunit "Clockify Workspace Help ori";
    begin
        Argument.SetResponseMarkdown(Help.GetHelp(Enum::"Message Type ori"::"Clockify.Workspace.List", GetDescription()));
    end;

    internal procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    var
        RequestMgt: Codeunit "Clockify Request Mgt ori";
    begin
        Argument.AssertVersion1();
        RequestMgt.Execute(Argument, 'GET', RequestMgt.AppendQuery(Argument.GetRequestJson(), '/workspaces'), false, '');
    end;
}
