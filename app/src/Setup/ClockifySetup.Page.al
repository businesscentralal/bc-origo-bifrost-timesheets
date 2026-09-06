namespace Origo.Bifrost.Clockify;

/// <summary>
/// Setup card for the Bifrost Clockify connector. Holds every Clockify setting and
/// the API-key, webhook and integration-link actions, so nothing has to be added to
/// Bifröst Foundation's own setup card. All action logic lives in
/// <c>Clockify Setup Mgt ori</c> and <c>Clockify Webhook Mgt ori</c>; the page only
/// reads API-key and webhook presence live.
/// </summary>
page 70009268 "Clockify Setup ori"
{
    AdditionalSearchTerms = 'Clockify,Time Tracking,Time Entry', Comment = 'is-IS=Clockify,Tímaskráning,Tímafærsla';
    ApplicationArea = All;
    Caption = 'Clockify Setup', Comment = 'is-IS=Uppsetning Clockify';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    ShowFilter = false;
    SourceTable = "Clockify Setup ori";
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General', Comment = 'is-IS=Almennt';

                field("API Version"; Rec."API Version")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies which Clockify API implementation the connector uses. Defaults to Version 1, which is fixed on the public Clockify v1 endpoint.', Comment = 'is-IS=Tilgreinir hvaða Clockify API útfærslu tengingin notar. Sjálfgefið er Útgáfa 1, sem er fest á almennu Clockify v1 slóðina.';
                }
                field("Default Workspace"; Rec."Default Workspace")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the default Clockify workspace ID used when a message request does not provide one. Use the lookup to pick a workspace by name from your Clockify account.', Comment = 'is-IS=Tilgreinir sjálfgefið Clockify vinnusvæði sem er notað þegar beiðni tilgreinir ekki vinnusvæði. Notaðu uppflettingu til að velja vinnusvæði eftir heiti úr Clockify aðganginum þínum.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        WorkspaceMgt: Codeunit "Clockify Workspace Mgt ori";
                        WorkspaceId: Text;
                        WorkspaceName: Text;
                    begin
                        if not WorkspaceMgt.LookupWorkspace(WorkspaceId, WorkspaceName) then
                            exit(false);
                        Text := WorkspaceId;
                        Rec."Workspace Name" := CopyStr(WorkspaceName, 1, MaxStrLen(Rec."Workspace Name"));
                        exit(true);
                    end;
                }
                field("Workspace Name"; Rec."Workspace Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the name of the selected default Clockify workspace.', Comment = 'is-IS=Tilgreinir heiti valins sjálfgefins Clockify vinnusvæðis.';
                }
                field(HasCompanyKey; ClockifyHasCompanyKey)
                {
                    ApplicationArea = All;
                    Caption = 'Company API Key Stored', Comment = 'is-IS=API lykill fyrirtækis geymdur';
                    Editable = false;
                    ToolTip = 'Specifies whether a company Clockify API key is stored. All connector calls authenticate with this key. Use the actions to set or clear it.', Comment = 'is-IS=Tilgreinir hvort Clockify API lykill fyrirtækis sé geymdur. Allar tengingar nota þennan lykil. Notaðu aðgerðirnar til að breyta honum.';
                }
            }

            group(JobJournal)
            {
                Caption = 'Job Journal', Comment = 'is-IS=Verkbók';

                field("Job Jnl. Template"; Rec."Job Jnl. Template")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Job Journal template that synced Clockify time entries are written to, by both the sync message type and the real-time webhook handler.', Comment = 'is-IS=Tilgreinir verkbókarlýsinguna sem samstilltar Clockify tímafærslur eru skrifaðar í, bæði af samstillingarboðtegundinni og rauntíma vefkróknum.';
                }
                field("Job Jnl. Batch"; Rec."Job Jnl. Batch")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Job Journal batch that synced Clockify time entries are written to. Must belong to the selected template.', Comment = 'is-IS=Tilgreinir verkbókarflokkinn sem samstilltar Clockify tímafærslur eru skrifaðar í. Verður að tilheyra valinni lýsingu.';
                }
                field("Default Work Type"; Rec."Default Work Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Work Type used on a synced Job Journal Line when the Clockify time entry has no tag linked to a Work Type. A linked Clockify tag takes precedence over this value.', Comment = 'is-IS=Tilgreinir vinnutegundina sem notuð er á samstillta verkbókarlínu þegar Clockify tímafærsla hefur engan merkimiða tengdan vinnutegund. Tengdur Clockify merkimiði hefur forgang fram yfir þetta gildi.';
                }
            }

            group(Webhooks)
            {
                Caption = 'Webhooks', Comment = 'is-IS=Vefkrókar';

                field("Webhook Receiver URL"; Rec."Webhook Receiver URL")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the URL of the webhook receiver that forwards Clockify events into Business Central, including the target company. Required before registering webhooks.', Comment = 'is-IS=Tilgreinir slóð vefkróka móttakara sem áframsendir Clockify atburði í Business Central, með marka fyrirtæki. Nauðsynlegt áður en vefkrókar eru skráðir.';
                }
                field(WebhooksRegistered; ClockifyWebhooksRegistered)
                {
                    ApplicationArea = All;
                    Caption = 'Webhooks Registered', Comment = 'is-IS=Vefkrókar skráðir';
                    Editable = false;
                    ToolTip = 'Specifies whether real-time time-entry webhooks are registered in Clockify. Use the actions to register or remove them.', Comment = 'is-IS=Tilgreinir hvort rauntíma vefkrókar fyrir tímafærslur séu skráðir í Clockify. Notaðu aðgerðirnar til að skrá þá eða fjarlægja.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            group(ApiKey)
            {
                Caption = 'API Key', Comment = 'is-IS=API lykill';
                Image = EncryptionKeys;

                action(SetCompanyApiKey)
                {
                    ApplicationArea = All;
                    Caption = 'Set Company API Key', Comment = 'is-IS=Skrá API lykil fyrirtækis';
                    Image = Lock;
                    ToolTip = 'Prompts for and stores the company-default Clockify API key.', Comment = 'is-IS=Biður um og geymir sjálfgefinn Clockify API lykil fyrirtækis.';

                    trigger OnAction()
                    var
                        SetupMgt: Codeunit "Clockify Setup Mgt ori";
                    begin
                        SetupMgt.PromptAndStoreCompanyApiKey();
                        CurrPage.Update(false);
                    end;
                }
                action(ClearCompanyApiKey)
                {
                    ApplicationArea = All;
                    Caption = 'Clear Company API Key', Comment = 'is-IS=Eyða API lykli fyrirtækis';
                    Image = Delete;
                    ToolTip = 'Removes the stored company-default Clockify API key.', Comment = 'is-IS=Fjarlægir geymdan Clockify API lykil fyrirtækis.';

                    trigger OnAction()
                    var
                        SetupMgt: Codeunit "Clockify Setup Mgt ori";
                    begin
                        SetupMgt.ConfirmAndClearCompanyApiKey();
                        CurrPage.Update(false);
                    end;
                }
            }
            group(WebhookActions)
            {
                Caption = 'Webhooks', Comment = 'is-IS=Vefkrókar';
                Image = Web;

                action(RegisterWebhooks)
                {
                    ApplicationArea = All;
                    Caption = 'Register Webhooks', Comment = 'is-IS=Skrá vefkróka';
                    Image = Web;
                    ToolTip = 'Registers real-time time-entry webhooks in Clockify pointing at the webhook receiver, and shows the signing tokens to configure on the receiver.', Comment = 'is-IS=Skráir rauntíma vefkróka fyrir tímafærslur í Clockify sem vísa á móttakarann og sýnir undirritunarlykla til að stilla á móttakaranum.';

                    trigger OnAction()
                    var
                        WebhookMgt: Codeunit "Clockify Webhook Mgt ori";
                    begin
                        WebhookMgt.RegisterTimeEntryWebhooks();
                        CurrPage.Update(false);
                    end;
                }
                action(RemoveWebhooks)
                {
                    ApplicationArea = All;
                    Caption = 'Remove Webhooks', Comment = 'is-IS=Fjarlægja vefkróka';
                    Image = RemoveLine;
                    ToolTip = 'Removes the registered Clockify time-entry webhooks.', Comment = 'is-IS=Fjarlægir skráða Clockify vefkróka fyrir tímafærslur.';

                    trigger OnAction()
                    var
                        WebhookMgt: Codeunit "Clockify Webhook Mgt ori";
                    begin
                        WebhookMgt.RemoveTimeEntryWebhooks();
                        CurrPage.Update(false);
                    end;
                }
                action(ShowWebhookTokens)
                {
                    ApplicationArea = All;
                    Caption = 'Show Signing Tokens', Comment = 'is-IS=Sýna undirritunarlykla';
                    Image = EncryptionKeys;
                    ToolTip = 'Re-fetches the signing tokens of the registered webhooks from Clockify so they can be configured on the webhook receiver.', Comment = 'is-IS=Sækir undirritunarlykla skráðra vefkróka aftur frá Clockify svo hægt sé að stilla þá á móttakaranum.';

                    trigger OnAction()
                    var
                        WebhookMgt: Codeunit "Clockify Webhook Mgt ori";
                    begin
                        WebhookMgt.ShowSigningTokens();
                    end;
                }
            }
        }
        area(Navigation)
        {
            action(IntegrationList)
            {
                ApplicationArea = All;
                Caption = 'Integration Links', Comment = 'is-IS=Clockify tengingar';
                Image = LinkWeb;
                RunObject = page "Clockify Integration List ori";
                ToolTip = 'Opens the administrative view of the links between Business Central records and Clockify objects.', Comment = 'is-IS=Opnar stjórnunarsýn yfir tengingar milli BC færslna og Clockify hluta.';
            }
            action(RegisteredWebhooks)
            {
                ApplicationArea = All;
                Caption = 'Registered Webhooks', Comment = 'is-IS=Skráðir vefkrókar';
                Image = Web;
                RunObject = page "Clockify Webhooks ori";
                ToolTip = 'Opens the list of Clockify webhooks registered from this company.', Comment = 'is-IS=Opnar lista yfir Clockify vefkróka sem eru skráðir frá þessu fyrirtæki.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'is-IS=Vinnsla';

                actionref(SetCompanyApiKeyPromoted; SetCompanyApiKey)
                {
                }
                actionref(RegisterWebhooksPromoted; RegisterWebhooks)
                {
                }
                actionref(IntegrationListPromoted; IntegrationList)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.GetSetup();
    end;

    trigger OnAfterGetCurrRecord()
    var
        SecretMgt: Codeunit "Clockify Secret Mgt ori";
        WebhookMgt: Codeunit "Clockify Webhook Mgt ori";
    begin
        ClockifyHasCompanyKey := SecretMgt.HasCompanyApiKey();
        ClockifyWebhooksRegistered := WebhookMgt.HasRegisteredWebhooks();
    end;

    var
        ClockifyHasCompanyKey: Boolean;
        ClockifyWebhooksRegistered: Boolean;
}
