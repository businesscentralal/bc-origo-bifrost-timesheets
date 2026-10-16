namespace Origo.Bifrost.Timesheets.Test;

using Microsoft.Inventory.Item;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Origo.Bifrost.Timesheets;
using System.TestLibraries.Utilities;

/// <summary>
/// Tests the phone Role Center lists and the sales-invoice add. Clockify calls
/// go through the mock API client. The 30 September decisions replace the open-job
/// current-customer rule with My Customers, and the add writes a sales invoice.
/// </summary>
codeunit 95615 "Phone Role Center Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryAssert: Codeunit "Library Assert";

    [Test]
    procedure ResolveCurrentResource_UserMapped_ReturnsResourceNo()
    var
        BufferMgt: Codeunit "Phone Cust Buffer Mgt ori";
        ResourceNo: Code[20];
        ExpectedNo: Code[20];
    begin
        Initialize();
        ExpectedNo := CreateResourceForCurrentUser();

        LibraryAssert.IsTrue(BufferMgt.ResolveCurrentResource(ResourceNo), 'A resource owned by the current user should resolve.');
        LibraryAssert.AreEqual(ExpectedNo, ResourceNo, 'The resolved resource should be the one mapped to the current user.');
    end;

    [Test]
    procedure ResolveCurrentResource_UserNotMapped_ReturnsFalse()
    var
        BufferMgt: Codeunit "Phone Cust Buffer Mgt ori";
        ResourceNo: Code[20];
    begin
        Initialize();
        ClearCurrentUserResources();

        LibraryAssert.IsFalse(BufferMgt.ResolveCurrentResource(ResourceNo), 'No resource should resolve when the user is not a time sheet owner.');
    end;

    [Test]
    procedure PopulateTodayCustomers_NoApiKey_ReturnsEmpty()
    var
        TempBuffer: Record "Phone Cust Buffer ori" temporary;
        BufferMgt: Codeunit "Phone Cust Buffer Mgt ori";
        SecretMgt: Codeunit "Clockify Secret Mgt ori";
        MockState: Codeunit "Clockify Mock State";
    begin
        Initialize();
        CreateResourceForCurrentUser();
        UseMockApi();
        SecretMgt.ClearCompanyApiKey();

        BufferMgt.PopulateTodayCustomers(TempBuffer);

        LibraryAssert.IsTrue(TempBuffer.IsEmpty(), 'Today should be empty when no company API key is stored.');
        LibraryAssert.AreEqual(0, MockState.CapturedPathCount(), 'No Clockify call should be made without an API key.');
    end;

    [Test]
    procedure PopulateTodayCustomers_FinishedEntryToday_ReturnsCustomer()
    var
        TempBuffer: Record "Phone Cust Buffer ori" temporary;
        BufferMgt: Codeunit "Phone Cust Buffer Mgt ori";
        MockState: Codeunit "Clockify Mock State";
        CustomerNo: Code[20];
    begin
        Initialize();
        CustomerNo := CreateMappedJob('P-PHONE', 'T-PHONE');
        UseMockApi();
        MockState.EnqueueResponse(true, 200, FinishedEntryJson('P-PHONE', 'T-PHONE', '2026-10-16T08:00:00Z', '2026-10-16T10:00:00Z'));
        MockState.EnqueueResponse(true, 200, '[]');

        BufferMgt.PopulateTodayCustomers(TempBuffer);

        TempBuffer.SetRange("Customer No.", CustomerNo);
        LibraryAssert.IsTrue(TempBuffer.FindFirst(), 'The job bill-to customer should be in the Today list.');
        LibraryAssert.AreEqual(2.0, TempBuffer."Hours Today", 'Two finished hours should be stored.');
        LibraryAssert.IsTrue(MockState.CapturedPathContains('in-progress=false'), 'Finished entries should be requested.');
        LibraryAssert.IsTrue(MockState.CapturedPathContains('in-progress=true'), 'The running timer should be requested as well.');
    end;

    [Test]
    procedure PopulateTodayCustomers_RunningEntry_ReturnsCustomer()
    var
        TempBuffer: Record "Phone Cust Buffer ori" temporary;
        BufferMgt: Codeunit "Phone Cust Buffer Mgt ori";
        MockState: Codeunit "Clockify Mock State";
        CustomerNo: Code[20];
    begin
        Initialize();
        CustomerNo := CreateMappedJob('P-RUN', 'T-RUN');
        UseMockApi();
        MockState.EnqueueResponse(true, 200, '[]');
        MockState.EnqueueResponse(true, 200, RunningEntryJson('P-RUN'));

        BufferMgt.PopulateTodayCustomers(TempBuffer);

        TempBuffer.SetRange("Customer No.", CustomerNo);
        LibraryAssert.IsTrue(TempBuffer.FindFirst(), 'A running timer should still put the customer on the Today list.');
        LibraryAssert.AreEqual(0.0, TempBuffer."Hours Today", 'A running timer contributes zero hours.');
        LibraryAssert.IsTrue(MockState.CapturedPathContains('in-progress=true'), 'The in-progress request should be sent.');
    end;

    [Test]
    procedure PopulateTodayCustomers_TwoJobsSameCustomer_Dedupes()
    var
        Job: Record Job;
        Job2: Record Job;
        TempBuffer: Record "Phone Cust Buffer ori" temporary;
        BufferMgt: Codeunit "Phone Cust Buffer Mgt ori";
        MockState: Codeunit "Clockify Mock State";
        LibraryJob: Codeunit "Library - Job";
        CustomerNo: Code[20];
    begin
        Initialize();
        CustomerNo := CreateMappedJob('P-ONE', 'T-ONE');
        LibraryJob.CreateJob(Job2);
        Job2.Validate("Bill-to Customer No.", CustomerNo);
        Job2.Modify(true);
        InsertIntegrationLink('PROJECT', 'P-TWO', Job2."No.");
        UseMockApi();
        MockState.EnqueueResponse(true, 200,
            '[' + FinishedEntryBody('E1', 'P-ONE', 'T-ONE', '2026-10-16T08:00:00Z', '2026-10-16T10:00:00Z') + ',' +
            FinishedEntryBody('E2', 'P-TWO', '', '2026-10-16T10:00:00Z', '2026-10-16T11:00:00Z') + ']');
        MockState.EnqueueResponse(true, 200, '[]');

        BufferMgt.PopulateTodayCustomers(TempBuffer);

        TempBuffer.SetRange("Customer No.", CustomerNo);
        LibraryAssert.AreEqual(1, TempBuffer.Count(), 'Two jobs for one customer should be one Today row.');
        TempBuffer.FindFirst();
        LibraryAssert.AreEqual(3.0, TempBuffer."Hours Today", 'Hours from both jobs should be added.');
        Job.Get(TempBuffer."Job No.");
    end;

    [Test]
    procedure PopulateCurrentCustomers_UsesMyCustomers()
    var
        Customer: Record Customer;
        OtherCustomer: Record Customer;
        MyCustomer: Record "My Customer";
        Job: Record Job;
        TempBuffer: Record "Phone Cust Buffer ori" temporary;
        BufferMgt: Codeunit "Phone Cust Buffer Mgt ori";
        LibraryJob: Codeunit "Library - Job";
        LibrarySales: Codeunit "Library - Sales";
    begin
        // [GIVEN] The 30 September decision: current customers are My Customers, not every open job.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomer(OtherCustomer);
        MyCustomer.Init();
        MyCustomer."User ID" := CopyStr(UserId(), 1, MaxStrLen(MyCustomer."User ID"));
        MyCustomer."Customer No." := Customer."No.";
        MyCustomer.Insert();
        LibraryJob.CreateJob(Job);
        Job.Validate("Bill-to Customer No.", OtherCustomer."No.");
        Job.Modify(true);

        BufferMgt.PopulateCurrentCustomers(TempBuffer);

        TempBuffer.SetRange("Customer No.", Customer."No.");
        LibraryAssert.IsTrue(TempBuffer.FindFirst(), 'A My Customer row should appear on the current list.');
        TempBuffer.SetRange("Customer No.", OtherCustomer."No.");
        LibraryAssert.IsTrue(TempBuffer.IsEmpty(), 'An open job whose customer is not in My Customers should not appear.');
    end;

    [Test]
    procedure ResolveLastWorkday_Monday_ReturnsFriday()
    var
        BufferMgt: Codeunit "Phone Cust Buffer Mgt ori";
    begin
        Initialize();
        WorkDate(DMY2Date(12, 10, 2026));
        LibraryAssert.AreEqual(DMY2Date(9, 10, 2026), BufferMgt.ResolveLastWorkday(WorkDate()), 'The workday before Monday 12 October 2026 is Friday 9 October.');

        WorkDate(DMY2Date(18, 10, 2026));
        LibraryAssert.AreEqual(DMY2Date(16, 10, 2026), BufferMgt.ResolveLastWorkday(WorkDate()), 'The workday before Sunday 18 October 2026 is Friday 16 October.');
    end;

    [Test]
    procedure AddServiceItemLine_ReusesOpenInvoice()
    var
        Customer: Record Customer;
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        MyItem: Record "My Item";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        QuickAdd: Codeunit "Phone Sales Quick Add ori";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryJob: Codeunit "Library - Job";
        LibrarySales: Codeunit "Library - Sales";
        DocumentNo: Code[20];
    begin
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        Item.Validate(Type, Item.Type::Service);
        Item.Modify(true);
        MyItem.Init();
        MyItem."User ID" := CopyStr(UserId(), 1, MaxStrLen(MyItem."User ID"));
        MyItem."Item No." := Item."No.";
        MyItem.Insert();
        LibraryJob.CreateJob(Job);
        Job.Validate("Bill-to Customer No.", Customer."No.");
        Job.Modify(true);
        LibraryJob.CreateJobTask(Job, JobTask);

        QuickAdd.AddServiceItemLine(Customer."No.", Job."No.", JobTask."Job Task No.", Item."No.", 2);

        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.SetRange("Sell-to Customer No.", Customer."No.");
        SalesHeader.SetRange("Phone RC Document ori", true);
        LibraryAssert.IsTrue(SalesHeader.FindFirst(), 'The first add should create a phone sales invoice.');
        DocumentNo := SalesHeader."No.";
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", DocumentNo);
        LibraryAssert.AreEqual(1, SalesLine.Count(), 'The first add should create one sales line.');
        SalesLine.FindFirst();
        LibraryAssert.AreEqual(Item."No.", SalesLine."No.", 'The line should be the chosen item.');
        LibraryAssert.AreEqual(2.0, SalesLine.Quantity, 'The line quantity should be the quantity passed in.');
        LibraryAssert.AreEqual(Job."No.", SalesLine."Job No.", 'The line should carry the job.');
        LibraryAssert.AreEqual(JobTask."Job Task No.", SalesLine."Job Task No.", 'The line should carry the job task.');

        QuickAdd.AddServiceItemLine(Customer."No.", Job."No.", JobTask."Job Task No.", Item."No.", 1);

        SalesHeader.SetRange("No.", DocumentNo);
        LibraryAssert.AreEqual(1, SalesHeader.Count(), 'The second add should reuse the open phone invoice.');
        SalesLine.SetRange("Document No.", DocumentNo);
        LibraryAssert.AreEqual(2, SalesLine.Count(), 'The second add should append a line.');
    end;

    [Test]
    procedure AddServiceItemLine_InvalidItem_Errors()
    var
        Customer: Record Customer;
        QuickAdd: Codeunit "Phone Sales Quick Add ori";
        LibrarySales: Codeunit "Library - Sales";
    begin
        Initialize();
        LibrarySales.CreateCustomer(Customer);

        asserterror QuickAdd.AddServiceItemLine(Customer."No.", '', '', 'NO-SUCH-ITEM', 1);

        LibraryAssert.ExpectedError('not a service item');
    end;

    local procedure Initialize()
    var
        SecretMgt: Codeunit "Clockify Secret Mgt ori";
        MockState: Codeunit "Clockify Mock State";
    begin
        MockState.Reset();
        SecretMgt.ClearCompanyApiKey();
        ClearCurrentUserResources();
    end;

    local procedure ClearCurrentUserResources()
    var
        Resource: Record Resource;
    begin
        Resource.SetRange("Time Sheet Owner User ID", UserId());
        if Resource.FindSet(true) then
            repeat
                Resource."Time Sheet Owner User ID" := '';
                Resource.Modify();
            until Resource.Next() = 0;
    end;

    local procedure CreateResourceForCurrentUser(): Code[20]
    var
        Resource: Record Resource;
        LibraryResource: Codeunit "Library - Resource";
    begin
        LibraryResource.CreateResourceNew(Resource);
        Resource."Time Sheet Owner User ID" := CopyStr(UserId(), 1, MaxStrLen(Resource."Time Sheet Owner User ID"));
        Resource.Modify(true);
        exit(Resource."No.");
    end;

    local procedure CreateMappedJob(ProjectId: Text; TaskId: Text): Code[20]
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        LibraryJob: Codeunit "Library - Job";
        ResourceNo: Code[20];
    begin
        ResourceNo := CreateResourceForCurrentUser();
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        InsertIntegrationLink('USER', 'U-PHONE', ResourceNo);
        InsertIntegrationLink('PROJECT', ProjectId, Job."No.");
        if TaskId <> '' then
            InsertIntegrationLink('TASK', TaskId, Job."No." + '-' + JobTask."Job Task No.");
        exit(Job."Bill-to Customer No.");
    end;

    local procedure InsertIntegrationLink(ClockifyType: Text; ClockifyId: Text; BCCode: Text)
    var
        Integration: Record "Clockify Integration ori";
    begin
        Integration.Init();
        Integration."Clockify Type" := CopyStr(ClockifyType, 1, MaxStrLen(Integration."Clockify Type"));
        Integration."Clockify Id" := CopyStr(ClockifyId, 1, MaxStrLen(Integration."Clockify Id"));
        Integration."BC Code" := CopyStr(BCCode, 1, MaxStrLen(Integration."BC Code"));
        Integration.Reversed := false;
        Integration.Insert(true);
    end;

    local procedure UseMockApi()
    var
        ClockifySetup: Record "Clockify Setup ori";
        SecretMgt: Codeunit "Clockify Secret Mgt ori";
        KeyText: Text;
    begin
        if not ClockifySetup.Get() then begin
            ClockifySetup.Init();
            ClockifySetup.Insert();
        end;
        ClockifySetup."API Version" := ClockifySetup."API Version"::Mock;
        ClockifySetup."Default Workspace" := 'WS-PHONE';
        ClockifySetup.Modify();
        KeyText := 'phone-test-key';
        SecretMgt.SetCompanyApiKey(KeyText);
    end;

    local procedure FinishedEntryJson(ProjectId: Text; TaskId: Text; StartText: Text; EndText: Text): Text
    begin
        exit('[' + FinishedEntryBody('E1', ProjectId, TaskId, StartText, EndText) + ']');
    end;

    local procedure FinishedEntryBody(EntryId: Text; ProjectId: Text; TaskId: Text; StartText: Text; EndText: Text): Text
    begin
        exit('{"id":"' + EntryId + '","projectId":"' + ProjectId + '","taskId":"' + TaskId + '","timeInterval":{"start":"' + StartText + '","end":"' + EndText + '"}}');
    end;

    local procedure RunningEntryJson(ProjectId: Text): Text
    begin
        exit('[{"id":"E-RUN","projectId":"' + ProjectId + '","timeInterval":{"start":"2026-10-16T08:00:00Z","end":null}}]');
    end;
}
