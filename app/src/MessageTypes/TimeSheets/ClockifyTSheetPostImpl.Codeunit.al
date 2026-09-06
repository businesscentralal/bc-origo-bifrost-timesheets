namespace Origo.Bifrost.Timesheets;

using Microsoft.Projects.TimeSheet;
using Origo.Bifrost;

/// <summary>
/// Implementation of the <c>Clockify.TimeSheet.Post</c> message type. Transfers approved,
/// unposted time-sheet detail into a Job Journal batch and posts it. BC-side operation —
/// does not call the Clockify API.
/// </summary>
codeunit 70009251 "Clockify TSheetPost Impl ori" implements "Msg Interface ori"
{
    Access = Internal;

    var
        MissingJournalErr: Label 'No Job Journal target is configured. Set the Clockify Job Journal Template and Batch on Clockify Setup, or pass ''journalTemplate'' and ''journalBatch'' in the request.', Locked = true;

    internal procedure IsEnabled(): Boolean
    var
        TimeSheetHeader: Record "Time Sheet Header";
    begin
        exit(TimeSheetHeader.WritePermission());
    end;

    internal procedure GetFilterTableNo(): Integer
    begin
        exit(0);
    end;

    internal procedure GetDescription(): Text[250]
    begin
        exit('Transfers approved, unposted time-sheet detail into a Job Journal batch and posts the lines.');
    end;

    internal procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit(Enum::"Msg Direction ori"::Inbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "Message Argument ori")
    var
        Help: Codeunit "Clockify TimeSheet Help ori";
    begin
        Argument.SetResponseMarkdown(Help.GetHelp(Enum::"Message Type ori"::"Clockify.TimeSheet.Post", GetDescription()));
    end;

    internal procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    var
        TimeSheetMgt: Codeunit "Clockify TimeSheet Mgt ori";
        SetupMgt: Codeunit "Clockify Setup Mgt ori";
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
        JsonToken: JsonToken;
        JournalTemplate: Code[10];
        JournalBatch: Code[10];
        PostedLineCount: Integer;
    begin
        Argument.AssertVersion1();
        RequestJson := Argument.GetRequestJson();

        SetupMgt.TryGetJobJournal(JournalTemplate, JournalBatch);
        if RequestJson.Get('journalTemplate', JsonToken) then
            if JsonToken.IsValue() then
                JournalTemplate := CopyStr(JsonToken.AsValue().AsText(), 1, 10);
        if RequestJson.Get('journalBatch', JsonToken) then
            if JsonToken.IsValue() then
                JournalBatch := CopyStr(JsonToken.AsValue().AsText(), 1, 10);
        if (JournalTemplate = '') or (JournalBatch = '') then begin
            Argument.RespondWithError(MissingJournalErr);
            exit;
        end;

        PostedLineCount := TimeSheetMgt.PostApprovedTimeSheets(JournalTemplate, JournalBatch);

        ResponseJson.Add('status', 'Success');
        ResponseJson.Add('postedLines', PostedLineCount);
        Argument.SetResponseJson(ResponseJson);
    end;
}
