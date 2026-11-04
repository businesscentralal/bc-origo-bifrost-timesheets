namespace Origo.Bifrost.Timesheets;

using Origo.Bifrost;

/// <summary>Contract and bilingual help for submitting owner time sheet lines.</summary>
codeunit 10036869 "TS Contract Parts ori"
{
    Access = Internal;

    /// <summary>Handles AddSubmitParameters for the Submit message contract.</summary>
    procedure AddSubmitParameters(var Parameters: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(ContractMgt.Parameter('timeSheetNo', 'string', false, SheetTxt));
        Parameters.Add(ContractMgt.Parameter('resourceNo', 'string', false, ResourceTxt));
        Parameters.Add(ContractMgt.Parameter('date', 'string', false, DateTxt));
        Parameters.Add(ContractMgt.Parameter('lineNos', 'array', false, LinesTxt));
        exit(true);
    end;

    /// <summary>Returns GetEnvelope for the Submit message contract.</summary>
    procedure GetEnvelope(MessageType: Enum "Message Type ori"; var Envelope: JsonObject): Boolean
    var
        Subject: JsonObject;
        Forms: JsonArray;
    begin
        Forms.Add('data');
        Subject.Add('use', 'optional');
        Subject.Add('forms', Forms);
        Envelope.Add('subject', Subject);
        Envelope.Add('dataRequired', true);
        Envelope.Add('version', '1.0');
        Envelope.Add('contentType', 'text/json');
        exit(true);
    end;

    /// <summary>Returns GetTarget for the Submit message contract.</summary>
    procedure GetTarget(MessageType: Enum "Message Type ori"; var Target: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Target.Add(ContractMgt.TargetEntry('data.timeSheetNo', 'string', SheetTxt));
        exit(true);
    end;

    /// <summary>Returns GetResponse for the Submit message contract.</summary>
    procedure GetResponse(MessageType: Enum "Message Type ori"; var Response: JsonObject): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Fields: JsonArray;
    begin
        Fields.Add(ContractMgt.ResponseField('status', 'string', SuccessTxt));
        Fields.Add(ContractMgt.ResponseField('lines', 'array', ResponseTxt));
        Response.Add('contentType', 'text/json');
        Response.Add('fields', Fields);
        exit(true);
    end;

    /// <summary>Returns GetErrors for the Submit message contract.</summary>
    procedure GetErrors(MessageType: Enum "Message Type ori"; var Errors: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::MissingParameter, MissingTxt, MissingTxt, MissingNextTxt));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::InvalidParameterFormat, TypeTxt, TypeTxt, TypeNextTxt));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::UnknownParameter, UnknownTxt, UnknownTxt, UnknownNextTxt));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::RecordNotFound, NotFoundTxt, NotFoundTxt, NotFoundNextTxt));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::ConflictingIdentifiers, ConflictTxt, ConflictTxt, ConflictNextTxt));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::PermissionDenied, PermissionTxt, PermissionTxt, PermissionNextTxt));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::PermissionDenied, OwnerTxt, OwnerTxt, OwnerNextTxt));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::PreconditionFailed, EmptyTxt, EmptyTxt, EmptyNextTxt));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::InvalidLine, LineTxt, LineTxt, LineNextTxt));
        exit(true);
    end;

    /// <summary>Returns GetEffect for the Submit message contract.</summary>
    procedure GetEffect(MessageType: Enum "Message Type ori"; var Effect: JsonObject): Boolean
    begin
        Effect.Add('effect', 'write');
        Effect.Add('changes', EffectTxt);
        Effect.Add('idempotent', true);
        Effect.Add('permissionSet', 'BIFROST Timeshts ori');
        exit(true);
    end;

    /// <summary>Returns GetRelated for the Submit message contract.</summary>
    procedure GetRelated(MessageType: Enum "Message Type ori"; var Related: JsonArray): Boolean
    begin
        exit(false);
    end;

    /// <summary>Returns GetWorkflow for the Submit message contract.</summary>
    procedure GetWorkflow(MessageType: Enum "Message Type ori"; var Workflow: JsonObject): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Steps: JsonArray;
    begin
        Steps.Add(ContractMgt.WorkflowStep('Timesheets.TimeSheet.Submit', OverviewTxt));
        Workflow.Add('steps', Steps);
        Workflow.Add('text', ResponseTxt);
        exit(true);
    end;

    /// <summary>Returns GetExamples for the Submit message contract.</summary>
    procedure GetExamples(MessageType: Enum "Message Type ori"; var Examples: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Examples.Add(ContractMgt.Example('Timesheets.TimeSheet.Submit', '{"type":"Timesheets.TimeSheet.Submit","data":{"timeSheetNo":"TS0001","lineNos":[10000]}}', '{"status":"Success","lines":[{"timeSheetNo":"TS0001","lineNo":10000,"status":"Submitted","changed":true}]}'));
        exit(true);
    end;

    /// <summary>Returns GetOverview for the Submit message contract.</summary>
    procedure GetOverview(MessageType: Enum "Message Type ori"; var Overview: Text): Boolean
    begin
        Overview := OverviewTxt;
        exit(true);
    end;

    /// <summary>Returns GetNotes for the Submit message contract.</summary>
    procedure GetNotes(MessageType: Enum "Message Type ori"; var Notes: Text): Boolean
    begin
        Notes := NotesTxt;
        exit(true);
    end;

    var
        SheetTxt: Label 'Time sheet number. Send this or resourceNo plus date.', Comment = 'is-IS=Númer tímaskýrslu. Sendu þetta eða resourceNo ásamt date.';
        ResourceTxt: Label 'Resource number, together with date, when timeSheetNo is omitted.', Comment = 'is-IS=Númer auðlindar ásamt date þegar timeSheetNo er sleppt.';
        DateTxt: Label 'ISO date inside the time sheet, together with resourceNo.', Comment = 'is-IS=ISO-dagsetning innan tímaskýrslunnar ásamt resourceNo.';
        LinesTxt: Label 'Optional line numbers. Omit for all open lines. An empty array selects none.', Comment = 'is-IS=Valfrjáls línunúmer. Sleppt til að velja allar opnar línur. Tómt fylki velur engar.';
        SuccessTxt: Label 'Success.', Comment = 'is-IS=Tókst.';
        ResponseTxt: Label 'Lines with timeSheetNo, lineNo, status and changed. Submitted lines return changed false. Empty lines follow the Business Central submission policy.', Comment = 'is-IS=Línur með timeSheetNo, lineNo, status og changed. Innsendar línur skila changed false. Tómar línur fylgja innsendingarstefnu Business Central.';
        MissingTxt: Label 'A required key is missing.', Comment = 'is-IS=Nauðsynlegur lykill vantar.';
        MissingNextTxt: Label 'Send the missing key.', Comment = 'is-IS=Sendu lykilinn sem vantar.';
        TypeTxt: Label 'A key has the wrong JSON type.', Comment = 'is-IS=Lykill er af röngu JSON-tagi.';
        TypeNextTxt: Label 'Send the key with the documented type.', Comment = 'is-IS=Sendu lykilinn með skráðu tagi.';
        UnknownTxt: Label 'The request contains an unknown key.', Comment = 'is-IS=Beiðnin inniheldur óþekktan lykil.';
        UnknownNextTxt: Label 'Remove the unknown key.', Comment = 'is-IS=Fjarlægðu óþekkta lykilinn.';
        NotFoundTxt: Label 'The identifier does not match a record.', Comment = 'is-IS=Auðkennið passar ekki við færslu.';
        NotFoundNextTxt: Label 'Use an identifier that exists.', Comment = 'is-IS=Notaðu auðkenni sem er til.';
        ConflictTxt: Label 'The request names the time sheet in more than one way.', Comment = 'is-IS=Beiðnin nefnir tímaskýrsluna á fleiri en einn hátt.';
        ConflictNextTxt: Label 'Send only one identifier for the time sheet.', Comment = 'is-IS=Sendu aðeins eitt auðkenni fyrir tímaskýrsluna.';
        PermissionTxt: Label 'The caller cannot write time sheets.', Comment = 'is-IS=Kallandinn getur ekki skrifað tímaskýrslur.';
        PermissionNextTxt: Label 'Assign the BIFROST Timeshts ori permission set.', Comment = 'is-IS=Úthlutaðu heimildasamstæðunni BIFROST Timeshts ori.';
        OwnerTxt: Label 'The caller is not the owner of the time sheet.', Comment = 'is-IS=Kallandinn er ekki eigandi tímaskýrslunnar.';
        OwnerNextTxt: Label 'Only the owner can submit; ask the owner.', Comment = 'is-IS=Aðeins eigandinn getur sent inn. Biddu eigandann.';
        EmptyTxt: Label 'The time sheet has no open lines.', Comment = 'is-IS=Tímaskýrslan hefur engar opnar línur.';
        EmptyNextTxt: Label 'Add lines first.', Comment = 'is-IS=Bættu við línum fyrst.';
        LineTxt: Label 'Business Central rejected the line.', Comment = 'is-IS=Business Central hafnaði línunni.';
        LineNextTxt: Label 'Fix the line and submit again.', Comment = 'is-IS=Lagfærðu línuna og sendu aftur inn.';
        EffectTxt: Label 'Submits selected open lines. Each successful call commits. If any line fails, all changes from this call roll back.', Comment = 'is-IS=Sendir valdar opnar línur inn. Hvert heppnað kall staðfestir breytingar. Ef einhver lína bregst eru allar breytingar kallsins afturkallaðar.';
        OverviewTxt: Label 'Timesheets.TimeSheet.Submit lets the time sheet owner submit open lines for approval.', Comment = 'is-IS=Timesheets.TimeSheet.Submit gerir eiganda tímaskýrslu kleift að senda opnar línur til samþykktar.';
        NotesTxt: Label 'Owner only. Parameters: timeSheetNo, or resourceNo and date; optional lineNos. MissingParameter: Send the missing key. InvalidParameterFormat: Send the key with the documented type. UnknownParameter: Remove the unknown key. RecordNotFound: Use an identifier that exists. ConflictingIdentifiers: Send only one identifier for the time sheet. PermissionDenied: Only the owner can submit; ask the owner. PermissionDenied for missing access: Assign the BIFROST Timeshts ori permission set. PreconditionFailed: Add lines first. InvalidLine: Fix the line and submit again. PreconditionFailed in an uncommitted batch: Submit outside an uncommitted batch. Submitted lines return changed false. Empty lines follow the Business Central submission policy. A successful call commits; a failed submission rolls back every selected line.', Comment = 'is-IS=Aðeins eigandinn getur sent inn. Færibreytur: timeSheetNo eða resourceNo og date; valfrjáls lineNos. MissingParameter: Sendu lykilinn sem vantar. InvalidParameterFormat: Sendu lykilinn með skráðu tagi. UnknownParameter: Fjarlægðu óþekkta lykilinn. RecordNotFound: Notaðu auðkenni sem er til. ConflictingIdentifiers: Sendu aðeins eitt auðkenni fyrir tímaskýrsluna. PermissionDenied: Aðeins eigandinn getur sent inn. Biddu eigandann. PermissionDenied vegna aðgangs: Úthlutaðu heimildasamstæðunni BIFROST Timeshts ori. PreconditionFailed: Bættu við línum fyrst. InvalidLine: Lagfærðu línuna og sendu aftur inn. PreconditionFailed í óstaðfestri lotu: Sendu inn utan óstaðfestrar lotu. Innsendar línur skila changed false. Tómar línur fylgja innsendingarstefnu Business Central. Heppnað kall staðfestir breytingar; misheppnuð innsending afturkallar allar valdar línur.';
}
