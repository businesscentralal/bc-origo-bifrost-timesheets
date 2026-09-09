namespace Origo.Bifrost.Timesheets.Providers.Clockify;

using Origo.Bifrost;

/// <summary>
/// Registers and removes the Clockify webhooks that drive real-time time-entry
/// sync. Creating a webhook POSTs to <c>/workspaces/{id}/webhooks</c> through the
/// configured <see cref="Interface.ClockifyApiClient"/> (authenticated with the
/// company API key) and Clockify returns a per-webhook signing token
/// (<c>authToken</c>). That token is echoed in the <c>clockify-signature</c>
/// header on every delivery; the webhook receiver (Azure Function) validates it.
///
/// The token is a secret, so it is never persisted in BC — it is shown to the
/// administrator at registration time and can be re-fetched from Clockify on
/// demand (<see cref="ShowSigningTokens"/>) to paste into the receiver's
/// <c>CLOCKIFY_WEBHOOK_SIGNATURES</c> setting. Only the webhook ID is tracked
/// locally, in <see cref="Table.ClockifyWebhook"/>.
/// </summary>
codeunit 10036830 "Clockify Webhook Mgt ori"
{
    Access = Internal;

    var
        NoApiKeyErr: Label 'Set the company Clockify API key before registering webhooks.', Comment = 'is-IS=Skráðu Clockify API lykil fyrirtækis áður en vefkrókar eru skráðir.';
        NoWorkspaceErr: Label 'Set a Default Workspace on Clockify Setup before registering webhooks.', Comment = 'is-IS=Veldu sjálfgefið vinnusvæði í uppsetningu Clockify áður en vefkrókar eru skráðir.';
        NoReceiverUrlErr: Label 'Set the Clockify Webhook Receiver URL on Clockify Setup before registering webhooks.', Comment = 'is-IS=Skráðu Clockify vefkróka móttökuslóð í uppsetningu Clockify áður en vefkrókar eru skráðir.';
        AlreadyRegisteredErr: Label 'Clockify webhooks are already registered. Remove them before registering again.', Comment = 'is-IS=Clockify vefkrókar eru þegar skráðir. Fjarlægðu þá áður en þú skráir aftur.';
        NotRegisteredMsg: Label 'No Clockify webhooks are registered.', Comment = 'is-IS=Engir Clockify vefkrókar eru skráðir.';
        CreateFailedErr: Label 'Creating the Clockify %1 webhook failed (HTTP %2): %3', Comment = '%1 = event, %2 = status code, %3 = response. is-IS=Ekki tókst að búa til Clockify %1 vefkrók (HTTP %2): %3';
        RegisterQst: Label 'Register Clockify webhooks for real-time time-entry sync?', Comment = 'is-IS=Skrá Clockify vefkróka fyrir rauntíma samstillingu tímafærslna?';
        RegisteredMsg: Label 'Registered %1 Clockify webhook(s).\n\nConfigure the webhook receiver app setting CLOCKIFY_WEBHOOK_SIGNATURES with these signing token(s):\n\n%2', Comment = '%1 = count, %2 = tokens. is-IS=Skráði %1 Clockify vefkrók(a).\n\nStilltu CLOCKIFY_WEBHOOK_SIGNATURES á móttakaranum með þessum undirritunarlyklum:\n\n%2';
        RemoveQst: Label 'Remove all registered Clockify webhooks?', Comment = 'is-IS=Fjarlægja alla skráða Clockify vefkróka?';
        RemovedMsg: Label 'Removed %1 Clockify webhook(s).', Comment = '%1 = count. is-IS=Fjarlægði %1 Clockify vefkrók(a).';
        TokensMsg: Label 'Configure these signing token(s) as CLOCKIFY_WEBHOOK_SIGNATURES on the webhook receiver:\n\n%1', Comment = '%1 = tokens. is-IS=Stilltu þessa undirritunarlykla sem CLOCKIFY_WEBHOOK_SIGNATURES á móttakaranum:\n\n%1';
        NoTokensMsg: Label 'The signing tokens could not be retrieved from Clockify.', Comment = 'is-IS=Ekki tókst að sækja undirritunarlykla frá Clockify.';
        WebhookNameTok: Label 'BC Bifrost - %1', Comment = '%1 = event', Locked = true;

    /// <summary>
    /// Registers a webhook in Clockify for each real-time time-entry event
    /// (<c>NEW_TIME_ENTRY</c>, <c>TIME_ENTRY_UPDATED</c>, <c>TIME_ENTRY_DELETED</c>),
    /// pointed at the configured receiver URL, and shows the returned signing
    /// tokens for the administrator to configure on the receiver.
    /// </summary>
    procedure RegisterTimeEntryWebhooks()
    var
        ClockifyWebhook: Record "Clockify Webhook ori";
        SecretMgt: Codeunit "Clockify Secret Mgt ori";
        Events: List of [Text];
        EventName: Text;
        WorkspaceId: Text;
        ReceiverUrl: Text;
        FullUrl: Text;
        WebhookId: Text;
        AuthToken: Text;
        TokensBuilder: TextBuilder;
        Registered: Integer;
    begin
        if not SecretMgt.HasCompanyApiKey() then
            Error(NoApiKeyErr);
        WorkspaceId := GetDefaultWorkspace();
        if WorkspaceId = '' then
            Error(NoWorkspaceErr);
        ReceiverUrl := GetReceiverUrl();
        if ReceiverUrl = '' then
            Error(NoReceiverUrlErr);
        if not ClockifyWebhook.IsEmpty() then
            Error(AlreadyRegisteredErr);
        if not Confirm(RegisterQst, false) then
            exit;

        FullUrl := AppendWorkspace(ReceiverUrl, WorkspaceId);
        Events := GetTimeEntryEvents();
        foreach EventName in Events do begin
            CreateWebhook(WorkspaceId, EventName, FullUrl, WebhookId, AuthToken);
            InsertRow(EventName, WebhookId, FullUrl, WorkspaceId);
            if TokensBuilder.Length() > 0 then
                TokensBuilder.Append(',');
            TokensBuilder.Append(AuthToken);
            Registered += 1;
        end;

        Message(RegisteredMsg, Registered, TokensBuilder.ToText());
    end;

    /// <summary>Deletes every registered Clockify webhook and clears the local tracking rows.</summary>
    procedure RemoveTimeEntryWebhooks()
    var
        ClockifyWebhook: Record "Clockify Webhook ori";
        Removed: Integer;
    begin
        if ClockifyWebhook.IsEmpty() then begin
            Message(NotRegisteredMsg);
            exit;
        end;
        if not Confirm(RemoveQst, false) then
            exit;

        ClockifyWebhook.SetLoadFields("Workspace Id", "Webhook Id");
        if ClockifyWebhook.FindSet() then
            repeat
                // Best-effort: a webhook already removed in Clockify must not block local cleanup.
                DeleteWebhook(ClockifyWebhook."Workspace Id", ClockifyWebhook."Webhook Id");
                Removed += 1;
            until ClockifyWebhook.Next() = 0;
        ClockifyWebhook.DeleteAll();
        Message(RemovedMsg, Removed);
    end;

    /// <summary>
    /// Re-fetches the signing token of each registered webhook from Clockify and
    /// shows them, so the administrator can configure the receiver without having
    /// to re-register.
    /// </summary>
    procedure ShowSigningTokens()
    var
        ClockifyWebhook: Record "Clockify Webhook ori";
        TokensBuilder: TextBuilder;
        AuthToken: Text;
    begin
        if ClockifyWebhook.IsEmpty() then begin
            Message(NotRegisteredMsg);
            exit;
        end;
        ClockifyWebhook.SetLoadFields("Workspace Id", "Webhook Id");
        if ClockifyWebhook.FindSet() then
            repeat
                if GetWebhookToken(ClockifyWebhook."Workspace Id", ClockifyWebhook."Webhook Id", AuthToken) and (AuthToken <> '') then begin
                    if TokensBuilder.Length() > 0 then
                        TokensBuilder.Append(',');
                    TokensBuilder.Append(AuthToken);
                end;
            until ClockifyWebhook.Next() = 0;

        if TokensBuilder.Length() = 0 then begin
            Message(NoTokensMsg);
            exit;
        end;
        Message(TokensMsg, TokensBuilder.ToText());
    end;

    /// <summary>Returns true when at least one Clockify webhook is registered.</summary>
    procedure HasRegisteredWebhooks(): Boolean
    var
        ClockifyWebhook: Record "Clockify Webhook ori";
    begin
        exit(not ClockifyWebhook.IsEmpty());
    end;

    local procedure CreateWebhook(WorkspaceId: Text; EventName: Text; Url: Text; var WebhookId: Text; var AuthToken: Text)
    var
        RequestMgt: Codeunit "Clockify Request Mgt ori";
        ApiClient: Interface "Clockify API Client ori";
        BodyObj: JsonObject;
        ResponseObj: JsonObject;
        Token: JsonToken;
        BodyText: Text;
        ResponseBody: Text;
        StatusCode: Integer;
    begin
        // Minimal workspace-wide create body. Add 'triggerSource'/'triggerSourceType'
        // here to scope a webhook to a specific project, task, tag or user.
        BodyObj.Add('name', StrSubstNo(WebhookNameTok, EventName));
        BodyObj.Add('url', Url);
        BodyObj.Add('webhookEvent', EventName);
        BodyObj.WriteTo(BodyText);

        ApiClient := RequestMgt.GetApiClient();
        if not ApiClient.Send('POST', '/workspaces/' + WorkspaceId + '/webhooks', true, BodyText, ResponseBody, StatusCode) then
            Error(CreateFailedErr, EventName, StatusCode, ResponseBody);

        WebhookId := '';
        AuthToken := '';
        if ResponseObj.ReadFrom(ResponseBody) then begin
            if ResponseObj.Get('id', Token) and Token.IsValue() then
                WebhookId := Token.AsValue().AsText();
            if ResponseObj.Get('authToken', Token) and Token.IsValue() then
                AuthToken := Token.AsValue().AsText();
        end;
    end;

    local procedure DeleteWebhook(WorkspaceId: Text; WebhookId: Text)
    var
        RequestMgt: Codeunit "Clockify Request Mgt ori";
        ApiClient: Interface "Clockify API Client ori";
        ResponseBody: Text;
        StatusCode: Integer;
    begin
        if WebhookId = '' then
            exit;
        ApiClient := RequestMgt.GetApiClient();
        if ApiClient.Send('DELETE', '/workspaces/' + WorkspaceId + '/webhooks/' + WebhookId, false, '', ResponseBody, StatusCode) then;
    end;

    local procedure GetWebhookToken(WorkspaceId: Text; WebhookId: Text; var AuthToken: Text): Boolean
    var
        RequestMgt: Codeunit "Clockify Request Mgt ori";
        ApiClient: Interface "Clockify API Client ori";
        ResponseObj: JsonObject;
        Token: JsonToken;
        ResponseBody: Text;
        StatusCode: Integer;
    begin
        AuthToken := '';
        if WebhookId = '' then
            exit(false);
        ApiClient := RequestMgt.GetApiClient();
        if not ApiClient.Send('GET', '/workspaces/' + WorkspaceId + '/webhooks/' + WebhookId, false, '', ResponseBody, StatusCode) then
            exit(false);
        if not ResponseObj.ReadFrom(ResponseBody) then
            exit(false);
        if ResponseObj.Get('authToken', Token) and Token.IsValue() then
            AuthToken := Token.AsValue().AsText();
        exit(AuthToken <> '');
    end;

    local procedure InsertRow(EventName: Text; WebhookId: Text; Url: Text; WorkspaceId: Text)
    var
        ClockifyWebhook: Record "Clockify Webhook ori";
    begin
        ClockifyWebhook.Init();
        ClockifyWebhook."Event" := CopyStr(EventName, 1, MaxStrLen(ClockifyWebhook."Event"));
        ClockifyWebhook."Webhook Id" := CopyStr(WebhookId, 1, MaxStrLen(ClockifyWebhook."Webhook Id"));
        ClockifyWebhook."Webhook Name" := CopyStr(StrSubstNo(WebhookNameTok, EventName), 1, MaxStrLen(ClockifyWebhook."Webhook Name"));
        ClockifyWebhook."Url" := CopyStr(Url, 1, MaxStrLen(ClockifyWebhook."Url"));
        ClockifyWebhook."Workspace Id" := CopyStr(WorkspaceId, 1, MaxStrLen(ClockifyWebhook."Workspace Id"));
        ClockifyWebhook."Registered At" := CurrentDateTime();
        ClockifyWebhook.Insert(true);
    end;

    local procedure GetTimeEntryEvents() Events: List of [Text]
    begin
        Events.Add('NEW_TIME_ENTRY');
        Events.Add('TIME_ENTRY_UPDATED');
        Events.Add('TIME_ENTRY_DELETED');
    end;

    local procedure GetDefaultWorkspace(): Text
    var
        ClockifySetup: Record "Clockify Setup ori";
    begin
        if not ClockifySetup.Get() then
            exit('');
        exit(ClockifySetup."Default Workspace");
    end;

    local procedure GetReceiverUrl(): Text
    var
        ClockifySetup: Record "Clockify Setup ori";
    begin
        if not ClockifySetup.Get() then
            exit('');
        exit(ClockifySetup."Webhook Receiver URL");
    end;

    local procedure AppendWorkspace(Url: Text; WorkspaceId: Text): Text
    begin
        if Url.Contains('?') then
            exit(Url + '&workspaceId=' + WorkspaceId);
        exit(Url + '?workspaceId=' + WorkspaceId);
    end;
}
