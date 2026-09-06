namespace Origo.PTE.CloudEvents.Clockify;

using Origo.APP.CloudEvents;

/// <summary>
/// Implementation of the <c>Clockify.User.GetCurrent</c> message type.
/// Returns the currently authenticated Clockify user (use its <c>id</c> as
/// <c>userId</c> for time-entry operations).
/// </summary>
codeunit 70009239 "Clockify User Current Impl" implements "Cloud Event Msg Interface ori"
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
        exit('Returns the currently authenticated Clockify user. Use its id as userId for time-entry operations.');
    end;

    internal procedure GetMessageDirection(): Enum "Cloud Event Msg Direction ori"
    begin
        exit(Enum::"Cloud Event Msg Direction ori"::Outbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "CE Message Argument ori")
    var
        HelpBuilder: Codeunit "Clockify Help Builder";
    begin
        HelpBuilder.Init('Clockify.User.GetCurrent', GetDescription(), 'GET', '/user');
        HelpBuilder.SetRequestExample('{ }');
        HelpBuilder.SetResponseNote('the authenticated user object (includes `id`, `name`, `email`, `activeWorkspace`, `defaultWorkspace`)');
        HelpBuilder.SetAfterSuccess('No tracking action required — this is a read operation. Use the returned `id` as `userId` in time-entry operations.');
        HelpBuilder.AddError(401, 'Unauthorized', 'Check API key on Cloud Events Setup');
        HelpBuilder.SetNotes('- No parameters needed — returns the user who owns the API key.\' +
            '- The `id` field is the `userId` required by `Clockify.TimeEntry.Create`, `Clockify.TimeEntry.List`, etc.\' +
            '- `activeWorkspace` is the user''s currently selected workspace ID.');
        HelpBuilder.SetRelated('- **List all users in workspace:** `Clockify.User.List`\' +
            '- **Use userId for time entries:** `Clockify.TimeEntry.Create`, `Clockify.TimeEntry.List`');
        Argument.SetResponseMarkdown(HelpBuilder.Render());
    end;

    internal procedure ExecuteCloudEventTask(var Argument: Record "CE Message Argument ori")
    var
        RequestMgt: Codeunit "Clockify Request Mgt";
    begin
        Argument.AssertVersion1();
        RequestMgt.Execute(Argument, 'GET', '/user', false, '');
    end;
}
