namespace Origo.Bifrost.Timesheets;

using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.Customer;
using System.Reflection;

/// <summary>
/// Builds the three phone Role Center customer lists. Current customers are the
/// signed-in user's My Customers. Today and last workday come from that user's
/// Clockify time entries. A missing resource, mapping, workspace or API key
/// leaves the time lists empty and does not raise an error.
/// </summary>
codeunit 10036858 "Phone Cust Buffer Mgt ori"
{
    Access = Internal;

    /// <summary>
    /// Resolves the resource whose time sheet owner is the signed-in user.
    /// </summary>
    /// <param name="ResourceNo">Out: the resource number. Unchanged when none is mapped.</param>
    /// <returns>True when a resource is mapped to <c>UserId</c>.</returns>
    procedure ResolveCurrentResource(var ResourceNo: Code[20]): Boolean
    var
        Resource: Record Resource;
    begin
        Resource.SetLoadFields("No.", "Time Sheet Owner User ID");
        Resource.SetRange("Time Sheet Owner User ID", UserId());
        if not Resource.FindFirst() then
            exit(false);
        ResourceNo := Resource."No.";
        exit(true);
    end;

    /// <summary>
    /// Resolves the active Clockify user id mapped to a resource.
    /// </summary>
    /// <param name="ResourceNo">The Business Central resource number.</param>
    /// <param name="ClockifyUserId">Out: the Clockify user id. Unchanged when no mapping exists.</param>
    /// <returns>True when an active USER mapping exists.</returns>
    procedure ResolveClockifyUserId(ResourceNo: Code[20]; var ClockifyUserId: Text[50]): Boolean
    var
        Integration: Record "Clockify Integration ori";
    begin
        if ResourceNo = '' then
            exit(false);
        Integration.ReadIsolation := IsolationLevel::ReadCommitted;
        Integration.SetRange("Clockify Type", 'USER');
        Integration.SetRange("BC Code", ResourceNo);
        Integration.SetRange(Reversed, false);
        Integration.SetLoadFields("Clockify Id");
        if not Integration.FindFirst() then
            exit(false);
        ClockifyUserId := CopyStr(Integration."Clockify Id", 1, MaxStrLen(ClockifyUserId));
        exit(ClockifyUserId <> '');
    end;

    /// <summary>
    /// Returns the previous Monday-to-Friday date. Saturday and Sunday are skipped,
    /// so a Monday resolves to the Friday before it.
    /// </summary>
    /// <param name="FromDate">The date to step back from.</param>
    /// <returns>The previous working day, or 0D when <paramref name="FromDate"/> is blank.</returns>
    procedure ResolveLastWorkday(FromDate: Date): Date
    var
        Candidate: Date;
        DayOfWeek: Integer;
    begin
        if FromDate = 0D then
            exit(0D);
        Candidate := CalcDate('<-1D>', FromDate);
        DayOfWeek := Date2DWY(Candidate, 1);
        while DayOfWeek in [6, 7] do begin
            Candidate := CalcDate('<-1D>', Candidate);
            DayOfWeek := Date2DWY(Candidate, 1);
        end;
        exit(Candidate);
    end;

    /// <summary>
    /// Fills the current-customer list from My Customers for the signed-in user.
    /// An open job for that bill-to customer, when one exists, is stored so Add can
    /// write the job and its first job task on the sales line.
    /// </summary>
    /// <param name="Buffer">Temporary buffer. Existing Current rows are replaced.</param>
    procedure PopulateCurrentCustomers(var Buffer: Record "Phone Cust Buffer ori" temporary)
    var
        MyCustomer: Record "My Customer";
        Customer: Record Customer;
    begin
        ClearBucket(Buffer, Enum::"Phone Cust Bucket ori"::Current);
        MyCustomer.SetRange("User ID", UserId());
        MyCustomer.SetLoadFields("Customer No.");
        if MyCustomer.FindSet() then
            repeat
                Customer.SetLoadFields("No.", Name);
                if Customer.Get(MyCustomer."Customer No.") then
                    InsertCustomer(Buffer, Enum::"Phone Cust Bucket ori"::Current, Customer."No.", Customer.Name, OpenJobNo(Customer."No."), '', 0);
            until MyCustomer.Next() = 0;
    end;

    /// <summary>
    /// Fills the today list from the signed-in user's finished Clockify entries for
    /// the work date, plus the one still-running timer when Clockify returns it.
    /// </summary>
    /// <param name="Buffer">Temporary buffer. Existing Today rows are replaced.</param>
    procedure PopulateTodayCustomers(var Buffer: Record "Phone Cust Buffer ori" temporary)
    var
        RangeStart: DateTime;
        RangeEnd: DateTime;
    begin
        ClearBucket(Buffer, Enum::"Phone Cust Bucket ori"::Today);
        RangeStart := CreateDateTime(WorkDate(), 000000T);
        RangeEnd := CurrentDateTime();
        if RangeEnd < RangeStart then
            RangeEnd := CreateDateTime(WorkDate(), 235959T);
        PopulateTimeCustomers(Buffer, Enum::"Phone Cust Bucket ori"::Today, RangeStart, RangeEnd, true);
    end;

    /// <summary>
    /// Fills the last-workday list from finished Clockify entries on the previous
    /// Monday-to-Friday date. An empty Clockify day leaves the list empty.
    /// </summary>
    /// <param name="Buffer">Temporary buffer. Existing LastWorkday rows are replaced.</param>
    procedure PopulateLastWorkdayCustomers(var Buffer: Record "Phone Cust Buffer ori" temporary)
    var
        Workday: Date;
        RangeStart: DateTime;
        RangeEnd: DateTime;
    begin
        ClearBucket(Buffer, Enum::"Phone Cust Bucket ori"::LastWorkday);
        Workday := ResolveLastWorkday(WorkDate());
        if Workday = 0D then
            exit;
        RangeStart := CreateDateTime(Workday, 000000T);
        RangeEnd := CreateDateTime(Workday, 235959T);
        PopulateTimeCustomers(Buffer, Enum::"Phone Cust Bucket ori"::LastWorkday, RangeStart, RangeEnd, false);
    end;

    local procedure PopulateTimeCustomers(var Buffer: Record "Phone Cust Buffer ori" temporary; Bucket: Enum "Phone Cust Bucket ori"; RangeStart: DateTime; RangeEnd: DateTime; IncludeRunning: Boolean)
    var
        SecretMgt: Codeunit "Clockify Secret Mgt ori";
        ResourceNo: Code[20];
        ClockifyUserId: Text[50];
        WorkspaceId: Text[50];
        Entries: JsonArray;
    begin
        if not ResolveCurrentResource(ResourceNo) then
            exit;
        if not ResolveClockifyUserId(ResourceNo, ClockifyUserId) then
            exit;
        if not TryGetDefaultWorkspace(WorkspaceId) then
            exit;
        if not SecretMgt.HasCompanyApiKey() then
            exit;
        if not TryGetTimeEntries(WorkspaceId, ClockifyUserId, RangeStart, RangeEnd, false, Entries) then
            exit;
        AddEntries(Buffer, Bucket, Entries);
        if not IncludeRunning then
            exit;
        Clear(Entries);
        if not TryGetTimeEntries(WorkspaceId, ClockifyUserId, 0DT, 0DT, true, Entries) then
            exit;
        AddEntries(Buffer, Bucket, Entries);
    end;

    local procedure TryGetDefaultWorkspace(var WorkspaceId: Text[50]): Boolean
    var
        ClockifySetup: Record "Clockify Setup ori";
    begin
        WorkspaceId := '';
        if not ClockifySetup.Get() then
            exit(false);
        if ClockifySetup."Default Workspace" = '' then
            exit(false);
        WorkspaceId := CopyStr(ClockifySetup."Default Workspace", 1, MaxStrLen(WorkspaceId));
        exit(true);
    end;

    local procedure TryGetTimeEntries(WorkspaceId: Text[50]; ClockifyUserId: Text[50]; RangeStart: DateTime; RangeEnd: DateTime; InProgress: Boolean; var Entries: JsonArray): Boolean
    var
        RequestMgt: Codeunit "Clockify Request Mgt ori";
        TypeHelper: Codeunit "Type Helper";
        ApiClient: Interface "Clockify API Client ori";
        PageToken: JsonToken;
        ResourcePath: Text;
        ResponseBody: Text;
        StartText: Text;
        EndText: Text;
        StatusCode: Integer;
    begin
        Clear(Entries);
        ResourcePath := '/workspaces/' + WorkspaceId + '/user/' + ClockifyUserId + '/time-entries?';
        if InProgress then
            ResourcePath += 'in-progress=true'
        else begin
            StartText := Format(RangeStart, 0, 9);
            EndText := Format(RangeEnd, 0, 9);
            ResourcePath +=
                'start=' + TypeHelper.UrlEncode(StartText) +
                '&end=' + TypeHelper.UrlEncode(EndText) +
                '&in-progress=false&page-size=200';
        end;
        ApiClient := RequestMgt.GetApiClient();
        if not ApiClient.Send('GET', ResourcePath, false, '', ResponseBody, StatusCode) then
            exit(false);
        if ResponseBody = '' then
            exit(true);
        if not PageToken.ReadFrom(ResponseBody) then
            exit(false);
        if not PageToken.IsArray() then
            exit(false);
        Entries := PageToken.AsArray();
        exit(true);
    end;

    local procedure AddEntries(var Buffer: Record "Phone Cust Buffer ori" temporary; Bucket: Enum "Phone Cust Bucket ori"; Entries: JsonArray)
    var
        TimeEntrySync: Codeunit "Clockify Time Entry Sync ori";
        Parse: Codeunit "Clockify TimeEntry Parse ori";
        EntryToken: JsonToken;
        EntryObject: JsonObject;
        IntervalToken: JsonToken;
        IntervalObject: JsonObject;
        ProjectId: Text[50];
        TaskId: Text[50];
        StartText: Text;
        EndText: Text;
        JobNo: Code[20];
        JobTaskNo: Code[20];
        CustomerNo: Code[20];
        CustomerName: Text[100];
        Hours: Decimal;
    begin
        foreach EntryToken in Entries do begin
            if not EntryToken.IsObject() then
                continue;
            EntryObject := EntryToken.AsObject();
            ProjectId := CopyStr(Parse.GetText(EntryObject, 'projectId'), 1, MaxStrLen(ProjectId));
            TaskId := CopyStr(Parse.GetText(EntryObject, 'taskId'), 1, MaxStrLen(TaskId));
            StartText := '';
            EndText := '';
            if EntryObject.Get('timeInterval', IntervalToken) then
                if IntervalToken.IsObject() then begin
                    IntervalObject := IntervalToken.AsObject();
                    StartText := Parse.GetText(IntervalObject, 'start');
                    EndText := Parse.GetText(IntervalObject, 'end');
                end;
            if not TimeEntrySync.ResolveProjectMapping(ProjectId, JobNo) then
                continue;
            JobTaskNo := '';
            if TaskId <> '' then
                TimeEntrySync.ResolveTaskMapping(TaskId, JobTaskNo);
            if not CustomerFromJob(JobNo, CustomerNo, CustomerName, JobTaskNo) then
                continue;
            Hours := Parse.CalculateHours(StartText, EndText);
            InsertCustomer(Buffer, Bucket, CustomerNo, CustomerName, JobNo, JobTaskNo, Hours);
        end;
    end;

    local procedure CustomerFromJob(JobNo: Code[20]; var CustomerNo: Code[20]; var CustomerName: Text[100]; var JobTaskNo: Code[20]): Boolean
    var
        Job: Record Job;
        Customer: Record Customer;
    begin
        CustomerNo := '';
        CustomerName := '';
        Job.SetLoadFields("No.", "Bill-to Customer No.");
        if not Job.Get(JobNo) then
            exit(false);
        if Job."Bill-to Customer No." = '' then
            exit(false);
        Customer.SetLoadFields("No.", Name);
        if not Customer.Get(Job."Bill-to Customer No.") then
            exit(false);
        CustomerNo := Customer."No.";
        CustomerName := CopyStr(Customer.Name, 1, MaxStrLen(CustomerName));
        if JobTaskNo = '' then
            JobTaskNo := FirstJobTaskNo(JobNo);
        exit(true);
    end;

    local procedure OpenJobNo(CustomerNo: Code[20]): Code[20]
    var
        Job: Record Job;
    begin
        Job.SetLoadFields("No.", "Bill-to Customer No.", Status);
        Job.SetRange("Bill-to Customer No.", CustomerNo);
        Job.SetFilter(Status, '<>%1', Job.Status::Completed);
        if Job.FindFirst() then
            exit(Job."No.");
        exit('');
    end;

    local procedure FirstJobTaskNo(JobNo: Code[20]): Code[20]
    var
        JobTask: Record "Job Task";
    begin
        JobTask.SetLoadFields("Job No.", "Job Task No.");
        JobTask.SetRange("Job No.", JobNo);
        if JobTask.FindFirst() then
            exit(JobTask."Job Task No.");
        exit('');
    end;

    local procedure InsertCustomer(var Buffer: Record "Phone Cust Buffer ori" temporary; Bucket: Enum "Phone Cust Bucket ori"; CustomerNo: Code[20]; CustomerName: Text[100]; JobNo: Code[20]; JobTaskNo: Code[20]; Hours: Decimal)
    var
        NextEntryNo: Integer;
    begin
        if CustomerNo = '' then
            exit;
        Buffer.Reset();
        Buffer.SetRange(Bucket, Bucket);
        Buffer.SetRange("Customer No.", CustomerNo);
        if Buffer.FindFirst() then begin
            Buffer."Hours Today" += Hours;
            if (Buffer."Job No." = '') and (JobNo <> '') then
                Buffer."Job No." := JobNo;
            if (Buffer."Job Task No." = '') and (JobTaskNo <> '') then
                Buffer."Job Task No." := JobTaskNo;
            Buffer.Modify();
            Buffer.Reset();
            exit;
        end;
        Buffer.Reset();
        if Buffer.FindLast() then
            NextEntryNo := Buffer."Entry No." + 1
        else
            NextEntryNo := 1;
        Buffer.Init();
        Buffer."Entry No." := NextEntryNo;
        Buffer.Bucket := Bucket;
        Buffer."Customer No." := CustomerNo;
        Buffer."Customer Name" := CustomerName;
        Buffer."Job No." := JobNo;
        if JobTaskNo = '' then
            JobTaskNo := FirstJobTaskNo(JobNo);
        Buffer."Job Task No." := JobTaskNo;
        Buffer."Hours Today" := Hours;
        Buffer.Insert();
        Buffer.Reset();
    end;

    local procedure ClearBucket(var Buffer: Record "Phone Cust Buffer ori" temporary; Bucket: Enum "Phone Cust Bucket ori")
    begin
        Buffer.Reset();
        Buffer.SetRange(Bucket, Bucket);
        Buffer.DeleteAll();
        Buffer.Reset();
    end;
}
