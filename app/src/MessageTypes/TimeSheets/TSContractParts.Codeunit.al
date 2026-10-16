namespace Origo.Bifrost.Timesheets;

using Origo.Bifrost;

/// <summary>
/// Contract chapters for the native Timesheets message types. Parameter lists are
/// separate procedures so each type declares only the keys it reads.
/// </summary>
codeunit 10036857 "TS Contract Parts ori"
{
    Access = Internal;

    procedure AddSubmitParameters(var Parameters: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(ContractMgt.Parameter('timeSheetNo', 'string', false, 'Time sheet number. Send this or resourceNo plus date.'));
        Parameters.Add(ContractMgt.Parameter('resourceNo', 'string', false, 'Resource number, together with date, when timeSheetNo is omitted.'));
        Parameters.Add(ContractMgt.Parameter('date', 'string', false, 'ISO date inside the time sheet, together with resourceNo.'));
        Parameters.Add(ContractMgt.Parameter('lineNos', 'array', false, 'Line numbers to submit. Omitted means every open line. An empty array selects none.'));
        exit(true);
    end;

    procedure AddCreateParameters(var Parameters: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(ContractMgt.Parameter('startingDate', 'string', true, 'First day of the first week. It must be the Time Sheet First Weekday.'));
        Parameters.Add(ContractMgt.Parameter('numberOfPeriods', 'integer', false, 'How many weeks to create. Defaults to 1. Maximum 52.'));
        Parameters.Add(ContractMgt.Parameter('resourceNo', 'string', false, 'One resource number. Do not combine with resourceNos or resourceGroup.'));
        Parameters.Add(ContractMgt.Parameter('resourceNos', 'array', false, 'Resource numbers. Do not combine with resourceNo or resourceGroup.'));
        Parameters.Add(ContractMgt.Parameter('resourceGroup', 'string', false, 'Resource group number. Do not combine with resourceNo or resourceNos.'));
        Parameters.Add(ContractMgt.Parameter('createLinesFromPlanning', 'boolean', false, 'When true, also creates lines from project planning. Defaults to false.'));
        exit(true);
    end;

    procedure AddPendingParameters(var Parameters: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(ContractMgt.Parameter('from', 'string', false, 'ISO date. Sheets that end before this date are left out.'));
        Parameters.Add(ContractMgt.Parameter('to', 'string', false, 'ISO date. Sheets that start after this date are left out. from must be <= to.'));
        Parameters.Add(ContractMgt.Parameter('resource', 'string', false, 'Resource number filter.'));
        Parameters.Add(ContractMgt.Parameter('type', 'string', false, 'Line type: Resource, Job, Service or Absence.'));
        Parameters.Add(ContractMgt.Parameter('take', 'integer', false, 'Page size. Defaults to 50. Maximum 100.'));
        Parameters.Add(ContractMgt.Parameter('skip', 'integer', false, 'Rows to skip. Defaults to 0.'));
        exit(true);
    end;

    procedure AddApproveParameters(var Parameters: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(ContractMgt.Parameter('timeSheetNo', 'string', true, 'Time sheet number.'));
        Parameters.Add(ContractMgt.Parameter('lineNos', 'array', false, 'Submitted line numbers. Omitted means every submitted line. An empty array selects none.'));
        exit(true);
    end;

    procedure AddRejectParameters(var Parameters: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(ContractMgt.Parameter('timeSheetNo', 'string', true, 'Time sheet number.'));
        Parameters.Add(ContractMgt.Parameter('lineNos', 'array', false, 'Submitted line numbers. Omitted means every submitted line. An empty array selects none.'));
        Parameters.Add(ContractMgt.Parameter('comment', 'string', false, 'Optional comment stored on each rejected line.'));
        exit(true);
    end;

    procedure AddCopyParameters(var Parameters: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(ContractMgt.Parameter('timeSheetNo', 'string', true, 'Time sheet that receives the copied lines.'));
        exit(true);
    end;

    procedure AddPlanningParameters(var Parameters: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(ContractMgt.Parameter('timeSheetNo', 'string', true, 'Time sheet that receives the planning lines.'));
        exit(true);
    end;

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

    procedure AddReopenParameters(var Parameters: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(ContractMgt.Parameter('endingDateTo', 'string', false, 'ISO date cutoff. Sheets ending after this date are left out. Defaults to the work date.'));
        exit(true);
    end;

    procedure AddPostParameters(var Parameters: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(ContractMgt.Parameter('journalTemplate', 'string', false, 'Job journal template. The Timesheets setup value is used when omitted.'));
        Parameters.Add(ContractMgt.Parameter('journalBatch', 'string', false, 'Job journal batch. The Timesheets setup value is used when omitted.'));
        exit(true);
    end;

    procedure AddArchiveParameters(var Parameters: JsonArray): Boolean
    begin
        exit(false);
    end;

    procedure GetEnvelope(MessageType: Enum "Message Type ori"; var Envelope: JsonObject): Boolean
    var
        Subject: JsonObject;
        Forms: JsonArray;
    begin
        Forms.Add('data');
        Subject.Add('use', 'optional');
        Subject.Add('forms', Forms);
        Subject.Add('description', 'The Business Central time sheet operation addressed by the request.');
        Envelope.Add('subject', Subject);
        Envelope.Add('dataRequired', MessageType <> MessageType::"Timesheets.PendingApproval.Get");
        Envelope.Add('version', '1.0');
        Envelope.Add('contentType', 'text/json');
        exit(true);
    end;

    procedure GetTarget(MessageType: Enum "Message Type ori"; var Target: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        case MessageType of
            MessageType::"Timesheets.TimeSheet.Submit",
            MessageType::"Timesheets.Absence.Register":
                Target.Add(ContractMgt.TargetEntry('data.timeSheetNo', 'string', 'Time sheet number, or omit it and send resourceNo plus date.'));
            MessageType::"Timesheets.TimeSheet.Approve",
            MessageType::"Timesheets.TimeSheet.Reject",
            MessageType::"Timesheets.TimeSheetLine.CopyFromPrevious",
            MessageType::"Timesheets.TimeSheetLine.CreateFromPlanning":
                Target.Add(ContractMgt.TargetEntry('data.timeSheetNo', 'string', 'Time sheet number.'));
            else
                exit(false);
        end;
        exit(true);
    end;

    procedure GetResponse(MessageType: Enum "Message Type ori"; var Response: JsonObject): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Fields: JsonArray;
    begin
        Fields.Add(ContractMgt.ResponseField('status', 'string', 'Success.'));
        case MessageType of
            MessageType::"Timesheets.TimeSheet.Create":
                begin
                    Fields.Add(ContractMgt.ResponseField('created', 'array', 'Sheets created, with timeSheetNo, resourceNo, startingDate and endingDate.'));
                    Fields.Add(ContractMgt.ResponseField('skipped', 'array', 'Sheets that already existed for that resource and week.'));
                end;
            MessageType::"Timesheets.PendingApproval.Get":
                begin
                    Fields.Add(ContractMgt.ResponseField('lines', 'array', 'Submitted lines for this approver: time sheet, resource, dates, line type, project or absence, hours per day and total.'));
                    Fields.Add(ContractMgt.ResponseField('take', 'integer', 'Page size used.'));
                    Fields.Add(ContractMgt.ResponseField('skip', 'integer', 'Rows skipped.'));
                end;
            MessageType::"Timesheets.TimeSheetLine.CopyFromPrevious":
                begin
                    Fields.Add(ContractMgt.ResponseField('copied', 'integer', 'Lines copied. Zero is success when the previous sheet has no lines.'));
                    Fields.Add(ContractMgt.ResponseField('lines', 'array', 'Lines on the sheet after the copy.'));
                end;
            MessageType::"Timesheets.TimeSheetLine.CreateFromPlanning":
                begin
                    Fields.Add(ContractMgt.ResponseField('created', 'integer', 'Lines created. Zero is success when planning has nothing in the period.'));
                    Fields.Add(ContractMgt.ResponseField('lines', 'array', 'Lines on the sheet after planning.'));
                end;
            MessageType::"Timesheets.Absence.Register":
                begin
                    Fields.Add(ContractMgt.ResponseField('timeSheetNo', 'string', 'Time sheet number.'));
                    Fields.Add(ContractMgt.ResponseField('lineNo', 'integer', 'Absence line number.'));
                    Fields.Add(ContractMgt.ResponseField('causeOfAbsenceCode', 'string', 'Cause of absence.'));
                    Fields.Add(ContractMgt.ResponseField('hours', 'array', 'Hours written, per day.'));
                    Fields.Add(ContractMgt.ResponseField('warnings', 'array', 'Present when hours fall on a non-working day. The line is still written.'));
                end;
            MessageType::"Timesheets.TimeSheet.Reopen":
                Fields.Add(ContractMgt.ResponseField('reopenedLines', 'integer', 'Lines reopened.'));
            MessageType::"Timesheets.TimeSheet.Post":
                Fields.Add(ContractMgt.ResponseField('postedLines', 'integer', 'Job journal lines posted.'));
            MessageType::"Timesheets.TimeSheet.Archive":
                Fields.Add(ContractMgt.ResponseField('archived', 'integer', 'Time sheets archived.'));
            else
                Fields.Add(ContractMgt.ResponseField('lines', 'array', 'Lines touched, each with timeSheetNo, lineNo, status and changed.'));
        end;
        Response.Add('contentType', 'text/json');
        Response.Add('fields', Fields);
        exit(true);
    end;

    procedure GetErrors(MessageType: Enum "Message Type ori"; var Errors: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::MissingParameter, 'A required key is missing.', 'The request omitted a key this type needs.', 'Send the missing key.'));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::InvalidParameterFormat, 'A key has the wrong JSON type.', 'A value was not the documented JSON type.', 'Send the key with the documented type.'));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::UnknownParameter, 'The request contains an unknown key.', 'This native type refuses keys it does not document. Processing stops.', 'Remove the unknown key.'));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::RecordNotFound, 'The identifier does not match a record.', 'The time sheet, resource, line or cause was not found.', 'Use an identifier that exists.'));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::ConflictingIdentifiers, 'The request names the record in more than one way.', 'Two identifiers were sent for one time sheet or resource.', 'Send only one identifier for the time sheet.'));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::PermissionDenied, 'The caller cannot run this type.', 'Write types need write access. The read type needs read access.', PermissionNext(MessageType)));
        case MessageType of
            MessageType::"Timesheets.TimeSheet.Submit":
                begin
                    Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::PermissionDenied, 'The caller is not the owner of the time sheet.', 'Owner User ID is blank or is a different user.', 'Only the owner can submit; ask the owner.'));
                    Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::PreconditionFailed, 'The time sheet has no open lines.', 'Nothing is waiting to be submitted.', 'Add lines first.'));
                    Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::InvalidLine, 'Business Central rejected the line.', 'The submit action refused the line. Nothing is written.', 'Fix the line and submit again.'));
                end;
            MessageType::"Timesheets.TimeSheet.Create":
                begin
                    Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::PreconditionFailed, 'startingDate must be the first weekday named in Resources Setup.', 'The date is not the Time Sheet First Weekday. Nothing is written.', 'Use the first weekday named in the refusal.'));
                    Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::RecordNotFound, 'The resource was not found or Use Time Sheet is off.', 'Every named resource must exist and use time sheets.', 'Turn on Use Time Sheet on the resource.'));
                    Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::LimitExceeded, 'numberOfPeriods is above 52.', 'One call creates at most 52 weeks.', 'Split the call.'));
                end;
            MessageType::"Timesheets.PendingApproval.Get":
                Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::InvalidParameter, 'The date range has from after to.', 'from is later than to. Nothing is written.', 'Use from <= to.'));
            MessageType::"Timesheets.TimeSheet.Approve",
            MessageType::"Timesheets.TimeSheet.Reject":
                begin
                    Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::PermissionDenied, 'The caller is not the approver named on the time sheet.', 'Approver User ID is blank or is a different user.', 'Only the approver named on the time sheet can approve.'));
                    Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::InvalidLine, 'The line is not submitted.', 'An open line cannot be approved or rejected yet.', 'Submit it first with Timesheets.TimeSheet.Submit.'));
                end;
            MessageType::"Timesheets.TimeSheetLine.CopyFromPrevious",
            MessageType::"Timesheets.TimeSheetLine.CreateFromPlanning":
                begin
                    Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::PermissionDenied, 'The caller is not the owner of the time sheet.', 'Owner User ID is blank or is a different user.', 'Ask the owner.'));
                    if MessageType = MessageType::"Timesheets.TimeSheetLine.CopyFromPrevious" then
                        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::PreconditionFailed, 'The resource has no previous time sheet.', 'There is no earlier sheet to copy. Nothing is written.', 'Add lines by hand.'));
                end;
            MessageType::"Timesheets.Absence.Register":
                begin
                    Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::PreconditionFailed, 'The resource is not linked to an employee.', 'No employee has this resource number. Nothing is written.', 'Link the resource to an employee in BC.'));
                    Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::RecordNotFound, 'The cause of absence was not found.', 'The code is not in Causes of Absence.', 'Use a code from Causes of Absence.'));
                end;
            MessageType::"Timesheets.TimeSheet.Reopen",
            MessageType::"Timesheets.TimeSheet.Post",
            MessageType::"Timesheets.TimeSheet.Archive":
                Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::DeprecatedParameter, 'The Clockify.TimeSheet name still runs.', 'That warning is returned by the old name, not by this native name.', 'Use the native name.'));
        end;
        exit(true);
    end;

    procedure GetEffect(MessageType: Enum "Message Type ori"; var Effect: JsonObject): Boolean
    var
        Preconditions: JsonArray;
        EffectName: Text;
        Changes: Text;
        Idempotent: Boolean;
    begin
        case MessageType of
            MessageType::"Timesheets.PendingApproval.Get":
                begin
                    EffectName := 'read';
                    Changes := 'Reads submitted time sheet lines for the caller and does not change Business Central.';
                    Idempotent := true;
                end;
            MessageType::"Timesheets.TimeSheet.Post":
                begin
                    EffectName := 'irreversible';
                    Changes := 'Posts approved time sheet lines through the job journal. Posted entries cannot be undone. The post commits.';
                    Idempotent := false;
                end;
            else begin
                EffectName := 'write';
                Changes := 'Changes Business Central time sheet records inside the caller transaction. A refused call writes nothing.';
                Idempotent := false;
            end;
        end;
        Preconditions.Add('The caller has the BIFROST Timeshts ori permission set.');
        Effect.Add('effect', EffectName);
        Effect.Add('changes', Changes);
        Effect.Add('idempotent', Idempotent);
        Effect.Add('permissionSet', 'BIFROST Timeshts ori');
        Effect.Add('preconditions', Preconditions);
        exit(true);
    end;

    procedure GetRelated(MessageType: Enum "Message Type ori"; var Related: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        case MessageType of
            MessageType::"Timesheets.TimeSheet.Submit":
                Related.Add(ContractMgt.RelatedEntry('Timesheets.TimeSheet.Approve', 'After submit, the approver approves or rejects the lines.'));
            MessageType::"Timesheets.TimeSheet.Create":
                Related.Add(ContractMgt.RelatedEntry('Timesheets.TimeSheet.Submit', 'After creation, the owner submits open lines.'));
            MessageType::"Timesheets.PendingApproval.Get":
                Related.Add(ContractMgt.RelatedEntry('Timesheets.TimeSheet.Approve', 'Approve a line returned by this list.'));
            MessageType::"Timesheets.TimeSheet.Reopen",
            MessageType::"Timesheets.TimeSheet.Post",
            MessageType::"Timesheets.TimeSheet.Archive":
                Related.Add(ContractMgt.RelatedEntry('Help.MessageTypes.Get', 'The native name is also listed with the other message types.'));
            else
                Related.Add(ContractMgt.RelatedEntry('Timesheets.TimeSheet.Submit', 'Submit open lines before approval.'));
        end;
        exit(true);
    end;

    procedure GetWorkflow(MessageType: Enum "Message Type ori"; var Workflow: JsonObject): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Steps: JsonArray;
    begin
        if MessageType = MessageType::"Timesheets.PendingApproval.Get" then
            exit(false);
        Steps.Add(ContractMgt.WorkflowStep(MessageTypeName(MessageType), 'Run the time sheet operation.'));
        Workflow.Add('steps', Steps);
        Workflow.Add('text', 'Read status before the next call. changed false means the line was already in the requested state.');
        exit(true);
    end;

    procedure GetExamples(MessageType: Enum "Message Type ori"; var Examples: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Name: Text;
    begin
        Name := MessageTypeName(MessageType);
        Examples.Add(ContractMgt.Example(Name, '{"type":"' + Name + '","data":' + ExampleRequest(MessageType) + '}', ExampleResponse(MessageType)));
        exit(true);
    end;

    procedure GetOverview(MessageType: Enum "Message Type ori"; var Overview: Text): Boolean
    begin
        case MessageType of
            MessageType::"Timesheets.PendingApproval.Get":
                Overview := 'Timesheets.PendingApproval.Get is read-only. It lists submitted lines where the caller is the approver. An empty list is success.';
            MessageType::"Timesheets.TimeSheet.Post":
                Overview := 'Timesheets.TimeSheet.Post is irreversible. It posts approved lines and commits. The same fields are returned by the older Clockify.TimeSheet.Post name, which also warns to use the native name.';
            else
                Overview := MessageTypeName(MessageType) + ' changes Business Central time sheets. A refusal writes nothing. Unknown keys are refused.';
        end;
        exit(true);
    end;

    procedure GetNotes(MessageType: Enum "Message Type ori"; var Notes: Text): Boolean
    begin
        Notes := NotesFor(MessageType);
        exit(Notes <> '');
    end;

    procedure MessageTypeName(MessageType: Enum "Message Type ori"): Text
    begin
        exit(Enum::"Message Type ori".Names().Get(Enum::"Message Type ori".Ordinals().IndexOf(MessageType.AsInteger())));
    end;

    local procedure PermissionNext(MessageType: Enum "Message Type ori"): Text
    begin
        if MessageType = MessageType::"Timesheets.PendingApproval.Get" then
            exit('Ask for the Timesheets permission set.');
        exit('Assign the BIFROST Timeshts ori permission set.');
    end;

    local procedure ExampleRequest(MessageType: Enum "Message Type ori"): Text
    begin
        case MessageType of
            MessageType::"Timesheets.TimeSheet.Submit":
                exit('{"timeSheetNo":"TS0001"}');
            MessageType::"Timesheets.TimeSheet.Create":
                exit('{"startingDate":"2026-06-01","numberOfPeriods":1,"resourceNo":"RES0001"}');
            MessageType::"Timesheets.PendingApproval.Get":
                exit('{"from":"2026-06-01","to":"2026-06-30","take":50,"skip":0}');
            MessageType::"Timesheets.TimeSheet.Reject":
                exit('{"timeSheetNo":"TS0001","comment":"Please split the job."}');
            MessageType::"Timesheets.Absence.Register":
                exit('{"timeSheetNo":"TS0001","causeOfAbsenceCode":"VAC","hours":[{"date":"2026-06-02","quantity":8}]}');
            MessageType::"Timesheets.TimeSheet.Reopen":
                exit('{"endingDateTo":"2026-06-30"}');
            MessageType::"Timesheets.TimeSheet.Post":
                exit('{"journalTemplate":"JOB","journalBatch":"DEFAULT"}');
            MessageType::"Timesheets.TimeSheet.Archive":
                exit('{}');
            else
                exit('{"timeSheetNo":"TS0001"}');
        end;
    end;

    local procedure ExampleResponse(MessageType: Enum "Message Type ori"): Text
    begin
        case MessageType of
            MessageType::"Timesheets.TimeSheet.Create":
                exit('{"status":"Success","created":[{"timeSheetNo":"TS0001","resourceNo":"RES0001","startingDate":"2026-06-01","endingDate":"2026-06-07"}],"skipped":[]}');
            MessageType::"Timesheets.PendingApproval.Get":
                exit('{"status":"Success","lines":[],"take":50,"skip":0}');
            MessageType::"Timesheets.TimeSheet.Reopen":
                exit('{"status":"Success","reopenedLines":0}');
            MessageType::"Timesheets.TimeSheet.Post":
                exit('{"status":"Success","postedLines":0}');
            MessageType::"Timesheets.TimeSheet.Archive":
                exit('{"status":"Success","archived":0}');
            MessageType::"Timesheets.Absence.Register":
                exit('{"status":"Success","timeSheetNo":"TS0001","lineNo":10000,"causeOfAbsenceCode":"VAC","hours":[{"date":"2026-06-02","quantity":8}]}');
            else
                exit('{"status":"Success","lines":[{"timeSheetNo":"TS0001","lineNo":10000,"status":"Submitted","changed":true}]}');
        end;
    end;

    local procedure NotesFor(MessageType: Enum "Message Type ori"): Text
    begin
        case MessageType of
            MessageType::"Timesheets.TimeSheet.Submit":
                exit('Owner only. No open lines: Add lines first. A line Business Central refuses: Fix the line and submit again. Already submitted lines return changed false. Send the missing key. Send the key with the documented type. Remove the unknown key. Use an identifier that exists. Send only one identifier for the time sheet. Only the owner can submit; ask the owner.');
            MessageType::"Timesheets.TimeSheet.Create":
                exit('Creates one weekly sheet per resource and period and skips a week that already has a sheet. Use the first weekday named in the refusal. Turn on Use Time Sheet on the resource. Split the call. This is not the older Clockify.TimeSheet.Create name.');
            MessageType::"Timesheets.PendingApproval.Get":
                exit('Read-only. Empty list is success. Use from <= to. Ask for the Timesheets permission set. Hours on a non-working day are not involved here.');
            MessageType::"Timesheets.TimeSheet.Approve":
                exit('Approver only. Only the approver named on the time sheet can approve. Submit it first with Timesheets.TimeSheet.Submit. Already approved lines return changed false. An empty lineNos array returns an empty list.');
            MessageType::"Timesheets.TimeSheet.Reject":
                exit('Approver only. Optional comment is stored on the rejected line. Only the approver named on the time sheet can approve. Submit it first with Timesheets.TimeSheet.Submit.');
            MessageType::"Timesheets.TimeSheetLine.CopyFromPrevious":
                exit('Owner only. No earlier sheet: Add lines by hand. Ask the owner. A previous sheet with no lines returns copied 0.');
            MessageType::"Timesheets.TimeSheetLine.CreateFromPlanning":
                exit('Owner only. Ask the owner. No planning lines in the period returns created 0.');
            MessageType::"Timesheets.Absence.Register":
                exit('Link the resource to an employee in BC. Use a code from Causes of Absence. Hours on Saturday or Sunday are written and returned with a warning. Posting the line to employee absence happens later.');
            MessageType::"Timesheets.TimeSheet.Reopen":
                exit('Same reopenedLines result as Clockify.TimeSheet.Reopen. The old name keeps working and adds a warning whose nextStep is Use the native name.');
            MessageType::"Timesheets.TimeSheet.Post":
                exit('Same postedLines result as Clockify.TimeSheet.Post. The post commits. The old name keeps working and adds a warning whose nextStep is Use the native name.');
            MessageType::"Timesheets.TimeSheet.Archive":
                exit('Same archived result as Clockify.TimeSheet.Archive. The request has no keys. The old name keeps working and adds a warning whose nextStep is Use the native name.');
        end;
    end;
}
