namespace Origo.Bifrost.Timesheets;

using Microsoft.Projects.TimeSheet;
using Origo.Bifrost;

/// <summary>
/// Implementation of the <c>Clockify.TimeSheet.Post</c> message type. Transfers approved,
/// unposted time-sheet detail into a Job Journal batch and posts it. BC-side operation —
/// does not call the Clockify API.
/// </summary>
codeunit 10036836 "Clockify TSheetPost Impl ori" implements "Msg Interface ori", "Msg Contract ori", "Msg Discovery ori"
{
    Access = Internal;

    var
        MissingJournalErr: Label 'No Job Journal target is configured. Set the Clockify Job Journal Template and Batch on Clockify Setup, or pass ''journalTemplate'' and ''journalBatch'' in the request.', Locked = true;

    procedure IsEnabled(): Boolean
    var
        TimeSheetHeader: Record "Time Sheet Header";
    begin
        exit(TimeSheetHeader.WritePermission());
    end;

    procedure GetFilterTableNo(): Integer
    begin
        exit(0);
    end;

    procedure GetDescription(): Text[250]
    begin
        exit('Transfers approved, unposted time-sheet detail into a Job Journal batch and posts the lines.');
    end;


    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'time sheet, post, journal, Clockify, timesheets', Comment = 'is-IS=tímaskýrsla, bóka, verkbók, Clockify, tímaskýrslur';
    begin
        exit(KeywordsLbl);
    end;

    procedure GetSelectionDescription(): Text
    var
        SelectionLbl: Label 'Clockify.TimeSheet.Post: Posts approved time-sheet lines to a Job Journal batch. It does not call Clockify.', Comment = 'is-IS=Clockify.TimeSheet.Post: Bókar samþykktar tímaskýrslulínur í verkbók. Kallar ekki á Clockify.';
    begin
        exit(SelectionLbl);
    end;

    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    var
        Parts: Codeunit "Clockify Contract Parts ori";
    begin
        exit(Parts.GetEnvelope(GetMessageType(), Envelope));
    end;

    procedure GetTarget(var Target: JsonArray): Boolean
    var
        Parts: Codeunit "Clockify Contract Parts ori";
    begin
        exit(Parts.GetTarget(GetMessageType(), Target));
    end;

    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        Parts: Codeunit "Clockify Contract Parts ori";
    begin
        exit(Parts.GetParameters(GetMessageType(), Parameters));
    end;

    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Parts: Codeunit "Clockify Contract Parts ori";
    begin
        exit(Parts.GetResponse(GetMessageType(), Response));
    end;

    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Parts: Codeunit "Clockify Contract Parts ori";
    begin
        exit(Parts.GetErrors(GetMessageType(), Errors));
    end;

    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Parts: Codeunit "Clockify Contract Parts ori";
    begin
        exit(Parts.GetEffect(GetMessageType(), Effect));
    end;

    procedure GetMetering(var Metering: JsonObject): Boolean
    var
        Parts: Codeunit "Clockify Contract Parts ori";
    begin
        exit(Parts.GetMetering(Metering));
    end;

    procedure GetRelated(var Related: JsonArray): Boolean
    var
        Parts: Codeunit "Clockify Contract Parts ori";
    begin
        exit(Parts.GetRelated(GetMessageType(), Related));
    end;

    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    var
        Parts: Codeunit "Clockify Contract Parts ori";
    begin
        exit(Parts.GetWorkflow(GetMessageType(), Workflow));
    end;

    procedure GetExamples(var Examples: JsonArray): Boolean
    var
        Parts: Codeunit "Clockify Contract Parts ori";
    begin
        exit(Parts.GetExamples(GetMessageType(), Examples));
    end;

    procedure GetOverview(var Overview: Text): Boolean
    var
        Parts: Codeunit "Clockify Contract Parts ori";
    begin
        exit(Parts.GetOverview(GetMessageType(), Overview));
    end;

    procedure GetNotes(var Notes: Text): Boolean
    var
        Parts: Codeunit "Clockify Contract Parts ori";
    begin
        exit(Parts.GetNotes(GetMessageType(), Notes));
    end;

    local procedure GetMessageType(): Enum "Message Type ori"
    begin
        exit(Enum::"Message Type ori"::"Clockify.TimeSheet.Post");
    end;

    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit(Enum::"Msg Direction ori"::Inbound);
    end;

    procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "Message Argument ori")
    var
        Help: Codeunit "Clockify Contract Help 3 ori";
    begin
        Argument.SetResponseMarkdown(Help.GetHelp(Enum::"Message Type ori"::"Clockify.TimeSheet.Post", GetDescription()));
    end;

    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
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
