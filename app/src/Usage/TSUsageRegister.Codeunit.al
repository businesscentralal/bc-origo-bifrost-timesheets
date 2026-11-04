namespace Origo.Bifrost.Timesheets;

using Origo.Bifrost;

/// <summary>
/// Register for the dedicated time sheet usage lifecycle.
/// </summary>
codeunit 10036853 "TS Usage Register ori" implements "Msg Interface ori", "Msg Contract ori", "Msg Discovery ori"
{
    Access = Internal;

    /// <summary>IsEnabled for the usage register contract.</summary>
    procedure IsEnabled(): Boolean
    var
        NativeMgt: Codeunit "TS Usage Mgt ori";
    begin
        exit(NativeMgt.IsEnabled('Register'));
    end;

    /// <summary>GetFilterTableNo for the usage register contract.</summary>
    procedure GetFilterTableNo(): Integer
    begin
        exit(0);
    end;

    /// <summary>GetDescription for the usage register contract.</summary>
    procedure GetDescription(): Text[250]
    var
        DescriptionLbl: Label 'Registers owned item or resource usage.', Comment = 'is-IS=Skráir eigin vöru- eða forðanotkun.';
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>GetKeywords for the usage register contract.</summary>
    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'time sheet, usage, item, resource, register', Comment = 'is-IS=tímaskýrsla, notkun, vara, forði, skráning';
    begin
        exit(KeywordsLbl);
    end;

    /// <summary>GetSelectionDescription for the usage register contract.</summary>
    procedure GetSelectionDescription(): Text
    var
        SelectionLbl: Label 'Timesheets.Usage.Register: Registers owned item or resource usage.', Comment = 'is-IS=Timesheets.Usage.Register: Skráir eigin vöru- eða forðanotkun.';
    begin
        exit(SelectionLbl);
    end;

    /// <summary>GetEnvelope for the usage register contract.</summary>
    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    var
        Parts: Codeunit "TS Usage Contract ori";
    begin
        exit(Parts.GetEnvelope(GetMessageType(), Envelope));
    end;

    /// <summary>GetTarget for the usage register contract.</summary>
    procedure GetTarget(var Target: JsonArray): Boolean
    var
        Parts: Codeunit "TS Usage Contract ori";
    begin
        exit(Parts.GetTarget(GetMessageType(), Target));
    end;

    /// <summary>GetParameters for the usage register contract.</summary>
    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        Parts: Codeunit "TS Usage Contract ori";
    begin
        exit(Parts.AddRegisterParameters(Parameters));
    end;

    /// <summary>GetResponse for the usage register contract.</summary>
    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Parts: Codeunit "TS Usage Contract ori";
    begin
        exit(Parts.GetResponse(GetMessageType(), Response));
    end;

    /// <summary>GetErrors for the usage register contract.</summary>
    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Parts: Codeunit "TS Usage Contract ori";
    begin
        exit(Parts.GetErrors(GetMessageType(), Errors));
    end;

    /// <summary>GetEffect for the usage register contract.</summary>
    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Parts: Codeunit "TS Usage Contract ori";
    begin
        exit(Parts.GetEffect(GetMessageType(), Effect));
    end;

    /// <summary>GetMetering for the usage register contract.</summary>
    procedure GetMetering(var Metering: JsonObject): Boolean
    begin
        exit(false);
    end;

    /// <summary>GetRelated for the usage register contract.</summary>
    procedure GetRelated(var Related: JsonArray): Boolean
    var
        Parts: Codeunit "TS Usage Contract ori";
    begin
        exit(Parts.GetRelated(GetMessageType(), Related));
    end;

    /// <summary>GetWorkflow for the usage register contract.</summary>
    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    var
        Parts: Codeunit "TS Usage Contract ori";
    begin
        exit(Parts.GetWorkflow(GetMessageType(), Workflow));
    end;

    /// <summary>GetExamples for the usage register contract.</summary>
    procedure GetExamples(var Examples: JsonArray): Boolean
    var
        Parts: Codeunit "TS Usage Contract ori";
    begin
        exit(Parts.GetExamples(GetMessageType(), Examples));
    end;

    /// <summary>GetOverview for the usage register contract.</summary>
    procedure GetOverview(var Overview: Text): Boolean
    var
        Parts: Codeunit "TS Usage Contract ori";
    begin
        exit(Parts.GetOverview(GetMessageType(), Overview));
    end;

    /// <summary>GetNotes for the usage register contract.</summary>
    procedure GetNotes(var Notes: Text): Boolean
    var
        Parts: Codeunit "TS Usage Contract ori";
    begin
        exit(Parts.GetNotes(GetMessageType(), Notes));
    end;

    local procedure GetMessageType(): Enum "Message Type ori"
    begin
        exit(Enum::"Message Type ori"::"Timesheets.Usage.Register");
    end;

    /// <summary>GetMessageDirection for the usage register contract.</summary>
    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit(Enum::"Msg Direction ori"::Inbound);
    end;

    /// <summary>ExecuteBifrostTask for the usage register contract.</summary>
    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    var
        NativeMgt: Codeunit "TS Usage Mgt ori";
    begin
        Argument.AssertVersion1();
        NativeMgt.ExecuteRegister(Argument);
    end;
}
