namespace Origo.Bifrost.Timesheets;

using Origo.Bifrost;

/// <summary>
/// Reopens submitted or approved lines up to a cutoff date.
/// </summary>
codeunit 10036881 "TS Sheet Reopen Impl ori" implements "Msg Interface ori", "Msg Contract ori", "Msg Discovery ori"
{
    Access = Internal;

    procedure IsEnabled(): Boolean
    var
        NativeMgt: Codeunit "TS Native Mgt ori";
    begin
        exit(NativeMgt.CanMaintainSheets());
    end;

    procedure GetFilterTableNo(): Integer
    begin
        exit(0);
    end;

    procedure GetDescription(): Text[250]
    begin
        exit('Reopens submitted or approved time sheet lines.');
    end;

    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'time sheet, reopen, timesheets', Comment = 'is-IS=tímaskýrsla, opna aftur, tímaskýrslur';
    begin
        exit(KeywordsLbl);
    end;

    procedure GetSelectionDescription(): Text
    var
        SelectionLbl: Label 'Timesheets.TimeSheet.Reopen: Reopens submitted or approved time sheet lines.', Comment = 'is-IS=Timesheets.TimeSheet.Reopen: Opnar aftur innsendar eða samþykktar tímaskýrslulínur.';
    begin
        exit(SelectionLbl);
    end;

    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    var
        Parts: Codeunit "TS Contract Parts ori";
    begin
        exit(Parts.GetEnvelope(GetMessageType(), Envelope));
    end;

    procedure GetTarget(var Target: JsonArray): Boolean
    var
        Parts: Codeunit "TS Contract Parts ori";
    begin
        exit(Parts.GetTarget(GetMessageType(), Target));
    end;

    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        Parts: Codeunit "TS Contract Parts ori";
    begin
        exit(Parts.AddReopenParameters(Parameters));
    end;

    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Parts: Codeunit "TS Contract Parts ori";
    begin
        exit(Parts.GetResponse(GetMessageType(), Response));
    end;

    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Parts: Codeunit "TS Contract Parts ori";
    begin
        exit(Parts.GetErrors(GetMessageType(), Errors));
    end;

    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Parts: Codeunit "TS Contract Parts ori";
    begin
        exit(Parts.GetEffect(GetMessageType(), Effect));
    end;

    procedure GetMetering(var Metering: JsonObject): Boolean
    begin
        exit(false);
    end;

    procedure GetRelated(var Related: JsonArray): Boolean
    var
        Parts: Codeunit "TS Contract Parts ori";
    begin
        exit(Parts.GetRelated(GetMessageType(), Related));
    end;

    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    var
        Parts: Codeunit "TS Contract Parts ori";
    begin
        exit(Parts.GetWorkflow(GetMessageType(), Workflow));
    end;

    procedure GetExamples(var Examples: JsonArray): Boolean
    var
        Parts: Codeunit "TS Contract Parts ori";
    begin
        exit(Parts.GetExamples(GetMessageType(), Examples));
    end;

    procedure GetOverview(var Overview: Text): Boolean
    var
        Parts: Codeunit "TS Contract Parts ori";
    begin
        exit(Parts.GetOverview(GetMessageType(), Overview));
    end;

    procedure GetNotes(var Notes: Text): Boolean
    var
        Parts: Codeunit "TS Contract Parts ori";
    begin
        exit(Parts.GetNotes(GetMessageType(), Notes));
    end;

    local procedure GetMessageType(): Enum "Message Type ori"
    begin
        exit(Enum::"Message Type ori"::"Timesheets.TimeSheet.Reopen");
    end;

    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit(Enum::"Msg Direction ori"::Inbound);
    end;

    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    var
        NativeMgt: Codeunit "TS Native Mgt ori";
    begin
        Argument.AssertVersion1();
        NativeMgt.ExecuteReopen(Argument);
    end;
}
