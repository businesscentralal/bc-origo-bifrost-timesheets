namespace Origo.Bifrost.Timesheets;

/// <summary>
/// Modal dialog that prompts for the Clockify API key without echoing keystrokes.
/// The calling page reads the entered value via <see cref="GetSecret"/> and passes
/// it to <c>Clockify Secret Mgt ori</c>.
/// </summary>
page 70009201 "Clockify Set Secret Dialog ori"
{
    PageType = StandardDialog;
    Caption = 'Enter Clockify API Key', Comment = 'is-IS=Slá inn Clockify API lykil';
    ApplicationArea = All;
    ContextSensitiveHelpPage = 'clockify-set-secret-dialog';
    UsageCategory = None;

    layout
    {
        area(content)
        {
            group(PromptGroup)
            {
                ShowCaption = false;
                InstructionalText = 'Paste your Clockify API key (Profile Settings > API in Clockify), then click OK.', Comment = 'is-IS=Límdu inn Clockify API lykilinn (Profile Settings > API í Clockify) og smelltu á Í lagi.';

                field(SecretInput; SecretInput)
                {
                    ApplicationArea = All;
                    Caption = 'API Key', Comment = 'is-IS=API lykill';
                    ExtendedDatatype = Masked;
                    ToolTip = 'Specifies the Clockify API key to store. The value is masked while you type.', Comment = 'is-IS=Tilgreinir Clockify API lykilinn sem á að geyma. Gildið er falið meðan þú slærð það inn.';
                }
            }
        }
    }

    var
        SecretInput: Text;

    /// <summary>Returns the value the user entered.</summary>
    procedure GetSecret(): Text
    begin
        exit(SecretInput);
    end;
}
