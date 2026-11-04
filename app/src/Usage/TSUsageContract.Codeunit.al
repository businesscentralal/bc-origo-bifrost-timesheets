namespace Origo.Bifrost.Timesheets;

using Origo.Bifrost;

/// <summary>Describes the dedicated usage lifecycle and stable JSON contracts.</summary>
codeunit 10036860 "TS Usage Contract ori"
{
    Access = Internal;
    var
        timeSheetNoLbl: Label 'Time sheet number.', Comment = 'is-IS=Númer tímaskýrslu.';
        lineNoLbl: Label 'Existing time sheet line number.', Comment = 'is-IS=Númer gildrar tímaskýrslulínu.';
        typeLbl: Label 'Item or Resource.', Comment = 'is-IS=Item eða Resource.';
        noLbl: Label 'Existing unblocked item or resource number.', Comment = 'is-IS=Númer gildrar ólokaðrar vöru eða forða.';
        dateLbl: Label 'ISO date inside the sheet week.', Comment = 'is-IS=ISO dagsetning innan viku skýrslunnar.';
        quantityLbl: Label 'Positive usage quantity.', Comment = 'is-IS=Jákvætt notkunarmagn.';
        unitOfMeasureLbl: Label 'Unit of measure; defaults to base unit.', Comment = 'is-IS=Mælieining; grunnmælieining er sjálfgefin.';
        descriptionLbl: Label 'Optional description, at most 100 characters.', Comment = 'is-IS=Valfrjáls lýsing, mest 100 stafir.';
        entryNosLbl: Label 'Alternative to entryNo: one to 200 usage entry numbers, transferred atomically.', Comment = 'is-IS=Valkostur við entryNo: eitt til 200 notkunarfærslunúmer, flutt saman í einni færslu.';
        entryNoLbl: Label 'Usage entry number.', Comment = 'is-IS=Númer notkunarfærslu.';
        commentLbl: Label 'Optional rejection comment, at most 80 characters.', Comment = 'is-IS=Valfrjáls höfnunarathugasemd, mest 80 stafir.';
        journalTemplateLbl: Label 'Existing journal template, at most 10 characters.', Comment = 'is-IS=Gilt sniðmát færslubókar, mest 10 stafir.';
        journalBatchLbl: Label 'Existing journal batch, at most 10 characters.', Comment = 'is-IS=Gild keyrsla færslubókar, mest 10 stafir.';
        createJournalLbl: Label 'Create a negative-quantity reversal journal. Default false.', Comment = 'is-IS=Stofna bakfærslulínu með neikvæðu magni. Sjálfgefið false.';
        weekLbl: Label 'First date of an inclusive seven-day usage window.', Comment = 'is-IS=Fyrsti dagur sjö daga notkunartímabils.';
        statusLbl: Label 'Open, Submitted, Approved, Rejected or Posted.', Comment = 'is-IS=Open, Submitted, Approved, Rejected eða Posted.';
        afterEntryNoLbl: Label 'Continue after this entry number, retaining filters.', Comment = 'is-IS=Halda áfram eftir þetta færslunúmer með sömu síum.';
        limitLbl: Label 'Maximum visible lines, 1..200; default 50.', Comment = 'is-IS=Hámarksfjöldi sýnilegra lína, 1..200; sjálfgefið 50.';
        OverviewLbl: Label 'Register usage on an owned open time sheet line. Submit it, then the independent sheet approver approves or rejects it. Transfer creates journals without posting; native posting records the ledger entry. Only Posted usage can be reversed, once.', Comment = 'is-IS=Skráðu notkun á eigin opinni tímaskýrslulínu. Sendu hana inn og óháður samþykktaraðili skýrslunnar samþykkir eða hafnar. Transfer stofnar færslubók án bókunar; innbyggð bókun skráir bókað færslunúmer. Aðeins bókaða notkun má bakfæra, einu sinni.';
        NotesLbl: Label 'List is read-only and scoped to the owner or submitted lines addressed to the approver. Retain the filters with afterEntryNo. All writes require an isolated transaction. Unknown keys are refused. Journal fields and status cannot be changed through Data.Records.Set.', Comment = 'is-IS=List er skrifvarið og takmarkað við eiganda eða innsendar línur ætlaðar samþykktaraðila. Haltu sömu síum með afterEntryNo. Allar skrifaðgerðir krefjast einangraðrar færslu. Óþekktum lyklum er hafnað. Ekki má breyta færslubókarreitum eða stöðu með Data.Records.Set.';
        ResponseLbl: Label 'Stable usage line data or a bounded lines array with hasMore and afterEntryNo.', Comment = 'is-IS=Stöðug notkunarlínugögn eða takmarkað lines fylki með hasMore og afterEntryNo.';
        PermissionLbl: Label 'Assign the Timesheets permissions and the destination journal write permissions.', Comment = 'is-IS=Úthlutaðu tímaskýrsluheimildum og skrifheimildum í viðkomandi færslubók.';
        ErrorLbl: Label 'The key, ownership, permissions or usage state is invalid. No changes were retained.', Comment = 'is-IS=Lykill, eignarhald, heimildir eða notkunarstaða er ógild. Engar breytingar voru varðveittar.';

    /// <summary>Declares only the keys consumed by Register.</summary>
    procedure AddRegisterParameters(var Parameters: JsonArray): Boolean
    var
        Contract: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(Contract.Parameter('timeSheetNo', 'string', true, timeSheetNoLbl));
        Parameters.Add(Contract.Parameter('lineNo', 'integer', true, lineNoLbl));
        Parameters.Add(Contract.Parameter('type', 'string', true, typeLbl));
        Parameters.Add(Contract.Parameter('no', 'string', true, noLbl));
        Parameters.Add(Contract.Parameter('date', 'string', true, dateLbl));
        Parameters.Add(Contract.Parameter('quantity', 'number', true, quantityLbl));
        Parameters.Add(Contract.Parameter('unitOfMeasure', 'string', false, unitOfMeasureLbl));
        Parameters.Add(Contract.Parameter('description', 'string', false, descriptionLbl));
    
        exit(true);
    end;

    /// <summary>Declares only the keys consumed by List.</summary>
    procedure AddListParameters(var Parameters: JsonArray): Boolean
    var
        Contract: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(Contract.Parameter('timeSheetNo', 'string', false, timeSheetNoLbl));
        Parameters.Add(Contract.Parameter('week', 'string', false, weekLbl));
        Parameters.Add(Contract.Parameter('status', 'string', false, statusLbl));
        Parameters.Add(Contract.Parameter('afterEntryNo', 'integer', false, afterEntryNoLbl));
        Parameters.Add(Contract.Parameter('limit', 'integer', false, limitLbl));
    
        exit(true);
    end;

    /// <summary>Declares only the keys consumed by Submit.</summary>
    procedure AddSubmitParameters(var Parameters: JsonArray): Boolean
    var
        Contract: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(Contract.Parameter('entryNo', 'integer', true, entryNoLbl));
        exit(true);
    end;

    /// <summary>Declares only the keys consumed by Approve.</summary>
    procedure AddApproveParameters(var Parameters: JsonArray): Boolean
    var
        Contract: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(Contract.Parameter('entryNo', 'integer', true, entryNoLbl));
        exit(true);
    end;

    /// <summary>Declares only the keys consumed by Reject.</summary>
    procedure AddRejectParameters(var Parameters: JsonArray): Boolean
    var
        Contract: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(Contract.Parameter('entryNo', 'integer', true, entryNoLbl));
        Parameters.Add(Contract.Parameter('comment', 'string', false, commentLbl));
    
        exit(true);
    end;

    /// <summary>Declares only the keys consumed by Transfer.</summary>
    procedure AddTransferParameters(var Parameters: JsonArray): Boolean
    var
        Contract: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(Contract.Parameter('entryNo', 'integer', false, entryNoLbl));
        Parameters.Add(Contract.Parameter('journalTemplate', 'string', true, journalTemplateLbl));
        Parameters.Add(Contract.Parameter('journalBatch', 'string', true, journalBatchLbl));
    
        Parameters.Add(Contract.Parameter('entryNos', 'array', false, entryNosLbl));
        exit(true);
    end;

    /// <summary>Declares only the keys consumed by Reverse.</summary>
    procedure AddReverseParameters(var Parameters: JsonArray): Boolean
    var
        Contract: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(Contract.Parameter('entryNo', 'integer', true, entryNoLbl));
        Parameters.Add(Contract.Parameter('createJournal', 'boolean', false, createJournalLbl));
        Parameters.Add(Contract.Parameter('journalTemplate', 'string', false, journalTemplateLbl));
        Parameters.Add(Contract.Parameter('journalBatch', 'string', false, journalBatchLbl));
    
        exit(true);
    end;

    /// <summary>Declares the versioned request envelope.</summary>
    procedure GetEnvelope(MessageType: Enum "Message Type ori"; var Envelope: JsonObject): Boolean
    begin
        Envelope.Add('dataRequired', true);
        Envelope.Add('version', '1.0');
        Envelope.Add('contentType', 'text/json');
        exit(true);
    end;

    /// <summary>Declares the usage target.</summary>
    procedure GetTarget(MessageType: Enum "Message Type ori"; var Target: JsonArray): Boolean
    begin
        exit(false);
    end;

    /// <summary>Describes language-independent returned usage.</summary>
    procedure GetResponse(MessageType: Enum "Message Type ori"; var Response: JsonObject): Boolean
    var
        Contract: Codeunit "Msg Contract Mgt ori";
        Fields: JsonArray;
    begin
        Fields.Add(Contract.ResponseField('status', 'string', 'Success or Error.'));
        if MessageType = MessageType::"Timesheets.Usage.List" then begin
            Fields.Add(Contract.ResponseField('lines', 'array', ResponseLbl));
            Fields.Add(Contract.ResponseField('hasMore', 'boolean', ResponseLbl));
            Fields.Add(Contract.ResponseField('afterEntryNo', 'integer', afterEntryNoLbl));
        end else
            Fields.Add(Contract.ResponseField('line', 'object', ResponseLbl));
        Response.Add('contentType', 'text/json');
        Response.Add('fields', Fields);
        exit(true);
    end;

    /// <summary>Declares refusal and rollback behavior.</summary>
    procedure GetErrors(MessageType: Enum "Message Type ori"; var Errors: JsonArray): Boolean
    var
        Contract: Codeunit "Msg Contract Mgt ori";
    begin
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::InvalidParameterFormat, ErrorLbl, ErrorLbl, NotesLbl));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::UnknownParameter, ErrorLbl, ErrorLbl, NotesLbl));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::PermissionDenied, ErrorLbl, ErrorLbl, PermissionLbl));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::InvalidLine, ErrorLbl, ErrorLbl, OverviewLbl));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::BusinessCentralError, ErrorLbl, ErrorLbl, NotesLbl));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::PreconditionFailed, ErrorLbl, ErrorLbl, NotesLbl));
        exit(true);
    end;

    /// <summary>Describes commits, rollback and journal effects.</summary>
    procedure GetEffect(MessageType: Enum "Message Type ori"; var Effect: JsonObject): Boolean
    begin
        if MessageType = MessageType::"Timesheets.Usage.List" then begin
            Effect.Add('effect', 'read');
            Effect.Add('idempotency', 'Read-only.');
        end else begin
            Effect.Add('effect', 'write');
            Effect.Add('transaction', 'commit');
            Effect.Add('idempotency', 'Register creates a new line. Transfer is unchanged while its journal link exists. Reverse is allowed once.');
        end;
        Effect.Add('description', OverviewLbl);
        exit(true);
    end;

    /// <summary>Names the related usage messages.</summary>
    procedure GetRelated(MessageType: Enum "Message Type ori"; var Related: JsonArray): Boolean
    begin
        Related.Add('Timesheets.Usage.Register');
        Related.Add('Timesheets.Usage.Submit');
        Related.Add('Timesheets.Usage.List');
        Related.Add('Timesheets.Usage.Approve');
        Related.Add('Timesheets.Usage.Reject');
        Related.Add('Timesheets.Usage.Transfer');
        Related.Add('Timesheets.Usage.Reverse');
        exit(true);
    end;

    /// <summary>Explains the lifecycle and journal routing.</summary>
    procedure GetWorkflow(MessageType: Enum "Message Type ori"; var Workflow: JsonObject): Boolean
    begin
        Workflow.Add('description', OverviewLbl);
        exit(true);
    end;

    /// <summary>Examples are covered by the English usage chapter.</summary>
    procedure GetExamples(MessageType: Enum "Message Type ori"; var Examples: JsonArray): Boolean
    begin
        exit(false);
    end;

    /// <summary>Returns the lifecycle overview.</summary>
    procedure GetOverview(MessageType: Enum "Message Type ori"; var Overview: Text): Boolean
    begin
        Overview := OverviewLbl;
        exit(true);
    end;

    /// <summary>Returns access, continuation and transaction notes.</summary>
    procedure GetNotes(MessageType: Enum "Message Type ori"; var Notes: Text): Boolean
    begin
        Notes := NotesLbl;
        exit(true);
    end;
}
