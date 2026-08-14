namespace Origo.PTE.CloudEvents.Clockify;

using Origo.APP.CloudEvents;

/// <summary>
/// Drives the Clockify actions on the <c>Cloud Events Setup</c> card. Prompts for
/// the API key via <see cref="Page.ClockifySetSecretDialog"/> and delegates storage
/// to <c>Clockify Secret Mgt</c>. Keeps all UI flow out of the page extension.
/// Also resolves the Job Journal target that synced time entries are written to.
/// </summary>
codeunit 71404 "Clockify Setup Mgt"
{
    Access = Internal;

    var
        EmptyKeyErr: Label 'No API key was entered.', Comment = 'is-IS=Enginn API lykill var sleginn inn.';
        ClearCompanyQst: Label 'Remove the stored company Clockify API key?', Comment = 'is-IS=Fjarlægja geymdan Clockify API lykil fyrirtækis?';

    /// <summary>Prompts for and stores the company Clockify API key.</summary>
    procedure PromptAndStoreCompanyApiKey()
    var
        SecretMgt: Codeunit "Clockify Secret Mgt";
        Dialog: Page "Clockify Set Secret Dialog";
        KeyText: Text;
    begin
        if Dialog.RunModal() <> Action::OK then
            exit;
        KeyText := Dialog.GetSecret();
        if KeyText = '' then
            Error(EmptyKeyErr);
        SecretMgt.SetCompanyApiKey(KeyText);
    end;

    /// <summary>Confirms and clears the stored company API key.</summary>
    procedure ConfirmAndClearCompanyApiKey()
    var
        SecretMgt: Codeunit "Clockify Secret Mgt";
    begin
        if not Confirm(ClearCompanyQst, false) then
            exit;
        SecretMgt.ClearCompanyApiKey();
    end;

    /// <summary>
    /// Resolves the configured Job Journal target for synced Clockify time entries.
    /// </summary>
    /// <param name="JournalTemplate">Out: the configured Job Journal template (blank when unset).</param>
    /// <param name="JournalBatch">Out: the configured Job Journal batch (blank when unset).</param>
    /// <returns>True when both a template and a batch are configured on Cloud Events Setup.</returns>
    procedure TryGetJobJournal(var JournalTemplate: Code[10]; var JournalBatch: Code[10]): Boolean
    var
        CloudEventsSetup: Record "Cloud Events Setup ori";
    begin
        JournalTemplate := '';
        JournalBatch := '';
        if not CloudEventsSetup.Get() then
            exit(false);
        JournalTemplate := CloudEventsSetup."Clockify Job Jnl. Template";
        JournalBatch := CloudEventsSetup."Clockify Job Jnl. Batch";
        exit((JournalTemplate <> '') and (JournalBatch <> ''));
    end;

    /// <summary>Returns the fallback Work Type configured on Cloud Events Setup, or blank.</summary>
    procedure GetDefaultWorkType(): Code[10]
    var
        CloudEventsSetup: Record "Cloud Events Setup ori";
    begin
        if not CloudEventsSetup.Get() then
            exit('');
        exit(CloudEventsSetup."Clockify Default Work Type");
    end;
}
