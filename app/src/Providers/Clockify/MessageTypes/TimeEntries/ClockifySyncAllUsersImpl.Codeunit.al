namespace Origo.Bifrost.Timesheets.Providers.Clockify;

using Origo.Bifrost;

/// <summary>
/// Implementation of the <c>Timesheets.SyncAllUsersFromClockify</c> message type. Iterates every
/// mapped Clockify user (USER integration rows) and syncs each user's finished entries in a
/// date range — restoring the legacy per-user auto-discovery. The <c>target</c> parameter
/// selects the destination: <c>timesheet</c> (default) writes BC Time Sheets;
/// <c>journal</c> writes Job Journal lines.
/// </summary>
codeunit 10036846 "Clockify SyncAllUsers Impl ori" implements "Msg Interface ori"
{
    Access = Internal;

    var
        MissingJournalErr: Label 'target=journal requires a Job Journal. Set the Clockify Job Journal Template and Batch on Clockify Setup, or pass ''journalTemplate'' and ''journalBatch''.', Locked = true;

    internal procedure IsEnabled(): Boolean
    var
        ClockifyIntegration: Record "Clockify Integration ori";
        SecretMgt: Codeunit "Clockify Secret Mgt ori";
    begin
        if not ClockifyIntegration.WritePermission() then
            exit(false);
        exit(SecretMgt.HasCompanyApiKey());
    end;

    internal procedure GetFilterTableNo(): Integer
    begin
        exit(0);
    end;

    internal procedure GetDescription(): Text[250]
    begin
        exit('Syncs finished Clockify time entries in a date range for every mapped user, to time sheets (default) or the Job Journal.');
    end;

    internal procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit(Enum::"Msg Direction ori"::Inbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "Message Argument ori")
    var
        Help: Codeunit "Clockify TimeSheet Help ori";
    begin
        Argument.SetResponseMarkdown(Help.GetHelp(Enum::"Message Type ori"::"Timesheets.SyncAllUsersFromClockify", GetDescription()));
    end;

    internal procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    var
        Integration: Record "Clockify Integration ori";
        RequestMgt: Codeunit "Clockify Request Mgt ori";
        SetupMgt: Codeunit "Clockify Setup Mgt ori";
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
        UsersArray: JsonArray;
        Counts: Dictionary of [Text, Integer];
        WorkspaceId: Text;
        StartText: Text;
        EndText: Text;
        Target: Text;
        JournalTemplate: Code[10];
        JournalBatch: Code[10];
        JsonToken: JsonToken;
    begin
        Argument.AssertVersion1();
        RequestJson := Argument.GetRequestJson();

        if not RequestMgt.ResolveWorkspaceId(Argument, RequestJson, WorkspaceId) then
            exit;
        if not RequestMgt.RequireParam(Argument, RequestJson, 'start', StartText) then
            exit;
        if not RequestMgt.RequireParam(Argument, RequestJson, 'end', EndText) then
            exit;

        Target := LowerCase(RequestMgt.GetText(RequestJson, 'target'));
        if Target = '' then
            Target := 'timesheet';

        if Target = 'journal' then begin
            SetupMgt.TryGetJobJournal(JournalTemplate, JournalBatch);
            if RequestJson.Get('journalTemplate', JsonToken) then
                if JsonToken.IsValue() then
                    JournalTemplate := CopyStr(JsonToken.AsValue().AsText(), 1, 10);
            if RequestJson.Get('journalBatch', JsonToken) then
                if JsonToken.IsValue() then
                    JournalBatch := CopyStr(JsonToken.AsValue().AsText(), 1, 10);
            if (JournalTemplate = '') or (JournalBatch = '') then begin
                Argument.RespondWithError(MissingJournalErr);
                exit;
            end;
        end;

        // Read-only driver cursor: the sync writes TIME_ENTRY rows, never these USER rows,
        // so it must not hold update locks on them for the whole run.
        Integration.ReadIsolation := IsolationLevel::ReadCommitted;
        Integration.SetCurrentKey("Clockify Type", "Clockify Id", "Reversed");
        Integration.SetRange("Clockify Type", 'USER');
        Integration.SetRange("Reversed", false);
        Integration.SetLoadFields("Clockify Id");
        if Integration.FindSet() then
            repeat
                SyncOneUser(WorkspaceId, Integration."Clockify Id", StartText, EndText, Target, JournalTemplate, JournalBatch, UsersArray, Counts);
            until Integration.Next() = 0;

        ResponseJson.Add('target', Target);
        ResponseJson.Add('users', UsersArray.Count());
        ResponseJson.Add('created', GetCount(Counts, 'Created'));
        ResponseJson.Add('skipped', GetCount(Counts, 'Skipped'));
        ResponseJson.Add('updated', GetCount(Counts, 'Updated'));
        ResponseJson.Add('errors', GetCount(Counts, 'Error'));
        ResponseJson.Add('userResults', UsersArray);
        Argument.SetResponseJson(ResponseJson);
    end;

    local procedure SyncOneUser(WorkspaceId: Text; UserId: Text; StartText: Text; EndText: Text; Target: Text; JournalTemplate: Code[10]; JournalBatch: Code[10]; var UsersArray: JsonArray; var Counts: Dictionary of [Text, Integer])
    var
        Fetch: Codeunit "Clockify TimeEntry Fetch ori";
        Entries: JsonArray;
        UserResult: JsonObject;
        FetchError: Text;
        Created: Integer;
        Skipped: Integer;
        Updated: Integer;
        Errors: Integer;
    begin
        Clear(UserResult);
        UserResult.Add('userId', UserId);
        if not Fetch.TryFetchUserEntries(WorkspaceId, UserId, StartText, EndText, Entries, FetchError) then begin
            IncrementCount(Counts, 'Error');
            UserResult.Add('error', FetchError);
            UsersArray.Add(UserResult);
            exit;
        end;

        SyncUserEntries(WorkspaceId, UserId, Entries, Target, JournalTemplate, JournalBatch, Counts, Created, Skipped, Updated, Errors);
        UserResult.Add('processed', Entries.Count());
        UserResult.Add('created', Created);
        UserResult.Add('skipped', Skipped);
        UserResult.Add('updated', Updated);
        UserResult.Add('errors', Errors);
        UsersArray.Add(UserResult);
    end;

    local procedure SyncUserEntries(WorkspaceId: Text; UserId: Text; Entries: JsonArray; Target: Text; JournalTemplate: Code[10]; JournalBatch: Code[10]; var Counts: Dictionary of [Text, Integer]; var Created: Integer; var Skipped: Integer; var Updated: Integer; var Errors: Integer)
    var
        TimeSheetSync: Codeunit "Clockify TimeSheet Sync ori";
        JournalSync: Codeunit "Clockify Time Entry Sync ori";
        ParseHelper: Codeunit "Clockify TimeEntry Parse ori";
        EntryToken: JsonToken;
        EntryObject: JsonObject;
        EntryId: Text;
        ProjectId: Text;
        TaskId: Text;
        Description: Text;
        EntryStart: Text;
        EntryEnd: Text;
        Billable: Boolean;
        Hours: Decimal;
        PostingDate: Date;
        TagIds: List of [Text];
        SyncResult: Enum "Clockify Sync Result ori";
        ResultMessage: Text;
    begin
        foreach EntryToken in Entries do begin
            EntryObject := EntryToken.AsObject();
            EntryId := ParseHelper.GetText(EntryObject, 'id');
            ProjectId := ParseHelper.GetText(EntryObject, 'projectId');
            TaskId := ParseHelper.GetText(EntryObject, 'taskId');
            Description := ParseHelper.GetText(EntryObject, 'description');
            GetInterval(EntryObject, EntryStart, EntryEnd);
            Billable := ParseHelper.GetBoolean(EntryObject, 'billable', true);
            ParseHelper.GetTagIds(EntryObject, TagIds);

            Hours := ParseHelper.CalculateHours(EntryStart, EntryEnd);
            PostingDate := ParseHelper.ParseDate(EntryStart);

            if (EntryEnd = '') or (Hours = 0) or (PostingDate = 0D) then
                SyncResult := SyncResult::Error
            else
                if Target = 'journal' then
                    SyncResult := JournalSync.SyncTimeEntry(
                        JournalTemplate, JournalBatch,
                        CopyStr(EntryId, 1, 50), CopyStr(WorkspaceId, 1, 50), CopyStr(UserId, 1, 50),
                        CopyStr(ProjectId, 1, 50), CopyStr(TaskId, 1, 50),
                        Description, PostingDate, Hours, Billable, TagIds, ResultMessage)
                else
                    SyncResult := TimeSheetSync.SyncTimeEntryToTimeSheet(
                        CopyStr(EntryId, 1, 50), CopyStr(WorkspaceId, 1, 50), CopyStr(UserId, 1, 50),
                        CopyStr(ProjectId, 1, 50), CopyStr(TaskId, 1, 50),
                        Description, PostingDate, Hours, Billable, TagIds, ResultMessage);

            IncrementCount(Counts, ParseHelper.SyncResultName(SyncResult));
            case SyncResult of
                SyncResult::Created:
                    Created += 1;
                SyncResult::Skipped:
                    Skipped += 1;
                SyncResult::Updated,
                SyncResult::Corrected:
                    Updated += 1;
                SyncResult::Error:
                    Errors += 1;
            end;
        end;
    end;

    local procedure GetInterval(EntryObject: JsonObject; var StartText: Text; var EndText: Text)
    var
        ParseHelper: Codeunit "Clockify TimeEntry Parse ori";
        Token: JsonToken;
    begin
        StartText := '';
        EndText := '';
        if not EntryObject.Get('timeInterval', Token) then
            exit;
        if not Token.IsObject() then
            exit;
        StartText := ParseHelper.GetText(Token.AsObject(), 'start');
        EndText := ParseHelper.GetText(Token.AsObject(), 'end');
    end;

    local procedure IncrementCount(var Counts: Dictionary of [Text, Integer]; ResultKey: Text)
    var
        Current: Integer;
    begin
        if Counts.Get(ResultKey, Current) then
            Counts.Set(ResultKey, Current + 1)
        else
            Counts.Add(ResultKey, 1);
    end;

    local procedure GetCount(Counts: Dictionary of [Text, Integer]; ResultKey: Text): Integer
    var
        Current: Integer;
    begin
        if Counts.Get(ResultKey, Current) then
            exit(Current);
        exit(0);
    end;
}
