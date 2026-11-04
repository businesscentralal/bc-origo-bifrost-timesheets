namespace Origo.Bifrost.Timesheets;

using Origo.Bifrost;

/// <summary>Localized contracts for the native Reopen, Post and Archive names.</summary>
codeunit 10036869 "TS Contract Parts ori"
{
    Access = Internal;

    var
        CutoffHelpLbl: Label 'ISO date cutoff. Sheets ending after this date are left out. Defaults to the work date.', Comment = 'is-IS=Lokadagur á ISO-sniði. Tímaskýrslum sem lýkur eftir þann dag er sleppt. Sjálfgefið er vinnudagsetningin.';
        JournalTemplateHelpLbl: Label 'Project journal template. The Timesheets setup value is used when omitted.', Comment = 'is-IS=Sniðmát verkbókar. Gildið í uppsetningu tímaskýrslna er notað ef því er sleppt.';
        JournalBatchHelpLbl: Label 'Project journal batch. The Timesheets setup value is used when omitted.', Comment = 'is-IS=Keyrsla verkbókar. Gildið í uppsetningu tímaskýrslna er notað ef því er sleppt.';
        BulkSubjectLbl: Label 'The Business Central time sheet operation addressed by the request.', Comment = 'is-IS=Aðgerð tímaskýrslu í Business Central sem beiðnin á við.';
        ReopenedCountLbl: Label 'Lines reopened.', Comment = 'is-IS=Línur sem voru opnaðar aftur.';
        PostedCountLbl: Label 'Project journal lines posted.', Comment = 'is-IS=Línur verkbókar sem voru bókaðar.';
        ArchivedCountLbl: Label 'Time sheets archived.', Comment = 'is-IS=Tímaskýrslur sem voru settar í geymslu.';
        MissingHelpLbl: Label 'A required key is missing.', Comment = 'is-IS=Nauðsynlegur lykill vantar.';
        MissingNextLbl: Label 'Send the missing key.', Comment = 'is-IS=Sendu lykilinn sem vantar.';
        FormatHelpLbl: Label 'A key has the wrong JSON type.', Comment = 'is-IS=Lykill er af röngu JSON-tagi.';
        FormatNextLbl: Label 'Send the key with the documented type.', Comment = 'is-IS=Sendu lykilinn með skráðu tagi.';
        UnknownHelpLbl: Label 'The request contains an unknown key.', Comment = 'is-IS=Beiðnin inniheldur óþekktan lykil.';
        UnknownNextLbl: Label 'Remove the unknown key.', Comment = 'is-IS=Fjarlægðu óþekkta lykilinn.';
        NotFoundHelpLbl: Label 'The journal identifier does not match a record.', Comment = 'is-IS=Auðkenni verkbókar passar ekki við færslu.';
        NotFoundNextLbl: Label 'Use an identifier that exists.', Comment = 'is-IS=Notaðu auðkenni sem er til.';
        ConflictHelpLbl: Label 'The request names a record in more than one way.', Comment = 'is-IS=Beiðnin nefnir færslu á fleiri en einn hátt.';
        ConflictNextLbl: Label 'Send only one identifier.', Comment = 'is-IS=Sendu aðeins eitt auðkenni.';
        PermissionHelpLbl: Label 'The caller cannot write the required time sheet or journal records.', Comment = 'is-IS=Kallandinn getur ekki skrifað nauðsynlegar tímaskýrslu- eða verkbókarfærslur.';
        PermissionNextLbl: Label 'Assign the BIFROST Timeshts ori permission set.', Comment = 'is-IS=Úthlutaðu heimildasamstæðunni BIFROST Timeshts ori.';
        RuntimeHelpLbl: Label 'Business Central rejected the operation.', Comment = 'is-IS=Business Central hafnaði aðgerðinni.';
        RetryHelpLbl: Label 'Review the time sheet and journal setup, then retry the call.', Comment = 'is-IS=Farðu yfir tímaskýrsluna og uppsetningu verkbókar og reyndu kallið aftur.';
        LegacyHelpLbl: Label 'The older Clockify.TimeSheet name still works and returns a deprecation warning.', Comment = 'is-IS=Eldra heitið Clockify.TimeSheet virkar enn og skilar viðvörun um úrelt heiti.';
        LegacyNextLbl: Label 'Use the native name.', Comment = 'is-IS=Notaðu innlenda heitið.';
        BulkPreconditionLbl: Label 'The caller has the BIFROST Timeshts ori permission set.', Comment = 'is-IS=Kallandinn hefur heimildasamstæðuna BIFROST Timeshts ori.';
        BulkChangesLbl: Label 'Changes eligible Business Central time sheets. A refused operation rolls back its own writes.', Comment = 'is-IS=Breytir gjaldgengum tímaskýrslum í Business Central. Ef aðgerð er hafnað eru eigin skrif hennar afturkölluð.';
        PostChangesLbl: Label 'Posts approved time sheet lines through the project journal and commits. Posted entries cannot be undone.', Comment = 'is-IS=Bókar samþykktar tímaskýrslulínur í gegnum verkbók og staðfestir færslurnar. Ekki er hægt að afturkalla bókaðar færslur.';
        BulkRelatedLbl: Label 'Discover the native names alongside the other message types.', Comment = 'is-IS=Finndu innlendu heitin ásamt öðrum skilaboðategundum.';
        BulkStepLbl: Label 'Run the time sheet operation.', Comment = 'is-IS=Keyrðu tímaskýrsluaðgerðina.';
        BulkWorkflowLbl: Label 'Review the returned count before the next call. The operation applies to every eligible time sheet.', Comment = 'is-IS=Farðu yfir fjöldann í svarinu áður en næsta kall er sent. Aðgerðin nær til allra gjaldgengra tímaskýrslna.';
        ReopenOverviewLbl: Label 'Reopens submitted or approved time sheet lines up to a cutoff date. Unknown keys are refused.', Comment = 'is-IS=Opnar aftur innsendar eða samþykktar tímaskýrslulínur til lokadags. Óþekktum lyklum er hafnað.';
        PostOverviewLbl: Label 'Posts approved time sheet lines and commits. This operation is irreversible. Unknown keys are refused.', Comment = 'is-IS=Bókar samþykktar tímaskýrslulínur og staðfestir færslurnar. Aðgerðin er óafturkræf. Óþekktum lyklum er hafnað.';
        ArchiveOverviewLbl: Label 'Archives fully posted time sheets and removes empty eligible sheets. The request has no parameters.', Comment = 'is-IS=Setur fullbókaðar tímaskýrslur í geymslu og fjarlægir tómar gjaldgengar skýrslur. Beiðnin hefur engar færibreytur.';
        ReopenNotesLbl: Label 'Returns reopenedLines, as Clockify.TimeSheet.Reopen does. The old name keeps working and warns: Use the native name.', Comment = 'is-IS=Skilar reopenedLines, eins og Clockify.TimeSheet.Reopen. Eldra heitið virkar áfram og varar við: Notaðu innlenda heitið.';
        PostNotesLbl: Label 'Returns postedLines, as Clockify.TimeSheet.Post does. Posting commits. The old name keeps working and warns: Use the native name.', Comment = 'is-IS=Skilar postedLines, eins og Clockify.TimeSheet.Post. Bókun staðfestir færslurnar. Eldra heitið virkar áfram og varar við: Notaðu innlenda heitið.';
        ArchiveNotesLbl: Label 'Returns archived, as Clockify.TimeSheet.Archive does. The old name keeps working and warns: Use the native name.', Comment = 'is-IS=Skilar archived, eins og Clockify.TimeSheet.Archive. Eldra heitið virkar áfram og varar við: Notaðu innlenda heitið.';

    /// <summary>Provides the AddReopenParameters contract chapter for the native aliases.</summary>
    procedure AddReopenParameters(var Parameters: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(ContractMgt.Parameter('endingDateTo', 'string', false, CutoffHelpLbl));
        exit(true);
    end;

    /// <summary>Provides the AddPostParameters contract chapter for the native aliases.</summary>
    procedure AddPostParameters(var Parameters: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(ContractMgt.Parameter('journalTemplate', 'string', false, JournalTemplateHelpLbl));
        Parameters.Add(ContractMgt.Parameter('journalBatch', 'string', false, JournalBatchHelpLbl));
        exit(true);
    end;

    /// <summary>Provides the AddArchiveParameters contract chapter for the native aliases.</summary>
    procedure AddArchiveParameters(var Parameters: JsonArray): Boolean
    begin
        exit(false);
    end;

    /// <summary>Describes the JSON envelope shared by the three native aliases.</summary>
    procedure GetEnvelope(MessageType: Enum "Message Type ori"; var Envelope: JsonObject): Boolean
    var
        Subject: JsonObject;
        Forms: JsonArray;
    begin
        Forms.Add('data');
        Subject.Add('use', 'optional');
        Subject.Add('forms', Forms);
        Subject.Add('description', BulkSubjectLbl);
        Envelope.Add('subject', Subject);
        Envelope.Add('dataRequired', true);
        Envelope.Add('version', '1.0');
        Envelope.Add('contentType', 'text/json');
        exit(true);
    end;

    /// <summary>The bulk aliases have no single-record target.</summary>
    procedure GetTarget(MessageType: Enum "Message Type ori"; var Target: JsonArray): Boolean
    begin
        exit(false);
    end;

    /// <summary>Preserves the count field returned by the existing operation.</summary>
    procedure GetResponse(MessageType: Enum "Message Type ori"; var Response: JsonObject): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Fields: JsonArray;
    begin
        Fields.Add(ContractMgt.ResponseField('status', 'string', 'Success'));
        case MessageType of
            MessageType::"Timesheets.TimeSheet.Reopen":
                Fields.Add(ContractMgt.ResponseField('reopenedLines', 'integer', ReopenedCountLbl));
            MessageType::"Timesheets.TimeSheet.Post":
                Fields.Add(ContractMgt.ResponseField('postedLines', 'integer', PostedCountLbl));
            MessageType::"Timesheets.TimeSheet.Archive":
                Fields.Add(ContractMgt.ResponseField('archived', 'integer', ArchivedCountLbl));
        end;
        Response.Add('contentType', 'text/json');
        Response.Add('fields', Fields);
        exit(true);
    end;

    /// <summary>Lists structured refusals and the legacy-name warning.</summary>
    procedure GetErrors(MessageType: Enum "Message Type ori"; var Errors: JsonArray): Boolean
    begin
        exit(GetBulkErrors(Errors));
    end;

    /// <summary>Documents write effects and posting commits.</summary>
    procedure GetEffect(MessageType: Enum "Message Type ori"; var Effect: JsonObject): Boolean
    begin
        exit(GetBulkEffect(MessageType, Effect));
    end;

    /// <summary>Links native-name discovery.</summary>
    procedure GetRelated(MessageType: Enum "Message Type ori"; var Related: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Related.Add(ContractMgt.RelatedEntry('Help.MessageTypes.Get', BulkRelatedLbl));
        exit(true);
    end;

    /// <summary>Explains the bulk operation and returned count.</summary>
    procedure GetWorkflow(MessageType: Enum "Message Type ori"; var Workflow: JsonObject): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Steps: JsonArray;
    begin
        Steps.Add(ContractMgt.WorkflowStep(MessageTypeName(MessageType), BulkStepLbl));
        Workflow.Add('steps', Steps);
        Workflow.Add('text', BulkWorkflowLbl);
        exit(true);
    end;

    /// <summary>Provides the GetExamples contract chapter for the native aliases.</summary>
    procedure GetExamples(MessageType: Enum "Message Type ori"; var Examples: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Name: Text;
    begin
        Name := MessageTypeName(MessageType);
        Examples.Add(ContractMgt.Example(Name, '{"type":"' + Name + '","data":' + ExampleRequest(MessageType) + '}', ExampleResponse(MessageType)));
        exit(true);
    end;

    /// <summary>Returns the localized purpose of the requested alias.</summary>
    procedure GetOverview(MessageType: Enum "Message Type ori"; var Overview: Text): Boolean
    begin
        case MessageType of
            MessageType::"Timesheets.TimeSheet.Reopen":
                Overview := ReopenOverviewLbl;
            MessageType::"Timesheets.TimeSheet.Post":
                Overview := PostOverviewLbl;
            MessageType::"Timesheets.TimeSheet.Archive":
                Overview := ArchiveOverviewLbl;
        end;
        exit(true);
    end;

    /// <summary>Provides the GetNotes contract chapter for the native aliases.</summary>
    procedure GetNotes(MessageType: Enum "Message Type ori"; var Notes: Text): Boolean
    begin
        Notes := NotesFor(MessageType);
        exit(Notes <> '');
    end;

    /// <summary>Provides the MessageTypeName contract chapter for the native aliases.</summary>
    procedure MessageTypeName(MessageType: Enum "Message Type ori"): Text
    begin
        exit(Enum::"Message Type ori".Names().Get(Enum::"Message Type ori".Ordinals().IndexOf(MessageType.AsInteger())));
    end;

    local procedure GetBulkErrors(var Errors: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::MissingParameter, MissingHelpLbl, MissingHelpLbl, MissingNextLbl));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::InvalidParameterFormat, FormatHelpLbl, FormatHelpLbl, FormatNextLbl));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::UnknownParameter, UnknownHelpLbl, UnknownHelpLbl, UnknownNextLbl));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::RecordNotFound, NotFoundHelpLbl, NotFoundHelpLbl, NotFoundNextLbl));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::ConflictingIdentifiers, ConflictHelpLbl, ConflictHelpLbl, ConflictNextLbl));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::PermissionDenied, PermissionHelpLbl, PermissionHelpLbl, PermissionNextLbl));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::BusinessCentralError, RuntimeHelpLbl, RuntimeHelpLbl, RetryHelpLbl));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::DeprecatedParameter, LegacyHelpLbl, LegacyHelpLbl, LegacyNextLbl));
        exit(true);
    end;

    local procedure GetBulkEffect(MessageType: Enum "Message Type ori"; var Effect: JsonObject): Boolean
    var
        Preconditions: JsonArray;
    begin
        if MessageType = MessageType::"Timesheets.TimeSheet.Post" then begin
            Effect.Add('effect', 'irreversible');
            Effect.Add('changes', PostChangesLbl);
        end else begin
            Effect.Add('effect', 'write');
            Effect.Add('changes', BulkChangesLbl);
        end;
        Preconditions.Add(BulkPreconditionLbl);
        Effect.Add('idempotent', false);
        Effect.Add('permissionSet', 'BIFROST Timeshts ori');
        Effect.Add('preconditions', Preconditions);
        exit(true);
    end;

    local procedure ExampleRequest(MessageType: Enum "Message Type ori"): Text
    begin
        case MessageType of
            MessageType::"Timesheets.TimeSheet.Reopen":
                exit('{"endingDateTo":"2026-06-30"}');
            MessageType::"Timesheets.TimeSheet.Post":
                exit('{"journalTemplate":"JOB","journalBatch":"DEFAULT"}');
            MessageType::"Timesheets.TimeSheet.Archive":
                exit('{}');
        end;
    end;

    local procedure ExampleResponse(MessageType: Enum "Message Type ori"): Text
    begin
        case MessageType of
            MessageType::"Timesheets.TimeSheet.Reopen":
                exit('{"status":"Success","reopenedLines":0}');
            MessageType::"Timesheets.TimeSheet.Post":
                exit('{"status":"Success","postedLines":0}');
            MessageType::"Timesheets.TimeSheet.Archive":
                exit('{"status":"Success","archived":0}');
        end;
    end;

    local procedure NotesFor(MessageType: Enum "Message Type ori"): Text
    begin
        case MessageType of
            MessageType::"Timesheets.TimeSheet.Reopen":
                exit(ReopenNotesLbl);
            MessageType::"Timesheets.TimeSheet.Post":
                exit(PostNotesLbl);
            MessageType::"Timesheets.TimeSheet.Archive":
                exit(ArchiveNotesLbl);
        end;
    end;
}
