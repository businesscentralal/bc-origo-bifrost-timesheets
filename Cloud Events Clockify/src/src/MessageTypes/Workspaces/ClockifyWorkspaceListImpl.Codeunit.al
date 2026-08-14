namespace Origo.PTE.CloudEvents.Clockify;

using Origo.APP.CloudEvents;

/// <summary>
/// Implementation of the <c>Clockify.Workspace.List</c> message type.
/// Lists the Clockify workspaces the configured API key can access.
/// </summary>
codeunit 71421 "Clockify Workspace List Impl" implements "Cloud Event Msg Interface ori"
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
        exit('Lists the Clockify workspaces the configured API key can access.');
    end;

    internal procedure GetMessageDirection(): Enum "Cloud Event Msg Direction ori"
    begin
        exit(Enum::"Cloud Event Msg Direction ori"::Outbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "CE Message Argument ori")
    var
        HelpBuilder: Codeunit "Clockify Help Builder";
    begin
        HelpBuilder.Init('Clockify.Workspace.List', GetDescription(), 'GET', '/workspaces');
        HelpBuilder.SetRequestExample('{ }');
        HelpBuilder.SetResponseNote('an array of workspace objects (each with `id`, `name`, `memberships`)');
        HelpBuilder.SetAfterSuccess('No tracking action required — this is a read operation. Use the returned `id` as `workspaceId` in all other Clockify calls.');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Cloud Events Setup');
        HelpBuilder.SetNotes('- No parameters needed — returns all workspaces accessible by the API key.\' +
            '- Most Clockify operations require a `workspaceId`. Call this first to resolve it.\' +
            '- The Cloud Events Setup stores a default workspace; this call is only needed to discover alternatives or verify the configured one.');
        HelpBuilder.SetRelated('- **Get current user:** `Clockify.User.GetCurrent` (also returns `activeWorkspace`)\' +
            '- **All other operations:** Pass workspace `id` as `workspaceId` parameter');
        Argument.SetResponseMarkdown(HelpBuilder.Render());
    end;

    internal procedure ExecuteCloudEventTask(var Argument: Record "CE Message Argument ori")
    var
        RequestMgt: Codeunit "Clockify Request Mgt";
    begin
        Argument.AssertVersion1();
        RequestMgt.Execute(Argument, 'GET', RequestMgt.AppendQuery(Argument.GetRequestJson(), '/workspaces'), false, '');
    end;
}
