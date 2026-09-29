namespace Origo.Bifrost.Timesheets;

using Microsoft.Projects.TimeSheet;
using Origo.Bifrost;

/// <summary>
/// Implementation of the <c>Clockify.TimeSheet.Archive</c> message type. Archives fully
/// posted time sheets and removes empty posted sheets. BC-side operation — does not call
/// the Clockify API.
/// </summary>
codeunit 10036837 "Clockify TSheetArch Impl ori" implements "Msg Interface ori", "Msg Contract ori", "Msg Discovery ori"
{
    Access = Internal;

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
        exit('Archives fully posted time sheets and removes empty posted sheets ending before the work date.');
    end;


    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'Clockify Clockify TimeSheet.Archive, Clockify, TimeSheet.Archive, Timesheets', Comment = 'is-IS=Clockify Clockify TimeSheet.Archive, Clockify, TimeSheet.Archive, tímaskýrslur';
    begin
        exit(KeywordsLbl);
    end;

    procedure GetSelectionDescription(): Text
    var
        SelectionLbl: Label 'Clockify.TimeSheet.Archive: TimeSheet.Archive operation for Clockify. Use the matching List or Get message for lookup.', Comment = 'is-IS=Clockify.TimeSheet.Archive: TimeSheet.Archive aðgerð fyrir Clockify. Notaðu samsvarandi lista- eða sækjaaðgerð fyrir uppflettingu.';
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
        exit(Enum::"Message Type ori"::"Clockify.TimeSheet.Archive");
    end;

    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit(Enum::"Msg Direction ori"::Inbound);
    end;

    procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "Message Argument ori")
    var
        Help: Codeunit "Clockify Contract Help 3 ori";
    begin
        Argument.SetResponseMarkdown(Help.GetHelp(Enum::"Message Type ori"::"Clockify.TimeSheet.Archive", GetDescription()));
    end;

    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    var
        TimeSheetMgt: Codeunit "Clockify TimeSheet Mgt ori";
        ResponseJson: JsonObject;
        ArchivedCount: Integer;
    begin
        Argument.AssertVersion1();
        ArchivedCount := TimeSheetMgt.ArchivePostedTimeSheets();

        ResponseJson.Add('status', 'Success');
        ResponseJson.Add('archived', ArchivedCount);
        Argument.SetResponseJson(ResponseJson);
    end;
}
