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

    /// <summary>Checks the caller permissions required for absence registration.</summary>
    procedure IsEnabled(): Boolean
    var
        TimeSheetHeader: Record "Time Sheet Header";
    begin
        exit(TimeSheetHeader.WritePermission());
    end;

    /// <summary>Returns zero because this message addresses a time sheet through request parameters.</summary>
    procedure GetFilterTableNo(): Integer
    begin
        exit(0);
    end;

    /// <summary>Returns the localized description of absence registration.</summary>
    procedure GetDescription(): Text[250]
    begin
        exit('Transfers approved, unposted time-sheet detail into a Job Journal batch and posts the lines.');
    end;


    /// <summary>Returns localized absence discovery keywords.</summary>
    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'time sheet, post, journal, Clockify, timesheets', Comment = 'is-IS=tímaskýrsla, bóka, verkbók, Clockify, tímaskýrslur';
    begin
        exit(KeywordsLbl);
    end;

    /// <summary>Returns the localized message picker description.</summary>
    procedure GetSelectionDescription(): Text
    var
        SelectionLbl: Label 'Clockify.TimeSheet.Post: Posts approved time-sheet lines to a Job Journal batch. It does not call Clockify.', Comment = 'is-IS=Clockify.TimeSheet.Post: Bókar samþykktar tímaskýrslulínur í verkbók. Kallar ekki á Clockify.';
    begin
        exit(SelectionLbl);
    end;

    /// <summary>Describes the supported task envelope.</summary>
    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    var
        Parts: Codeunit "Clockify Contract Parts ori";
    begin
        exit(Parts.GetEnvelope(GetMessageType(), Envelope));
    end;

    /// <summary>Describes the time-sheet identifier.</summary>
    procedure GetTarget(var Target: JsonArray): Boolean
    var
        Parts: Codeunit "Clockify Contract Parts ori";
    begin
        exit(Parts.GetTarget(GetMessageType(), Target));
    end;

    /// <summary>Lists the accepted absence registration parameters.</summary>
    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        Parts: Codeunit "Clockify Contract Parts ori";
    begin
        exit(Parts.GetParameters(GetMessageType(), Parameters));
    end;

    /// <summary>Describes the absence line returned on success.</summary>
    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Parts: Codeunit "Clockify Contract Parts ori";
    begin
        exit(Parts.GetResponse(GetMessageType(), Response));
    end;

    /// <summary>Lists documented refusals and recovery steps.</summary>
    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Parts: Codeunit "Clockify Contract Parts ori";
    begin
        exit(Parts.GetErrors(GetMessageType(), Errors));
    end;

    /// <summary>Describes the committed write and required permissions.</summary>
    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Parts: Codeunit "Clockify Contract Parts ori";
    begin
        exit(Parts.GetEffect(GetMessageType(), Effect));
    end;

    /// <summary>Indicates that the type has no additional metering chapter.</summary>
    procedure GetMetering(var Metering: JsonObject): Boolean
    var
        Parts: Codeunit "Clockify Contract Parts ori";
    begin
        exit(Parts.GetMetering(Metering));
    end;

    /// <summary>Lists related discovery messages.</summary>
    procedure GetRelated(var Related: JsonArray): Boolean
    var
        Parts: Codeunit "Clockify Contract Parts ori";
    begin
        exit(Parts.GetRelated(GetMessageType(), Related));
    end;

    /// <summary>Describes the absence registration workflow.</summary>
    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    var
        Parts: Codeunit "Clockify Contract Parts ori";
    begin
        exit(Parts.GetWorkflow(GetMessageType(), Workflow));
    end;

    /// <summary>Provides an absence registration request and response example.</summary>
    procedure GetExamples(var Examples: JsonArray): Boolean
    var
        Parts: Codeunit "Clockify Contract Parts ori";
    begin
        exit(Parts.GetExamples(GetMessageType(), Examples));
    end;

    /// <summary>Returns the localized purpose of the message.</summary>
    procedure GetOverview(var Overview: Text): Boolean
    var
        Parts: Codeunit "Clockify Contract Parts ori";
    begin
        exit(Parts.GetOverview(GetMessageType(), Overview));
    end;

    /// <summary>Explains employee linking, weekend warnings and commit behavior.</summary>
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

    /// <summary>Declares the message as an inbound write.</summary>
    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit(Enum::"Msg Direction ori"::Inbound);
    end;

    /// <summary>Validates the message version and dispatches isolated absence registration.</summary>
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
