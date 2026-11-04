namespace Origo.Bifrost.Timesheets;

using Origo.Bifrost;

/// <summary>
/// Reverse for the dedicated time sheet usage lifecycle.
/// </summary>
codeunit 10036867 "TS Usage Reverse ori" implements "Msg Interface ori", "Msg Contract ori", "Msg Discovery ori"
{
    Access = Internal;

    /// <summary>IsEnabled for the usage reverse contract.</summary>
    procedure IsEnabled(): Boolean
    var
        NativeMgt: Codeunit "TS Usage Mgt ori";
    begin
        exit(NativeMgt.IsEnabled('Reverse'));
    end;

    /// <summary>GetFilterTableNo for the usage reverse contract.</summary>
    procedure GetFilterTableNo(): Integer
    begin
        exit(0);
    end;

    /// <summary>GetDescription for the usage reverse contract.</summary>
    procedure GetDescription(): Text[250]
    var
        DescriptionLbl: Label 'Reverses posted usage once, optionally creating a reversing journal.', Comment = 'is-IS=Bakfærir bókaða notkun einu sinni og stofnar valfrjálst bakfærslulínu.';
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>GetKeywords for the usage reverse contract.</summary>
    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'time sheet, usage, item, resource, reverse', Comment = 'is-IS=tímaskýrsla, notkun, vara, forði';
    begin
        exit(KeywordsLbl);
    end;

    /// <summary>GetSelectionDescription for the usage reverse contract.</summary>
    procedure GetSelectionDescription(): Text
    var
        SelectionLbl: Label 'Timesheets.Usage.Reverse: Reverses posted usage once, optionally creating a reversing journal.', Comment = 'is-IS=Timesheets.Usage.Reverse: Bakfærir bókaða notkun einu sinni og stofnar valfrjálst bakfærslulínu.';
    begin
        exit(SelectionLbl);
    end;

    /// <summary>GetEnvelope for the usage reverse contract.</summary>
    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    var
        Parts: Codeunit "TS Usage Contract ori";
    begin
        exit(Parts.GetEnvelope(GetMessageType(), Envelope));
    end;

    /// <summary>GetTarget for the usage reverse contract.</summary>
    procedure GetTarget(var Target: JsonArray): Boolean
    var
        Parts: Codeunit "TS Usage Contract ori";
    begin
        exit(Parts.GetTarget(GetMessageType(), Target));
    end;

    /// <summary>GetParameters for the usage reverse contract.</summary>
    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        Parts: Codeunit "TS Usage Contract ori";
    begin
        exit(Parts.AddParameters('Reverse', Parameters));
    end;

    /// <summary>GetResponse for the usage reverse contract.</summary>
    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Parts: Codeunit "TS Usage Contract ori";
    begin
        exit(Parts.GetResponse(GetMessageType(), Response));
    end;

    /// <summary>GetErrors for the usage reverse contract.</summary>
    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Parts: Codeunit "TS Usage Contract ori";
    begin
        exit(Parts.GetErrors(GetMessageType(), Errors));
    end;

    /// <summary>GetEffect for the usage reverse contract.</summary>
    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Parts: Codeunit "TS Usage Contract ori";
    begin
        exit(Parts.GetEffect(GetMessageType(), Effect));
    end;

    /// <summary>GetMetering for the usage reverse contract.</summary>
    procedure GetMetering(var Metering: JsonObject): Boolean
    begin
        exit(false);
    end;

    /// <summary>GetRelated for the usage reverse contract.</summary>
    procedure GetRelated(var Related: JsonArray): Boolean
    var
        Parts: Codeunit "TS Usage Contract ori";
    begin
        exit(Parts.GetRelated(GetMessageType(), Related));
    end;

    /// <summary>GetWorkflow for the usage reverse contract.</summary>
    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    var
        Parts: Codeunit "TS Usage Contract ori";
    begin
        exit(Parts.GetWorkflow(GetMessageType(), Workflow));
    end;

    /// <summary>GetExamples for the usage reverse contract.</summary>
    procedure GetExamples(var Examples: JsonArray): Boolean
    var
        Parts: Codeunit "TS Usage Contract ori";
    begin
        exit(Parts.GetExamples(GetMessageType(), Examples));
    end;

    /// <summary>GetOverview for the usage reverse contract.</summary>
    procedure GetOverview(var Overview: Text): Boolean
    var
        Parts: Codeunit "TS Usage Contract ori";
    begin
        exit(Parts.GetOverview(GetMessageType(), Overview));
    end;

    /// <summary>GetNotes for the usage reverse contract.</summary>
    procedure GetNotes(var Notes: Text): Boolean
    var
        Parts: Codeunit "TS Usage Contract ori";
    begin
        exit(Parts.GetNotes(GetMessageType(), Notes));
    end;

    local procedure GetMessageType(): Enum "Message Type ori"
    begin
        exit(Enum::"Message Type ori"::"Timesheets.Usage.Reverse");
    end;

    /// <summary>GetMessageDirection for the usage reverse contract.</summary>
    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit(Enum::"Msg Direction ori"::Inbound);
    end;

    /// <summary>ExecuteBifrostTask for the usage reverse contract.</summary>
    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    var
        NativeMgt: Codeunit "TS Usage Mgt ori";
    begin
        Argument.AssertVersion1();
        NativeMgt.Execute(Argument, 'Reverse');
    end;
}
