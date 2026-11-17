namespace Origo.Bifrost.Timesheets;

using Origo.Bifrost;

/// <summary>
/// Implementation of the <c>Clockify.TimeSheet.Reopen</c> message type. Reopens submitted or
/// approved time-sheet lines back to Open, up to a cut-off ending date. BC-side operation —
/// does not call the Clockify API.
/// </summary>
/// <remarks>Runs the base time-sheet approval engine; no Clockify API call.</remarks>
codeunit 10036844 "Clockify TSheetReopen Impl ori" implements "Msg Interface ori", "Msg Contract ori", "Msg Discovery ori"
{
    Access = Internal;

    /// <summary>Checks the native permissions needed by this retained Clockify handler.</summary>
    procedure IsEnabled(): Boolean
    var
        NativeMgt: Codeunit "Clockify TSheet Request ori";
    begin
        exit(NativeMgt.CanReopenSheets());
    end;

    /// <summary>Returns zero because this handler takes explicit request parameters.</summary>
    procedure GetFilterTableNo(): Integer
    begin
        exit(0);
    end;

    /// <summary>Returns the description of the retained Clockify operation.</summary>
    procedure GetDescription(): Text[250]
    begin
        exit('Reopens submitted or approved time-sheet lines back to Open, up to a cut-off date.');
    end;


    /// <summary>Returns localized search keywords.</summary>
    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'time sheet, reopen, Clockify, timesheets', Comment = 'is-IS=tímaskýrsla, opna aftur, Clockify, tímaskýrslur';
    begin
        exit(KeywordsLbl);
    end;

    /// <summary>Returns the localized operation summary.</summary>
    procedure GetSelectionDescription(): Text
    var
        SelectionLbl: Label 'Clockify.TimeSheet.Reopen: Reopens submitted or approved time-sheet lines back to Open up to a cut-off date.', Comment = 'is-IS=Clockify.TimeSheet.Reopen: Opnar aftur innsendar eða samþykktar tímaskýrslulínur í stöðuna Open til lokadags.';
    begin
        exit(SelectionLbl);
    end;

    /// <summary>Returns the envelope chapter of the retained Clockify contract.</summary>
    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    var
        Parts: Codeunit "Clockify Contract Parts ori";
    begin
        exit(Parts.GetEnvelope(GetMessageType(), Envelope));
    end;

    /// <summary>Returns the target chapter of the retained Clockify contract.</summary>
    procedure GetTarget(var Target: JsonArray): Boolean
    var
        Parts: Codeunit "Clockify Contract Parts ori";
    begin
        exit(Parts.TargetForTimeSheetReopen(Target));
    end;

    /// <summary>Returns the parameters chapter of the retained Clockify contract.</summary>
    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        Parts: Codeunit "Clockify Contract Parts ori";
    begin
        exit(Parts.ParametersForTimeSheetReopen(Parameters));
    end;

    /// <summary>Returns the response chapter of the retained Clockify contract.</summary>
    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Parts: Codeunit "Clockify Contract Parts ori";
    begin
        exit(Parts.GetResponse(GetMessageType(), Response));
    end;

    /// <summary>Returns the errors chapter of the retained Clockify contract.</summary>
    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Parts: Codeunit "Clockify Contract Parts ori";
    begin
        exit(Parts.GetErrors(GetMessageType(), Errors));
    end;

    /// <summary>Returns the effect chapter of the retained Clockify contract.</summary>
    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Parts: Codeunit "Clockify Contract Parts ori";
    begin
        exit(Parts.GetEffect(GetMessageType(), Effect));
    end;

    /// <summary>Returns the metering chapter of the retained Clockify contract.</summary>
    procedure GetMetering(var Metering: JsonObject): Boolean
    var
        Parts: Codeunit "Clockify Contract Parts ori";
    begin
        exit(Parts.GetMetering(Metering));
    end;

    /// <summary>Returns the related chapter of the retained Clockify contract.</summary>
    procedure GetRelated(var Related: JsonArray): Boolean
    var
        Parts: Codeunit "Clockify Contract Parts ori";
    begin
        exit(Parts.GetRelated(GetMessageType(), Related));
    end;

    /// <summary>Returns the workflow chapter of the retained Clockify contract.</summary>
    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    var
        Parts: Codeunit "Clockify Contract Parts ori";
    begin
        exit(Parts.GetWorkflow(GetMessageType(), Workflow));
    end;

    /// <summary>Returns the examples chapter of the retained Clockify contract.</summary>
    procedure GetExamples(var Examples: JsonArray): Boolean
    var
        Parts: Codeunit "Clockify Contract Parts ori";
    begin
        exit(Parts.GetExamples(GetMessageType(), Examples));
    end;

    /// <summary>Returns the overview chapter of the retained Clockify contract.</summary>
    procedure GetOverview(var Overview: Text): Boolean
    var
        Parts: Codeunit "Clockify Contract Parts ori";
    begin
        exit(Parts.GetOverview(GetMessageType(), Overview));
    end;

    /// <summary>Returns the notes chapter of the retained Clockify contract.</summary>
    procedure GetNotes(var Notes: Text): Boolean
    var
        Parts: Codeunit "Clockify Contract Parts ori";
    begin
        exit(Parts.GetNotes(GetMessageType(), Notes));
    end;

    local procedure GetMessageType(): Enum "Message Type ori"
    begin
        // exit(Enum::"Message Type ori"::"Clockify.TimeSheet.Reopen");
        exit;
    end;

    /// <summary>Returns the inbound direction of this handler.</summary>
    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit(Enum::"Msg Direction ori"::Inbound);
    end;

    /// <summary>Validates the version and executes the retained Clockify bulk operation.</summary>
    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    var
        NativeMgt: Codeunit "Clockify TSheet Request ori";
        ResponseJson: JsonObject;
        StatusToken: JsonToken;
    begin
        Argument.AssertVersion1();
        NativeMgt.ExecuteReopen(Argument);
        ResponseJson := Argument.GetResponseJson();
        if ResponseJson.Get('status', StatusToken) then
            if StatusToken.AsValue().AsText() = 'Success' then begin
                NativeMgt.AddLegacyNameWarning(ResponseJson);
                Argument.SetResponseJson(ResponseJson);
            end;
    end;
}
