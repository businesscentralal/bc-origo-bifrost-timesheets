namespace Origo.Bifrost.Timesheets.Test;

using Origo.Bifrost;
using System.TestLibraries.Utilities;

/// <summary>
/// Help text and direction fixes for the Clockify message types (issue #32, found in the
/// 29.0.0.32 verify). The per-type chapters live in the Clockify Contract Parts codeunit, so
/// the tests assert on the contract chapters and on GetMessageDirection; the overview
/// assertions run Help.Clockify.Get through the public dispatcher with the mock API client
/// enabled. The direction convention is platform-wide: Inbound for write and mutating types,
/// Outbound for read types, regardless of which system is called.
/// </summary>
codeunit 95612 "Clockify Help Fixes Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    [Test]
    procedure ClockifyWrites_DeclareInbound()
    begin
        // [SCENARIO] The fifteen Clockify Create/Update/Delete types mutate Clockify data,
        // so GetMessageDirection must say Inbound (platform convention: mutate = Inbound,
        // read = Outbound), not Outbound.
        AssertDirection("Message Type ori"::"Clockify.Client.Create", "Msg Direction ori"::Inbound);
        AssertDirection("Message Type ori"::"Clockify.Client.Update", "Msg Direction ori"::Inbound);
        AssertDirection("Message Type ori"::"Clockify.Client.Delete", "Msg Direction ori"::Inbound);
        AssertDirection("Message Type ori"::"Clockify.Project.Create", "Msg Direction ori"::Inbound);
        AssertDirection("Message Type ori"::"Clockify.Project.Update", "Msg Direction ori"::Inbound);
        AssertDirection("Message Type ori"::"Clockify.Project.Delete", "Msg Direction ori"::Inbound);
        AssertDirection("Message Type ori"::"Clockify.Task.Create", "Msg Direction ori"::Inbound);
        AssertDirection("Message Type ori"::"Clockify.Task.Update", "Msg Direction ori"::Inbound);
        AssertDirection("Message Type ori"::"Clockify.Task.Delete", "Msg Direction ori"::Inbound);
        AssertDirection("Message Type ori"::"Clockify.Tag.Create", "Msg Direction ori"::Inbound);
        AssertDirection("Message Type ori"::"Clockify.Tag.Update", "Msg Direction ori"::Inbound);
        AssertDirection("Message Type ori"::"Clockify.Tag.Delete", "Msg Direction ori"::Inbound);
        AssertDirection("Message Type ori"::"Clockify.TimeEntry.Create", "Msg Direction ori"::Inbound);
        AssertDirection("Message Type ori"::"Clockify.TimeEntry.Update", "Msg Direction ori"::Inbound);
        AssertDirection("Message Type ori"::"Clockify.TimeEntry.Delete", "Msg Direction ori"::Inbound);
    end;

    [Test]
    procedure BusinessCentralSideTypes_StayInbound()
    begin
        // [SCENARIO] Regression guard: the eleven BC-side types were already Inbound and must
        // stay Inbound (the direction fix must not touch them).
        AssertDirection("Message Type ori"::"Clockify.TimeEntry.Sync", "Msg Direction ori"::Inbound);
        AssertDirection("Message Type ori"::"Clockify.TimeEntry.SyncRange", "Msg Direction ori"::Inbound);
        AssertDirection("Message Type ori"::"Clockify.TimeEntry.SyncToTimeSheet", "Msg Direction ori"::Inbound);
        AssertDirection("Message Type ori"::"Clockify.TimeEntry.SyncRangeToTimeSheet", "Msg Direction ori"::Inbound);
        AssertDirection("Message Type ori"::"Clockify.TimeEntry.SyncAllUsers", "Msg Direction ori"::Inbound);
        AssertDirection("Message Type ori"::"Clockify.TimeSheet.Create", "Msg Direction ori"::Inbound);
        AssertDirection("Message Type ori"::"Clockify.TimeSheet.Approve", "Msg Direction ori"::Inbound);
        AssertDirection("Message Type ori"::"Clockify.TimeSheet.Reject", "Msg Direction ori"::Inbound);
        AssertDirection("Message Type ori"::"Clockify.TimeSheet.Reopen", "Msg Direction ori"::Inbound);
        AssertDirection("Message Type ori"::"Clockify.TimeSheet.Post", "Msg Direction ori"::Inbound);
        AssertDirection("Message Type ori"::"Clockify.TimeSheet.Archive", "Msg Direction ori"::Inbound);
    end;

    [Test]
    procedure ReadTypes_StayOutbound()
    begin
        // [SCENARIO] List, Get and help types are reads and stay Outbound.
        AssertDirection("Message Type ori"::"Clockify.Workspace.List", "Msg Direction ori"::Outbound);
        AssertDirection("Message Type ori"::"Clockify.Client.Get", "Msg Direction ori"::Outbound);
        AssertDirection("Message Type ori"::"Clockify.Client.List", "Msg Direction ori"::Outbound);
        AssertDirection("Message Type ori"::"Clockify.Project.Get", "Msg Direction ori"::Outbound);
        AssertDirection("Message Type ori"::"Clockify.Project.List", "Msg Direction ori"::Outbound);
        AssertDirection("Message Type ori"::"Clockify.Task.List", "Msg Direction ori"::Outbound);
        AssertDirection("Message Type ori"::"Clockify.Tag.List", "Msg Direction ori"::Outbound);
        AssertDirection("Message Type ori"::"Clockify.TimeEntry.List", "Msg Direction ori"::Outbound);
        AssertDirection("Message Type ori"::"Clockify.TimeEntry.Get", "Msg Direction ori"::Outbound);
        AssertDirection("Message Type ori"::"Clockify.User.GetCurrent", "Msg Direction ori"::Outbound);
        AssertDirection("Message Type ori"::"Clockify.Currency.List", "Msg Direction ori"::Outbound);
        AssertDirection("Message Type ori"::"Clockify.UserGroup.List", "Msg Direction ori"::Outbound);
        AssertDirection("Message Type ori"::"Clockify.CustomField.List", "Msg Direction ori"::Outbound);
        AssertDirection("Message Type ori"::"Help.Clockify.Get", "Msg Direction ori"::Outbound);
    end;

    [Test]
    procedure SyncParameters_MatchOptionalUsageInCode()
    var
        Parameters: JsonArray;
    begin
        // [GIVEN] Clockify.TimeEntry.Sync help, where the Impl codeunit reads start/end via
        // GetOptionalParam (only userId, entryId and projectId go through RequireParam).
        AssertParameters("Message Type ori"::"Clockify.TimeEntry.Sync", Parameters);
        AssertParamRequired(Parameters, 'userId', true, 'Sync userId');
        AssertParamRequired(Parameters, 'entryId', true, 'Sync entryId');
        AssertParamRequired(Parameters, 'projectId', true, 'Sync projectId');
        AssertParamRequired(Parameters, 'taskId', false, 'Sync taskId');
        AssertParamRequired(Parameters, 'start', false, 'Sync start');
        AssertParamRequired(Parameters, 'end', false, 'Sync end');
    end;

    [Test]
    procedure SyncToTimeSheetParameters_MatchOptionalUsageInCode()
    var
        Parameters: JsonArray;
    begin
        // [GIVEN] Clockify.TimeEntry.SyncToTimeSheet help, where the Impl codeunit reads
        // taskId/start/end via ParseHelper.GetText (only userId, entryId and projectId are
        // required).
        AssertParameters("Message Type ori"::"Clockify.TimeEntry.SyncToTimeSheet", Parameters);
        AssertParamRequired(Parameters, 'userId', true, 'SyncToTimeSheet userId');
        AssertParamRequired(Parameters, 'entryId', true, 'SyncToTimeSheet entryId');
        AssertParamRequired(Parameters, 'projectId', true, 'SyncToTimeSheet projectId');
        AssertParamRequired(Parameters, 'taskId', false, 'SyncToTimeSheet taskId');
        AssertParamRequired(Parameters, 'start', false, 'SyncToTimeSheet start');
        AssertParamRequired(Parameters, 'end', false, 'SyncToTimeSheet end');
    end;

    [Test]
    procedure WrongWorkspace_DocumentedAs400Not404()
    var
        Errors: JsonArray;
    begin
        // [GIVEN] help for the single-ID write and read types. Live verify (27.09) shows
        // Clockify answering a wrong-workspace ID with HTTP 400 "<entity> doesn't belong to
        // Workspace", not 404.
        AssertErrors("Message Type ori"::"Clockify.Client.Get", Errors);
        AssertHasErrorText(Errors, 'doesn''t belong to Workspace', 'Client.Get 400');
        AssertErrors("Message Type ori"::"Clockify.Project.Get", Errors);
        AssertHasErrorText(Errors, 'doesn''t belong to Workspace', 'Project.Get 400');
        AssertErrors("Message Type ori"::"Clockify.Task.List", Errors);
        AssertHasErrorText(Errors, 'doesn''t belong to Workspace', 'Task.List 400');
        AssertErrors("Message Type ori"::"Clockify.TimeEntry.List", Errors);
        AssertHasErrorText(Errors, 'doesn''t belong to Workspace', 'TimeEntry.List 400');
        AssertErrors("Message Type ori"::"Clockify.Client.Delete", Errors);
        AssertHasErrorText(Errors, 'doesn''t belong to Workspace', 'Client.Delete 400');
    end;

    [Test]
    procedure CustomFieldList_Documents403ForFreePlan()
    var
        Errors: JsonArray;
    begin
        // [GIVEN] Clockify.CustomField.List help. Live verify (27.09): a FREE plan workspace
        // answers the list call with 403 Access Denied (Clockify code 501).
        AssertErrors("Message Type ori"::"Clockify.CustomField.List", Errors);
        AssertHasErrorText(Errors, '403', 'CustomField.List 403 status');
        AssertHasErrorText(Errors, 'paid Clockify plan', 'CustomField.List paid plan');
    end;

    [Test]
    procedure Overview_DefinesDirectionByMutation()
    var
        TempArgument: Record "Message Argument ori";
        MsgInterface: Interface "Msg Interface ori";
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
        ResultToken: JsonToken;
        MarkdownToken: JsonToken;
        Markdown: Text;
    begin
        // [GIVEN] Help.Clockify.Get run through the public dispatcher (mock API, key set).
        UseMockApi();
        TempArgument.Init();
        TempArgument."Type" := "Message Type ori"::"Help.Clockify.Get";
        TempArgument.Insert();
        RequestJson.Add('workspaceId', 'test-workspace');
        TempArgument.SetRequestJson(RequestJson);
        MsgInterface := TempArgument.GetMessageTypeInterface();
        MsgInterface.ExecuteBifrostTask(TempArgument);
        TempArgument.GetResponseJson(ResponseJson);
        Assert.IsTrue(ResponseJson.Get('result', ResultToken), 'overview result');
        Assert.IsTrue(ResultToken.AsObject().Get('markdown', MarkdownToken), 'overview markdown');
        Markdown := MarkdownToken.AsValue().AsText();

        // [THEN] the direction paragraph defines Outbound as read and Inbound as
        // write/mutating, lists the eleven BC-side types, and says the sync types maintain
        // integration rows.
        Assert.IsTrue(Markdown.Contains('inbound** when they write or mutate data'), 'direction definition');
        Assert.IsTrue(Markdown.Contains('Clockify.TimeEntry.SyncToTimeSheet'), 'SyncToTimeSheet listed');
        Assert.IsTrue(Markdown.Contains('the six `Clockify.TimeSheet.Create/Approve/Reject/Reopen/Post/Archive` operations'), 'six time sheet types listed');
        Assert.IsTrue(Markdown.Contains('create, update or reverse the `TIME_ENTRY` rows they sync themselves'), 'sync types maintain rows');
        Assert.IsFalse(Markdown.Contains('never touch it'), 'stale "never touch it" sentence gone');
    end;

    local procedure UseMockApi()
    var
        ClockifySetup: Record "Clockify Setup ori";
        MockState: Codeunit "Clockify Mock State";
        SecretMgt: Codeunit "Clockify Secret Mgt ori";
    begin
        MockState.Reset();
        if not ClockifySetup.Get() then begin
            ClockifySetup.Init();
            ClockifySetup.Insert();
        end;
        ClockifySetup."API Version" := ClockifySetup."API Version"::Mock;
        ClockifySetup.Modify();
        SecretMgt.ClearCompanyApiKey();
        SecretMgt.SetCompanyApiKey('test-company-api-key');
    end;

    local procedure AssertDirection(MessageType: Enum "Message Type ori"; Expected: Enum "Msg Direction ori")
    var
        MsgInterface: Interface "Msg Interface ori";
        Name: Text;
    begin
        MsgInterface := MessageType;
        Name := Enum::"Message Type ori".Names().Get(Enum::"Message Type ori".Ordinals().IndexOf(MessageType.AsInteger()));
        Assert.AreEqual(Expected, MsgInterface.GetMessageDirection(), Name + ' direction');
    end;

    local procedure AssertParameters(MessageType: Enum "Message Type ori"; var Parameters: JsonArray)
    var
        Parts: Codeunit "Clockify Contract Parts ori";
    begin
        Assert.IsTrue(Parts.GetParameters(MessageType, Parameters), 'parameters present');
    end;

    local procedure AssertParamRequired(Parameters: JsonArray; Name: Text; Required: Boolean; Label: Text)
    var
        Index: Integer;
        EntryToken: JsonToken;
        Entry: JsonObject;
        NameToken: JsonToken;
        RequiredToken: JsonToken;
    begin
        for Index := 0 to Parameters.Count() - 1 do
            if Parameters.Get(Index, EntryToken) then begin
                Entry := EntryToken.AsObject();
                if Entry.Get('name', NameToken) then
                    if NameToken.AsValue().AsText() = Name then begin
                        Assert.IsTrue(Entry.Get('required', RequiredToken), Label);
                        Assert.AreEqual(Required, RequiredToken.AsValue().AsBoolean(), Label);
                        exit;
                    end;
            end;
        Assert.Fail(Label + ': parameter not found');
    end;

    local procedure AssertErrors(MessageType: Enum "Message Type ori"; var Errors: JsonArray)
    var
        Parts: Codeunit "Clockify Contract Parts ori";
    begin
        Assert.IsTrue(Parts.GetErrors(MessageType, Errors), 'errors present');
    end;

    local procedure AssertHasErrorText(Errors: JsonArray; Substring: Text; Label: Text)
    var
        Index: Integer;
        EntryToken: JsonToken;
        Entry: JsonObject;
        ErrorToken: JsonToken;
    begin
        for Index := 0 to Errors.Count() - 1 do
            if Errors.Get(Index, EntryToken) then begin
                Entry := EntryToken.AsObject();
                if Entry.Get('error', ErrorToken) then
                    if ErrorToken.AsValue().AsText().Contains(Substring) then
                        exit;
            end;
        Assert.Fail(Label + ': no error entry contains ' + Substring);
    end;
}
