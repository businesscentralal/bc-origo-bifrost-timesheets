namespace Origo.Bifrost.Timesheets;

using Origo.Bifrost;

/// <summary>
/// Shared contract chapters for the Clockify message types. The implementation
/// codeunits own discovery labels and delegate their chapter construction here.
/// </summary>
codeunit 10036855 "Clockify Contract Parts ori"
{
    Access = Internal;

    procedure GetEnvelope(MessageType: Enum "Message Type ori"; var Envelope: JsonObject): Boolean
    var
        Subject: JsonObject;
        Forms: JsonArray;
    begin
        if MessageType = MessageType::"Help.Clockify.Get" then begin
            Envelope.Add('subject', Subject);
            Envelope.Add('dataRequired', false);
            Envelope.Add('version', '1.0');
            Envelope.Add('contentType', 'text/json');
            exit(true);
        end;
        if IsInbound(MessageType) then
            Forms.Add('data')
        else
            Forms.Add('workspaceId');
        Subject.Add('use', 'optional');
        Subject.Add('forms', Forms);
        Subject.Add('description', 'The Clockify workspace or BC operation addressed by the request.');
        Envelope.Add('subject', Subject);
        Envelope.Add('dataRequired', HasRequiredData(MessageType));
        Envelope.Add('version', '1.0');
        Envelope.Add('contentType', 'text/json');
        exit(true);
    end;

    procedure GetTarget(MessageType: Enum "Message Type ori"; var Target: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        if IsCollection(MessageType) or (MessageType = MessageType::"Help.Clockify.Get") then
            exit(false);
        Target.Add(ContractMgt.TargetEntry('data.workspaceId', 'string', 'The Clockify workspace ID.'));
        Target.Add(ContractMgt.TargetEntry('data.id, data.entryId, data.clientId, data.projectId, data.taskId', 'string', 'The Clockify object ID required by the operation.'));
        exit(true);
    end;

    procedure GetParameters(MessageType: Enum "Message Type ori"; var Parameters: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        if MessageType = MessageType::"Help.Clockify.Get" then
            exit(false);
        if UsesWorkspace(MessageType) then
            Parameters.Add(ContractMgt.Parameter('workspaceId', 'string', false, 'Clockify workspace ID. The configured default is used when omitted.'));
        case MessageType of
            MessageType::"Clockify.User.List":
                AddPagingParameters(Parameters, ContractMgt);
            MessageType::"Clockify.Client.List":
                AddPagingParameters(Parameters, ContractMgt);
            MessageType::"Clockify.Client.Get":
                AddIdParameter(Parameters, ContractMgt, 'clientId', 'Clockify client ID.');
            MessageType::"Clockify.Client.Create":
                AddBodyParameter(Parameters, ContractMgt, 'Client fields, including name and optional currencyId.');
            MessageType::"Clockify.Client.Update":
                AddIdAndBodyParameters(Parameters, ContractMgt, 'clientId', 'Clockify client ID.', 'Client fields to update.');
            MessageType::"Clockify.Client.Delete":
                AddIdParameter(Parameters, ContractMgt, 'clientId', 'Archived Clockify client ID.');
            MessageType::"Clockify.Project.List":
                AddPagingParameters(Parameters, ContractMgt);
            MessageType::"Clockify.Project.Get":
                AddIdParameter(Parameters, ContractMgt, 'projectId', 'Clockify project ID.');
            MessageType::"Clockify.Project.Create":
                AddBodyParameter(Parameters, ContractMgt, 'Project fields, including name and optional clientId.');
            MessageType::"Clockify.Project.Update":
                AddIdAndBodyParameters(Parameters, ContractMgt, 'projectId', 'Clockify project ID.', 'Project fields to update.');
            MessageType::"Clockify.Project.Delete":
                AddIdParameter(Parameters, ContractMgt, 'projectId', 'Archived Clockify project ID.');
            MessageType::"Clockify.Task.List":
                begin
                    AddIdParameter(Parameters, ContractMgt, 'projectId', 'Clockify project ID.');
                    AddPagingParameters(Parameters, ContractMgt);
                end;
            MessageType::"Clockify.Task.Create":
                begin
                    AddIdParameter(Parameters, ContractMgt, 'projectId', 'Clockify project ID.');
                    AddBodyParameter(Parameters, ContractMgt, 'Task fields, including name.');
                end;
            MessageType::"Clockify.Task.Update":
                begin
                    AddIdParameter(Parameters, ContractMgt, 'projectId', 'Clockify project ID.');
                    AddIdAndBodyParameters(Parameters, ContractMgt, 'taskId', 'Clockify task ID.', 'Task fields to update.');
                end;
            MessageType::"Clockify.Task.Delete":
                begin
                    AddIdParameter(Parameters, ContractMgt, 'projectId', 'Clockify project ID.');
                    AddIdParameter(Parameters, ContractMgt, 'taskId', 'Clockify task ID.');
                end;
            MessageType::"Clockify.Tag.List", MessageType::"Clockify.UserGroup.List", MessageType::"Clockify.CustomField.List":
                AddPagingParameters(Parameters, ContractMgt);
            MessageType::"Clockify.Tag.Create":
                AddBodyParameter(Parameters, ContractMgt, 'Tag fields, including name and optional archived flag.');
            MessageType::"Clockify.Tag.Update":
                AddIdAndBodyParameters(Parameters, ContractMgt, 'tagId', 'Clockify tag ID.', 'Tag fields to update.');
            MessageType::"Clockify.Tag.Delete":
                AddIdParameter(Parameters, ContractMgt, 'tagId', 'Clockify tag ID.');
            MessageType::"Clockify.TimeEntry.List":
                begin
                    AddIdParameter(Parameters, ContractMgt, 'userId', 'Clockify user ID.');
                    AddPagingParameters(Parameters, ContractMgt);
                end;
            MessageType::"Clockify.TimeEntry.Get", MessageType::"Clockify.TimeEntry.Delete":
                AddIdParameter(Parameters, ContractMgt, 'entryId', 'Clockify time-entry ID.');
            MessageType::"Clockify.TimeEntry.Create":
                begin
                    AddIdParameter(Parameters, ContractMgt, 'userId', 'Clockify user ID.');
                    AddBodyParameter(Parameters, ContractMgt, 'Time-entry fields, including start and billable values.');
                end;
            MessageType::"Clockify.TimeEntry.Update":
                begin
                    AddIdAndBodyParameters(Parameters, ContractMgt, 'entryId', 'Clockify time-entry ID.', 'Time-entry fields to update.');
                end;
            MessageType::"Clockify.TimeEntry.Sync":
                AddSyncParameters(Parameters, ContractMgt, false);
            MessageType::"Clockify.TimeEntry.SyncRange":
                AddRangeParameters(Parameters, ContractMgt, false, false);
            MessageType::"Clockify.TimeSheet.Create":
                Parameters.Add(ContractMgt.Parameter('weeksAhead', 'integer', false, 'Number of upcoming weeks to create.'));
            MessageType::"Clockify.TimeSheet.Approve", MessageType::"Clockify.TimeSheet.Reject", MessageType::"Clockify.TimeSheet.Reopen":
                Parameters.Add(ContractMgt.Parameter('endingDateTo', 'string', false, 'ISO date cutoff; defaults to the work date.'));
            MessageType::"Clockify.TimeSheet.Post":
                AddJournalParameters(Parameters, ContractMgt);
            MessageType::"Clockify.TimeEntry.SyncToTimeSheet":
                AddSyncParameters(Parameters, ContractMgt, true);
            MessageType::"Clockify.TimeEntry.SyncRangeToTimeSheet":
                AddRangeParameters(Parameters, ContractMgt, true, true);
            MessageType::"Clockify.TimeEntry.SyncAllUsers":
                begin
                    AddRangeParameters(Parameters, ContractMgt, true, false);
                    Parameters.Add(ContractMgt.Parameter('target', 'string', false, 'timesheet (default) or journal.'));
                    AddJournalParameters(Parameters, ContractMgt);
                end;
        end;
        exit(Parameters.Count() > 0);
    end;

    procedure GetResponse(MessageType: Enum "Message Type ori"; var Response: JsonObject): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Fields: JsonArray;
    begin
        if MessageType = MessageType::"Help.Clockify.Get" then begin
            Fields.Add(ContractMgt.ResponseField('messageType', 'string', 'The requested help message type.'));
            Fields.Add(ContractMgt.ResponseField('format', 'string', 'The value markdown for the legacy overview response.'));
            Fields.Add(ContractMgt.ResponseField('markdown', 'string', 'Residual overview text.'));
        end else begin
            Fields.Add(ContractMgt.ResponseField('status', 'string', 'Success or Error.'));
            Fields.Add(ContractMgt.ResponseField('statusCode', 'integer', 'Clockify HTTP status code when an API call was made.'));
            Fields.Add(ContractMgt.ResponseField('data', 'object', 'The Clockify response data or BC-side operation result.'));
        end;
        Response.Add('contentType', 'text/json');
        Response.Add('fields', Fields);
        exit(true);
    end;

    procedure GetErrors(MessageType: Enum "Message Type ori"; var Errors: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Errors.Add(ContractMgt.TextErrorEntry('Unauthorized', 'The Clockify API key is missing or rejected.', 'Configure a valid company API key on Clockify Setup.'));
        Errors.Add(ContractMgt.TextErrorEntry('Forbidden', 'The API key user lacks access to the workspace or operation.', 'Use a key with the required Clockify permissions.'));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::MissingParameter, 'A required identifier or date value is missing.', 'Provide the parameter named in the error response.'));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::InvalidParameterFormat, 'A parameter has the wrong JSON type or format.', 'Send the parameter with the documented type and format.'));
        if IsInbound(MessageType) then
            Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::PreconditionFailed, 'The BC records are not in the state required by the operation.', 'Resolve the mapping, setup, or approval precondition and retry.'));
        exit(true);
    end;

    procedure GetEffect(MessageType: Enum "Message Type ori"; var Effect: JsonObject): Boolean
    var
        Preconditions: JsonArray;
        EffectName: Text;
        Changes: Text;
    begin
        if IsRead(MessageType) then begin
            EffectName := 'read';
            Changes := 'Reads Clockify data and does not change Business Central records.';
        end else begin
            EffectName := 'write';
            Changes := 'Creates or updates Clockify data or mapped Business Central integration records.';
        end;
        if IsIrreversible(MessageType) then begin
            EffectName := 'irreversible';
            Changes := 'Deletes, posts, archives, approves, rejects, reopens, or synchronizes data in a way that can create accounting or time-sheet changes.';
        end;
        Preconditions.Add('The caller has the Bifrost Timesheets permission set.');
        if UsesWorkspace(MessageType) then
            Preconditions.Add('A valid Clockify API key and workspace are available.');
        Effect.Add('effect', EffectName);
        Effect.Add('changes', Changes);
        Effect.Add('idempotent', IsRead(MessageType));
        Effect.Add('permissionSet', 'BIFROST Timeshts ori');
        Effect.Add('preconditions', Preconditions);
        exit(true);
    end;

    procedure GetMetering(var Metering: JsonObject): Boolean
    begin
        exit(false);
    end;

    procedure GetRelated(MessageType: Enum "Message Type ori"; var Related: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        if MessageType = MessageType::"Help.Clockify.Get" then
            exit(false);
        Related.Add(ContractMgt.RelatedEntry('Clockify.Workspace.List', 'You need to resolve a workspace ID.'));
        if IsCollection(MessageType) then
            exit(true);
        Related.Add(ContractMgt.RelatedEntry('Data.Records.Get', 'You need the BC-to-Clockify integration link rather than a Clockify API operation.'));
        exit(true);
    end;

    procedure GetWorkflow(MessageType: Enum "Message Type ori"; var Workflow: JsonObject): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Steps: JsonArray;
    begin
        if IsRead(MessageType) or (MessageType = MessageType::"Help.Clockify.Get") then
            exit(false);
        Steps.Add(ContractMgt.WorkflowStep('Clockify.Workspace.List', 'Resolve the workspace and required Clockify IDs.'));
        Steps.Add(ContractMgt.WorkflowStep(MessageTypeName(MessageType), 'Execute the requested Timesheets operation.'));
        Workflow.Add('steps', Steps);
        Workflow.Add('text', 'Validate the response status before continuing with a dependent operation.');
        exit(true);
    end;

    procedure GetExamples(MessageType: Enum "Message Type ori"; var Examples: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Name: Text;
    begin
        Name := MessageTypeName(MessageType);
        Examples.Add(ContractMgt.Example('Minimal request', '{"type":"' + Name + '","data":{"workspaceId":"<workspaceId>"}}', '{"status":"Success","statusCode":200,"data":[]}'));
        exit(true);
    end;

    procedure GetOverview(MessageType: Enum "Message Type ori"; var Overview: Text): Boolean
    begin
        Overview := MessageTypeName(MessageType) + ' exposes one Clockify Timesheets operation. Use the parameters, response and effect chapters as the authoritative contract.';
        exit(true);
    end;

    procedure GetNotes(MessageType: Enum "Message Type ori"; var Notes: Text): Boolean
    begin
        if IsInbound(MessageType) then
            Notes := 'This operation writes Business Central data. It is not retry-safe unless its response explicitly reports a skipped or unchanged result.'
        else
            Notes := 'Clockify IDs are opaque values. Resolve IDs with the relevant List message before sending a write request.';
        exit(true);
    end;

    local procedure AddPagingParameters(var Parameters: JsonArray; ContractMgt: Codeunit "Msg Contract Mgt ori")
    begin
        Parameters.Add(ContractMgt.Parameter('query', 'object', false, 'Optional Clockify query parameters such as page-size, page, name, status, or archived.'));
    end;

    local procedure AddIdParameter(var Parameters: JsonArray; ContractMgt: Codeunit "Msg Contract Mgt ori"; Name: Text; Description: Text)
    begin
        Parameters.Add(ContractMgt.Parameter(Name, 'string', true, Description));
    end;

    local procedure AddBodyParameter(var Parameters: JsonArray; ContractMgt: Codeunit "Msg Contract Mgt ori"; Description: Text)
    begin
        Parameters.Add(ContractMgt.Parameter('body', 'object', true, Description));
    end;

    local procedure AddIdAndBodyParameters(var Parameters: JsonArray; ContractMgt: Codeunit "Msg Contract Mgt ori"; IdName: Text; IdDescription: Text; BodyDescription: Text)
    begin
        AddIdParameter(Parameters, ContractMgt, IdName, IdDescription);
        AddBodyParameter(Parameters, ContractMgt, BodyDescription);
    end;

    local procedure AddSyncParameters(var Parameters: JsonArray; ContractMgt: Codeunit "Msg Contract Mgt ori"; ToTimeSheet: Boolean)
    begin
        Parameters.Add(ContractMgt.Parameter('userId', 'string', true, 'Clockify user ID mapped to a Business Central Resource.'));
        Parameters.Add(ContractMgt.Parameter('entryId', 'string', true, 'Clockify time-entry ID.'));
        Parameters.Add(ContractMgt.Parameter('projectId', 'string', true, 'Clockify project ID mapped to a BC Job.'));
        Parameters.Add(ContractMgt.Parameter('taskId', 'string', not ToTimeSheet, 'Clockify task ID mapped to a BC Job Task.'));
        Parameters.Add(ContractMgt.Parameter('start', 'string', true, 'Start time in ISO-8601 format.'));
        Parameters.Add(ContractMgt.Parameter('end', 'string', true, 'End time in ISO-8601 format; in-progress entries are rejected.'));
        Parameters.Add(ContractMgt.Parameter('tagIds', 'array', false, 'Clockify tag IDs used for Work Type resolution.'));
        if not ToTimeSheet then
            AddJournalParameters(Parameters, ContractMgt);
    end;

    local procedure AddRangeParameters(var Parameters: JsonArray; ContractMgt: Codeunit "Msg Contract Mgt ori"; ToTimeSheet: Boolean; RequireUser: Boolean)
    begin
        Parameters.Add(ContractMgt.Parameter('userId', 'string', RequireUser, 'Clockify user ID whose entries are synchronized.'));
        Parameters.Add(ContractMgt.Parameter('start', 'string', true, 'Inclusive range start in ISO-8601 format.'));
        Parameters.Add(ContractMgt.Parameter('end', 'string', true, 'Inclusive range end in ISO-8601 format.'));
        if not ToTimeSheet then
            AddJournalParameters(Parameters, ContractMgt);
    end;

    local procedure AddJournalParameters(var Parameters: JsonArray; ContractMgt: Codeunit "Msg Contract Mgt ori")
    begin
        Parameters.Add(ContractMgt.Parameter('journalTemplate', 'string', false, 'BC Job Journal Template; defaults to Clockify Setup.'));
        Parameters.Add(ContractMgt.Parameter('journalBatch', 'string', false, 'BC Job Journal Batch; defaults to Clockify Setup.'));
    end;

    local procedure IsInbound(MessageType: Enum "Message Type ori"): Boolean
    begin
        exit(MessageType.AsInteger() >= 10036815);
    end;

    local procedure UsesWorkspace(MessageType: Enum "Message Type ori"): Boolean
    begin
        if IsInbound(MessageType) then
            exit(MessageType.AsInteger() in [10036815, 10036816, 10036821, 10036822, 10036825]);
        exit(MessageType <> MessageType::"Clockify.User.GetCurrent");
    end;


    local procedure HasRequiredData(MessageType: Enum "Message Type ori"): Boolean
    begin
        if MessageType = MessageType::"Clockify.User.GetCurrent" then
            exit(false);
        exit(IsInbound(MessageType) or not IsCollection(MessageType));
    end;

    local procedure IsCollection(MessageType: Enum "Message Type ori"): Boolean
    begin
        exit(MessageType.AsInteger() in [10036786, 10036788, 10036789, 10036794, 10036799, 10036803, 10036807, 10036812, 10036813, 10036814, 10036816]);
    end;

    local procedure IsRead(MessageType: Enum "Message Type ori"): Boolean
    begin
        exit((MessageType.AsInteger() in [10036786, 10036787, 10036788, 10036789, 10036790, 10036794, 10036795, 10036799, 10036803, 10036807, 10036808, 10036812, 10036813, 10036814]) or (MessageType = MessageType::"Help.Clockify.Get"));
    end;

    local procedure IsIrreversible(MessageType: Enum "Message Type ori"): Boolean
    begin
        exit(MessageType.AsInteger() in [10036793, 10036798, 10036802, 10036806, 10036811, 10036817, 10036818, 10036819, 10036820, 10036823, 10036824]);
    end;

    local procedure MessageTypeName(MessageType: Enum "Message Type ori"): Text
    begin
        exit(Enum::"Message Type ori".Names().Get(Enum::"Message Type ori".Ordinals().IndexOf(MessageType.AsInteger())));
    end;
}