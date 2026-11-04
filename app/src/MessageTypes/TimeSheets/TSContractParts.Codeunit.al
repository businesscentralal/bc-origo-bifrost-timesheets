namespace Origo.Bifrost.Timesheets;

using Origo.Bifrost;

/// <summary>Localized contracts for issue 63 manager decisions.</summary>
codeunit 10036869 "TS Contract Parts ori"
{
    Access = Internal;

    var
        SheetTxt: Label 'Time sheet number. Send exactly one of timeSheetNo and timeSheetId.', Comment = 'is-IS=Númer tímaskýrslu. Sendu nákvæmlega annað hvort timeSheetNo eða timeSheetId.';
        IdTxt: Label 'Time sheet SystemId as a GUID; alternative to timeSheetNo.', Comment = 'is-IS=SystemId tímaskýrslu sem GUID; valkostur við timeSheetNo.';
        LinesTxt: Label 'Positive integer line numbers. Omitted selects all submitted lines; an empty array selects none.', Comment = 'is-IS=Jákvæðar heiltölur línunúmera. Sé sleppt eru allar innsendar línur valdar; tómt fylki velur engar.';
        CommentTxt: Label 'Optional rejection comment, at most 80 characters, stored on every rejected line.', Comment = 'is-IS=Valfrjáls höfnunarathugasemd, að hámarki 80 stafir, vistuð á hverri hafnaðri línu.';
        EnvelopeTxt: Label 'Identify the time sheet in data.', Comment = 'is-IS=Auðkenndu tímaskýrsluna í data.';
        StatusTxt: Label 'Success or Error.', Comment = 'is-IS=Success eða Error.';
        ResponseTxt: Label 'Selected lines: timeSheetNo, lineNo, status (Approved or Rejected), changed. Already approved selected lines return changed false for approval.', Comment = 'is-IS=Valdar línur: timeSheetNo, lineNo, status (Approved eða Rejected), changed. Þegar samþykktar valdar línur skila changed false við samþykki.';
        PermissionTxt: Label 'Assign the BIFROST Timeshts ori permission set.', Comment = 'is-IS=Úthlutaðu heimildasamstæðunni BIFROST Timeshts ori.';
        ApproverTxt: Label 'Only the approver named on the time sheet can approve.', Comment = 'is-IS=Aðeins samþykktaraðilinn sem er nefndur á tímaskýrslunni getur samþykkt.';
        SubmitTxt: Label 'Submit it first with Timesheets.TimeSheet.Submit.', Comment = 'is-IS=Sendu hana fyrst inn með Timesheets.TimeSheet.Submit.';
        MissingTxt: Label 'A required identifier is missing.', Comment = 'is-IS=Nauðsynlegt auðkenni vantar.';
        MissingNextTxt: Label 'Send the missing key.', Comment = 'is-IS=Sendu lykilinn sem vantar.';
        FormatTxt: Label 'A key has an invalid type, length or value.', Comment = 'is-IS=Lykill er af röngu tagi, lengd eða gildi.';
        FormatNextTxt: Label 'Send the key with the documented type.', Comment = 'is-IS=Sendu lykilinn með skráðu tagi.';
        UnknownTxt: Label 'The request contains an unknown key.', Comment = 'is-IS=Beiðnin inniheldur óþekktan lykil.';
        UnknownNextTxt: Label 'Remove the unknown key.', Comment = 'is-IS=Fjarlægðu óþekkta lykilinn.';
        NotFoundTxt: Label 'The time sheet or selected line does not exist.', Comment = 'is-IS=Tímaskýrslan eða valin lína er ekki til.';
        NotFoundNextTxt: Label 'Use an identifier that exists.', Comment = 'is-IS=Notaðu auðkenni sem er til.';
        ConflictTxt: Label 'Both timeSheetNo and timeSheetId were supplied.', Comment = 'is-IS=Bæði timeSheetNo og timeSheetId voru send.';
        ConflictNextTxt: Label 'Send only one identifier for the time sheet.', Comment = 'is-IS=Sendu aðeins eitt auðkenni fyrir tímaskýrsluna.';
        PermissionErrorTxt: Label 'The caller lacks access to a table used by this action.', Comment = 'is-IS=Kallandinn hefur ekki aðgang að töflu sem aðgerðin notar.';
        ApproverErrorTxt: Label 'The caller is not the named approver.', Comment = 'is-IS=Kallandinn er ekki tilgreindur samþykktaraðili.';
        InvalidLineTxt: Label 'The selected line is not Submitted. Approval alone accepts an already Approved line as unchanged.', Comment = 'is-IS=Valin lína er ekki innsend. Aðeins samþykki tekur við þegar samþykktri línu án breytinga.';
        RuntimeTxt: Label 'Business Central refused the action; all selected changes were rolled back.', Comment = 'is-IS=Business Central hafnaði aðgerðinni; allar valdar breytingar voru afturkallaðar.';
        RuntimeNextTxt: Label 'Correct the Business Central error and retry.', Comment = 'is-IS=Leiðréttu Business Central villuna og reyndu aftur.';
        IsolatedTxt: Label 'This action requires an isolated transaction.', Comment = 'is-IS=Þessi aðgerð krefst einangraðrar færslu.';
        IsolatedNextTxt: Label 'Run the request without omitCommit.', Comment = 'is-IS=Keyrðu beiðnina án omitCommit.';
        EffectTxt: Label 'Approves or rejects selected submitted lines atomically through the native time sheet action. A successful call commits; a failed action rolls back all selected changes. Approving absence lines also posts their absence entries.', Comment = 'is-IS=Samþykkir eða hafnar völdum innsendum línum í einni færslu með innbyggðri tímaskýrsluaðgerð. Heppnað kall staðfestir; misheppnuð aðgerð afturkallar allar valdar breytingar. Samþykki fjarvistarlína bókar einnig fjarvistarfærslur.';
        OverviewTxt: Label 'Manager approval and rejection of submitted time sheet lines. Only the sheet approver may act. Existing Clockify approval behavior is unchanged. Unknown keys are refused.', Comment = 'is-IS=Samþykki stjórnanda og höfnun innsendra tímaskýrslulína. Aðeins samþykktaraðili skýrslunnar má framkvæma aðgerðina. Núverandi samþykktarvirkni Clockify er óbreytt. Óþekktum lyklum er hafnað.';
        NotesTxt: Label 'Omitted lineNos selects only submitted lines. Empty lineNos returns an empty list. Approval of an explicitly selected approved line returns changed false. Rejection requires Submitted for every selected line. Status is returned in a language-independent form. A successful action commits; omitCommit is not supported.', Comment = 'is-IS=Sé lineNos sleppt eru aðeins innsendar línur valdar. Tómt lineNos skilar tómum lista. Samþykki sérstaklega valinnar samþykktrar línu skilar changed false. Höfnun krefst þess að allar valdar línur séu innsendar. Staða er skilað óháð tungumáli. Heppnuð aðgerð staðfestir; omitCommit er ekki stutt.';
        WorkflowTxt: Label 'Submit the lines, then let the sheet approver approve or reject them. Read the returned status and changed flag.', Comment = 'is-IS=Sendu línurnar inn, láttu síðan samþykktaraðila skýrslunnar samþykkja eða hafna þeim. Lestu stöðuna og changed merkið í svarinu.';
        RelatedTxt: Label 'Discover the available time sheet operations.', Comment = 'is-IS=Finndu tiltækar tímaskýrsluaðgerðir.';

    /// <summary>Declares the approval request keys.</summary>
    procedure AddApproveParameters(var Parameters: JsonArray): Boolean
    begin
        AddDecisionParameters(Parameters);
        exit(true);
    end;

    /// <summary>Declares rejection keys including the optional comment.</summary>
    procedure AddRejectParameters(var Parameters: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        AddDecisionParameters(Parameters);
        Parameters.Add(ContractMgt.Parameter('comment', 'string', false, CommentTxt));
        exit(true);
    end;

    local procedure AddDecisionParameters(var Parameters: JsonArray)
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(ContractMgt.Parameter('timeSheetNo', 'string', false, SheetTxt));
        Parameters.Add(ContractMgt.Parameter('timeSheetId', 'string', false, IdTxt));
        Parameters.Add(ContractMgt.Parameter('lineNos', 'array', false, LinesTxt));
    end;

    /// <summary>Describes the versioned JSON envelope.</summary>
    procedure GetEnvelope(MessageType: Enum "Message Type ori"; var Envelope: JsonObject): Boolean
    var
        Subject: JsonObject;
        Forms: JsonArray;
    begin
        Forms.Add('data');
        Subject.Add('use', 'optional');
        Subject.Add('forms', Forms);
        Subject.Add('description', EnvelopeTxt);
        Envelope.Add('subject', Subject);
        Envelope.Add('dataRequired', true);
        Envelope.Add('version', '1.0');
        Envelope.Add('contentType', 'text/json');
        exit(true);
    end;

    /// <summary>Describes the alternative time sheet identifiers.</summary>
    procedure GetTarget(MessageType: Enum "Message Type ori"; var Target: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Target.Add(ContractMgt.TargetEntry('data.timeSheetNo', 'string', SheetTxt));
        Target.Add(ContractMgt.TargetEntry('data.timeSheetId', 'string', IdTxt));
        exit(true);
    end;

    /// <summary>Describes the returned decision lines.</summary>
    procedure GetResponse(MessageType: Enum "Message Type ori"; var Response: JsonObject): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Fields: JsonArray;
    begin
        Fields.Add(ContractMgt.ResponseField('status', 'string', StatusTxt));
        Fields.Add(ContractMgt.ResponseField('lines', 'array', ResponseTxt));
        Response.Add('contentType', 'text/json');
        Response.Add('fields', Fields);
        exit(true);
    end;

    /// <summary>Lists refusals and corrective next steps.</summary>
    procedure GetErrors(MessageType: Enum "Message Type ori"; var Errors: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::MissingParameter, MissingTxt, MissingTxt, MissingNextTxt));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::InvalidParameterFormat, FormatTxt, FormatTxt, FormatNextTxt));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::UnknownParameter, UnknownTxt, UnknownTxt, UnknownNextTxt));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::RecordNotFound, NotFoundTxt, NotFoundTxt, NotFoundNextTxt));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::ConflictingIdentifiers, ConflictTxt, ConflictTxt, ConflictNextTxt));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::PermissionDenied, PermissionErrorTxt, PermissionErrorTxt, PermissionTxt));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::PermissionDenied, ApproverErrorTxt, ApproverErrorTxt, ApproverTxt));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::InvalidLine, InvalidLineTxt, InvalidLineTxt, SubmitTxt));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::BusinessCentralError, RuntimeTxt, RuntimeTxt, RuntimeNextTxt));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::PreconditionFailed, IsolatedTxt, IsolatedTxt, IsolatedNextTxt));
        exit(true);
    end;

    /// <summary>Documents commits and native absence posting side effects.</summary>
    procedure GetEffect(MessageType: Enum "Message Type ori"; var Effect: JsonObject): Boolean
    var
        Preconditions: JsonArray;
    begin
        Preconditions.Add(PermissionTxt);
        Preconditions.Add(ApproverTxt);
        Effect.Add('effect', 'write');
        Effect.Add('changes', EffectTxt);
        Effect.Add('idempotent', MessageType = MessageType::"Timesheets.TimeSheet.Approve");
        Effect.Add('permissionSet', 'BIFROST Timeshts ori');
        Effect.Add('preconditions', Preconditions);
        exit(true);
    end;

    /// <summary>Links available message discovery.</summary>
    procedure GetRelated(MessageType: Enum "Message Type ori"; var Related: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Related.Add(ContractMgt.RelatedEntry('Help.MessageTypes.Get', RelatedTxt));
        exit(true);
    end;

    /// <summary>Explains the manager decision workflow.</summary>
    procedure GetWorkflow(MessageType: Enum "Message Type ori"; var Workflow: JsonObject): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Steps: JsonArray;
    begin
        Steps.Add(ContractMgt.WorkflowStep(MessageTypeName(MessageType), WorkflowTxt));
        Workflow.Add('steps', Steps);
        Workflow.Add('text', WorkflowTxt);
        exit(true);
    end;

    /// <summary>Provides the action's request and response example.</summary>
    procedure GetExamples(MessageType: Enum "Message Type ori"; var Examples: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        TypeName: Text;
        RequestText: Text;
        ResponseText: Text;
    begin
        TypeName := MessageTypeName(MessageType);
        RequestText := '{"type":"' + TypeName + '","data":{"timeSheetNo":"TS0001","lineNos":[10000]}}';
        if MessageType = MessageType::"Timesheets.TimeSheet.Reject" then
            ResponseText := '{"status":"Success","lines":[{"timeSheetNo":"TS0001","lineNo":10000,"status":"Rejected","changed":true}]}'
        else
            ResponseText := '{"status":"Success","lines":[{"timeSheetNo":"TS0001","lineNo":10000,"status":"Approved","changed":true}]}';
        Examples.Add(ContractMgt.Example(TypeName, RequestText, ResponseText));
        exit(true);
    end;

    /// <summary>Returns the localized purpose.</summary>
    procedure GetOverview(MessageType: Enum "Message Type ori"; var Overview: Text): Boolean
    begin
        Overview := OverviewTxt;
        exit(true);
    end;

    /// <summary>Returns edge cases and transaction limitations.</summary>
    procedure GetNotes(MessageType: Enum "Message Type ori"; var Notes: Text): Boolean
    begin
        Notes := NotesTxt;
        exit(true);
    end;

    local procedure MessageTypeName(MessageType: Enum "Message Type ori"): Text
    begin
        exit(MessageType.Names().Get(MessageType.Ordinals().IndexOf(MessageType.AsInteger())));
    end;
}
