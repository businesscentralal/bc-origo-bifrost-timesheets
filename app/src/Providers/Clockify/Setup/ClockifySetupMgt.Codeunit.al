namespace Origo.Bifrost.Timesheets.Providers.Clockify;

using Origo.Bifrost;

/// <summary>
/// Drives the Clockify actions on the <c>Clockify Setup</c> card. Prompts for
/// the API key via <see cref="Page.ClockifySetSecretDialog"/> and delegates storage
/// to <c>Clockify Secret Mgt ori</c>. Keeps all UI flow out of the page extension.
/// Also resolves the Job Journal target that synced time entries are written to.
/// </summary>
codeunit 10036829 "Clockify Setup Mgt ori"
{
    Access = Internal;

    var
        EmptyKeyErr: Label 'No API key was entered.', Comment = 'is-IS=Enginn API lykill var sleginn inn.';
        ClearCompanyQst: Label 'Remove the stored company Clockify API key?', Comment = 'is-IS=Fjarlægja geymdan Clockify API lykil fyrirtækis?';

    /// <summary>Prompts for and stores the company Clockify API key.</summary>
    procedure PromptAndStoreCompanyApiKey()
    var
        SecretMgt: Codeunit "Clockify Secret Mgt ori";
        Dialog: Page "Clockify Set Secret Dialog ori";
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
        SecretMgt: Codeunit "Clockify Secret Mgt ori";
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
    /// <returns>True when both a template and a batch are configured on Clockify Setup.</returns>
    procedure TryGetJobJournal(var JournalTemplate: Code[10]; var JournalBatch: Code[10]): Boolean
    var
        ClockifySetup: Record "Clockify Setup ori";
    begin
        JournalTemplate := '';
        JournalBatch := '';
        if not ClockifySetup.Get() then
            exit(false);
        JournalTemplate := ClockifySetup."Job Jnl. Template";
        JournalBatch := ClockifySetup."Job Jnl. Batch";
        exit((JournalTemplate <> '') and (JournalBatch <> ''));
    end;

    /// <summary>Returns the fallback Work Type configured on Clockify Setup, or blank.</summary>
    procedure GetDefaultWorkType(): Code[10]
    var
        ClockifySetup: Record "Clockify Setup ori";
    begin
        if not ClockifySetup.Get() then
            exit('');
        exit(ClockifySetup."Default Work Type");
    end;
}
