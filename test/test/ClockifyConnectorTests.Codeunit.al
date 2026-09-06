namespace Origo.Bifrost.Timesheets.Test;

using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.Resources.Setup;
using Microsoft.Projects.TimeSheet;
using Microsoft.Utilities;
using Origo.Bifrost;
using Origo.Bifrost.Timesheets;
using System.DataAdministration;
using System.TestLibraries.Utilities;

/// <summary>
/// Tests for the Bifrost Timesheets connector that run without network access:
/// message-type registration and metadata, per-type Markdown help, API-key secret
/// storage, the API-version selection that replaced the base-URL field, and the
/// full request/response pipeline driven through a mock <c>Clockify API Client ori</c>.
/// </summary>
codeunit 95601 "Clockify Connector Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryAssert: Codeunit "Library Assert";

    [Test]
    procedure HelpTypeIsOutboundWithNoFilterTable()
    var
        Argument: Record "Message Argument ori";
        MsgInterface: Interface "Msg Interface ori";
    begin
        // [SCENARIO] The Help.Clockify.Get type reports correct metadata.
        Argument."Type" := Argument."Type"::"Help.Clockify.Get";
        MsgInterface := Argument.GetMessageTypeInterface();

        LibraryAssert.AreEqual(Enum::"Msg Direction ori"::Outbound, MsgInterface.GetMessageDirection(), 'Help type should be outbound.');
        LibraryAssert.AreEqual(0, MsgInterface.GetFilterTableNo(), 'Help type should have no filter table.');
        LibraryAssert.AreNotEqual('', MsgInterface.GetDescription(), 'Help type should have a description.');
    end;

    [Test]
    procedure EveryClockifyTypeHasMetadataAndHelp()
    var
        MessageType: Enum "Message Type ori";
        Ordinals: List of [Integer];
        Ordinal: Integer;
    begin
        // [SCENARIO] Every Clockify message type (10036785-10036814) exposes metadata and non-empty help.
        Ordinals := MessageType.Ordinals();
        foreach Ordinal in Ordinals do
            if (Ordinal >= 10036785) and (Ordinal <= 10036814) then
                VerifyTypeMetadataAndHelp(Ordinal);
    end;

    local procedure VerifyTypeMetadataAndHelp(Ordinal: Integer)
    var
        Argument: Record "Message Argument ori";
        MessageType: Enum "Message Type ori";
        MsgInterface: Interface "Msg Interface ori";
        HelpText: Text;
        NotOutboundErr: Label 'Type %1 should be outbound.', Comment = '%1 = message type';
        NoDescriptionErr: Label 'Type %1 should have a description.', Comment = '%1 = message type';
        NoHelpErr: Label 'Type %1 should produce help markdown.', Comment = '%1 = message type';
    begin
        MessageType := Enum::"Message Type ori".FromInteger(Ordinal);
        Argument.Init();
        Argument."Type" := MessageType;
        Argument.Insert();
        MsgInterface := Argument.GetMessageTypeInterface();

        LibraryAssert.AreEqual(
            Enum::"Msg Direction ori"::Outbound,
            MsgInterface.GetMessageDirection(),
            StrSubstNo(NotOutboundErr, MessageType));
        LibraryAssert.AreNotEqual('', MsgInterface.GetDescription(), StrSubstNo(NoDescriptionErr, MessageType));

        MsgInterface.GetMessageHelpAsMarkdownDocument(Argument);
        HelpText := Argument.GetResponseText();
        LibraryAssert.AreNotEqual('', HelpText, StrSubstNo(NoHelpErr, MessageType));
    end;

    [Test]
    procedure CompanyApiKeyRoundtrips()
    var
        SecretMgt: Codeunit "Clockify Secret Mgt ori";
        KeyText: Text;
    begin
        // [SCENARIO] A stored company API key is reported as present and can be cleared.
        SecretMgt.ClearCompanyApiKey();
        LibraryAssert.IsFalse(SecretMgt.HasCompanyApiKey(), 'No company key expected initially.');

        KeyText := 'test-company-api-key';
        SecretMgt.SetCompanyApiKey(KeyText);
        LibraryAssert.IsTrue(SecretMgt.HasCompanyApiKey(), 'Company key should be stored.');

        SecretMgt.ClearCompanyApiKey();
        LibraryAssert.IsFalse(SecretMgt.HasCompanyApiKey(), 'Company key should be cleared.');
    end;

    [Test]
    procedure DefaultApiVersionIsVersion1()
    var
        ClockifySetup: Record "Clockify Setup ori";
    begin
        // [SCENARIO] A fresh setup record selects Version 1, which is fixed on the public endpoint.
        Clear(ClockifySetup);
        ClockifySetup.Init();
        LibraryAssert.AreEqual(
            ClockifySetup."API Version"::"Version 1",
            ClockifySetup."API Version",
            'A new setup record should default to the Version 1 Clockify API.');
    end;

    [Test]
    procedure WorkspaceListRoutesGetThroughClient()
    var
        Argument: Record "Message Argument ori";
        MockState: Codeunit "Clockify Mock State";
        ResponseJson: JsonObject;
    begin
        // [GIVEN] The connector is routed to the mock API client
        UseMockApi();
        // [GIVEN] The mock will return a successful workspace array
        MockState.SetNextResponse(true, 200, '[{"id":"WS-1","name":"Acme"}]');

        // [WHEN] The Clockify.Workspace.List task executes
        ExecuteType(Argument, Argument."Type"::"Clockify.Workspace.List");

        // [THEN] The mock received a GET on /workspaces
        LibraryAssert.AreEqual('GET', MockState.GetLastMethod(), 'Workspace list should issue a GET.');
        LibraryAssert.AreEqual('/workspaces', MockState.GetLastResourcePath(), 'Workspace list should call /workspaces.');

        // [THEN] The response envelope reports success and carries the mocked data
        ResponseJson := Argument.GetResponseJson();
        LibraryAssert.AreEqual('Success', ReadText(ResponseJson, 'status'), 'A 2xx response should map to Success.');
        LibraryAssert.AreEqual('200', ReadText(ResponseJson, 'statusCode'), 'Status code should be surfaced.');
        LibraryAssert.IsTrue(HasKey(ResponseJson, 'data'), 'The response should carry a data array.');
    end;

    [Test]
    procedure ErrorResponseIsSurfacedWithStatusCode()
    var
        Argument: Record "Message Argument ori";
        MockState: Codeunit "Clockify Mock State";
        ResponseJson: JsonObject;
    begin
        // [GIVEN] The mock will return a 404 error payload
        UseMockApi();
        MockState.SetNextResponse(false, 404, '{"message":"Workspace not found"}');

        // [WHEN] The Clockify.Workspace.List task executes
        ExecuteType(Argument, Argument."Type"::"Clockify.Workspace.List");

        // [THEN] The envelope reports the error, the status code and the Clockify message
        ResponseJson := Argument.GetResponseJson();
        LibraryAssert.AreEqual('Error', ReadText(ResponseJson, 'status'), 'A non-2xx response should map to Error.');
        LibraryAssert.AreEqual('404', ReadText(ResponseJson, 'statusCode'), 'Status code should be surfaced.');
        LibraryAssert.AreEqual('Workspace not found', ReadText(ResponseJson, 'error'), 'The Clockify error message should be extracted.');
    end;

    [Test]
    procedure ProjectCreatePostsBodyToWorkspace()
    var
        Argument: Record "Message Argument ori";
        MockState: Codeunit "Clockify Mock State";
        RequestJson: JsonObject;
        BodyJson: JsonObject;
    begin
        // [GIVEN] A create-project request with an explicit workspace and body
        UseMockApi();
        MockState.SetNextResponse(true, 201, '{"id":"P-1","name":"Implementation"}');
        BodyJson.Add('name', 'Implementation');
        RequestJson.Add('workspaceId', 'WS-1');
        RequestJson.Add('body', BodyJson);

        // [WHEN] The Clockify.Project.Create task executes
        ExecuteTypeWithRequest(Argument, Argument."Type"::"Clockify.Project.Create", RequestJson);

        // [THEN] The mock received a POST to the workspace's projects path, carrying the body
        LibraryAssert.AreEqual('POST', MockState.GetLastMethod(), 'Project create should issue a POST.');
        LibraryAssert.AreEqual('/workspaces/WS-1/projects', MockState.GetLastResourcePath(), 'Project create should target the workspace projects path.');
        LibraryAssert.IsTrue(MockState.GetLastHasBody(), 'Project create should send a body.');
        LibraryAssert.IsTrue(MockState.GetLastRequestBody().Contains('Implementation'), 'The request body should be forwarded verbatim.');
    end;

    [Test]
    procedure DefaultWorkspaceUsedWhenRequestOmitsIt()
    var
        ClockifySetup: Record "Clockify Setup ori";
        Argument: Record "Message Argument ori";
        MockState: Codeunit "Clockify Mock State";
        RequestJson: JsonObject;
    begin
        // [GIVEN] A default workspace configured on setup, and a request that omits workspaceId
        UseMockApi();
        if not ClockifySetup.Get() then
            ClockifySetup.Insert();
        ClockifySetup."Default Workspace" := 'WS-DEF';
        ClockifySetup.Modify();
        MockState.SetNextResponse(true, 200, '[]');

        // [WHEN] The Clockify.Project.List task executes without a workspaceId
        ExecuteTypeWithRequest(Argument, Argument."Type"::"Clockify.Project.List", RequestJson);

        // [THEN] The default workspace is used in the resource path
        LibraryAssert.AreEqual('/workspaces/WS-DEF/projects', MockState.GetLastResourcePath(), 'The default workspace should fill in for the missing workspaceId.');
    end;

    [Test]
    procedure WorkspaceLookupRequiresApiKey()
    var
        SecretMgt: Codeunit "Clockify Secret Mgt ori";
        WorkspaceMgt: Codeunit "Clockify Workspace Mgt ori";
        WorkspaceId: Text;
        WorkspaceName: Text;
    begin
        // [SCENARIO] The workspace picker refuses to run until the company API key is set.
        UseMockApi();
        SecretMgt.ClearCompanyApiKey();

        // [WHEN] The picker is opened with no API key stored
        asserterror WorkspaceMgt.LookupWorkspace(WorkspaceId, WorkspaceName);

        // [THEN] A guiding error is raised
        LibraryAssert.ExpectedError('Set the company Clockify API key before selecting a workspace.');
    end;

    [Test]
    [HandlerFunctions('WorkspaceLookupModalHandler')]
    procedure WorkspaceLookupReturnsSelection()
    var
        SecretMgt: Codeunit "Clockify Secret Mgt ori";
        WorkspaceMgt: Codeunit "Clockify Workspace Mgt ori";
        MockState: Codeunit "Clockify Mock State";
        KeyText: Text;
        WorkspaceId: Text;
        WorkspaceName: Text;
        Selected: Boolean;
    begin
        // [GIVEN] A company API key and a mocked workspace list
        UseMockApi();
        KeyText := 'test-company-api-key';
        SecretMgt.SetCompanyApiKey(KeyText);
        MockState.SetNextResponse(true, 200, '[{"id":"WS-1","name":"Acme"},{"id":"WS-2","name":"Globex"}]');

        // [WHEN] The picker runs and the handler selects the first workspace
        Selected := WorkspaceMgt.LookupWorkspace(WorkspaceId, WorkspaceName);

        // [THEN] The picker fetched the workspace list and returned the chosen workspace
        LibraryAssert.AreEqual('GET', MockState.GetLastMethod(), 'The picker should GET the workspaces.');
        LibraryAssert.AreEqual('/workspaces', MockState.GetLastResourcePath(), 'The picker should call /workspaces.');
        LibraryAssert.IsTrue(Selected, 'A workspace should have been selected.');
        LibraryAssert.AreEqual('WS-1', WorkspaceId, 'The first workspace ID should be returned.');
        LibraryAssert.AreEqual('Acme', WorkspaceName, 'The first workspace name should be returned.');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,GenericMessageHandler')]
    procedure RegisterCreatesWebhooksForEachTimeEntryEvent()
    var
        ClockifySetup: Record "Clockify Setup ori";
        ClockifyWebhook: Record "Clockify Webhook ori";
        SecretMgt: Codeunit "Clockify Secret Mgt ori";
        WebhookMgt: Codeunit "Clockify Webhook Mgt ori";
        MockState: Codeunit "Clockify Mock State";
        KeyText: Text;
    begin
        // [GIVEN] Mock API, a stored key, a default workspace and a receiver URL
        UseMockApi();
        KeyText := 'test-company-api-key';
        SecretMgt.SetCompanyApiKey(KeyText);
        if not ClockifySetup.Get() then
            ClockifySetup.Insert();
        ClockifySetup."Default Workspace" := 'WS-1';
        ClockifySetup."Webhook Receiver URL" := 'https://site/api/clockify-webhooks?companyId=C1';
        ClockifySetup.Modify();
        ClockifyWebhook.DeleteAll();
        MockState.SetNextResponse(true, 200, '{"id":"WH-1","authToken":"tok-1"}');

        // [WHEN] Webhooks are registered
        WebhookMgt.RegisterTimeEntryWebhooks();

        // [THEN] One webhook per time-entry event was created via POST to the workspace webhooks path
        LibraryAssert.AreEqual('POST', MockState.GetLastMethod(), 'Webhook registration should POST.');
        LibraryAssert.AreEqual('/workspaces/WS-1/webhooks', MockState.GetLastResourcePath(), 'Registration should target the workspace webhooks path.');
        LibraryAssert.IsTrue(MockState.GetLastHasBody(), 'Registration should send a body.');
        LibraryAssert.IsTrue(MockState.GetLastRequestBody().Contains('TIME_ENTRY_DELETED'), 'The last create body should carry its webhookEvent.');
        LibraryAssert.AreEqual(3, ClockifyWebhook.Count(), 'Three time-entry webhooks should be tracked.');
        LibraryAssert.IsTrue(ClockifyWebhook.Get('NEW_TIME_ENTRY'), 'A NEW_TIME_ENTRY webhook row should exist.');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,GenericMessageHandler')]
    procedure RemoveDeletesRegisteredWebhooks()
    var
        ClockifyWebhook: Record "Clockify Webhook ori";
        WebhookMgt: Codeunit "Clockify Webhook Mgt ori";
        MockState: Codeunit "Clockify Mock State";
    begin
        // [GIVEN] Mock API and a tracked webhook row
        UseMockApi();
        ClockifyWebhook.DeleteAll();
        ClockifyWebhook.Init();
        ClockifyWebhook."Event" := 'NEW_TIME_ENTRY';
        ClockifyWebhook."Webhook Id" := 'WH-1';
        ClockifyWebhook."Workspace Id" := 'WS-1';
        ClockifyWebhook.Insert();
        MockState.SetNextResponse(true, 200, '{}');

        // [WHEN] Webhooks are removed
        WebhookMgt.RemoveTimeEntryWebhooks();

        // [THEN] The webhook was deleted in Clockify and the tracking row cleared
        LibraryAssert.AreEqual('DELETE', MockState.GetLastMethod(), 'Removal should issue a DELETE.');
        LibraryAssert.AreEqual('/workspaces/WS-1/webhooks/WH-1', MockState.GetLastResourcePath(), 'Removal should target the webhook resource.');
        LibraryAssert.IsTrue(ClockifyWebhook.IsEmpty(), 'Tracking rows should be cleared after removal.');
    end;

    [Test]
    procedure ReverseTimeEntryWithNoLinkIsSkipped()
    var
        TimeEntrySync: Codeunit "Clockify Time Entry Sync ori";
        SyncResult: Enum "Clockify Sync Result ori";
        ResultMessage: Text;
    begin
        // [SCENARIO] A TIME_ENTRY_DELETED webhook for an entry that was never synced is a safe no-op.
        SyncResult := TimeEntrySync.ReverseTimeEntry('UNKNOWN-ENTRY', ResultMessage);

        // [THEN] It reports Skipped without raising an error
        LibraryAssert.AreEqual(Enum::"Clockify Sync Result ori"::Skipped, SyncResult, 'Reversing an unknown entry should be Skipped.');
    end;

    [Test]
    procedure JobJournalResolvesFromSetup()
    var
        ClockifySetup: Record "Clockify Setup ori";
        SetupMgt: Codeunit "Clockify Setup Mgt ori";
        Template: Code[10];
        Batch: Code[10];
    begin
        // [GIVEN] A fully configured Job Journal target on setup
        if not ClockifySetup.Get() then
            ClockifySetup.Insert();
        ClockifySetup."Job Jnl. Template" := 'JOB';
        ClockifySetup."Job Jnl. Batch" := 'DEFAULT';
        ClockifySetup.Modify();

        // [THEN] The resolver returns the configured values
        LibraryAssert.IsTrue(SetupMgt.TryGetJobJournal(Template, Batch), 'A fully configured journal should resolve.');
        LibraryAssert.AreEqual('JOB', Template, 'Template should come from setup.');
        LibraryAssert.AreEqual('DEFAULT', Batch, 'Batch should come from setup.');

        // [THEN] Clearing the batch makes it unresolved
        ClockifySetup."Job Jnl. Batch" := '';
        ClockifySetup.Modify();
        LibraryAssert.IsFalse(SetupMgt.TryGetJobJournal(Template, Batch), 'A missing batch should not resolve.');
    end;

    [Test]
    procedure TimeEntrySyncErrorsWhenNoJournalConfigured()
    var
        ClockifySetup: Record "Clockify Setup ori";
        Argument: Record "Message Argument ori";
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
    begin
        // [GIVEN] No Job Journal configured on setup and none supplied in the request
        UseMockApi();
        if not ClockifySetup.Get() then
            ClockifySetup.Insert();
        ClockifySetup."Job Jnl. Template" := '';
        ClockifySetup."Job Jnl. Batch" := '';
        ClockifySetup.Modify();
        RequestJson.Add('workspaceId', 'WS-1');
        RequestJson.Add('userId', 'U-1');
        RequestJson.Add('entryId', 'E-1');
        RequestJson.Add('projectId', 'P-1');

        // [WHEN] The Clockify.TimeEntry.Sync task executes
        ExecuteTypeWithRequest(Argument, Argument."Type"::"Clockify.TimeEntry.Sync", RequestJson);

        // [THEN] It reports an error pointing at the missing Job Journal configuration
        ResponseJson := Argument.GetResponseJson();
        LibraryAssert.AreEqual('Error', ReadText(ResponseJson, 'status'), 'Missing journal config should map to Error.');
        LibraryAssert.IsTrue(ReadText(ResponseJson, 'error').Contains('Job Journal'), 'The error should mention the Job Journal configuration.');
    end;

    [Test]
    procedure TimeEntrySyncRejectsInProgressEntries()
    var
        ClockifySetup: Record "Clockify Setup ori";
        Argument: Record "Message Argument ori";
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
    begin
        // [GIVEN] A sync request with no end timestamp (in-progress timer)
        UseMockApi();
        if not ClockifySetup.Get() then
            ClockifySetup.Insert();
        ClockifySetup."Job Jnl. Template" := 'JOB';
        ClockifySetup."Job Jnl. Batch" := 'DEFAULT';
        ClockifySetup.Modify();

        RequestJson.Add('workspaceId', 'WS-1');
        RequestJson.Add('userId', 'U-1');
        RequestJson.Add('entryId', 'E-1');
        RequestJson.Add('projectId', 'P-1');
        RequestJson.Add('start', '2026-06-09T08:00:00Z');

        // [WHEN] The Clockify.TimeEntry.Sync task executes
        ExecuteTypeWithRequest(Argument, Argument."Type"::"Clockify.TimeEntry.Sync", RequestJson);

        // [THEN] The request is rejected and clearly reports the in-progress rule
        ResponseJson := Argument.GetResponseJson();
        LibraryAssert.AreEqual('Error', ReadText(ResponseJson, 'status'), 'In-progress entries should be rejected.');
        LibraryAssert.IsTrue(ReadText(ResponseJson, 'error').Contains('In-progress time entries'), 'The response should explain why the sync was blocked.');
    end;

    [Test]
    procedure WorkTypeResolvesFromTagThenDefault()
    var
        ClockifySetup: Record "Clockify Setup ori";
        Integration: Record "Clockify Integration ori";
        TimeEntrySync: Codeunit "Clockify Time Entry Sync ori";
        TagIds: List of [Text];
    begin
        // [GIVEN] A Clockify tag linked to a Work Type, and a default Work Type on setup
        Integration.DeleteAll();
        Integration.Init();
        Integration."Clockify Type" := 'TAG';
        Integration."Clockify Id" := 'tag-1';
        Integration."BC Code" := 'DESIGN';
        Integration."Reversed" := false;
        Integration.Insert(true);
        if not ClockifySetup.Get() then
            ClockifySetup.Insert();
        ClockifySetup."Default Work Type" := 'GENERAL';
        ClockifySetup.Modify();

        // [THEN] A linked tag resolves to its Work Type
        Clear(TagIds);
        TagIds.Add('tag-1');
        LibraryAssert.AreEqual('DESIGN', Format(TimeEntrySync.ResolveWorkType(TagIds)), 'A linked tag should set the Work Type.');

        // [THEN] An unlinked tag falls back to the setup default
        Clear(TagIds);
        TagIds.Add('tag-unknown');
        LibraryAssert.AreEqual('GENERAL', Format(TimeEntrySync.ResolveWorkType(TagIds)), 'An unlinked tag should fall back to the default Work Type.');

        // [THEN] No tags falls back to the setup default
        Clear(TagIds);
        LibraryAssert.AreEqual('GENERAL', Format(TimeEntrySync.ResolveWorkType(TagIds)), 'No tags should fall back to the default Work Type.');
    end;

    [Test]
    procedure SyncCreatesJobJournalLineWithWorkTypeFromTag()
    var
        JobJournalLine: Record "Job Journal Line";
        TimeEntrySync: Codeunit "Clockify Time Entry Sync ori";
        JobNo: Code[20];
        JobTaskNo: Code[20];
        ResourceNo: Code[20];
        WorkTypeCode: Code[10];
        TemplateName: Code[10];
        BatchName: Code[10];
        TagIds: List of [Text];
        SyncResult: Enum "Clockify Sync Result ori";
        Msg: Text;
    begin
        // [GIVEN] Master data + integration links (PROJECT/TASK/USER/TAG) and a configured journal
        CreateSyncEnvironment(JobNo, JobTaskNo, ResourceNo, WorkTypeCode, TemplateName, BatchName);
        Clear(TagIds);
        TagIds.Add('CTAG');

        // [WHEN] A billable 4-hour entry tagged CTAG is synced
        SyncResult := TimeEntrySync.SyncTimeEntry(
            TemplateName, BatchName, 'E1', 'WS1', 'CUSER', 'CPROJ', 'CTASK',
            'Design work', Today(), 4, true, TagIds, Msg);

        // [THEN] A journal line is created with the mapped Job/Task/Resource, hours, Work Type and billable line type
        LibraryAssert.AreEqual(Enum::"Clockify Sync Result ori"::Created, SyncResult, 'First sync should create a line.');
        JobJournalLine.SetRange("Journal Template Name", TemplateName);
        JobJournalLine.SetRange("Journal Batch Name", BatchName);
        LibraryAssert.IsTrue(JobJournalLine.FindFirst(), 'A job journal line should exist.');
        LibraryAssert.AreEqual(JobNo, JobJournalLine."Job No.", 'Job No. should come from the PROJECT link.');
        LibraryAssert.AreEqual(JobTaskNo, JobJournalLine."Job Task No.", 'Job Task No. should come from the TASK link.');
        LibraryAssert.AreEqual(ResourceNo, JobJournalLine."No.", 'Resource should come from the USER link.');
        LibraryAssert.AreEqual(4, JobJournalLine.Quantity, 'Quantity should be the hours.');
        LibraryAssert.AreEqual(WorkTypeCode, JobJournalLine."Work Type Code", 'Work Type should come from the linked tag.');
        LibraryAssert.AreEqual(JobJournalLine."Line Type"::"Both Budget and Billable", JobJournalLine."Line Type", 'Billable should map to Both Budget and Billable.');
    end;

    [Test]
    procedure SyncSkipsUnchangedThenUpdatesOnChange()
    var
        JobJournalLine: Record "Job Journal Line";
        TimeEntrySync: Codeunit "Clockify Time Entry Sync ori";
        JobNo: Code[20];
        JobTaskNo: Code[20];
        ResourceNo: Code[20];
        WorkTypeCode: Code[10];
        TemplateName: Code[10];
        BatchName: Code[10];
        TagIds: List of [Text];
        SyncResult: Enum "Clockify Sync Result ori";
        Msg: Text;
    begin
        // [GIVEN] An entry already synced once
        CreateSyncEnvironment(JobNo, JobTaskNo, ResourceNo, WorkTypeCode, TemplateName, BatchName);
        Clear(TagIds);
        TagIds.Add('CTAG');
        TimeEntrySync.SyncTimeEntry(TemplateName, BatchName, 'E1', 'WS1', 'CUSER', 'CPROJ', 'CTASK', 'Work', Today(), 4, true, TagIds, Msg);

        // [WHEN] The same entry is synced again unchanged
        SyncResult := TimeEntrySync.SyncTimeEntry(TemplateName, BatchName, 'E1', 'WS1', 'CUSER', 'CPROJ', 'CTASK', 'Work', Today(), 4, true, TagIds, Msg);
        // [THEN] It is skipped
        LibraryAssert.AreEqual(Enum::"Clockify Sync Result ori"::Skipped, SyncResult, 'An unchanged re-sync should be Skipped.');

        // [WHEN] The hours change
        SyncResult := TimeEntrySync.SyncTimeEntry(TemplateName, BatchName, 'E1', 'WS1', 'CUSER', 'CPROJ', 'CTASK', 'Work', Today(), 6, true, TagIds, Msg);
        // [THEN] The existing line is updated in place (still one line, new quantity)
        LibraryAssert.AreEqual(Enum::"Clockify Sync Result ori"::Updated, SyncResult, 'A changed re-sync should be Updated.');
        JobJournalLine.SetRange("Journal Template Name", TemplateName);
        JobJournalLine.SetRange("Journal Batch Name", BatchName);
        LibraryAssert.AreEqual(1, JobJournalLine.Count(), 'An in-place update should not add a second line.');
        JobJournalLine.FindFirst();
        LibraryAssert.AreEqual(6, JobJournalLine.Quantity, 'The line quantity should reflect the new hours.');
    end;

    [Test]
    procedure ReverseDeletesSyncedJournalLine()
    var
        JobJournalLine: Record "Job Journal Line";
        Integration: Record "Clockify Integration ori";
        TimeEntrySync: Codeunit "Clockify Time Entry Sync ori";
        JobNo: Code[20];
        JobTaskNo: Code[20];
        ResourceNo: Code[20];
        WorkTypeCode: Code[10];
        TemplateName: Code[10];
        BatchName: Code[10];
        TagIds: List of [Text];
        SyncResult: Enum "Clockify Sync Result ori";
        Msg: Text;
    begin
        // [GIVEN] A synced (unposted) time entry
        CreateSyncEnvironment(JobNo, JobTaskNo, ResourceNo, WorkTypeCode, TemplateName, BatchName);
        Clear(TagIds);
        TagIds.Add('CTAG');
        TimeEntrySync.SyncTimeEntry(TemplateName, BatchName, 'E1', 'WS1', 'CUSER', 'CPROJ', 'CTASK', 'Work', Today(), 4, true, TagIds, Msg);

        // [WHEN] A TIME_ENTRY_DELETED reversal is processed
        SyncResult := TimeEntrySync.ReverseTimeEntry('E1', Msg);

        // [THEN] The journal line is deleted and the active link is reversed
        LibraryAssert.AreEqual(Enum::"Clockify Sync Result ori"::Updated, SyncResult, 'Reversing an unposted entry should delete the line.');
        JobJournalLine.SetRange("Journal Template Name", TemplateName);
        JobJournalLine.SetRange("Journal Batch Name", BatchName);
        LibraryAssert.IsTrue(JobJournalLine.IsEmpty(), 'The journal line should have been deleted.');
        Integration.SetRange("Clockify Type", 'TIME_ENTRY');
        Integration.SetRange("Clockify Id", 'E1');
        Integration.SetRange("Reversed", false);
        LibraryAssert.IsTrue(Integration.IsEmpty(), 'The active TIME_ENTRY link should have been reversed.');
    end;

    [Test]
    procedure WebhookDispatchCreatesJobJournalLine()
    var
        JobJournalLine: Record "Job Journal Line";
        Dispatcher: Codeunit "Dispatcher ori";
        RequestContent: BigText;
        ResponseContent: BigText;
        JobNo: Code[20];
        JobTaskNo: Code[20];
        ResourceNo: Code[20];
        WorkTypeCode: Code[10];
        TemplateName: Code[10];
        BatchName: Code[10];
        ResponseContentType: Text[50];
        BodyText: Text;
    begin
        // [GIVEN] Master data + links, and a Clockify time-entry webhook payload wrapped as the receiver sends it
        CreateSyncEnvironment(JobNo, JobTaskNo, ResourceNo, WorkTypeCode, TemplateName, BatchName);
        BodyText :=
            '{"body":{"id":"E9","workspaceId":"WS1","userId":"CUSER","projectId":"CPROJ","taskId":"CTASK",' +
            '"description":"Webhook work","billable":true,' +
            '"timeInterval":{"start":"2026-06-09T08:00:00Z","end":"2026-06-09T12:00:00Z"},"tagIds":["CTAG"]},"headers":{}}';
        RequestContent.AddText(BodyText);

        // [WHEN] The Webhook.Inbound.Receive message is dispatched (fires OnWebhookReceived -> Clockify Webhook Handler)
        Dispatcher.Execute(
            Enum::"Message Type ori"::"Webhook.Inbound.Receive",
            Enum::"Message Version ori"::"1.0",
            'NEW_TIME_ENTRY', 'clockify/WS1', 'application/json',
            RequestContent, ResponseContent, ResponseContentType);

        // [THEN] The handler synced the entry to a Job Journal Line with the tag's Work Type
        JobJournalLine.SetRange("Journal Template Name", TemplateName);
        JobJournalLine.SetRange("Journal Batch Name", BatchName);
        LibraryAssert.IsTrue(JobJournalLine.FindFirst(), 'The webhook should have created a job journal line via the handler.');
        LibraryAssert.AreEqual(WorkTypeCode, JobJournalLine."Work Type Code", 'Work Type should be resolved from the tag.');
        LibraryAssert.AreEqual(4, JobJournalLine.Quantity, 'Quantity should be 4 hours from the time interval.');
    end;

    [ModalPageHandler]
    procedure WorkspaceLookupModalHandler(var WorkspaceLookup: TestPage "Clockify Workspace Lookup ori")
    begin
        WorkspaceLookup.First();
        WorkspaceLookup.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmYesHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    procedure GenericMessageHandler(Msg: Text[1024])
    begin
    end;

    [Test]
    procedure IntegrationTableStampsAndClearsReversedAt()
    var
        ClockifyIntegration: Record "Clockify Integration ori";
    begin
        // [SCENARIO] Reversing a link stamps Reversed At; un-reversing clears it.
        ClockifyIntegration.Init();
        ClockifyIntegration."BC Table No." := Database::"Clockify Integration ori";
        ClockifyIntegration."Clockify Type" := 'client';
        ClockifyIntegration."Clockify Id" := 'CL-1';
        ClockifyIntegration.Insert(true);

        // [THEN] A fresh link has no reversal timestamp
        LibraryAssert.AreEqual(0DT, ClockifyIntegration."Reversed At", 'Reversed At should be empty for an active link.');

        // [WHEN] The link is reversed
        ClockifyIntegration.Reversed := true;
        ClockifyIntegration.Modify(true);

        // [THEN] Reversed At is stamped
        LibraryAssert.AreNotEqual(0DT, ClockifyIntegration."Reversed At", 'Reversed At should be stamped when the link is reversed.');

        // [WHEN] The link is restored
        ClockifyIntegration.Reversed := false;
        ClockifyIntegration.Modify(true);

        // [THEN] Reversed At is cleared
        LibraryAssert.AreEqual(0DT, ClockifyIntegration."Reversed At", 'Reversed At should clear when the link is un-reversed.');
    end;

    [Test]
    procedure RetentionRegistersIntegrationTable()
    var
        RetenPolicy: Codeunit "Clockify Reten. Policy ori";
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
    begin
        // [SCENARIO] The Clockify Integration table is registered for retention.
        RetenPolicy.AddAllowedTable();
        LibraryAssert.IsTrue(
            RetenPolAllowedTables.IsAllowedTable(Database::"Clockify Integration ori"),
            'The Clockify Integration table should be an allowed retention table.');
    end;

    [Test]
    procedure HelpIncludesIntegrationTracking()
    var
        Argument: Record "Message Argument ori";
        MsgInterface: Interface "Msg Interface ori";
        HelpText: Text;
    begin
        // [SCENARIO] Per-type help explains how to use the integration table.
        Argument.Init();
        Argument."Type" := Argument."Type"::"Clockify.Client.Create";
        Argument.Insert();
        MsgInterface := Argument.GetMessageTypeInterface();
        MsgInterface.GetMessageHelpAsMarkdownDocument(Argument);
        HelpText := Argument.GetResponseText();

        LibraryAssert.IsTrue(HelpText.Contains('Integration tracking'), 'Per-type help should include an integration tracking section.');
        LibraryAssert.IsTrue(HelpText.Contains('Clockify Integration'), 'Per-type help should reference the Clockify Integration table.');
    end;

    [Test]
    procedure CurrencyListProjectsWorkspaceCurrencies()
    var
        Argument: Record "Message Argument ori";
        MockState: Codeunit "Clockify Mock State";
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
        DataToken: JsonToken;
    begin
        // [GIVEN] The connector is routed to the mock API client and a workspace id is supplied
        UseMockApi();
        // [GIVEN] Clockify has no /currencies endpoint; currencies arrive inline on the workspace object
        MockState.SetNextResponse(true, 200,
            '[{"id":"WS-1","name":"Acme","currencies":[{"id":"CUR-1","code":"ISK","isDefault":true},{"id":"CUR-2","code":"USD","isDefault":false}]},{"id":"WS-2","name":"Globex","currencies":[{"id":"CUR-9","code":"EUR","isDefault":true}]}]');
        RequestJson.Add('workspaceId', 'WS-1');

        // [WHEN] The Clockify.Currency.List task executes
        ExecuteTypeWithRequest(Argument, Argument."Type"::"Clockify.Currency.List", RequestJson);

        // [THEN] The mock received a GET on /workspaces (no standalone currencies endpoint exists)
        LibraryAssert.AreEqual('GET', MockState.GetLastMethod(), 'Currency list should issue a GET.');
        LibraryAssert.AreEqual('/workspaces', MockState.GetLastResourcePath(), 'Currency list should read the workspace list, not a /currencies endpoint.');
        LibraryAssert.IsFalse(MockState.GetLastHasBody(), 'Currency list should not send a body.');

        // [THEN] The response projects out only the requested workspace's currencies
        ResponseJson := Argument.GetResponseJson();
        LibraryAssert.AreEqual('Success', ReadText(ResponseJson, 'status'), 'A resolved workspace should map to Success.');
        LibraryAssert.IsTrue(ResponseJson.Get('data', DataToken), 'The response should carry a data array.');
        LibraryAssert.IsTrue(DataToken.IsArray(), 'The currency data should be an array.');
        LibraryAssert.AreEqual(2, DataToken.AsArray().Count(), 'Only WS-1''s two currencies should be returned.');
    end;

    [Test]
    procedure UserGroupListRoutesGetToWorkspacesUserGroups()
    var
        Argument: Record "Message Argument ori";
        MockState: Codeunit "Clockify Mock State";
        RequestJson: JsonObject;
    begin
        // [GIVEN] The connector is routed to the mock API client and a workspace id is supplied
        UseMockApi();
        MockState.SetNextResponse(true, 200, '[{"id":"61...","name":"Consultants","userIds":["63..."]}]');
        RequestJson.Add('workspaceId', 'WS-1');

        // [WHEN] The Clockify.UserGroup.List task executes
        ExecuteTypeWithRequest(Argument, Argument."Type"::"Clockify.UserGroup.List", RequestJson);

        // [THEN] The mock received a GET on /workspaces/{id}/user-groups with no body
        LibraryAssert.AreEqual('GET', MockState.GetLastMethod(), 'User-group list should issue a GET.');
        LibraryAssert.AreEqual('/workspaces/WS-1/user-groups', MockState.GetLastResourcePath(), 'User-group list should call /workspaces/{id}/user-groups.');
        LibraryAssert.IsFalse(MockState.GetLastHasBody(), 'User-group list should not send a body.');
    end;

    [Test]
    procedure UserGroupListForwardsQueryString()
    var
        Argument: Record "Message Argument ori";
        MockState: Codeunit "Clockify Mock State";
        RequestJson: JsonObject;
        QueryJson: JsonObject;
    begin
        // [GIVEN] A user-group list request that carries a query filter
        UseMockApi();
        MockState.SetNextResponse(true, 200, '[]');
        RequestJson.Add('workspaceId', 'WS-1');
        QueryJson.Add('name', 'Consultants');
        RequestJson.Add('query', QueryJson);

        // [WHEN] The Clockify.UserGroup.List task executes
        ExecuteTypeWithRequest(Argument, Argument."Type"::"Clockify.UserGroup.List", RequestJson);

        // [THEN] The resource path carries the encoded query parameter
        LibraryAssert.IsTrue(MockState.GetLastResourcePath().StartsWith('/workspaces/WS-1/user-groups?'), 'User-group list should append the query string.');
        LibraryAssert.IsTrue(MockState.GetLastResourcePath().Contains('name=Consultants'), 'The query filter should be present in the resource path.');
    end;

    [Test]
    procedure TimeEntryListForwardsInProgressQueryParameter()
    var
        Argument: Record "Message Argument ori";
        MockState: Codeunit "Clockify Mock State";
        RequestJson: JsonObject;
        QueryJson: JsonObject;
    begin
        // [GIVEN] A time-entry list request that filters for running timers
        UseMockApi();
        MockState.SetNextResponse(true, 200, '[]');
        RequestJson.Add('workspaceId', 'WS-1');
        RequestJson.Add('userId', 'U-1');
        QueryJson.Add('in-progress', true);
        RequestJson.Add('query', QueryJson);

        // [WHEN] The Clockify.TimeEntry.List task executes
        ExecuteTypeWithRequest(Argument, Argument."Type"::"Clockify.TimeEntry.List", RequestJson);

        // [THEN] The resource path carries the in-progress query parameter
        LibraryAssert.IsTrue(MockState.GetLastResourcePath().StartsWith('/workspaces/WS-1/user/U-1/time-entries?'), 'Time-entry list should append the query string.');
        LibraryAssert.IsTrue(MockState.GetLastResourcePath().Contains('in-progress=true'), 'The in-progress filter should be present in the resource path.');
    end;

    [Test]
    procedure CustomFieldListRoutesGetToWorkspacesCustomFields()
    var
        Argument: Record "Message Argument ori";
        MockState: Codeunit "Clockify Mock State";
        RequestJson: JsonObject;
    begin
        // [GIVEN] The connector is routed to the mock API client and a workspace id is supplied
        UseMockApi();
        MockState.SetNextResponse(true, 200, '[{"id":"62...","name":"PO Number","type":"TXT"}]');
        RequestJson.Add('workspaceId', 'WS-1');

        // [WHEN] The Clockify.CustomField.List task executes
        ExecuteTypeWithRequest(Argument, Argument."Type"::"Clockify.CustomField.List", RequestJson);

        // [THEN] The mock received a GET on /workspaces/{id}/custom-fields with no body
        LibraryAssert.AreEqual('GET', MockState.GetLastMethod(), 'Custom-field list should issue a GET.');
        LibraryAssert.AreEqual('/workspaces/WS-1/custom-fields', MockState.GetLastResourcePath(), 'Custom-field list should call /workspaces/{id}/custom-fields.');
        LibraryAssert.IsFalse(MockState.GetLastHasBody(), 'Custom-field list should not send a body.');
    end;

    [Test]
    procedure LookupEndpointsUseDefaultWorkspaceWhenRequestOmitsIt()
    var
        ClockifySetup: Record "Clockify Setup ori";
        Argument: Record "Message Argument ori";
        MockState: Codeunit "Clockify Mock State";
        RequestJson: JsonObject;
    begin
        // [GIVEN] A default workspace configured on setup, and a UserGroup.List request that omits workspaceId
        UseMockApi();
        if not ClockifySetup.Get() then
            ClockifySetup.Insert();
        ClockifySetup."Default Workspace" := 'WS-DEF';
        ClockifySetup.Modify();
        MockState.SetNextResponse(true, 200, '[]');

        // [WHEN] The Clockify.UserGroup.List task executes without a workspaceId
        ExecuteTypeWithRequest(Argument, Argument."Type"::"Clockify.UserGroup.List", RequestJson);

        // [THEN] The default workspace is used in the resource path
        LibraryAssert.AreEqual('/workspaces/WS-DEF/user-groups', MockState.GetLastResourcePath(), 'The default workspace should fill in for the missing workspaceId.');
    end;

    [Test]
    procedure UserGroupListHelpExplainsIdUsage()
    var
        Argument: Record "Message Argument ori";
        MsgInterface: Interface "Msg Interface ori";
        HelpText: Text;
    begin
        // [SCENARIO] UserGroup.List help directs the caller to use the returned id as userGroupIds on project writes.
        Argument.Init();
        Argument."Type" := Argument."Type"::"Clockify.UserGroup.List";
        Argument.Insert();
        MsgInterface := Argument.GetMessageTypeInterface();
        MsgInterface.GetMessageHelpAsMarkdownDocument(Argument);
        HelpText := Argument.GetResponseText();

        LibraryAssert.IsTrue(HelpText.Contains('Notes'), 'UserGroup.List help should render a Notes section.');
        LibraryAssert.IsTrue(HelpText.Contains('userGroupIds'), 'UserGroup.List help should point to userGroupIds on project writes.');
    end;

    [Test]
    procedure CustomFieldListHelpExplainsIdUsage()
    var
        Argument: Record "Message Argument ori";
        MsgInterface: Interface "Msg Interface ori";
        HelpText: Text;
    begin
        // [SCENARIO] CustomField.List help directs the caller to use the returned id as customFieldId on time-entry and project writes.
        Argument.Init();
        Argument."Type" := Argument."Type"::"Clockify.CustomField.List";
        Argument.Insert();
        MsgInterface := Argument.GetMessageTypeInterface();
        MsgInterface.GetMessageHelpAsMarkdownDocument(Argument);
        HelpText := Argument.GetResponseText();

        LibraryAssert.IsTrue(HelpText.Contains('Notes'), 'CustomField.List help should render a Notes section.');
        LibraryAssert.IsTrue(HelpText.Contains('customFieldId'), 'CustomField.List help should point to customFieldId on write payloads.');
    end;

    [Test]
    procedure TimeEntryListHelpExplainsInProgressFilter()
    var
        Argument: Record "Message Argument ori";
        MsgInterface: Interface "Msg Interface ori";
        HelpText: Text;
    begin
        // [SCENARIO] TimeEntry.List help explains query.in-progress and its effect on result shape.
        Argument.Init();
        Argument."Type" := Argument."Type"::"Clockify.TimeEntry.List";
        Argument.Insert();
        MsgInterface := Argument.GetMessageTypeInterface();
        MsgInterface.GetMessageHelpAsMarkdownDocument(Argument);
        HelpText := Argument.GetResponseText();

        LibraryAssert.IsTrue(HelpText.Contains('query.in-progress'), 'TimeEntry.List help should document query.in-progress.');
        LibraryAssert.IsTrue(HelpText.Contains('running timers'), 'TimeEntry.List help should explain the running-timer behavior.');
    end;

    [Test]
    procedure TimeEntrySyncHelpWarnsAboutInProgressEntries()
    var
        Argument: Record "Message Argument ori";
        MsgInterface: Interface "Msg Interface ori";
        HelpText: Text;
    begin
        // [SCENARIO] TimeEntry.Sync help warns that in-progress entries are never written to Job Journal.
        Argument.Init();
        Argument."Type" := Argument."Type"::"Clockify.TimeEntry.Sync";
        Argument.Insert();
        MsgInterface := Argument.GetMessageTypeInterface();
        MsgInterface.GetMessageHelpAsMarkdownDocument(Argument);
        HelpText := Argument.GetResponseText();

        LibraryAssert.IsTrue(HelpText.Contains('In-progress protection'), 'TimeEntry.Sync help should include the in-progress protection note.');
        LibraryAssert.IsTrue(HelpText.Contains('never written to Job Journal'), 'TimeEntry.Sync help should clearly state the posting guardrail.');
    end;

    [Test]
    procedure UserListHelpExplainsOptionalQueryEffects()
    var
        Argument: Record "Message Argument ori";
        MsgInterface: Interface "Msg Interface ori";
        HelpText: Text;
    begin
        // [SCENARIO] Optional query behavior is explained for list endpoints.
        Argument.Init();
        Argument."Type" := Argument."Type"::"Clockify.User.List";
        Argument.Insert();
        MsgInterface := Argument.GetMessageTypeInterface();
        MsgInterface.GetMessageHelpAsMarkdownDocument(Argument);
        HelpText := Argument.GetResponseText();

        LibraryAssert.IsTrue(HelpText.Contains('Agent guidance — optional parameter effects'), 'Help should include the optional-parameter guidance section.');
        LibraryAssert.IsTrue(HelpText.Contains('query.*'), 'List help should explain that query parameters shape returned data.');
        LibraryAssert.IsTrue(HelpText.Contains('page-size'), 'List help should explain paging parameter effects.');
    end;

    [Test]
    procedure ClientUpdateHelpExplainsOptionalBodyEffects()
    var
        Argument: Record "Message Argument ori";
        MsgInterface: Interface "Msg Interface ori";
        HelpText: Text;
    begin
        // [SCENARIO] Optional body behavior is explained for update endpoints.
        Argument.Init();
        Argument."Type" := Argument."Type"::"Clockify.Client.Update";
        Argument.Insert();
        MsgInterface := Argument.GetMessageTypeInterface();
        MsgInterface.GetMessageHelpAsMarkdownDocument(Argument);
        HelpText := Argument.GetResponseText();

        LibraryAssert.IsTrue(HelpText.Contains('Agent guidance — optional parameter effects'), 'Help should include the optional-parameter guidance section.');
        LibraryAssert.IsTrue(HelpText.Contains('Optional `body.*` fields omitted'), 'Update help should explain omitted optional body behavior.');
        LibraryAssert.IsTrue(HelpText.Contains('existing Clockify values'), 'Update help should explain that omitted fields keep existing values.');
    end;

    [Test]
    procedure OverviewListsLookupEndpoints()
    var
        Argument: Record "Message Argument ori";
        MsgInterface: Interface "Msg Interface ori";
        HelpText: Text;
    begin
        // [SCENARIO] The Clockify overview lists the three lookup endpoints so callers can discover them.
        Argument.Init();
        Argument."Type" := Argument."Type"::"Help.Clockify.Get";
        Argument.Insert();
        MsgInterface := Argument.GetMessageTypeInterface();
        MsgInterface.GetMessageHelpAsMarkdownDocument(Argument);
        HelpText := Argument.GetResponseText();

        LibraryAssert.IsTrue(HelpText.Contains('Clockify.Currency.List'), 'Overview should list Clockify.Currency.List.');
        LibraryAssert.IsTrue(HelpText.Contains('Clockify.UserGroup.List'), 'Overview should list Clockify.UserGroup.List.');
        LibraryAssert.IsTrue(HelpText.Contains('Clockify.CustomField.List'), 'Overview should list Clockify.CustomField.List.');
    end;

    [Test]
    procedure OverviewGotchasCallOutIdOnlyWrites()
    var
        Argument: Record "Message Argument ori";
        MsgInterface: Interface "Msg Interface ori";
        HelpText: Text;
    begin
        // [SCENARIO] The overview warns that Clockify writes accept opaque IDs, never names or BC keys.
        Argument.Init();
        Argument."Type" := Argument."Type"::"Help.Clockify.Get";
        Argument.Insert();
        MsgInterface := Argument.GetMessageTypeInterface();
        MsgInterface.GetMessageHelpAsMarkdownDocument(Argument);
        HelpText := Argument.GetResponseText();

        LibraryAssert.IsTrue(HelpText.Contains('Writes accept Clockify IDs'), 'Overview gotchas should warn that writes accept Clockify IDs only.');
        LibraryAssert.IsTrue(HelpText.Contains('archived before they can be deleted'), 'Overview gotchas should mention the archive-before-delete rule.');
    end;

    [Test]
    procedure IntegrationGateAllowsWriteAccess()
    var
        Argument: Record "Message Argument ori";
        IntegrationGate: Codeunit "Clockify Integration Gate ori";
    begin
        // [SCENARIO] With write permission to the integration table, the gate lets the operation proceed.
        Argument.Init();
        LibraryAssert.IsTrue(
            IntegrationGate.AssertCanWriteIntegration(Argument),
            'The gate should allow a user with write permission to the Clockify Integration table.');
    end;

    [Test]
    procedure SyncRangeIsInboundWithHelp()
    var
        Argument: Record "Message Argument ori";
        MsgInterface: Interface "Msg Interface ori";
    begin
        // [SCENARIO] Clockify.TimeEntry.SyncRange reports inbound metadata and produces help.
        Argument.Init();
        Argument."Type" := Argument."Type"::"Clockify.TimeEntry.SyncRange";
        Argument.Insert();
        MsgInterface := Argument.GetMessageTypeInterface();

        LibraryAssert.AreEqual(Enum::"Msg Direction ori"::Inbound, MsgInterface.GetMessageDirection(), 'SyncRange should be inbound (BC-side).');
        LibraryAssert.AreEqual(0, MsgInterface.GetFilterTableNo(), 'SyncRange should have no filter table.');
        LibraryAssert.AreNotEqual('', MsgInterface.GetDescription(), 'SyncRange should have a description.');

        MsgInterface.GetMessageHelpAsMarkdownDocument(Argument);
        LibraryAssert.AreNotEqual('', Argument.GetResponseText(), 'SyncRange should produce help markdown.');
    end;

    [Test]
    procedure SyncRangeErrorsWhenNoJournalConfigured()
    var
        ClockifySetup: Record "Clockify Setup ori";
        Argument: Record "Message Argument ori";
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
    begin
        // [GIVEN] No Job Journal configured on setup and none supplied in the request
        UseMockApi();
        if not ClockifySetup.Get() then
            ClockifySetup.Insert();
        ClockifySetup."Job Jnl. Template" := '';
        ClockifySetup."Job Jnl. Batch" := '';
        ClockifySetup.Modify();
        RequestJson.Add('workspaceId', 'WS1');
        RequestJson.Add('userId', 'CUSER');
        RequestJson.Add('start', '2026-06-01T00:00:00Z');
        RequestJson.Add('end', '2026-06-30T23:59:59Z');

        // [WHEN] The Clockify.TimeEntry.SyncRange task executes
        ExecuteTypeWithRequest(Argument, Argument."Type"::"Clockify.TimeEntry.SyncRange", RequestJson);

        // [THEN] It reports an error pointing at the missing Job Journal configuration
        ResponseJson := Argument.GetResponseJson();
        LibraryAssert.AreEqual('Error', ReadText(ResponseJson, 'status'), 'Missing journal config should map to Error.');
        LibraryAssert.IsTrue(ReadText(ResponseJson, 'error').Contains('Job Journal'), 'The error should mention the Job Journal configuration.');
    end;

    [Test]
    procedure SyncRangeCreatesLinesForEntriesInRange()
    var
        JobJournalLine: Record "Job Journal Line";
        Argument: Record "Message Argument ori";
        MockState: Codeunit "Clockify Mock State";
        JobNo: Code[20];
        JobTaskNo: Code[20];
        ResourceNo: Code[20];
        WorkTypeCode: Code[10];
        TemplateName: Code[10];
        BatchName: Code[10];
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
    begin
        // [GIVEN] Mapped master data + journal, and Clockify returns two finished entries in the range
        CreateSyncEnvironment(JobNo, JobTaskNo, ResourceNo, WorkTypeCode, TemplateName, BatchName);
        UseMockApi();
        MockState.SetNextResponse(true, 200,
            '[{"id":"E1","description":"Work A","projectId":"CPROJ","taskId":"CTASK","billable":true,"tagIds":["CTAG"],"timeInterval":{"start":"2026-06-09T08:00:00Z","end":"2026-06-09T12:00:00Z"}},' +
            '{"id":"E2","description":"Work B","projectId":"CPROJ","taskId":"CTASK","billable":true,"tagIds":["CTAG"],"timeInterval":{"start":"2026-06-10T08:00:00Z","end":"2026-06-10T10:00:00Z"}}]');
        RequestJson.Add('workspaceId', 'WS1');
        RequestJson.Add('userId', 'CUSER');
        RequestJson.Add('start', '2026-06-01T00:00:00Z');
        RequestJson.Add('end', '2026-06-30T23:59:59Z');

        // [WHEN] The batch sync executes
        ExecuteTypeWithRequest(Argument, Argument."Type"::"Clockify.TimeEntry.SyncRange", RequestJson);

        // [THEN] Both entries are created and a job journal line exists per entry
        ResponseJson := Argument.GetResponseJson();
        LibraryAssert.AreEqual(2, ReadInt(ResponseJson, 'processed'), 'Both entries should be processed.');
        LibraryAssert.AreEqual(2, ReadInt(ResponseJson, 'created'), 'Both entries should be created.');
        LibraryAssert.AreEqual(0, ReadInt(ResponseJson, 'errors'), 'No entry should error.');
        JobJournalLine.SetRange("Journal Template Name", TemplateName);
        JobJournalLine.SetRange("Journal Batch Name", BatchName);
        LibraryAssert.AreEqual(2, JobJournalLine.Count(), 'One journal line should exist per synced entry.');
    end;

    [Test]
    procedure SyncRangePerEntryErrorDoesNotAbortBatch()
    var
        JobJournalLine: Record "Job Journal Line";
        Argument: Record "Message Argument ori";
        MockState: Codeunit "Clockify Mock State";
        JobNo: Code[20];
        JobTaskNo: Code[20];
        ResourceNo: Code[20];
        WorkTypeCode: Code[10];
        TemplateName: Code[10];
        BatchName: Code[10];
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
    begin
        // [GIVEN] Two entries where the second references an unmapped project
        CreateSyncEnvironment(JobNo, JobTaskNo, ResourceNo, WorkTypeCode, TemplateName, BatchName);
        UseMockApi();
        MockState.SetNextResponse(true, 200,
            '[{"id":"E1","description":"Work A","projectId":"CPROJ","taskId":"CTASK","billable":true,"tagIds":["CTAG"],"timeInterval":{"start":"2026-06-09T08:00:00Z","end":"2026-06-09T12:00:00Z"}},' +
            '{"id":"E2","description":"Work B","projectId":"UNMAPPED","taskId":"CTASK","billable":true,"tagIds":["CTAG"],"timeInterval":{"start":"2026-06-10T08:00:00Z","end":"2026-06-10T10:00:00Z"}}]');
        RequestJson.Add('workspaceId', 'WS1');
        RequestJson.Add('userId', 'CUSER');
        RequestJson.Add('start', '2026-06-01T00:00:00Z');
        RequestJson.Add('end', '2026-06-30T23:59:59Z');

        // [WHEN] The batch sync executes
        ExecuteTypeWithRequest(Argument, Argument."Type"::"Clockify.TimeEntry.SyncRange", RequestJson);

        // [THEN] The mapped entry still syncs while the unmapped one is counted as an error
        ResponseJson := Argument.GetResponseJson();
        LibraryAssert.AreEqual(2, ReadInt(ResponseJson, 'processed'), 'Both entries should be processed.');
        LibraryAssert.AreEqual(1, ReadInt(ResponseJson, 'created'), 'Only the mapped entry should be created.');
        LibraryAssert.AreEqual(1, ReadInt(ResponseJson, 'errors'), 'The unmapped entry should be an error.');
        JobJournalLine.SetRange("Journal Template Name", TemplateName);
        JobJournalLine.SetRange("Journal Batch Name", BatchName);
        LibraryAssert.AreEqual(1, JobJournalLine.Count(), 'Only the mapped entry should produce a journal line.');
    end;

    [Test]
    procedure AllInboundTimeTypesAreInboundWithHelp()
    var
        MessageType: Enum "Message Type ori";
        Ordinals: List of [Integer];
        Ordinal: Integer;
    begin
        // [SCENARIO] Every inbound time-entry/time-sheet type (10036815-10036825) is Inbound with help.
        Ordinals := MessageType.Ordinals();
        foreach Ordinal in Ordinals do
            if (Ordinal >= 10036815) and (Ordinal <= 10036825) then
                VerifyInboundTypeMetadataAndHelp(Ordinal);
    end;

    local procedure VerifyInboundTypeMetadataAndHelp(Ordinal: Integer)
    var
        Argument: Record "Message Argument ori";
        MessageType: Enum "Message Type ori";
        MsgInterface: Interface "Msg Interface ori";
        NotInboundErr: Label 'Type %1 should be inbound.', Comment = '%1 = message type';
        NoHelpErr: Label 'Type %1 should produce help markdown.', Comment = '%1 = message type';
    begin
        MessageType := Enum::"Message Type ori".FromInteger(Ordinal);
        Argument.Init();
        Argument."Type" := MessageType;
        Argument.Insert();
        MsgInterface := Argument.GetMessageTypeInterface();
        LibraryAssert.AreEqual(Enum::"Msg Direction ori"::Inbound, MsgInterface.GetMessageDirection(), StrSubstNo(NotInboundErr, MessageType));
        MsgInterface.GetMessageHelpAsMarkdownDocument(Argument);
        LibraryAssert.AreNotEqual('', Argument.GetResponseText(), StrSubstNo(NoHelpErr, MessageType));
    end;

    [Test]
    procedure TimeSheetCreateReturnsCountWithNoResources()
    var
        ResourcesSetup: Record "Resources Setup";
        Resource: Record Resource;
        Argument: Record "Message Argument ori";
        ResponseJson: JsonObject;
    begin
        // [GIVEN] A Time Sheet No. Series is configured but no time-sheet resources exist
        if not ResourcesSetup.Get() then
            ResourcesSetup.Insert();
        ResourcesSetup."Time Sheet Nos." := 'TS';
        ResourcesSetup.Modify();
        Resource.SetRange("Use Time Sheet", true);
        Resource.ModifyAll("Use Time Sheet", false);

        // [WHEN] Clockify.TimeSheet.Create runs
        ExecuteType(Argument, Argument."Type"::"Clockify.TimeSheet.Create");

        // [THEN] It succeeds and creates nothing
        ResponseJson := Argument.GetResponseJson();
        LibraryAssert.AreEqual('Success', ReadText(ResponseJson, 'status'), 'Create should succeed.');
        LibraryAssert.AreEqual(0, ReadInt(ResponseJson, 'created'), 'No eligible resources should yield 0 created.');
    end;

    [Test]
    procedure TimeSheetApproveReturnsZeroWhenNothingOpen()
    var
        Argument: Record "Message Argument ori";
        ResponseJson: JsonObject;
    begin
        // [WHEN] Clockify.TimeSheet.Approve runs with no open sheets in range
        ExecuteType(Argument, Argument."Type"::"Clockify.TimeSheet.Approve");

        // [THEN] It succeeds and approves nothing
        ResponseJson := Argument.GetResponseJson();
        LibraryAssert.AreEqual('Success', ReadText(ResponseJson, 'status'), 'Approve should succeed.');
        LibraryAssert.AreEqual(0, ReadInt(ResponseJson, 'approvedLines'), 'No open sheets should yield 0 approved lines.');
    end;

    [Test]
    procedure TimeSheetArchiveReturnsZeroWhenNothingPosted()
    var
        Argument: Record "Message Argument ori";
        ResponseJson: JsonObject;
    begin
        // [WHEN] Clockify.TimeSheet.Archive runs with no posted sheets
        ExecuteType(Argument, Argument."Type"::"Clockify.TimeSheet.Archive");

        // [THEN] It succeeds and archives nothing
        ResponseJson := Argument.GetResponseJson();
        LibraryAssert.AreEqual('Success', ReadText(ResponseJson, 'status'), 'Archive should succeed.');
        LibraryAssert.AreEqual(0, ReadInt(ResponseJson, 'archived'), 'No posted sheets should yield 0 archived.');
    end;

    [Test]
    procedure TimeSheetRejectReturnsZeroWhenNothingSubmitted()
    var
        Argument: Record "Message Argument ori";
        ResponseJson: JsonObject;
    begin
        // [WHEN] Clockify.TimeSheet.Reject runs with no submitted sheets
        ExecuteType(Argument, Argument."Type"::"Clockify.TimeSheet.Reject");

        // [THEN] It succeeds and rejects nothing
        ResponseJson := Argument.GetResponseJson();
        LibraryAssert.AreEqual('Success', ReadText(ResponseJson, 'status'), 'Reject should succeed.');
        LibraryAssert.AreEqual(0, ReadInt(ResponseJson, 'rejectedLines'), 'No submitted sheets should yield 0 rejected lines.');
    end;

    [Test]
    procedure TimeSheetReopenReturnsZeroWhenNothingPending()
    var
        Argument: Record "Message Argument ori";
        ResponseJson: JsonObject;
    begin
        // [WHEN] Clockify.TimeSheet.Reopen runs with no submitted/approved sheets
        ExecuteType(Argument, Argument."Type"::"Clockify.TimeSheet.Reopen");

        // [THEN] It succeeds and reopens nothing
        ResponseJson := Argument.GetResponseJson();
        LibraryAssert.AreEqual('Success', ReadText(ResponseJson, 'status'), 'Reopen should succeed.');
        LibraryAssert.AreEqual(0, ReadInt(ResponseJson, 'reopenedLines'), 'No pending sheets should yield 0 reopened lines.');
    end;

    [Test]
    procedure TimeSheetPostErrorsWhenNoJournalConfigured()
    var
        ClockifySetup: Record "Clockify Setup ori";
        Argument: Record "Message Argument ori";
        ResponseJson: JsonObject;
    begin
        // [GIVEN] No Job Journal configured and none supplied
        if not ClockifySetup.Get() then
            ClockifySetup.Insert();
        ClockifySetup."Job Jnl. Template" := '';
        ClockifySetup."Job Jnl. Batch" := '';
        ClockifySetup.Modify();

        // [WHEN] Clockify.TimeSheet.Post runs
        ExecuteType(Argument, Argument."Type"::"Clockify.TimeSheet.Post");

        // [THEN] It reports the missing Job Journal configuration
        ResponseJson := Argument.GetResponseJson();
        LibraryAssert.AreEqual('Error', ReadText(ResponseJson, 'status'), 'Missing journal config should map to Error.');
        LibraryAssert.IsTrue(ReadText(ResponseJson, 'error').Contains('Job Journal'), 'The error should mention the Job Journal.');
    end;

    [Test]
    procedure TimeSheetPostReturnsZeroWhenNoApprovedLines()
    var
        Argument: Record "Message Argument ori";
        JobNo: Code[20];
        JobTaskNo: Code[20];
        ResourceNo: Code[20];
        WorkTypeCode: Code[10];
        TemplateName: Code[10];
        BatchName: Code[10];
        ResponseJson: JsonObject;
    begin
        // [GIVEN] A configured Job Journal but no approved time-sheet lines
        CreateSyncEnvironment(JobNo, JobTaskNo, ResourceNo, WorkTypeCode, TemplateName, BatchName);

        // [WHEN] Clockify.TimeSheet.Post runs
        ExecuteType(Argument, Argument."Type"::"Clockify.TimeSheet.Post");

        // [THEN] It succeeds and posts nothing
        ResponseJson := Argument.GetResponseJson();
        LibraryAssert.AreEqual('Success', ReadText(ResponseJson, 'status'), 'Post should succeed.');
        LibraryAssert.AreEqual(0, ReadInt(ResponseJson, 'postedLines'), 'No approved lines should yield 0 posted.');
    end;

    [Test]
    procedure SyncToTimeSheetErrorsWhenNoMapping()
    var
        Argument: Record "Message Argument ori";
        Integration: Record "Clockify Integration ori";
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
    begin
        // [GIVEN] No integration mappings
        Integration.DeleteAll();
        RequestJson.Add('workspaceId', 'WS1');
        RequestJson.Add('userId', 'CUSER');
        RequestJson.Add('entryId', 'E1');
        RequestJson.Add('projectId', 'UNMAPPED');
        RequestJson.Add('start', '2026-06-09T08:00:00Z');
        RequestJson.Add('end', '2026-06-09T12:00:00Z');

        // [WHEN] Clockify.TimeEntry.SyncToTimeSheet runs
        ExecuteTypeWithRequest(Argument, Argument."Type"::"Clockify.TimeEntry.SyncToTimeSheet", RequestJson);

        // [THEN] It reports a missing mapping
        ResponseJson := Argument.GetResponseJson();
        LibraryAssert.AreEqual('Error', ReadText(ResponseJson, 'result'), 'An unmapped project should error.');
        LibraryAssert.IsTrue(ReadText(ResponseJson, 'message').Contains('mapping'), 'The message should mention the missing mapping.');
    end;

    [Test]
    procedure SyncToTimeSheetErrorsWhenNoOpenTimeSheet()
    var
        Argument: Record "Message Argument ori";
        JobNo: Code[20];
        JobTaskNo: Code[20];
        ResourceNo: Code[20];
        WorkTypeCode: Code[10];
        TemplateName: Code[10];
        BatchName: Code[10];
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
    begin
        // [GIVEN] Mappings exist but the resource has no open time sheet
        CreateSyncEnvironment(JobNo, JobTaskNo, ResourceNo, WorkTypeCode, TemplateName, BatchName);
        RequestJson.Add('workspaceId', 'WS1');
        RequestJson.Add('userId', 'CUSER');
        RequestJson.Add('entryId', 'E1');
        RequestJson.Add('projectId', 'CPROJ');
        RequestJson.Add('taskId', 'CTASK');
        RequestJson.Add('start', '2026-06-09T08:00:00Z');
        RequestJson.Add('end', '2026-06-09T12:00:00Z');

        // [WHEN] Clockify.TimeEntry.SyncToTimeSheet runs
        ExecuteTypeWithRequest(Argument, Argument."Type"::"Clockify.TimeEntry.SyncToTimeSheet", RequestJson);

        // [THEN] It reports the missing open time sheet
        ResponseJson := Argument.GetResponseJson();
        LibraryAssert.AreEqual('Error', ReadText(ResponseJson, 'result'), 'A missing open sheet should error.');
        LibraryAssert.IsTrue(ReadText(ResponseJson, 'message').Contains('open time sheet'), 'The message should explain the missing sheet.');
    end;

    [Test]
    procedure SyncToTimeSheetCreatesDetailOnOpenSheet()
    var
        TimeSheetDetail: Record "Time Sheet Detail";
        Argument: Record "Message Argument ori";
        JobNo: Code[20];
        JobTaskNo: Code[20];
        ResourceNo: Code[20];
        WorkTypeCode: Code[10];
        TemplateName: Code[10];
        BatchName: Code[10];
        TimeSheetNo: Code[20];
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
    begin
        // [GIVEN] Mappings and an open time sheet covering the entry date
        CreateSyncEnvironment(JobNo, JobTaskNo, ResourceNo, WorkTypeCode, TemplateName, BatchName);
        TimeSheetNo := CreateOpenTimeSheet(ResourceNo, DMY2Date(1, 6, 2026), DMY2Date(30, 6, 2026));
        RequestJson.Add('workspaceId', 'WS1');
        RequestJson.Add('userId', 'CUSER');
        RequestJson.Add('entryId', 'E1');
        RequestJson.Add('projectId', 'CPROJ');
        RequestJson.Add('taskId', 'CTASK');
        RequestJson.Add('description', 'Work A');
        RequestJson.Add('start', '2026-06-09T08:00:00Z');
        RequestJson.Add('end', '2026-06-09T12:00:00Z');

        // [WHEN] Clockify.TimeEntry.SyncToTimeSheet runs
        ExecuteTypeWithRequest(Argument, Argument."Type"::"Clockify.TimeEntry.SyncToTimeSheet", RequestJson);

        // [THEN] A time-sheet detail is created with the entry's hours
        ResponseJson := Argument.GetResponseJson();
        LibraryAssert.AreEqual('Created', ReadText(ResponseJson, 'result'), 'First sync should create a time-sheet detail.');
        TimeSheetDetail.SetRange("Time Sheet No.", TimeSheetNo);
        LibraryAssert.AreEqual(1, TimeSheetDetail.Count(), 'One time-sheet detail should exist.');
        TimeSheetDetail.FindFirst();
        LibraryAssert.AreEqual(4, TimeSheetDetail.Quantity, 'The detail quantity should be the entry hours.');
    end;

    [Test]
    procedure SyncRangeToTimeSheetCreatesDetailsForEntries()
    var
        TimeSheetDetail: Record "Time Sheet Detail";
        Argument: Record "Message Argument ori";
        MockState: Codeunit "Clockify Mock State";
        JobNo: Code[20];
        JobTaskNo: Code[20];
        ResourceNo: Code[20];
        WorkTypeCode: Code[10];
        TemplateName: Code[10];
        BatchName: Code[10];
        TimeSheetNo: Code[20];
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
    begin
        // [GIVEN] Mappings, an open sheet, and Clockify returns two finished entries
        CreateSyncEnvironment(JobNo, JobTaskNo, ResourceNo, WorkTypeCode, TemplateName, BatchName);
        TimeSheetNo := CreateOpenTimeSheet(ResourceNo, DMY2Date(1, 6, 2026), DMY2Date(30, 6, 2026));
        UseMockApi();
        MockState.SetNextResponse(true, 200,
            '[{"id":"E1","description":"Work A","projectId":"CPROJ","taskId":"CTASK","billable":true,"tagIds":["CTAG"],"timeInterval":{"start":"2026-06-09T08:00:00Z","end":"2026-06-09T12:00:00Z"}},' +
            '{"id":"E2","description":"Work B","projectId":"CPROJ","taskId":"CTASK","billable":true,"tagIds":["CTAG"],"timeInterval":{"start":"2026-06-10T08:00:00Z","end":"2026-06-10T10:00:00Z"}}]');
        RequestJson.Add('workspaceId', 'WS1');
        RequestJson.Add('userId', 'CUSER');
        RequestJson.Add('start', '2026-06-01T00:00:00Z');
        RequestJson.Add('end', '2026-06-30T23:59:59Z');

        // [WHEN] Clockify.TimeEntry.SyncRangeToTimeSheet runs
        ExecuteTypeWithRequest(Argument, Argument."Type"::"Clockify.TimeEntry.SyncRangeToTimeSheet", RequestJson);

        // [THEN] Both entries land as time-sheet details
        ResponseJson := Argument.GetResponseJson();
        LibraryAssert.AreEqual(2, ReadInt(ResponseJson, 'processed'), 'Both entries should be processed.');
        LibraryAssert.AreEqual(2, ReadInt(ResponseJson, 'created'), 'Both entries should be created.');
        TimeSheetDetail.SetRange("Time Sheet No.", TimeSheetNo);
        LibraryAssert.AreEqual(2, TimeSheetDetail.Count(), 'One detail should exist per synced entry.');
    end;

    [Test]
    procedure SyncRangeToTimeSheetPerEntryErrorDoesNotAbort()
    var
        Argument: Record "Message Argument ori";
        MockState: Codeunit "Clockify Mock State";
        JobNo: Code[20];
        JobTaskNo: Code[20];
        ResourceNo: Code[20];
        WorkTypeCode: Code[10];
        TemplateName: Code[10];
        BatchName: Code[10];
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
    begin
        // [GIVEN] Two entries where the second references an unmapped project
        CreateSyncEnvironment(JobNo, JobTaskNo, ResourceNo, WorkTypeCode, TemplateName, BatchName);
        CreateOpenTimeSheet(ResourceNo, DMY2Date(1, 6, 2026), DMY2Date(30, 6, 2026));
        UseMockApi();
        MockState.SetNextResponse(true, 200,
            '[{"id":"E1","description":"Work A","projectId":"CPROJ","taskId":"CTASK","billable":true,"tagIds":["CTAG"],"timeInterval":{"start":"2026-06-09T08:00:00Z","end":"2026-06-09T12:00:00Z"}},' +
            '{"id":"E2","description":"Work B","projectId":"UNMAPPED","taskId":"CTASK","billable":true,"tagIds":["CTAG"],"timeInterval":{"start":"2026-06-10T08:00:00Z","end":"2026-06-10T10:00:00Z"}}]');
        RequestJson.Add('workspaceId', 'WS1');
        RequestJson.Add('userId', 'CUSER');
        RequestJson.Add('start', '2026-06-01T00:00:00Z');
        RequestJson.Add('end', '2026-06-30T23:59:59Z');

        // [WHEN] Clockify.TimeEntry.SyncRangeToTimeSheet runs
        ExecuteTypeWithRequest(Argument, Argument."Type"::"Clockify.TimeEntry.SyncRangeToTimeSheet", RequestJson);

        // [THEN] The mapped entry syncs while the unmapped one is counted as an error
        ResponseJson := Argument.GetResponseJson();
        LibraryAssert.AreEqual(2, ReadInt(ResponseJson, 'processed'), 'Both entries should be processed.');
        LibraryAssert.AreEqual(1, ReadInt(ResponseJson, 'created'), 'Only the mapped entry should be created.');
        LibraryAssert.AreEqual(1, ReadInt(ResponseJson, 'errors'), 'The unmapped entry should be an error.');
    end;

    [Test]
    procedure SyncAllUsersSyncsMappedUserToTimeSheet()
    var
        TimeSheetDetail: Record "Time Sheet Detail";
        Argument: Record "Message Argument ori";
        MockState: Codeunit "Clockify Mock State";
        JobNo: Code[20];
        JobTaskNo: Code[20];
        ResourceNo: Code[20];
        WorkTypeCode: Code[10];
        TemplateName: Code[10];
        BatchName: Code[10];
        TimeSheetNo: Code[20];
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
    begin
        // [GIVEN] One mapped user (CUSER) with an open sheet, and Clockify returns one entry
        CreateSyncEnvironment(JobNo, JobTaskNo, ResourceNo, WorkTypeCode, TemplateName, BatchName);
        TimeSheetNo := CreateOpenTimeSheet(ResourceNo, DMY2Date(1, 6, 2026), DMY2Date(30, 6, 2026));
        UseMockApi();
        MockState.SetNextResponse(true, 200,
            '[{"id":"E1","description":"Work A","projectId":"CPROJ","taskId":"CTASK","billable":true,"tagIds":["CTAG"],"timeInterval":{"start":"2026-06-09T08:00:00Z","end":"2026-06-09T12:00:00Z"}}]');
        RequestJson.Add('workspaceId', 'WS1');
        RequestJson.Add('start', '2026-06-01T00:00:00Z');
        RequestJson.Add('end', '2026-06-30T23:59:59Z');
        RequestJson.Add('target', 'timesheet');

        // [WHEN] Clockify.TimeEntry.SyncAllUsers runs (no userId — auto-discovered)
        ExecuteTypeWithRequest(Argument, Argument."Type"::"Clockify.TimeEntry.SyncAllUsers", RequestJson);

        // [THEN] The mapped user's entry lands on the time sheet
        ResponseJson := Argument.GetResponseJson();
        LibraryAssert.AreEqual(1, ReadInt(ResponseJson, 'users'), 'Exactly one mapped user should be processed.');
        LibraryAssert.AreEqual(1, ReadInt(ResponseJson, 'created'), 'The user''s entry should be created.');
        TimeSheetDetail.SetRange("Time Sheet No.", TimeSheetNo);
        LibraryAssert.AreEqual(1, TimeSheetDetail.Count(), 'One time-sheet detail should exist.');
    end;

    [Test]
    procedure ReverseFromTimeSheetRemovesOpenDetail()
    var
        TimeSheetDetail: Record "Time Sheet Detail";
        TimeSheetSync: Codeunit "Clockify TimeSheet Sync ori";
        JobNo: Code[20];
        JobTaskNo: Code[20];
        ResourceNo: Code[20];
        WorkTypeCode: Code[10];
        TemplateName: Code[10];
        BatchName: Code[10];
        TimeSheetNo: Code[20];
        TagIds: List of [Text];
        SyncResult: Enum "Clockify Sync Result ori";
        Msg: Text;
    begin
        // [GIVEN] A time entry synced to an open time sheet
        CreateSyncEnvironment(JobNo, JobTaskNo, ResourceNo, WorkTypeCode, TemplateName, BatchName);
        TimeSheetNo := CreateOpenTimeSheet(ResourceNo, DMY2Date(1, 6, 2026), DMY2Date(30, 6, 2026));
        TimeSheetSync.SyncTimeEntryToTimeSheet('E1', 'WS1', 'CUSER', 'CPROJ', 'CTASK', 'Work A', DMY2Date(9, 6, 2026), 4, true, TagIds, Msg);
        TimeSheetDetail.SetRange("Time Sheet No.", TimeSheetNo);
        LibraryAssert.AreEqual(1, TimeSheetDetail.Count(), 'The detail should exist before reversal.');

        // [WHEN] A TIME_ENTRY_DELETED reversal is processed
        SyncResult := TimeSheetSync.ReverseFromTimeSheet('E1', Msg);

        // [THEN] The detail is removed from the open sheet
        LibraryAssert.AreEqual(Enum::"Clockify Sync Result ori"::Updated, SyncResult, 'Reversing an open-sheet entry should remove the detail.');
        TimeSheetDetail.SetRange("Time Sheet No.", TimeSheetNo);
        LibraryAssert.IsTrue(TimeSheetDetail.IsEmpty(), 'The time-sheet detail should have been deleted.');
    end;

    local procedure CreateOpenTimeSheet(ResourceNo: Code[20]; StartingDate: Date; EndingDate: Date) TimeSheetNo: Code[20]
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
    begin
        TimeSheetNo := CopyStr(DelChr(Format(CreateGuid(), 0, 4), '=', '{}-'), 1, MaxStrLen(TimeSheetNo));
        TimeSheetHeader.Init();
        TimeSheetHeader."No." := TimeSheetNo;
        TimeSheetHeader."Resource No." := ResourceNo;
        TimeSheetHeader."Starting Date" := StartingDate;
        TimeSheetHeader."Ending Date" := EndingDate;
        TimeSheetHeader.Insert(false);
        // An open line makes the header's "Open Exists" flowfield true so the sync can target it.
        TimeSheetLine.Init();
        TimeSheetLine."Time Sheet No." := TimeSheetNo;
        TimeSheetLine."Line No." := 10000;
        TimeSheetLine."Time Sheet Starting Date" := StartingDate;
        TimeSheetLine.Type := TimeSheetLine.Type::Job;
        TimeSheetLine.Status := TimeSheetLine.Status::Open;
        TimeSheetLine.Insert(false, true);
    end;

    local procedure CreateSyncEnvironment(var JobNo: Code[20]; var JobTaskNo: Code[20]; var ResourceNo: Code[20]; var WorkTypeCode: Code[10]; var TemplateName: Code[10]; var BatchName: Code[10])
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        Resource: Record Resource;
        WorkType: Record "Work Type";
        JobJournalTemplate: Record "Job Journal Template";
        JobJournalBatch: Record "Job Journal Batch";
        Integration: Record "Clockify Integration ori";
        ClockifySetup: Record "Clockify Setup ori";
        LibraryJob: Codeunit "Library - Job";
        LibraryResource: Codeunit "Library - Resource";
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryResource.CreateResourceNew(Resource);
        LibraryResource.CreateWorkType(WorkType);
        LibraryJob.CreateJobJournalTemplate(JobJournalTemplate);
        LibraryJob.CreateJobJournalBatch(JobJournalTemplate.Name, JobJournalBatch);

        JobNo := Job."No.";
        JobTaskNo := JobTask."Job Task No.";
        ResourceNo := Resource."No.";
        WorkTypeCode := WorkType.Code;
        TemplateName := JobJournalTemplate.Name;
        BatchName := JobJournalBatch.Name;

        // Link the Clockify objects the sync expects: PROJECT->Job, TASK->Job Task,
        // USER->Resource, TAG->Work Type.
        Integration.DeleteAll();
        InsertIntegrationLink('PROJECT', 'CPROJ', JobNo);
        InsertIntegrationLink('TASK', 'CTASK', JobNo + '-' + JobTaskNo);
        InsertIntegrationLink('USER', 'CUSER', ResourceNo);
        InsertIntegrationLink('TAG', 'CTAG', WorkTypeCode);

        if not ClockifySetup.Get() then
            ClockifySetup.Insert();
        ClockifySetup."Job Jnl. Template" := TemplateName;
        ClockifySetup."Job Jnl. Batch" := BatchName;
        ClockifySetup."Default Work Type" := '';
        ClockifySetup.Modify();
    end;

    local procedure InsertIntegrationLink(ClockifyType: Text; ClockifyId: Text; BCCode: Text)
    var
        Integration: Record "Clockify Integration ori";
    begin
        Integration.Init();
        Integration."Clockify Type" := CopyStr(ClockifyType, 1, MaxStrLen(Integration."Clockify Type"));
        Integration."Clockify Id" := CopyStr(ClockifyId, 1, MaxStrLen(Integration."Clockify Id"));
        Integration."BC Code" := CopyStr(BCCode, 1, MaxStrLen(Integration."BC Code"));
        Integration."Reversed" := false;
        Integration.Insert(true);
    end;

    local procedure UseMockApi()
    var
        ClockifySetup: Record "Clockify Setup ori";
        MockState: Codeunit "Clockify Mock State";
    begin
        MockState.Reset();
        if not ClockifySetup.Get() then begin
            ClockifySetup.Init();
            ClockifySetup.Insert();
        end;
        ClockifySetup."API Version" := ClockifySetup."API Version"::Mock;
        ClockifySetup.Modify();
    end;

    local procedure ExecuteType(var Argument: Record "Message Argument ori"; MessageType: Enum "Message Type ori")
    var
        RequestJson: JsonObject;
    begin
        ExecuteTypeWithRequest(Argument, MessageType, RequestJson);
    end;

    local procedure ExecuteTypeWithRequest(var Argument: Record "Message Argument ori"; MessageType: Enum "Message Type ori"; RequestJson: JsonObject)
    var
        MsgInterface: Interface "Msg Interface ori";
    begin
        Argument.Init();
        Argument."Type" := MessageType;
        Argument.Insert();
        Argument.SetRequestJson(RequestJson);
        MsgInterface := Argument.GetMessageTypeInterface();
        MsgInterface.ExecuteBifrostTask(Argument);
    end;

    local procedure ReadText(JsonObj: JsonObject; PropertyName: Text): Text
    var
        Token: JsonToken;
    begin
        if not JsonObj.Get(PropertyName, Token) then
            exit('');
        if not Token.IsValue() then
            exit('');
        exit(Token.AsValue().AsText());
    end;

    local procedure ReadInt(JsonObj: JsonObject; PropertyName: Text): Integer
    var
        Token: JsonToken;
    begin
        if not JsonObj.Get(PropertyName, Token) then
            exit(0);
        if not Token.IsValue() then
            exit(0);
        exit(Token.AsValue().AsInteger());
    end;

    local procedure HasKey(JsonObj: JsonObject; PropertyName: Text): Boolean
    var
        Token: JsonToken;
    begin
        exit(JsonObj.Get(PropertyName, Token));
    end;
}
