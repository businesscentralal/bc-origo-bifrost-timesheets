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
        if not HasTarget(MessageType) then
            exit(false);
        if UsesWorkspace(MessageType) then
            Target.Add(ContractMgt.TargetEntry('data.workspaceId', 'string', 'The Clockify workspace ID. The Default Workspace ID on Clockify Setup is used when this is omitted.'));
        case MessageType of
            MessageType::"Clockify.Client.Get", MessageType::"Clockify.Client.Update", MessageType::"Clockify.Client.Delete":
                Target.Add(ContractMgt.TargetEntry('data.clientId', 'string', 'The Clockify client ID.'));
            MessageType::"Clockify.Project.Get", MessageType::"Clockify.Project.Update", MessageType::"Clockify.Project.Delete":
                Target.Add(ContractMgt.TargetEntry('data.projectId', 'string', 'The Clockify project ID.'));
            MessageType::"Clockify.Task.Create":
                Target.Add(ContractMgt.TargetEntry('data.projectId', 'string', 'The Clockify project ID that owns the task.'));
            MessageType::"Clockify.Task.Update", MessageType::"Clockify.Task.Delete":
                begin
                    Target.Add(ContractMgt.TargetEntry('data.projectId', 'string', 'The Clockify project ID that owns the task.'));
                    Target.Add(ContractMgt.TargetEntry('data.taskId', 'string', 'The Clockify task ID.'));
                end;
            MessageType::"Clockify.Tag.Update", MessageType::"Clockify.Tag.Delete":
                Target.Add(ContractMgt.TargetEntry('data.tagId', 'string', 'The Clockify tag ID.'));
            MessageType::"Clockify.TimeEntry.List", MessageType::"Clockify.TimeEntry.Create":
                Target.Add(ContractMgt.TargetEntry('data.userId', 'string', 'The Clockify user ID whose time entries are addressed.'));
            MessageType::"Clockify.TimeEntry.Get", MessageType::"Clockify.TimeEntry.Update", MessageType::"Clockify.TimeEntry.Delete":
                Target.Add(ContractMgt.TargetEntry('data.timeEntryId', 'string', 'The Clockify time-entry ID.'));
            MessageType::"Clockify.TimeEntry.Sync", MessageType::"Clockify.TimeEntry.SyncToTimeSheet":
                Target.Add(ContractMgt.TargetEntry('data.entryId', 'string', 'The Clockify time-entry ID to sync.'));
        end;
        exit(Target.Count() > 0);
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
                AddBodyParameter(Parameters, ContractMgt, 'Client fields sent verbatim. name is the display name. address is one line: concatenate BC Address, Address 2, Post Code, City, and Country/Region Code. currencyId is the Clockify id from Clockify.Currency.List; currencyCode is ignored.');
            MessageType::"Clockify.Client.Update":
                AddIdAndBodyParameters(Parameters, ContractMgt, 'clientId', 'Clockify client ID.', 'Client fields to change. Optional body fields omitted keep the existing Clockify values. currencyId is the Clockify id, not currencyCode. Set archived true before Clockify.Client.Delete.');
            MessageType::"Clockify.Client.Delete":
                AddIdParameter(Parameters, ContractMgt, 'clientId', 'Archived Clockify client ID.');
            MessageType::"Clockify.Project.List":
                AddPagingParameters(Parameters, ContractMgt);
            MessageType::"Clockify.Project.Get":
                AddIdParameter(Parameters, ContractMgt, 'projectId', 'Clockify project ID.');
            MessageType::"Clockify.Project.Create":
                AddBodyParameter(Parameters, ContractMgt, 'Project fields sent verbatim, including name, clientId, and userGroupIds. userGroupIds are Clockify group ids from Clockify.UserGroup.List, not group names. customFieldId values are set later with Clockify.Project.Update.');
            MessageType::"Clockify.Project.Update":
                AddIdAndBodyParameters(Parameters, ContractMgt, 'projectId', 'Clockify project ID.', 'Project fields to change. Optional body fields omitted keep the existing Clockify values. userGroupIds and customFields.customFieldId are Clockify ids from Clockify.UserGroup.List and Clockify.CustomField.List.');
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
                    Parameters.Add(ContractMgt.Parameter('query', 'object', false, 'Optional query. query.in-progress = true returns running timers (end is null). query.in-progress = false returns finished entries. page-size and page only change the paging window.'));
                end;
            MessageType::"Clockify.TimeEntry.Get", MessageType::"Clockify.TimeEntry.Delete":
                AddIdParameter(Parameters, ContractMgt, 'timeEntryId', 'Clockify time-entry ID.');
            MessageType::"Clockify.TimeEntry.Create":
                begin
                    AddIdParameter(Parameters, ContractMgt, 'userId', 'Clockify user ID.');
                    AddBodyParameter(Parameters, ContractMgt, 'Time-entry fields sent verbatim, including start. customFields.customFieldId comes from Clockify.CustomField.List. Omit end to leave a running timer.');
                end;
            MessageType::"Clockify.TimeEntry.Update":
                begin
                    AddIdAndBodyParameters(Parameters, ContractMgt, 'timeEntryId', 'Clockify time-entry ID.', 'Time-entry fields to change. Optional body fields omitted keep the existing Clockify values. An empty tagIds array clears tags; omitting tagIds keeps them. customFieldId comes from Clockify.CustomField.List.');
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
        case MessageType of
            MessageType::"Help.Clockify.Get":
                begin
                    Fields.Add(ContractMgt.ResponseField('status', 'string', 'Success.'));
                    Fields.Add(ContractMgt.ResponseField('result.messageType', 'string', 'Help.Clockify.Get.'));
                    Fields.Add(ContractMgt.ResponseField('result.format', 'string', 'The value markdown.'));
                    Fields.Add(ContractMgt.ResponseField('result.markdown', 'string', 'The overview, including Clockify.Currency.List, Clockify.UserGroup.List, and Clockify.CustomField.List.'));
                end;
            MessageType::"Clockify.TimeEntry.Sync", MessageType::"Clockify.TimeEntry.SyncToTimeSheet":
                begin
                    Fields.Add(ContractMgt.ResponseField('result', 'string', 'Created, Skipped, Updated, Corrected, or Error.'));
                    Fields.Add(ContractMgt.ResponseField('message', 'string', 'The sync result message.'));
                    Fields.Add(ContractMgt.ResponseField('entryId', 'string', 'The Clockify time-entry ID.'));
                    Fields.Add(ContractMgt.ResponseField('hours', 'decimal', 'Hours derived from start and end.'));
                    Fields.Add(ContractMgt.ResponseField('postingDate', 'string', 'The posting date derived from start.'));
                end;
            MessageType::"Clockify.TimeEntry.SyncRange":
                begin
                    Fields.Add(ContractMgt.ResponseField('processed', 'integer', 'Entries considered.'));
                    Fields.Add(ContractMgt.ResponseField('created', 'integer', 'Journal lines created.'));
                    Fields.Add(ContractMgt.ResponseField('skipped', 'integer', 'Unchanged entries.'));
                    Fields.Add(ContractMgt.ResponseField('updated', 'integer', 'Journal lines updated.'));
                    Fields.Add(ContractMgt.ResponseField('corrected', 'integer', 'Posted entries corrected.'));
                    Fields.Add(ContractMgt.ResponseField('errors', 'integer', 'Per-entry failures. They do not abort the batch.'));
                    Fields.Add(ContractMgt.ResponseField('results', 'array', 'Per-entry result rows.'));
                end;
            MessageType::"Clockify.TimeEntry.SyncRangeToTimeSheet":
                begin
                    Fields.Add(ContractMgt.ResponseField('processed', 'integer', 'Entries considered.'));
                    Fields.Add(ContractMgt.ResponseField('created', 'integer', 'Time-sheet lines created.'));
                    Fields.Add(ContractMgt.ResponseField('skipped', 'integer', 'Unchanged entries.'));
                    Fields.Add(ContractMgt.ResponseField('updated', 'integer', 'Time-sheet lines updated.'));
                    Fields.Add(ContractMgt.ResponseField('errors', 'integer', 'Per-entry failures. They do not abort the batch.'));
                    Fields.Add(ContractMgt.ResponseField('results', 'array', 'Per-entry result rows.'));
                end;
            MessageType::"Clockify.TimeEntry.SyncAllUsers":
                begin
                    Fields.Add(ContractMgt.ResponseField('target', 'string', 'timesheet or journal.'));
                    Fields.Add(ContractMgt.ResponseField('users', 'integer', 'Mapped users considered.'));
                    Fields.Add(ContractMgt.ResponseField('created', 'integer', 'Rows created.'));
                    Fields.Add(ContractMgt.ResponseField('skipped', 'integer', 'Unchanged entries.'));
                    Fields.Add(ContractMgt.ResponseField('updated', 'integer', 'Rows updated.'));
                    Fields.Add(ContractMgt.ResponseField('errors', 'integer', 'Per-user or per-entry failures. They do not abort the batch.'));
                    Fields.Add(ContractMgt.ResponseField('userResults', 'array', 'Per-user result rows.'));
                end;
            MessageType::"Clockify.TimeSheet.Create":
                begin
                    Fields.Add(ContractMgt.ResponseField('status', 'string', 'Success.'));
                    Fields.Add(ContractMgt.ResponseField('created', 'integer', 'Time sheets created.'));
                end;
            MessageType::"Clockify.TimeSheet.Approve":
                begin
                    Fields.Add(ContractMgt.ResponseField('status', 'string', 'Success.'));
                    Fields.Add(ContractMgt.ResponseField('approvedLines', 'integer', 'Lines submitted and approved.'));
                end;
            MessageType::"Clockify.TimeSheet.Reject":
                begin
                    Fields.Add(ContractMgt.ResponseField('status', 'string', 'Success.'));
                    Fields.Add(ContractMgt.ResponseField('rejectedLines', 'integer', 'Lines rejected.'));
                end;
            MessageType::"Clockify.TimeSheet.Reopen":
                begin
                    Fields.Add(ContractMgt.ResponseField('status', 'string', 'Success.'));
                    Fields.Add(ContractMgt.ResponseField('reopenedLines', 'integer', 'Lines reopened to Open.'));
                end;
            MessageType::"Clockify.TimeSheet.Post":
                begin
                    Fields.Add(ContractMgt.ResponseField('status', 'string', 'Success.'));
                    Fields.Add(ContractMgt.ResponseField('postedLines', 'integer', 'Approved lines posted to the Job Journal.'));
                end;
            MessageType::"Clockify.TimeSheet.Archive":
                begin
                    Fields.Add(ContractMgt.ResponseField('status', 'string', 'Success.'));
                    Fields.Add(ContractMgt.ResponseField('archived', 'integer', 'Time sheets archived.'));
                end;
            else begin
                Fields.Add(ContractMgt.ResponseField('status', 'string', 'Success or Error.'));
                Fields.Add(ContractMgt.ResponseField('statusCode', 'integer', 'Clockify HTTP status when an API call was made. The app forwards this status; it does not raise Unauthorized or Forbidden as its own code.'));
                Fields.Add(ContractMgt.ResponseField('data', 'object', 'The Clockify payload, or the projected currency array for Clockify.Currency.List.'));
            end;
        end;
        Response.Add('contentType', 'text/json');
        Response.Add('fields', Fields);
        exit(true);
    end;

    procedure GetErrors(MessageType: Enum "Message Type ori"; var Errors: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        if SendsWritePermissionError(MessageType) then
            Errors.Add(ContractMgt.TextErrorEntry('You do not have write permission to the Clockify Integration table, which is required to run Clockify connector operations. Ask your administrator to assign the Clockify - Full permission set.', 'Clockify Integration Gate rejects the call before the operation runs.', 'Assign a permission set that can write the Clockify Integration table.'));
        if SendsMissingWorkspace(MessageType) then
            Errors.Add(ContractMgt.TextErrorEntry('No workspace was supplied. Provide ''workspaceId'' in the request or set a Default Workspace ID on Clockify Setup.', 'ResolveWorkspaceId found neither a request workspaceId nor a default.', 'Pass workspaceId or set Default Workspace ID on Clockify Setup.'));
        if SendsMissingParameter(MessageType) then
            Errors.Add(ContractMgt.TextErrorEntry('Missing required ''%1'' in the request.', 'RequireParam did not find the named value.', 'Send the parameter named in the error text.'));
        if SendsMissingBody(MessageType) then
            Errors.Add(ContractMgt.TextErrorEntry('Missing required ''body'' object in the request.', 'RequireBody did not find a body object.', 'Send the body object.'));
        case MessageType of
            MessageType::"Clockify.Currency.List":
                Errors.Add(ContractMgt.TextErrorEntry('The Clockify workspace ''%1'' was not found for the configured API key.', 'The workspace list did not contain the requested workspace.', 'Call Clockify.Workspace.List and pass one of its ids.'));
            MessageType::"Clockify.TimeEntry.Sync":
                begin
                    Errors.Add(ContractMgt.TextErrorEntry('In-progress time entries are not synced to Job Journal. Provide an entry with a non-empty ''end'' value (timer stopped).', 'end is empty.', 'Stop the timer before sync. In-progress protection: these entries are never written to Job Journal.'));
                    Errors.Add(ContractMgt.TextErrorEntry('No Job Journal target is configured. Set the Clockify Job Journal Template and Batch on Clockify Setup, or pass ''journalTemplate'' and ''journalBatch'' in the request.', 'Neither the request nor Clockify Setup names a journal template and batch.', 'Set the journal on Clockify Setup or pass both parameters.'));
                    Errors.Add(ContractMgt.TextErrorEntry('Cannot calculate hours: start and end are required ISO 8601 datetime values.', 'start or end is missing or not a datetime.', 'Send start and end as ISO-8601 datetimes.'));
                    Errors.Add(ContractMgt.TextErrorEntry('Cannot parse posting date from start value.', 'start is not a date the app can parse.', 'Send start as an ISO-8601 datetime.'));
                end;
            MessageType::"Clockify.TimeEntry.SyncToTimeSheet":
                begin
                    Errors.Add(ContractMgt.TextErrorEntry('In-progress time entries are not synced. Provide an entry with a non-empty ''end'' value (timer stopped).', 'end is empty.', 'Stop the timer before sync.'));
                    Errors.Add(ContractMgt.TextErrorEntry('Cannot derive hours and posting date: start and end must be ISO-8601 datetimes.', 'start or end is missing or not a datetime.', 'Send start and end as ISO-8601 datetimes.'));
                end;
            MessageType::"Clockify.TimeEntry.SyncRange":
                begin
                    Errors.Add(ContractMgt.TextErrorEntry('No Job Journal target is configured. Set the Clockify Job Journal Template and Batch on Clockify Setup, or pass ''journalTemplate'' and ''journalBatch'' in the request.', 'Neither the request nor Clockify Setup names a journal template and batch.', 'Set the journal on Clockify Setup or pass both parameters.'));
                    Errors.Add(ContractMgt.TextErrorEntry('Failed to read time entries from Clockify (HTTP %1): %2', 'The Clockify list call did not succeed.', 'Read the HTTP status and Clockify message, then retry.'));
                    Errors.Add(ContractMgt.TextErrorEntry('Unexpected response from Clockify when listing time entries: expected a JSON array.', 'The list body was not a JSON array.', 'Retry the list. The app does not accept an object payload here.'));
                end;
            MessageType::"Clockify.TimeEntry.SyncRangeToTimeSheet":
                Errors.Add(ContractMgt.TextErrorEntry('Failed to read time entries from Clockify (HTTP %1): %2', 'The Clockify list call did not succeed.', 'Read the HTTP status and Clockify message, then retry.'));
            MessageType::"Clockify.TimeSheet.Post":
                Errors.Add(ContractMgt.TextErrorEntry('No Job Journal target is configured. Set the Clockify Job Journal Template and Batch on Clockify Setup, or pass ''journalTemplate'' and ''journalBatch'' in the request.', 'Neither the request nor Clockify Setup names a journal template and batch.', 'Set the journal on Clockify Setup or pass both parameters.'));
            MessageType::"Clockify.TimeEntry.SyncAllUsers":
                Errors.Add(ContractMgt.TextErrorEntry('target=journal requires a Job Journal. Set the Clockify Job Journal Template and Batch on Clockify Setup, or pass ''journalTemplate'' and ''journalBatch''.', 'target is journal and no template or batch is available.', 'Set the journal on Clockify Setup or pass both parameters.'));
        end;
        exit(Errors.Count() > 0);
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
            Changes := 'Deletes a Clockify record. The delete cannot be undone from this message type.';
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
        if MessageType = MessageType::"Help.Clockify.Get" then begin
            Related.Add(ContractMgt.RelatedEntry('Clockify.Workspace.List', 'After the overview, list workspaces to obtain a workspace ID.'));
            exit(true);
        end;
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
        RequestText: Text;
        ResponseText: Text;
    begin
        Name := MessageTypeName(MessageType);
        ExamplePair(MessageType, RequestText, ResponseText);
        Examples.Add(ContractMgt.Example(ExampleTitle(MessageType), '{"type":"' + Name + '","data":' + RequestText + '}', ResponseText));
        exit(true);
    end;

    procedure GetOverview(MessageType: Enum "Message Type ori"; var Overview: Text): Boolean
    begin
        if MessageType = MessageType::"Help.Clockify.Get" then
            Overview := 'Help.Clockify.Get is read-only. It lists every Clockify message type, including Clockify.Currency.List, Clockify.UserGroup.List, and Clockify.CustomField.List. Writes accept Clockify IDs, never names or BC keys. Clients and projects must be archived before they can be deleted.'
        else
            if IsRead(MessageType) then
                Overview := MessageTypeName(MessageType) + ' is read-only. It does not change Clockify or Business Central.'
            else
                if IsIrreversible(MessageType) then
                    Overview := MessageTypeName(MessageType) + ' is irreversible. Look the id up with the matching List or Get message before deleting.'
                else
                    Overview := MessageTypeName(MessageType) + ' changes Clockify or Business Central data.';
        exit(true);
    end;

    procedure GetNotes(MessageType: Enum "Message Type ori"; var Notes: Text): Boolean
    begin
        Notes := NotesFor(MessageType);
        exit(Notes <> '');
    end;

    local procedure AddPagingParameters(var Parameters: JsonArray; ContractMgt: Codeunit "Msg Contract Mgt ori")
    begin
        Parameters.Add(ContractMgt.Parameter('query', 'object', false, 'Optional query object. query.* parameters such as page-size, page, name, status, or archived only shape the returned data. page-size and page change the paging window.'));
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
        Parameters.Add(ContractMgt.Parameter('taskId', 'string', false, 'Clockify task ID mapped to a BC Job Task. The app reads it when present and does not require it.'));
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
        exit(MessageType in [
            MessageType::"Clockify.TimeEntry.Sync",
            MessageType::"Clockify.TimeEntry.SyncRange",
            MessageType::"Clockify.TimeEntry.SyncToTimeSheet",
            MessageType::"Clockify.TimeEntry.SyncRangeToTimeSheet",
            MessageType::"Clockify.TimeEntry.SyncAllUsers",
            MessageType::"Clockify.TimeSheet.Create",
            MessageType::"Clockify.TimeSheet.Approve",
            MessageType::"Clockify.TimeSheet.Reject",
            MessageType::"Clockify.TimeSheet.Reopen",
            MessageType::"Clockify.TimeSheet.Post",
            MessageType::"Clockify.TimeSheet.Archive"]);
    end;

    local procedure UsesWorkspace(MessageType: Enum "Message Type ori"): Boolean
    begin
        if MessageType in [
            MessageType::"Help.Clockify.Get",
            MessageType::"Clockify.User.GetCurrent",
            MessageType::"Clockify.TimeSheet.Create",
            MessageType::"Clockify.TimeSheet.Approve",
            MessageType::"Clockify.TimeSheet.Reject",
            MessageType::"Clockify.TimeSheet.Reopen",
            MessageType::"Clockify.TimeSheet.Post",
            MessageType::"Clockify.TimeSheet.Archive"]
        then
            exit(false);
        exit(true);
    end;

    local procedure HasRequiredData(MessageType: Enum "Message Type ori"): Boolean
    begin
        if MessageType = MessageType::"Clockify.User.GetCurrent" then
            exit(false);
        exit(IsInbound(MessageType) or not IsCollection(MessageType));
    end;

    local procedure IsCollection(MessageType: Enum "Message Type ori"): Boolean
    begin
        exit(MessageType in [
            MessageType::"Clockify.Workspace.List",
            MessageType::"Clockify.User.List",
            MessageType::"Clockify.Client.List",
            MessageType::"Clockify.Project.List",
            MessageType::"Clockify.Task.List",
            MessageType::"Clockify.Tag.List",
            MessageType::"Clockify.TimeEntry.List",
            MessageType::"Clockify.Currency.List",
            MessageType::"Clockify.UserGroup.List",
            MessageType::"Clockify.CustomField.List"]);
    end;

    local procedure IsRead(MessageType: Enum "Message Type ori"): Boolean
    begin
        exit(IsCollection(MessageType) or (MessageType in [
            MessageType::"Help.Clockify.Get",
            MessageType::"Clockify.User.GetCurrent",
            MessageType::"Clockify.Client.Get",
            MessageType::"Clockify.Project.Get",
            MessageType::"Clockify.TimeEntry.Get"]));
    end;

    local procedure IsIrreversible(MessageType: Enum "Message Type ori"): Boolean
    begin
        exit(MessageType in [
            MessageType::"Clockify.Client.Delete",
            MessageType::"Clockify.Project.Delete",
            MessageType::"Clockify.Task.Delete",
            MessageType::"Clockify.Tag.Delete",
            MessageType::"Clockify.TimeEntry.Delete"]);
    end;

    local procedure HasTarget(MessageType: Enum "Message Type ori"): Boolean
    begin
        if IsCollection(MessageType) then
            exit(false);
        if MessageType in [
            MessageType::"Help.Clockify.Get",
            MessageType::"Clockify.User.GetCurrent",
            MessageType::"Clockify.TimeEntry.SyncRange",
            MessageType::"Clockify.TimeEntry.SyncRangeToTimeSheet",
            MessageType::"Clockify.TimeEntry.SyncAllUsers",
            MessageType::"Clockify.TimeSheet.Create",
            MessageType::"Clockify.TimeSheet.Approve",
            MessageType::"Clockify.TimeSheet.Reject",
            MessageType::"Clockify.TimeSheet.Reopen",
            MessageType::"Clockify.TimeSheet.Post",
            MessageType::"Clockify.TimeSheet.Archive"]
        then
            exit(false);
        exit(not IsCollection(MessageType));
    end;

    local procedure SendsWritePermissionError(MessageType: Enum "Message Type ori"): Boolean
    begin
        exit(not IsInbound(MessageType) and (MessageType <> MessageType::"Help.Clockify.Get"));
    end;

    local procedure SendsMissingWorkspace(MessageType: Enum "Message Type ori"): Boolean
    begin
        if not UsesWorkspace(MessageType) then
            exit(false);
        exit(MessageType <> MessageType::"Clockify.Workspace.List");
    end;

    local procedure SendsMissingParameter(MessageType: Enum "Message Type ori"): Boolean
    begin
        exit(MessageType in [
            MessageType::"Clockify.Client.Get",
            MessageType::"Clockify.Client.Update",
            MessageType::"Clockify.Client.Delete",
            MessageType::"Clockify.Project.Get",
            MessageType::"Clockify.Project.Update",
            MessageType::"Clockify.Project.Delete",
            MessageType::"Clockify.Task.List",
            MessageType::"Clockify.Task.Create",
            MessageType::"Clockify.Task.Update",
            MessageType::"Clockify.Task.Delete",
            MessageType::"Clockify.Tag.Update",
            MessageType::"Clockify.Tag.Delete",
            MessageType::"Clockify.TimeEntry.List",
            MessageType::"Clockify.TimeEntry.Get",
            MessageType::"Clockify.TimeEntry.Create",
            MessageType::"Clockify.TimeEntry.Update",
            MessageType::"Clockify.TimeEntry.Delete",
            MessageType::"Clockify.TimeEntry.Sync",
            MessageType::"Clockify.TimeEntry.SyncRange",
            MessageType::"Clockify.TimeEntry.SyncToTimeSheet",
            MessageType::"Clockify.TimeEntry.SyncRangeToTimeSheet",
            MessageType::"Clockify.TimeEntry.SyncAllUsers"]);
    end;

    local procedure SendsMissingBody(MessageType: Enum "Message Type ori"): Boolean
    begin
        exit(MessageType in [
            MessageType::"Clockify.Client.Create",
            MessageType::"Clockify.Client.Update",
            MessageType::"Clockify.Project.Create",
            MessageType::"Clockify.Project.Update",
            MessageType::"Clockify.Task.Create",
            MessageType::"Clockify.Task.Update",
            MessageType::"Clockify.Tag.Create",
            MessageType::"Clockify.Tag.Update",
            MessageType::"Clockify.TimeEntry.Create",
            MessageType::"Clockify.TimeEntry.Update"]);
    end;

    local procedure ExampleTitle(MessageType: Enum "Message Type ori"): Text
    begin
        if MessageType in [
            MessageType::"Clockify.TimeEntry.SyncToTimeSheet",
            MessageType::"Clockify.TimeEntry.SyncRangeToTimeSheet",
            MessageType::"Clockify.TimeSheet.Archive"]
        then
            exit('## Request example');
        exit('Minimal request');
    end;

    local procedure ExamplePair(MessageType: Enum "Message Type ori"; var RequestText: Text; var ResponseText: Text)
    begin
        ResponseText := '{"status":"Success","statusCode":200,"data":{}}';
        RequestText := '{}';
        case MessageType of
            MessageType::"Help.Clockify.Get":
                begin
                    RequestText := '{}';
                    ResponseText := '{"status":"Success","result":{"messageType":"Help.Clockify.Get","format":"markdown","markdown":"..."}}';
                end;
            MessageType::"Clockify.User.GetCurrent":
                ResponseText := '{"status":"Success","statusCode":200,"data":{"id":"<userId>"}}';
            MessageType::"Clockify.Workspace.List":
                ResponseText := '{"status":"Success","statusCode":200,"data":[{"id":"<workspaceId>","name":"Workspace"}]}';
            MessageType::"Clockify.User.List",
            MessageType::"Clockify.Client.List",
            MessageType::"Clockify.Project.List",
            MessageType::"Clockify.Tag.List",
            MessageType::"Clockify.Currency.List",
            MessageType::"Clockify.UserGroup.List",
            MessageType::"Clockify.CustomField.List":
                begin
                    RequestText := '{"workspaceId":"<workspaceId>","query":{"page-size":50,"page":1}}';
                    ResponseText := '{"status":"Success","statusCode":200,"data":[]}';
                end;
            MessageType::"Clockify.Client.Get", MessageType::"Clockify.Client.Delete":
                RequestText := '{"workspaceId":"<workspaceId>","clientId":"<clientId>"}';
            MessageType::"Clockify.Client.Create":
                RequestText := '{"workspaceId":"<workspaceId>","body":{"name":"Adatum","currencyId":"<currencyId>"}}';
            MessageType::"Clockify.Client.Update":
                RequestText := '{"workspaceId":"<workspaceId>","clientId":"<clientId>","body":{"archived":true}}';
            MessageType::"Clockify.Project.Get", MessageType::"Clockify.Project.Delete":
                RequestText := '{"workspaceId":"<workspaceId>","projectId":"<projectId>"}';
            MessageType::"Clockify.Project.Create":
                RequestText := '{"workspaceId":"<workspaceId>","body":{"name":"Implementation","clientId":"<clientId>","userGroupIds":["<userGroupId>"]}}';
            MessageType::"Clockify.Project.Update":
                RequestText := '{"workspaceId":"<workspaceId>","projectId":"<projectId>","body":{"userGroupIds":["<userGroupId>"],"customFields":[{"customFieldId":"<customFieldId>"}]}}';
            MessageType::"Clockify.Task.List":
                RequestText := '{"workspaceId":"<workspaceId>","projectId":"<projectId>","query":{"page-size":50,"page":1}}';
            MessageType::"Clockify.Task.Create":
                RequestText := '{"workspaceId":"<workspaceId>","projectId":"<projectId>","body":{"name":"Design"}}';
            MessageType::"Clockify.Task.Update", MessageType::"Clockify.Task.Delete":
                RequestText := '{"workspaceId":"<workspaceId>","projectId":"<projectId>","taskId":"<taskId>"}';
            MessageType::"Clockify.Tag.Create":
                RequestText := '{"workspaceId":"<workspaceId>","body":{"name":"Billable"}}';
            MessageType::"Clockify.Tag.Update", MessageType::"Clockify.Tag.Delete":
                RequestText := '{"workspaceId":"<workspaceId>","tagId":"<tagId>"}';
            MessageType::"Clockify.TimeEntry.List":
                begin
                    RequestText := '{"workspaceId":"<workspaceId>","userId":"<userId>","query":{"in-progress":false,"page-size":50,"page":1}}';
                    ResponseText := '{"status":"Success","statusCode":200,"data":[]}';
                end;
            MessageType::"Clockify.TimeEntry.Get", MessageType::"Clockify.TimeEntry.Delete":
                RequestText := '{"workspaceId":"<workspaceId>","timeEntryId":"<timeEntryId>"}';
            MessageType::"Clockify.TimeEntry.Create":
                RequestText := '{"workspaceId":"<workspaceId>","userId":"<userId>","body":{"start":"2026-06-09T08:00:00Z","end":"2026-06-09T10:00:00Z","customFields":[{"customFieldId":"<customFieldId>","value":"PO-1"}]}}';
            MessageType::"Clockify.TimeEntry.Update":
                RequestText := '{"workspaceId":"<workspaceId>","timeEntryId":"<timeEntryId>","body":{"end":"2026-06-09T11:00:00Z"}}';
            MessageType::"Clockify.TimeEntry.Sync":
                begin
                    RequestText := '{"workspaceId":"<workspaceId>","userId":"<userId>","entryId":"<entryId>","projectId":"<projectId>","start":"2026-06-09T08:00:00Z","end":"2026-06-09T10:00:00Z"}';
                    ResponseText := '{"result":"Created","message":"","entryId":"<entryId>","hours":2,"postingDate":"2026-06-09"}';
                end;
            MessageType::"Clockify.TimeEntry.SyncRange":
                begin
                    RequestText := '{"workspaceId":"<workspaceId>","userId":"<userId>","start":"2026-06-01T00:00:00Z","end":"2026-06-30T23:59:59Z"}';
                    ResponseText := '{"processed":1,"created":1,"skipped":0,"updated":0,"corrected":0,"errors":0,"results":[]}';
                end;
            MessageType::"Clockify.TimeEntry.SyncToTimeSheet":
                begin
                    RequestText := '{"workspaceId":"<workspaceId>","userId":"<userId>","entryId":"<entryId>","projectId":"<projectId>","start":"2026-06-09T08:00:00Z","end":"2026-06-09T10:00:00Z"}';
                    ResponseText := '{"result":"Created","message":"","entryId":"<entryId>","hours":2,"postingDate":"2026-06-09"}';
                end;
            MessageType::"Clockify.TimeEntry.SyncRangeToTimeSheet":
                begin
                    RequestText := '{"workspaceId":"<workspaceId>","userId":"<userId>","start":"2026-06-01T00:00:00Z","end":"2026-06-30T23:59:59Z"}';
                    ResponseText := '{"processed":1,"created":1,"skipped":0,"updated":0,"errors":0,"results":[]}';
                end;
            MessageType::"Clockify.TimeEntry.SyncAllUsers":
                begin
                    RequestText := '{"workspaceId":"<workspaceId>","start":"2026-06-01T00:00:00Z","end":"2026-06-30T23:59:59Z","target":"timesheet"}';
                    ResponseText := '{"target":"timesheet","users":1,"created":1,"skipped":0,"updated":0,"errors":0,"userResults":[]}';
                end;
            MessageType::"Clockify.TimeSheet.Create":
                begin
                    RequestText := '{"weeksAhead":4}';
                    ResponseText := '{"status":"Success","created":0}';
                end;
            MessageType::"Clockify.TimeSheet.Approve", MessageType::"Clockify.TimeSheet.Reject", MessageType::"Clockify.TimeSheet.Reopen":
                begin
                    RequestText := '{"endingDateTo":"2026-06-30"}';
                    ResponseText := '{"status":"Success"}';
                end;
            MessageType::"Clockify.TimeSheet.Post":
                begin
                    RequestText := '{"journalTemplate":"VERK","journalBatch":"CONTOSO"}';
                    ResponseText := '{"status":"Success","postedLines":0}';
                end;
            MessageType::"Clockify.TimeSheet.Archive":
                begin
                    RequestText := '{ }';
                    ResponseText := '{"status":"Success","archived":0}';
                end;
        end;
    end;

    local procedure NotesFor(MessageType: Enum "Message Type ori"): Text
    var
        Notes: Text;
    begin
        case MessageType of
            MessageType::"Help.Clockify.Get":
                Notes := 'Integration tracking uses Data.Records.Set on the Clockify Integration table. "tableName": "Clockify Integration ori". Clockify Type values are CLIENT, PROJECT, TASK, TAG, TIME_ENTRY, USER, and WORKSPACE. Writes accept Clockify IDs. Clients and projects must be archived before they can be deleted.';
            MessageType::"Clockify.Client.Create":
                Notes := 'Integration tracking: after create, call Data.Records.Set on the Clockify Integration table with Clockify Type = CLIENT. currencyCode is ignored; use currencyId. address is a single line.';
            MessageType::"Clockify.Client.Update":
                Notes := 'Agent guidance — optional parameter effects. Optional `body.*` fields omitted keep the existing Clockify values. Set archived true before delete. Clockify Type = CLIENT.';
            MessageType::"Clockify.Client.Delete":
                Notes := 'Irreversible. Archive the client first. Then mark the Clockify Integration row reversed; do not delete the row. Clockify Type = CLIENT.';
            MessageType::"Clockify.Client.List", MessageType::"Clockify.Client.Get":
                Notes := 'Read-only. Resolve clientId from this list or from the Clockify Integration table before a write. Clockify Type = CLIENT.';
            MessageType::"Clockify.Project.Create":
                Notes := 'userGroupIds must be Clockify group ids. Names are ignored. Set customFieldId later with Clockify.Project.Update. Integration tracking: Clockify Type = PROJECT.';
            MessageType::"Clockify.Project.Update":
                Notes := 'Agent guidance — optional parameter effects. Optional `body.*` fields omitted keep the existing Clockify values. userGroupIds and customFieldId are Clockify ids. Clockify Type = PROJECT.';
            MessageType::"Clockify.Project.Delete":
                Notes := 'Irreversible. Archive the project first. Tasks under it are removed by Clockify. Mark the Clockify Integration row reversed. Clockify Type = PROJECT.';
            MessageType::"Clockify.Project.List", MessageType::"Clockify.Project.Get":
                Notes := 'Read-only. Use the id as projectId on later writes. Clockify Type = PROJECT.';
            MessageType::"Clockify.Task.Create", MessageType::"Clockify.Task.Update":
                Notes := 'Tasks are scoped to a project. Optional body fields omitted on update keep the existing Clockify values. Clockify Type = TASK. No archive step is required before delete.';
            MessageType::"Clockify.Task.Delete":
                Notes := 'Irreversible. Unlike clients and projects, tasks do not need to be archived first. Clockify Type = TASK.';
            MessageType::"Clockify.Task.List":
                Notes := 'Read-only. Use the id as taskId on time entries. Clockify Type = TASK.';
            MessageType::"Clockify.Tag.Create":
                Notes := 'Tags are workspace-scoped. Use the id, not the name, in tagIds. Integration tracking: Clockify Type = TAG.';
            MessageType::"Clockify.Tag.Update":
                Notes := 'Agent guidance — optional parameter effects. Optional `body.*` fields omitted keep the existing Clockify values. Archiving is not required before delete. Clockify Type = TAG.';
            MessageType::"Clockify.Tag.Delete":
                Notes := 'Irreversible. No archive step. Clockify Type = TAG.';
            MessageType::"Clockify.Tag.List":
                Notes := 'Read-only. Use id values in tagIds. Clockify Type = TAG.';
            MessageType::"Clockify.UserGroup.List":
                Notes := 'Notes: use the returned id as userGroupIds on Clockify.Project.Create and Clockify.Project.Update. Group names are not accepted. Read-only.';
            MessageType::"Clockify.CustomField.List":
                Notes := 'Notes: use the returned id as customFieldId on time-entry and project write payloads. This list is workspace-level definitions only. Read-only.';
            MessageType::"Clockify.Currency.List":
                Notes := 'Read-only. Clockify has no currencies endpoint. The app reads the workspace list and returns that workspace currencies array. Use id as currencyId, not the code.';
            MessageType::"Clockify.User.List":
                Notes := 'Agent guidance — optional parameter effects. query.* parameters such as page-size and page only shape the returned data. Read-only. The id is the userId for time entries. Clockify Type = USER.';
            MessageType::"Clockify.User.GetCurrent":
                Notes := 'Read-only. No workspaceId. The id is the userId for time-entry calls. activeWorkspace is the user current workspace.';
            MessageType::"Clockify.Workspace.List":
                Notes := 'Read-only. Returns workspaces the API key can access. Pass id as workspaceId on later calls, or set Default Workspace ID on Clockify Setup.';
            MessageType::"Clockify.TimeEntry.List":
                Notes := 'Read-only. query.in-progress = true returns running timers. query.in-progress = false returns finished entries. Prefer finished entries before Clockify.TimeEntry.Sync.';
            MessageType::"Clockify.TimeEntry.Get":
                Notes := 'Read-only. The parameter name is timeEntryId. Clockify Type = TIME_ENTRY.';
            MessageType::"Clockify.TimeEntry.Create", MessageType::"Clockify.TimeEntry.Update":
                Notes := 'customFieldId values come from Clockify.CustomField.List. Optional body fields omitted on update keep the existing Clockify values. An empty tagIds array clears tags. Clockify Type = TIME_ENTRY.';
            MessageType::"Clockify.TimeEntry.Delete":
                Notes := 'Irreversible. No archive step. Clockify Type = TIME_ENTRY.';
            MessageType::"Clockify.TimeEntry.Sync":
                Notes := 'In-progress protection: entries with an empty end are rejected and never written to Job Journal. This operation does not call Clockify. It writes a Job Journal line and tracks Clockify Type = TIME_ENTRY. taskId is optional. Results are Created, Skipped, Updated, or Corrected. Safe to retry when the response says Skipped.';
            MessageType::"Clockify.TimeEntry.SyncRange":
                Notes := 'Reads finished Clockify entries, then writes Job Journal lines. Per-entry failures are counted and do not abort the batch. Running timers are excluded. Safe to re-run: unchanged entries are Skipped.';
            MessageType::"Clockify.TimeEntry.SyncToTimeSheet":
                Notes := 'Writes a BC Time Sheet line and detail, not the Job Journal. Deduplicated by entryId. Clockify Type = TIME_ENTRY. Run Clockify.TimeSheet.Create first so an open sheet covers the date. In-progress entries are rejected.';
            MessageType::"Clockify.TimeEntry.SyncRangeToTimeSheet":
                Notes := 'Reads finished entries from Clockify and writes BC Time Sheets. Per-entry failures do not abort the batch. The request includes start and end. Safe to re-run.';
            MessageType::"Clockify.TimeEntry.SyncAllUsers":
                Notes := 'Iterates every USER mapping. target timesheet is the default; target journal writes the Job Journal. Per-user failures do not abort the batch. No userId parameter.';
            MessageType::"Clockify.TimeSheet.Create":
                Notes := 'BC-side only. Does not call Clockify. Idempotent up to weeksAhead open sheets per resource.';
            MessageType::"Clockify.TimeSheet.Approve":
                Notes := 'BC-side only. Submits and approves open lines through the time-sheet approval engine up to endingDateTo.';
            MessageType::"Clockify.TimeSheet.Reject":
                Notes := 'BC-side only. Rejects submitted lines up to endingDateTo.';
            MessageType::"Clockify.TimeSheet.Reopen":
                Notes := 'BC-side only. Reopens submitted or approved lines back to Open up to endingDateTo.';
            MessageType::"Clockify.TimeSheet.Post":
                Notes := 'BC-side only. Posts approved, unposted job lines.';
            MessageType::"Clockify.TimeSheet.Archive":
                Notes := 'BC-side only. Archives fully posted sheets and removes empty posted sheets. The request example is an empty object.';
        end;
        if IsCollection(MessageType) and (MessageType <> MessageType::"Clockify.TimeEntry.List") and (MessageType <> MessageType::"Clockify.User.List") then
            Notes := Notes + ' Agent guidance — optional parameter effects. query.* parameters such as page-size only shape the returned data.';
        exit(Notes);
    end;

    procedure MessageTypeName(MessageType: Enum "Message Type ori"): Text
    begin
        exit(Enum::"Message Type ori".Names().Get(Enum::"Message Type ori".Ordinals().IndexOf(MessageType.AsInteger())));
    end;
}