namespace Origo.Bifrost.Timesheets;

using Origo.Bifrost;

/// <summary>
/// Implementation of the <c>Clockify.TimeEntry.Delete</c> message type.
/// Deletes a time entry by ID.
/// </summary>
codeunit 10036818 "Clockify TEntryDelete Impl ori" implements "Msg Interface ori"
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
        exit('Deletes a Clockify time entry by ID.');
    end;

    internal procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit(Enum::"Msg Direction ori"::Outbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "Message Argument ori")
    var
        Help: Codeunit "Clockify TimeEntry Help ori";
    begin
        Argument.SetResponseMarkdown(Help.GetHelp(Enum::"Message Type ori"::"Clockify.TimeEntry.Delete", GetDescription()));
    end;

    internal procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    var
        RequestMgt: Codeunit "Clockify Request Mgt ori";
        RequestJson: JsonObject;
        WorkspaceId: Text;
        TimeEntryId: Text;
    begin
        Argument.AssertVersion1();
        RequestJson := Argument.GetRequestJson();
        if not RequestMgt.ResolveWorkspaceId(Argument, RequestJson, WorkspaceId) then
            exit;
        if not RequestMgt.RequireParam(Argument, RequestJson, 'timeEntryId', TimeEntryId) then
            exit;
        RequestMgt.Execute(Argument, 'DELETE', '/workspaces/' + WorkspaceId + '/time-entries/' + TimeEntryId, false, '');
    end;
}
