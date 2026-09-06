namespace Origo.PTE.CloudEvents.Clockify;

using Origo.APP.CloudEvents;

/// <summary>
/// Adds the Clockify configuration pane and API-key management actions to the
/// <c>Cloud Events Setup</c> card. All action logic lives in <c>Clockify Setup Mgt</c>;
/// the page only reads key presence live via <c>Clockify Secret Mgt</c>.
/// </summary>
pageextension 70009200 "Clockify Setup Ext" extends "Cloud Events Setup ori"
{
    layout
    {
        addlast(content)
        {
            group(Clockify)
            {
                Caption = 'Clockify', Comment = 'is-IS=Clockify';

                field("Clockify API Version"; Rec."Clockify API Version")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies which Clockify API implementation the connector uses. Defaults to Version 1, which is fixed on the public Clockify v1 endpoint.', Comment = 'is-IS=Tilgreinir hvaða Clockify API útfærslu tengingin notar. Sjálfgefið er Útgáfa 1, sem er fest á almennu Clockify v1 slóðina.';
                }
                field("Clockify Default Workspace"; Rec."Clockify Default Workspace")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the default Clockify workspace ID used when a message request does not provide one. Use the lookup to pick a workspace by name from your Clockify account.', Comment = 'is-IS=Tilgreinir sjálfgefið Clockify vinnusvæði sem er notað þegar beiðni tilgreinir ekki vinnusvæði. Notaðu uppflettingu til að velja vinnusvæði eftir heiti úr Clockify aðganginum þínum.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        WorkspaceMgt: Codeunit "Clockify Workspace Mgt";
                        WorkspaceId: Text;
                        WorkspaceName: Text;
                    begin
                        if not WorkspaceMgt.LookupWorkspace(WorkspaceId, WorkspaceName) then
                            exit(false);
                        Text := WorkspaceId;
                        Rec."Clockify Workspace Name" := CopyStr(WorkspaceName, 1, MaxStrLen(Rec."Clockify Workspace Name"));
                        exit(true);
                    end;
                }
                field("Clockify Workspace Name"; Rec."Clockify Workspace Name")
                {
                    ApplicationArea = All;
                    Caption = 'Default Workspace', Comment = 'is-IS=Sjálfgefið vinnusvæði';
                    Editable = false;
                    ToolTip = 'Specifies the name of the selected default Clockify workspace.', Comment = 'is-IS=Tilgreinir heiti valins sjálfgefins Clockify vinnusvæðis.';
                }
                field("Clockify Job Jnl. Template"; Rec."Clockify Job Jnl. Template")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Job Journal template that synced Clockify time entries are written to, by both the sync message type and the real-time webhook handler.', Comment = 'is-IS=Tilgreinir verkbókarlýsinguna sem samstilltar Clockify tímafærslur eru skrifaðar í, bæði af samstillingarboðtegundinni og rauntíma vefkróknum.';
                }
                field("Clockify Job Jnl. Batch"; Rec."Clockify Job Jnl. Batch")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Job Journal batch that synced Clockify time entries are written to. Must belong to the selected template.', Comment = 'is-IS=Tilgreinir verkbókarflokkinn sem samstilltar Clockify tímafærslur eru skrifaðar í. Verður að tilheyra valinni lýsingu.';
                }
                field("Clockify Default Work Type"; Rec."Clockify Default Work Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Work Type used on a synced Job Journal Line when the Clockify time entry has no tag linked to a Work Type. A linked Clockify tag takes precedence over this value.', Comment = 'is-IS=Tilgreinir vinnutegundina sem notuð er á samstillta verkbókarlínu þegar Clockify tímafærsla hefur engan merkimiða tengdan vinnutegund. Tengdur Clockify merkimiði hefur forgang fram yfir þetta gildi.';
                }
                field(HasClockifyCompanyKey; ClockifyHasCompanyKey)
                {
                    ApplicationArea = All;
                    Caption = 'Company API Key Stored', Comment = 'is-IS=API lykill fyrirtækis geymdur';
                    Editable = false;
                    ToolTip = 'Specifies whether a company Clockify API key is stored. All connector calls authenticate with this key. Use the actions below to set or clear it.', Comment = 'is-IS=Tilgreinir hvort Clockify API lykill fyrirtækis sé geymdur. Allar tengingar nota þennan lykil. Notaðu aðgerðirnar hér að neðan til að breyta honum.';
                }
                field("Clockify Webhook Receiver URL"; Rec."Clockify Webhook Receiver URL")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the URL of the webhook receiver (Azure Function) that forwards Clockify events into Business Central, including the target company, for example https://my-site/api/clockify-webhooks?companyId={guid}. Required before registering webhooks.', Comment = 'is-IS=Tilgreinir slóð vefkróka móttakara (Azure Function) sem áframsendir Clockify atburði í Business Central, með marka fyrirtæki, t.d. https://min-sida/api/clockify-webhooks?companyId={guid}. Nauðsynlegt áður en vefkrókar eru skráðir.';
                }
                field(ClockifyWebhooksRegistered; ClockifyWebhooksRegistered)
                {
                    ApplicationArea = All;
                    Caption = 'Webhooks Registered', Comment = 'is-IS=Vefkrókar skráðir';
                    Editable = false;
                    ToolTip = 'Specifies whether real-time time-entry webhooks are registered in Clockify. Use the actions below to register or remove them.', Comment = 'is-IS=Tilgreinir hvort rauntíma vefkrókar fyrir tímafærslur séu skráðir í Clockify. Notaðu aðgerðirnar hér að neðan til að skrá þá eða fjarlægja.';
                }
            }
        }
    }

    actions
    {
        addlast(Navigation)
        {
            group(ClockifyActions)
            {
                Caption = 'Clockify', Comment = 'is-IS=Clockify';
                Image = Setup;

                action(ClockifySetCompanyApiKey)
                {
                    ApplicationArea = All;
                    Caption = 'Set Company API Key', Comment = 'is-IS=Skrá API lykil fyrirtækis';
                    ToolTip = 'Prompts for and stores the company-default Clockify API key.', Comment = 'is-IS=Biður um og geymir sjálfgefinn Clockify API lykil fyrirtækis.';
                    Image = Lock;

                    trigger OnAction()
                    var
                        SetupMgt: Codeunit "Clockify Setup Mgt";
                    begin
                        SetupMgt.PromptAndStoreCompanyApiKey();
                        CurrPage.Update(false);
                    end;
                }
                action(ClockifyClearCompanyApiKey)
                {
                    ApplicationArea = All;
                    Caption = 'Clear Company API Key', Comment = 'is-IS=Eyða API lykli fyrirtækis';
                    ToolTip = 'Removes the stored company-default Clockify API key.', Comment = 'is-IS=Fjarlægir geymdan Clockify API lykil fyrirtækis.';
                    Image = Delete;

                    trigger OnAction()
                    var
                        SetupMgt: Codeunit "Clockify Setup Mgt";
                    begin
                        SetupMgt.ConfirmAndClearCompanyApiKey();
                        CurrPage.Update(false);
                    end;
                }
                action(ClockifyIntegrationList)
                {
                    ApplicationArea = All;
                    Caption = 'Integration Links', Comment = 'is-IS=Clockify tengingar';
                    ToolTip = 'Opens the administrative view of the links between Business Central records and Clockify objects.', Comment = 'is-IS=Opnar stjórnunarsýn yfir tengingar milli BC færslna og Clockify hluta.';
                    Image = LinkWeb;
                    RunObject = page "Clockify Integration List";
                }
                action(ClockifyRegisterWebhooks)
                {
                    ApplicationArea = All;
                    Caption = 'Register Webhooks', Comment = 'is-IS=Skrá vefkróka';
                    ToolTip = 'Registers real-time time-entry webhooks in Clockify pointing at the webhook receiver, and shows the signing tokens to configure on the receiver.', Comment = 'is-IS=Skráir rauntíma vefkróka fyrir tímafærslur í Clockify sem vísa á móttakarann og sýnir undirritunarlykla til að stilla á móttakaranum.';
                    Image = Web;

                    trigger OnAction()
                    var
                        WebhookMgt: Codeunit "Clockify Webhook Mgt";
                    begin
                        WebhookMgt.RegisterTimeEntryWebhooks();
                        CurrPage.Update(false);
                    end;
                }
                action(ClockifyRemoveWebhooks)
                {
                    ApplicationArea = All;
                    Caption = 'Remove Webhooks', Comment = 'is-IS=Fjarlægja vefkróka';
                    ToolTip = 'Removes the registered Clockify time-entry webhooks.', Comment = 'is-IS=Fjarlægir skráða Clockify vefkróka fyrir tímafærslur.';
                    Image = RemoveLine;

                    trigger OnAction()
                    var
                        WebhookMgt: Codeunit "Clockify Webhook Mgt";
                    begin
                        WebhookMgt.RemoveTimeEntryWebhooks();
                        CurrPage.Update(false);
                    end;
                }
                action(ClockifyShowWebhookTokens)
                {
                    ApplicationArea = All;
                    Caption = 'Show Signing Tokens', Comment = 'is-IS=Sýna undirritunarlykla';
                    ToolTip = 'Re-fetches the signing tokens of the registered webhooks from Clockify so they can be configured on the webhook receiver.', Comment = 'is-IS=Sækir undirritunarlykla skráðra vefkróka aftur frá Clockify svo hægt sé að stilla þá á móttakaranum.';
                    Image = EncryptionKeys;

                    trigger OnAction()
                    var
                        WebhookMgt: Codeunit "Clockify Webhook Mgt";
                    begin
                        WebhookMgt.ShowSigningTokens();
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        SecretMgt: Codeunit "Clockify Secret Mgt";
        WebhookMgt: Codeunit "Clockify Webhook Mgt";
    begin
        ClockifyHasCompanyKey := SecretMgt.HasCompanyApiKey();
        ClockifyWebhooksRegistered := WebhookMgt.HasRegisteredWebhooks();
    end;

    var
        ClockifyHasCompanyKey: Boolean;
        ClockifyWebhooksRegistered: Boolean;
}
