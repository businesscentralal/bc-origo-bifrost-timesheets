namespace Origo.PTE.CloudEvents.Clockify;

/// <summary>
/// Builds AI-optimised Markdown help documents for the Clockify connector.
/// Uses a builder pattern: call <c>Init</c>, then <c>AddParam</c>/<c>AddError</c>/setters,
/// then <c>Render</c> to produce the final document.
/// Each section is designed for unambiguous machine parsing: structured tables,
/// explicit types, resolution instructions, preconditions, and workflow context.
/// </summary>
codeunit 71408 "Clockify Help Builder"
{
    Access = Internal;

    var
        TitleVar: Text;
        DescriptionVar: Text;
        HttpMethodVar: Text;
        ApiPathVar: Text;
        RequestExampleVar: Text;
        ResponseNoteVar: Text;
        NotesVar: Text;
        PreconditionsVar: Text;
        AfterSuccessVar: Text;
        RelatedVar: Text;
        ParamsBuilder: TextBuilder;
        ErrorsBuilder: TextBuilder;
        ParamCount: Integer;
        ErrorCount: Integer;
        HasOptionalParams: Boolean;
        HasOptionalQueryParams: Boolean;
        HasOptionalBodyParams: Boolean;
        HasQueryPagingParams: Boolean;
        HasInProgressQueryParam: Boolean;
        HasBodyEndParam: Boolean;

    /// <summary>
    /// Initializes the builder for a single message type document.
    /// </summary>
    /// <param name="MessageType">The full message type name (e.g. 'Clockify.Client.Create').</param>
    /// <param name="Description">One or two sentence summary of what it does.</param>
    /// <param name="HttpMethod">The Clockify HTTP method (GET/POST/PUT/DELETE).</param>
    /// <param name="ApiPath">The Clockify resource path template (e.g. '/workspaces/{workspaceId}/clients').</param>
    procedure Init(MessageType: Text; Description: Text; HttpMethod: Text; ApiPath: Text)
    begin
        TitleVar := MessageType;
        DescriptionVar := Description;
        HttpMethodVar := HttpMethod;
        ApiPathVar := ApiPath;
        RequestExampleVar := '';
        ResponseNoteVar := '';
        NotesVar := '';
        PreconditionsVar := '';
        AfterSuccessVar := '';
        RelatedVar := '';
        ParamCount := 0;
        ErrorCount := 0;
        HasOptionalParams := false;
        HasOptionalQueryParams := false;
        HasOptionalBodyParams := false;
        HasQueryPagingParams := false;
        HasInProgressQueryParam := false;
        HasBodyEndParam := false;
        Clear(ParamsBuilder);
        Clear(ErrorsBuilder);
    end;

    /// <summary>
    /// Adds one row to the Parameters table. Call once per request parameter.
    /// </summary>
    /// <param name="ParamName">The JSON property name (e.g. 'workspaceId', 'body.name').</param>
    /// <param name="Required">Whether the parameter is required for a successful call.</param>
    /// <param name="DataType">The value type (string, boolean, integer, ISO-8601 datetime, array, object).</param>
    /// <param name="Description">What the parameter means or controls.</param>
    /// <param name="ResolveVia">Which message type or method resolves this value. Empty when not applicable.</param>
    procedure AddParam(ParamName: Text; Required: Boolean; DataType: Text; Description: Text; ResolveVia: Text)
    begin
        TrackOptionalParamSemantics(ParamName, Required);

        ParamCount += 1;
        if ParamCount = 1 then begin
            ParamsBuilder.AppendLine('| Parameter | Required | Type | Description | Resolve via |');
            ParamsBuilder.AppendLine('|---|---|---|---|---|');
        end;
        ParamsBuilder.Append('| `');
        ParamsBuilder.Append(ParamName);
        ParamsBuilder.Append('` | ');
        if Required then
            ParamsBuilder.Append('**Yes**')
        else
            ParamsBuilder.Append('No');
        ParamsBuilder.Append(' | ');
        ParamsBuilder.Append(DataType);
        ParamsBuilder.Append(' | ');
        ParamsBuilder.Append(Description);
        ParamsBuilder.Append(' | ');
        if ResolveVia <> '' then begin
            ParamsBuilder.Append('`');
            ParamsBuilder.Append(ResolveVia);
            ParamsBuilder.Append('`');
        end else
            ParamsBuilder.Append('—');
        ParamsBuilder.AppendLine(' |');
    end;

    /// <summary>
    /// Sets the JSON request example shown in the Request section.
    /// </summary>
    procedure SetRequestExample(Example: Text)
    begin
        RequestExampleVar := Example;
    end;

    /// <summary>
    /// Sets the one-line description of what <c>data</c> contains in a successful response.
    /// </summary>
    procedure SetResponseNote(Note: Text)
    begin
        ResponseNoteVar := Note;
    end;

    /// <summary>
    /// Sets the Preconditions section content (Markdown). Use for steps that MUST happen before calling.
    /// </summary>
    procedure SetPreconditions(Preconditions: Text)
    begin
        PreconditionsVar := Preconditions;
    end;

    /// <summary>
    /// Overrides the auto-generated After Success section. When not set, the builder
    /// derives it from the entity/action (integration tracking guidance).
    /// </summary>
    procedure SetAfterSuccess(AfterSuccess: Text)
    begin
        AfterSuccessVar := AfterSuccess;
    end;

    /// <summary>
    /// Adds one row to the Common Errors table.
    /// </summary>
    /// <param name="HttpCode">The HTTP status code Clockify returns.</param>
    /// <param name="ErrorMsg">The error message or condition.</param>
    /// <param name="Resolution">What the caller should do to resolve it.</param>
    procedure AddError(HttpCode: Integer; ErrorMsg: Text; Resolution: Text)
    begin
        ErrorCount += 1;
        if ErrorCount = 1 then begin
            ErrorsBuilder.AppendLine('| HTTP | Error | Resolution |');
            ErrorsBuilder.AppendLine('|---|---|---|');
        end;
        ErrorsBuilder.Append('| ');
        ErrorsBuilder.Append(Format(HttpCode));
        ErrorsBuilder.Append(' | ');
        ErrorsBuilder.Append(ErrorMsg);
        ErrorsBuilder.Append(' | ');
        ErrorsBuilder.Append(Resolution);
        ErrorsBuilder.AppendLine(' |');
    end;

    /// <summary>
    /// Sets the Notes section content (Markdown). Use for Clockify quirks, field coercion, etc.
    /// </summary>
    procedure SetNotes(Notes: Text)
    begin
        NotesVar := Notes;
    end;

    /// <summary>
    /// Sets the Related Operations section (Markdown). Shows workflow context:
    /// what to call before/after, sibling operations on the same entity.
    /// </summary>
    procedure SetRelated(Related: Text)
    begin
        RelatedVar := Related;
    end;

    /// <summary>
    /// Renders the final Markdown document from all accumulated builder state.
    /// </summary>
    /// <returns>The complete AI-optimised help document.</returns>
    procedure Render(): Text
    var
        Builder: TextBuilder;
        Entity: Text;
        Action: Text;
    begin
        ParseMessageType(TitleVar, Entity, Action);

        Builder.AppendLine('# ' + TitleVar);
        Builder.AppendLine('');
        Builder.AppendLine(DescriptionVar);
        Builder.AppendLine('');

        // Metadata
        Builder.AppendLine('## Metadata');
        Builder.AppendLine('- **Direction:** Outbound');
        Builder.AppendLine('- **Content-Type:** text/json');
        Builder.AppendLine('- **Clockify API:** `' + HttpMethodVar + ' ' + ApiPathVar + '`');
        if IsMappableEntity(Entity) then
            Builder.AppendLine('- **Tracks in:** Clockify Integration table (`Clockify Type` = `' + LowerCaseFirst(Entity) + '`)');
        Builder.AppendLine('');

        // Parameters
        if ParamCount > 0 then begin
            Builder.AppendLine('## Parameters');
            Builder.AppendLine('');
            Builder.Append(ParamsBuilder.ToText());
            Builder.AppendLine('');
            Builder.AppendLine('`workspaceId` may be omitted when Default Workspace ID is configured on Cloud Events Setup.');
            Builder.AppendLine('');
        end;

        // Request example
        Builder.AppendLine('## Request example');
        Builder.AppendLine('```json');
        Builder.AppendLine(RequestExampleVar);
        Builder.AppendLine('```');
        Builder.AppendLine('');

        // Response
        Builder.AppendLine('## Response');
        Builder.AppendLine('Success:');
        Builder.AppendLine('```json');
        Builder.AppendLine('{ "status": "Success", "statusCode": 200, "data": ... }');
        Builder.AppendLine('```');
        Builder.AppendLine('`data` contains ' + ResponseNoteVar + '.');
        Builder.AppendLine('');
        Builder.AppendLine('Failure:');
        Builder.AppendLine('```json');
        Builder.AppendLine('{ "status": "Error", "statusCode": <N>, "error": "<Clockify error message>" }');
        Builder.AppendLine('```');
        Builder.AppendLine('');

        // Preconditions
        if PreconditionsVar <> '' then begin
            Builder.AppendLine('## Preconditions');
            Builder.AppendLine(PreconditionsVar);
            Builder.AppendLine('');
        end;

        // Integration tracking
        Builder.AppendLine('## Integration tracking');
        if AfterSuccessVar <> '' then
            Builder.AppendLine(AfterSuccessVar)
        else
            Builder.AppendLine(GetIntegrationNote(TitleVar));
        Builder.AppendLine('');

        // Common errors
        if ErrorCount > 0 then begin
            Builder.AppendLine('## Common errors');
            Builder.AppendLine('');
            Builder.Append(ErrorsBuilder.ToText());
            Builder.AppendLine('');
        end;

        // Notes
        if NotesVar <> '' then begin
            Builder.AppendLine('## Notes');
            Builder.AppendLine(NotesVar);
            Builder.AppendLine('');
        end;

        // Related operations
        if RelatedVar <> '' then begin
            Builder.AppendLine('## Related operations');
            Builder.AppendLine(RelatedVar);
            Builder.AppendLine('');
        end;

        AppendOptionalParameterGuidanceSection(Builder, Entity, Action);

        // Footer
        Builder.AppendLine('---');
        Builder.AppendLine('Full integration-table reference and entity model: request help for `Help.Clockify.Get`.');

        exit(Builder.ToText());
    end;

    /// <summary>
    /// Returns the per-message-type guidance on using the Clockify Integration table,
    /// derived from the message type name (entity + action).
    /// </summary>
    local procedure GetIntegrationNote(MessageType: Text): Text
    var
        Entity: Text;
        Action: Text;
        ClockifyType: Text;
        NotTrackedTok: Label 'This message type is not tracked in the Clockify Integration table.', Locked = true;
        CreateNoteTok: Label 'Record the link: call `Data.Records.Set` on `Clockify Integration` with `BC Table No.`, `BC SystemId`, `BC Code` (the BC source record), `Clockify Type` = `%1`, `Clockify Id` = the `id` from `data` in the response, `Clockify Workspace Id` = the workspace used, `Clockify Name` = display name. Set `Reversed` = `false`.', Comment = '%1 = clockify type', Locked = true;
        UpdateNoteTok: Label 'If this changes which Business Central record the %1 maps to, update the matching `Clockify Integration` row (find via `Data.Records.Get` filter `Clockify Type` = `%1`, `Clockify Id` = the ID, `Reversed` = `false`). Update `BC SystemId`, `BC Code`, and `Clockify Name` with `Data.Records.Set`.', Comment = '%1 = clockify type', Locked = true;
        DeleteNoteTok: Label 'Mark the integration link as broken: find the `Clockify Integration` row (filter `Clockify Type` = `%1`, `Clockify Id` = the deleted ID, `Reversed` = `false`) and set `Reversed` = `true` with `Data.Records.Set`. Do NOT delete the row. The retention policy purges reversed rows ~1 month later.', Comment = '%1 = clockify type', Locked = true;
        ResolveNoteTok: Label 'Resolve existing links first: call `Data.Records.Get` on `Clockify Integration` with filter `Clockify Type` = `%1`, `Reversed` = `false`. The `Clockify Id` field gives you the ID to pass to write operations.', Comment = '%1 = clockify type', Locked = true;
    begin
        ParseMessageType(MessageType, Entity, Action);
        ClockifyType := LowerCaseFirst(Entity);

        if not IsMappableEntity(Entity) then
            exit(NotTrackedTok);

        case Action of
            'Create':
                exit(StrSubstNo(CreateNoteTok, ClockifyType));
            'Update':
                exit(StrSubstNo(UpdateNoteTok, ClockifyType));
            'Delete':
                exit(StrSubstNo(DeleteNoteTok, ClockifyType));
            else
                exit(StrSubstNo(ResolveNoteTok, ClockifyType));
        end;
    end;

    local procedure ParseMessageType(MessageType: Text; var Entity: Text; var Action: Text)
    var
        Parts: List of [Text];
    begin
        Parts := MessageType.Split('.');
        if Parts.Count() >= 2 then
            Entity := Parts.Get(2);
        if Parts.Count() >= 3 then
            Action := Parts.Get(3);
    end;

    local procedure IsMappableEntity(Entity: Text): Boolean
    begin
        exit(Entity in ['Client', 'Project', 'Task', 'Tag', 'TimeEntry', 'User']);
    end;

    local procedure LowerCaseFirst(Value: Text): Text
    begin
        if Value = '' then
            exit('');
        exit(LowerCase(CopyStr(Value, 1, 1)) + CopyStr(Value, 2));
    end;

    local procedure TrackOptionalParamSemantics(ParamName: Text; Required: Boolean)
    begin
        if Required then
            exit;

        HasOptionalParams := true;

        if IsQueryParam(ParamName) then begin
            HasOptionalQueryParams := true;
            if (ParamName = 'query.page-size') or (ParamName = 'query.page') then
                HasQueryPagingParams := true;
            if ParamName = 'query.in-progress' then
                HasInProgressQueryParam := true;
        end;

        if IsBodyParam(ParamName) then begin
            HasOptionalBodyParams := true;
            if ParamName = 'body.end' then
                HasBodyEndParam := true;
        end;
    end;

    local procedure AppendOptionalParameterGuidanceSection(var Builder: TextBuilder; Entity: Text; Action: Text)
    begin
        if not HasOptionalParams then
            exit;

        Builder.AppendLine('## Agent guidance — optional parameter effects');
        Builder.AppendLine('');
        Builder.AppendLine('- Any parameter marked **Required = No** may be omitted.');

        if HasOptionalQueryParams then begin
            Builder.AppendLine('- `query.*` parameters only shape the returned `data` set (filtering/paging). They never mutate Clockify state.');
            Builder.AppendLine('- Omitting query filters returns a broader result set than filtered calls.');
        end;

        if HasQueryPagingParams then
            Builder.AppendLine('- `query.page-size` and `query.page` only change paging windows; they do not change underlying records.');

        if HasInProgressQueryParam then
            Builder.AppendLine('- `query.in-progress = true` returns running timers (`end` = null). `query.in-progress = false` returns finished entries (`end` has a value).');

        if HasOptionalBodyParams then
            case Action of
                'Create':
                    Builder.AppendLine('- Optional `body.*` fields omitted from the request are not sent to Clockify; Clockify applies endpoint defaults.');
                'Update':
                    Builder.AppendLine('- Optional `body.*` fields omitted from the request are not sent to Clockify; existing Clockify values typically remain unchanged.');
                else
                    Builder.AppendLine('- Optional `body.*` fields omitted from the request are not sent to Clockify.');
            end;

        if (Entity = 'TimeEntry') and HasBodyEndParam and ((Action = 'Create') or (Action = 'Update')) then
            Builder.AppendLine('- A time entry without `end` is in-progress (running timer). Stop the timer (set `end`) before syncing to BC Job Journal.');

        if (Entity = 'TimeEntry') and (Action = 'Sync') then
            Builder.AppendLine('- In-progress entries (`end` missing/null) are rejected by design and never written to BC Job Journal.');

        Builder.AppendLine('');
    end;

    local procedure IsQueryParam(ParamName: Text): Boolean
    begin
        exit(CopyStr(ParamName, 1, 6) = 'query.');
    end;

    local procedure IsBodyParam(ParamName: Text): Boolean
    begin
        exit(CopyStr(ParamName, 1, 5) = 'body.');
    end;
}
