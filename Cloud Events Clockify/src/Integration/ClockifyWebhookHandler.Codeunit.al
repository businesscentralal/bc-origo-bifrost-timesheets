namespace Origo.PTE.CloudEvents.Clockify;

using Origo.APP.CloudEvents;

/// <summary>
/// Routes inbound Clockify webhooks to the time-entry sync engine. Subscribes to
/// <c>Webhook Inbound Events.OnWebhookReceived</c> (Cloud Events Base), which fires
/// when the webhook receiver (Azure Function) forwards a Clockify delivery as a
/// <c>Webhook.Inbound.Receive</c> message.
///
/// Only events whose source label starts with <c>clockify/</c> are handled:
/// <c>NEW_TIME_ENTRY</c> / <c>TIME_ENTRY_UPDATED</c> sync the entry to a Job
/// Journal Line (idempotent — re-delivery and a reconciliation poll converge on
/// the same link), and <c>TIME_ENTRY_DELETED</c> reverses it. The webhook body is
/// the Clockify time-entry object, so no extra API fetch is needed.
/// </summary>
codeunit 70009206 "Clockify Webhook Handler"
{
    Access = Internal;

    var
        SourcePrefixTok: Label 'clockify/', Locked = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Webhook Inbound Events ori", 'OnWebhookReceived', '', false, false)]
    local procedure HandleClockifyWebhook(EventSource: Text; EventType: Text; HeadersJson: Text; BodyJson: Text; var Handled: Boolean)
    begin
        if not EventSource.StartsWith(SourcePrefixTok) then
            exit;

        case EventType of
            'NEW_TIME_ENTRY', 'TIME_ENTRY_UPDATED':
                SyncFromWebhook(BodyJson);
            'TIME_ENTRY_DELETED':
                ReverseFromWebhook(BodyJson);
            else
                exit; // a Clockify event we do not act on — leave Handled = false
        end;

        Handled := true;
    end;

    local procedure SyncFromWebhook(BodyJson: Text)
    var
        TimeEntrySync: Codeunit "Clockify Time Entry Sync";
        SetupMgt: Codeunit "Clockify Setup Mgt";
        Body: JsonObject;
        EntryId: Text;
        WorkspaceId: Text;
        UserId: Text;
        ProjectId: Text;
        TaskId: Text;
        Description: Text;
        StartText: Text;
        EndText: Text;
        ResultMessage: Text;
        JournalTemplate: Code[10];
        JournalBatch: Code[10];
        TagIds: List of [Text];
        Hours: Decimal;
        PostingDate: Date;
        Billable: Boolean;
    begin
        if not Body.ReadFrom(BodyJson) then
            exit;

        // The webhook carries no journal target — use the Cloud Events Setup
        // configuration. If it is not set, skip rather than fail the delivery
        // (which Clockify would otherwise retry indefinitely).
        if not SetupMgt.TryGetJobJournal(JournalTemplate, JournalBatch) then
            exit;

        EntryId := GetText(Body, 'id');
        WorkspaceId := GetText(Body, 'workspaceId');
        UserId := GetText(Body, 'userId');
        ProjectId := GetText(Body, 'projectId');
        TaskId := GetText(Body, 'taskId');
        Description := GetText(Body, 'description');
        GetTimeInterval(Body, StartText, EndText);
        Billable := GetBool(Body, 'billable');
        GetTagIds(Body, TagIds);

        Hours := CalculateHours(StartText, EndText);
        PostingDate := ParseDate(StartText);
        if (Hours = 0) or (PostingDate = 0D) then
            exit; // running timer or malformed interval — nothing to post yet

        TimeEntrySync.SyncTimeEntry(
            JournalTemplate, JournalBatch,
            CopyStr(EntryId, 1, 50), CopyStr(WorkspaceId, 1, 50), CopyStr(UserId, 1, 50),
            CopyStr(ProjectId, 1, 50), CopyStr(TaskId, 1, 50),
            Description, PostingDate, Hours, Billable, TagIds, ResultMessage);
    end;

    local procedure ReverseFromWebhook(BodyJson: Text)
    var
        TimeEntrySync: Codeunit "Clockify Time Entry Sync";
        TimeSheetSync: Codeunit "Clockify TimeSheet Sync";
        Body: JsonObject;
        EntryId: Text;
        ResultMessage: Text;
    begin
        if not Body.ReadFrom(BodyJson) then
            exit;
        EntryId := GetText(Body, 'id');
        if EntryId = '' then
            exit;
        // Reverse whichever lane holds an active link for this entry (Job Journal or Time Sheet).
        TimeEntrySync.ReverseTimeEntry(CopyStr(EntryId, 1, 50), ResultMessage);
        TimeSheetSync.ReverseFromTimeSheet(CopyStr(EntryId, 1, 50), ResultMessage);
    end;

    local procedure GetTimeInterval(Body: JsonObject; var StartText: Text; var EndText: Text)
    var
        Token: JsonToken;
        Interval: JsonObject;
    begin
        StartText := '';
        EndText := '';
        if not Body.Get('timeInterval', Token) then
            exit;
        if not Token.IsObject() then
            exit;
        Interval := Token.AsObject();
        StartText := GetText(Interval, 'start');
        EndText := GetText(Interval, 'end');
    end;

    local procedure GetTagIds(Body: JsonObject; var TagIds: List of [Text])
    var
        Token: JsonToken;
        TagToken: JsonToken;
    begin
        Clear(TagIds);
        if not Body.Get('tagIds', Token) then
            exit;
        if not Token.IsArray() then
            exit;
        foreach TagToken in Token.AsArray() do
            if TagToken.IsValue() then
                if not TagToken.AsValue().IsNull() then
                    TagIds.Add(TagToken.AsValue().AsText());
    end;

    local procedure CalculateHours(StartText: Text; EndText: Text): Decimal
    var
        StartDT: DateTime;
        EndDT: DateTime;
        DurationMs: BigInteger;
    begin
        if (StartText = '') or (EndText = '') then
            exit(0);
        if not Evaluate(StartDT, StartText) then
            exit(0);
        if not Evaluate(EndDT, EndText) then
            exit(0);
        DurationMs := EndDT - StartDT;
        exit(DurationMs / 3600000);
    end;

    local procedure ParseDate(DateTimeText: Text): Date
    var
        DateTimeParsed: DateTime;
    begin
        if DateTimeText = '' then
            exit(0D);
        if not Evaluate(DateTimeParsed, DateTimeText) then
            exit(0D);
        exit(DT2Date(DateTimeParsed));
    end;

    local procedure GetText(JsonObj: JsonObject; PropertyName: Text): Text
    var
        Token: JsonToken;
    begin
        if not JsonObj.Get(PropertyName, Token) then
            exit('');
        if not Token.IsValue() then
            exit('');
        if Token.AsValue().IsNull() then
            exit('');
        exit(Token.AsValue().AsText());
    end;

    local procedure GetBool(JsonObj: JsonObject; PropertyName: Text): Boolean
    var
        Token: JsonToken;
    begin
        if not JsonObj.Get(PropertyName, Token) then
            exit(false);
        if not Token.IsValue() then
            exit(false);
        if Token.AsValue().IsNull() then
            exit(false);
        exit(Token.AsValue().AsBoolean());
    end;
}
