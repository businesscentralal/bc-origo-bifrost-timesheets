namespace Origo.Bifrost.Timesheets;

using Origo.Bifrost;

/// <summary>
/// Contract chapters for the native Timesheets message types. Parameter lists are
/// separate procedures so each type declares only the keys it reads.
/// </summary>
codeunit 10036869 "TS Contract Parts ori"
{
    Access = Internal;

    procedure AddAbsenceParameters(var Parameters: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(ContractMgt.Parameter('timeSheetNo', 'string', false, 'Time sheet number. Send this or resourceNo plus date.'));
        Parameters.Add(ContractMgt.Parameter('resourceNo', 'string', false, 'Resource number, together with date, when timeSheetNo is omitted.'));
        Parameters.Add(ContractMgt.Parameter('date', 'string', false, 'ISO date inside the time sheet, or the day of a single quantity.'));
        Parameters.Add(ContractMgt.Parameter('causeOfAbsenceCode', 'string', true, 'Cause of absence code.'));
        Parameters.Add(ContractMgt.Parameter('hours', 'array', false, 'Days as objects with date and quantity. Do not combine with quantity.'));
        Parameters.Add(ContractMgt.Parameter('quantity', 'decimal', false, 'Hours on date. Do not combine with hours.'));
        exit(true);
    end;

    procedure GetEnvelope(MessageType: Enum "Message Type ori"; var Envelope: JsonObject): Boolean
    var
        Forms: JsonArray;
        Subject: JsonObject;
    begin
        Forms.Add('data');
        Subject.Add('use', 'optional');
        Subject.Add('forms', Forms);
        Subject.Add('description', 'The Business Central time sheet operation addressed by the request.');
        Envelope.Add('subject', Subject);
        Envelope.Add('dataRequired', true);
        Envelope.Add('version', '1.0');
        Envelope.Add('contentType', 'text/json');
        exit(MessageType = MessageType::"Timesheets.Absence.Register");
    end;

    procedure GetTarget(MessageType: Enum "Message Type ori"; var Target: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        if MessageType <> MessageType::"Timesheets.Absence.Register" then
            exit(false);
        Target.Add(ContractMgt.TargetEntry('data.timeSheetNo', 'string', 'Time sheet number, or omit it and send resourceNo plus date.'));
        exit(true);
    end;

    procedure GetResponse(MessageType: Enum "Message Type ori"; var Response: JsonObject): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Fields: JsonArray;
    begin
        if MessageType <> MessageType::"Timesheets.Absence.Register" then
            exit(false);
        Fields.Add(ContractMgt.ResponseField('status', 'string', 'Success.'));
        Fields.Add(ContractMgt.ResponseField('timeSheetNo', 'string', 'Time sheet number.'));
        Fields.Add(ContractMgt.ResponseField('lineNo', 'integer', 'Absence line number.'));
        Fields.Add(ContractMgt.ResponseField('causeOfAbsenceCode', 'string', 'Cause of absence.'));
        Fields.Add(ContractMgt.ResponseField('resourceNo', 'string', 'Resource number of the time sheet.'));
        Fields.Add(ContractMgt.ResponseField('hours', 'array', 'Hours written, per day.'));
        Fields.Add(ContractMgt.ResponseField('warnings', 'array', 'Present when hours fall on a non-working day. The line is still written.'));
        Response.Add('contentType', 'text/json');
        Response.Add('fields', Fields);
        exit(true);
    end;

    procedure GetErrors(MessageType: Enum "Message Type ori"; var Errors: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        if MessageType <> MessageType::"Timesheets.Absence.Register" then
            exit(false);
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::MissingParameter, 'A required key is missing.', 'The request omitted a key this type needs.', 'Send the missing key.'));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::InvalidParameterFormat, 'A key has the wrong JSON type.', 'A value was not the documented JSON type.', 'Send the key with the documented type.'));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::UnknownParameter, 'The request contains an unknown key.', 'This native type refuses keys it does not document. Processing stops.', 'Remove the unknown key.'));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::RecordNotFound, 'The identifier does not match a record.', 'The time sheet, resource or cause was not found.', 'Use an identifier that exists.'));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::ConflictingIdentifiers, 'The request names the record in more than one way.', 'Two identifiers were sent for one time sheet or resource.', 'Send only one identifier for the time sheet.'));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::PermissionDenied, 'The caller cannot run this type.', 'This type needs write access to time sheets.', 'Assign the BIFROST Timeshts ori permission set.'));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::PreconditionFailed, 'The resource is not linked to an employee.', 'No employee has this resource number. Nothing is written.', 'Link the resource to an employee in BC.'));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::RecordNotFound, 'The cause of absence was not found.', 'The code is not in Causes of Absence.', 'Use a code from Causes of Absence.'));
        exit(true);
    end;

    procedure GetEffect(MessageType: Enum "Message Type ori"; var Effect: JsonObject): Boolean
    var
        Preconditions: JsonArray;
    begin
        if MessageType <> MessageType::"Timesheets.Absence.Register" then
            exit(false);
        Preconditions.Add('The caller has the BIFROST Timeshts ori permission set.');
        Effect.Add('effect', 'write');
        Effect.Add('changes', 'Adds an absence line and its daily hours to a time sheet inside the caller transaction. A refused call writes nothing.');
        Effect.Add('idempotent', false);
        Effect.Add('permissionSet', 'BIFROST Timeshts ori');
        Effect.Add('preconditions', Preconditions);
        exit(true);
    end;

    procedure GetRelated(MessageType: Enum "Message Type ori"; var Related: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        if MessageType <> MessageType::"Timesheets.Absence.Register" then
            exit(false);
        Related.Add(ContractMgt.RelatedEntry('Help.MessageTypes.Get', 'The type is also listed with the other message types.'));
        exit(true);
    end;

    procedure GetWorkflow(MessageType: Enum "Message Type ori"; var Workflow: JsonObject): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Steps: JsonArray;
    begin
        if MessageType <> MessageType::"Timesheets.Absence.Register" then
            exit(false);
        Steps.Add(ContractMgt.WorkflowStep(MessageTypeName(MessageType), 'Register the absence line and its hours.'));
        Workflow.Add('steps', Steps);
        Workflow.Add('text', 'Read the returned line before the next call. The line becomes an Employee Absence when the time sheet is posted.');
        exit(true);
    end;

    procedure GetExamples(MessageType: Enum "Message Type ori"; var Examples: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Name: Text;
    begin
        if MessageType <> MessageType::"Timesheets.Absence.Register" then
            exit(false);
        Name := MessageTypeName(MessageType);
        Examples.Add(ContractMgt.Example(Name, '{"type":"' + Name + '","data":{"timeSheetNo":"TS0001","causeOfAbsenceCode":"VAC","hours":[{"date":"2026-06-02","quantity":8}]}}', '{"status":"Success","timeSheetNo":"TS0001","lineNo":10000,"causeOfAbsenceCode":"VAC","resourceNo":"RES0001","hours":[{"date":"2026-06-02","quantity":8}]}'));
        exit(true);
    end;

    procedure GetOverview(MessageType: Enum "Message Type ori"; var Overview: Text): Boolean
    begin
        if MessageType <> MessageType::"Timesheets.Absence.Register" then
            exit(false);
        Overview := 'Timesheets.Absence.Register adds an absence line with a cause of absence and hours per day to a time sheet. A refusal writes nothing. Unknown keys are refused.';
        exit(true);
    end;

    procedure GetNotes(MessageType: Enum "Message Type ori"; var Notes: Text): Boolean
    begin
        if MessageType <> MessageType::"Timesheets.Absence.Register" then
            exit(false);
        Notes := 'Link the resource to an employee in BC. Use a code from Causes of Absence. Hours on Saturday or Sunday are written and returned with a warning. Employee Absence is created when the line is posted by Business Central, not by this type. The write is committed when the call succeeds.';
        exit(true);
    end;

    procedure MessageTypeName(MessageType: Enum "Message Type ori"): Text
    begin
        exit(Enum::"Message Type ori".Names().Get(Enum::"Message Type ori".Ordinals().IndexOf(MessageType.AsInteger())));
    end;
}
