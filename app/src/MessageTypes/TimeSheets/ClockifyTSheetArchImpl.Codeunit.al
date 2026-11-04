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
        exit('Archives fully posted time sheets and removes empty posted sheets ending before the work date.');
    end;


    /// <summary>Returns localized absence discovery keywords.</summary>
    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'time sheet, archive, Clockify, timesheets', Comment = 'is-IS=tímaskýrsla, geymsla, Clockify, tímaskýrslur';
    begin
        exit(KeywordsLbl);
    end;

    /// <summary>Returns the localized message picker description.</summary>
    procedure GetSelectionDescription(): Text
    var
        SelectionLbl: Label 'Clockify.TimeSheet.Archive: Archives fully posted time sheets and removes empty posted sheets. It does not call Clockify.', Comment = 'is-IS=Clockify.TimeSheet.Archive: Setur fullbókaðar tímaskýrslur í geymslu og fjarlægir tómar bókaðar skýrslur. Kallar ekki á Clockify.';
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
        exit(Enum::"Message Type ori"::"Clockify.TimeSheet.Archive");
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
