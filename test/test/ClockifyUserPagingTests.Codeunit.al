namespace Origo.Bifrost.Timesheets.Test;

using Origo.Bifrost;
using Origo.Bifrost.Timesheets;
using System.TestLibraries.Utilities;

/// <summary>Verifies bounded mapped-user sync with isolated mappings and a network-free Clockify client.</summary>
codeunit 95604 "Clockify User Paging Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        MockState: Codeunit "Clockify Mock State";

    [Test]
    procedure DefaultPageProcessesOneHundredUsers()
    var
        Request: JsonObject;
        Response: JsonObject;
    begin
        // [GIVEN] More active mappings than the default page size, plus excluded rows.
        Initialize(103);
        AddMapping('ZZTEST-REVERSED', 'USER', true);
        AddMapping('ZZTEST-PROJECT', 'PROJECT', false);
        Request := MakeRequest();
        // [WHEN] No paging parameters are supplied.
        Response := Execute(Request);
        // [THEN] Only the first page is fetched and the total excludes reversed/non-user rows.
        AssertPage(Response, 100, 103, 100, true);
        Assert.AreEqual(100, MockState.GetRequestCount(), 'One fetch per user in the page.');
        AssertUser(Response, 0, UserIdFor(1));
        AssertUser(Response, 99, UserIdFor(100));
    end;

    [Test]
    procedure ZeroTakeUsesDefaultPageSize()
    var
        Request: JsonObject;
        Response: JsonObject;
    begin
        // [GIVEN] A zero take uses Foundation's default, not an unbounded loop.
        Initialize(101);
        Request := MakeRequest();
        Request.Add('take', 0);
        // [WHEN] The page is synced.
        Response := Execute(Request);
        // [THEN] Exactly 100 users are processed.
        AssertPage(Response, 100, 101, 100, true);
        Assert.AreEqual(100, MockState.GetRequestCount(), 'Zero take must be bounded.');
    end;

    [Test]
    procedure NegativeSkipFailsBeforeFetching()
    var
        Request: JsonObject;
    begin
        // [GIVEN] A negative offset.
        Initialize(2);
        Request := MakeRequest();
        Request.Add('skip', -1);
        // [WHEN] The request is evaluated.
        asserterror Execute(Request);
        // [THEN] Foundation's exact validation is preserved without outbound calls.
        Assert.ExpectedError('skip must be zero or greater.');
        Assert.AreEqual(0, MockState.GetRequestCount(), 'Invalid paging must not fetch users.');
    end;

    [Test]
    procedure NegativeTakeFailsBeforeFetching()
    var
        Request: JsonObject;
    begin
        // [GIVEN] A negative page size.
        Initialize(2);
        Request := MakeRequest();
        Request.Add('take', -1);
        // [WHEN] The request is evaluated.
        asserterror Execute(Request);
        // [THEN] Foundation's exact validation is preserved without outbound calls.
        Assert.ExpectedError('take must be zero or greater.');
        Assert.AreEqual(0, MockState.GetRequestCount(), 'Invalid paging must not fetch users.');
    end;

    [Test]
    procedure OversizedTakeIsClamped()
    var
        Request: JsonObject;
        Response: JsonObject;
    begin
        // [GIVEN] More than the hard maximum of active mappings.
        Initialize(1002);
        Request := MakeRequest();
        Request.Add('take', 1001);
        // [WHEN] A page larger than the maximum is requested.
        Response := Execute(Request);
        // [THEN] The page is clamped, not rejected or left unbounded.
        AssertPage(Response, 1000, 1002, 1000, true);
        Assert.AreEqual(1000, MockState.GetRequestCount(), 'Hard maximum applies to fetches.');
        AssertUser(Response, 999, UserIdFor(1000));
    end;

    [Test]
    procedure NextSkipContinuesWithoutRepeatingUsers()
    var
        Request: JsonObject;
        FirstResponse: JsonObject;
        SecondResponse: JsonObject;
    begin
        // [GIVEN] Five mappings and a page size of three.
        Initialize(5);
        Request := MakeRequest();
        Request.Add('take', 3);
        FirstResponse := Execute(Request);
        Request.Add('skip', IntegerValue(FirstResponse, 'nextSkip'));
        // [WHEN] The caller uses the returned offset.
        SecondResponse := Execute(Request);
        // [THEN] The last partial page starts after the previous page's final user.
        AssertPage(FirstResponse, 3, 5, 3, true);
        AssertPage(SecondResponse, 2, 5, 5, false);
        AssertUser(FirstResponse, 2, UserIdFor(3));
        AssertUser(SecondResponse, 0, UserIdFor(4));
        AssertUser(SecondResponse, 1, UserIdFor(5));
        Assert.AreEqual(5, MockState.GetRequestCount(), 'Each user must be fetched exactly once.');
    end;

    [Test]
    procedure FailedUserDoesNotStopThePage()
    var
        Request: JsonObject;
        Response: JsonObject;
        UserResult: JsonObject;
        Token: JsonToken;
    begin
        // [GIVEN] The middle user fails while its neighbours return empty successful arrays.
        Initialize(3);
        MockState.FailPath('/user/' + UserIdFor(2) + '/');
        Request := MakeRequest();
        // [WHEN] The page is processed.
        Response := Execute(Request);
        // [THEN] Failure is counted, reported and included in the continuation offset.
        AssertPage(Response, 3, 3, 3, false);
        Assert.AreEqual(1, IntegerValue(Response, 'errors'), 'Exactly one user failed.');
        UserResult := UserAt(Response, 1);
        Assert.IsTrue(UserResult.Get('error', Token), 'The failed user has its own error.');
        Assert.IsTrue(Token.AsValue().AsText().Contains('HTTP 503'), 'Original failure is retained.');
        UserResult := UserAt(Response, 2);
        Assert.AreEqual(0, IntegerValue(UserResult, 'processed'), 'The following user still succeeds.');
        Assert.AreEqual(3, MockState.GetRequestCount(), 'The failure must not abort the page.');
    end;

    [Test]
    procedure SkipAtAndBeyondEndDoesNotFetch()
    var
        Request: JsonObject;
        Response: JsonObject;
    begin
        // [GIVEN] A caller already reached the end of the set.
        Initialize(3);
        Request := MakeRequest();
        Request.Add('skip', 3);
        // [WHEN] The offset equals the total, then exceeds it.
        Response := Execute(Request);
        AssertPage(Response, 0, 3, 3, false);
        Request.Replace('skip', 2147483647);
        Response := Execute(Request);
        // [THEN] No user is fetched and the offset does not overflow.
        AssertPage(Response, 0, 3, 2147483647, false);
        Assert.AreEqual(0, MockState.GetRequestCount(), 'Exhausted pages must not fetch users.');
    end;

    [Test]
    procedure EmptyMappingSetReturnsCompletedPage()
    var
        Request: JsonObject;
        Response: JsonObject;
    begin
        // [GIVEN] No mapped users.
        Initialize(0);
        Request := MakeRequest();
        // [WHEN] Sync is requested.
        Response := Execute(Request);
        // [THEN] Paging finishes without a Clockify request.
        AssertPage(Response, 0, 0, 0, false);
        Assert.AreEqual(0, MockState.GetRequestCount(), 'Empty sets require no fetch.');
    end;

    [Test]
    procedure HelpDescribesParametersResponseAndCallerLoop()
    var
        Parts: Codeunit "Clockify Contract Parts ori";
        Parameters: JsonArray;
        Response: JsonObject;
        Examples: JsonArray;
        Workflow: JsonObject;
        Notes: Text;
        ContractText: Text;
    begin
        // [GIVEN] The published structured contract for SyncAllUsers.
        Parts.GetParameters("Message Type ori"::"Clockify.TimeEntry.SyncAllUsers", Parameters);
        Parts.GetResponse("Message Type ori"::"Clockify.TimeEntry.SyncAllUsers", Response);
        Parts.GetExamples("Message Type ori"::"Clockify.TimeEntry.SyncAllUsers", Examples);
        Parts.GetWorkflow("Message Type ori"::"Clockify.TimeEntry.SyncAllUsers", Workflow);
        // [WHEN] The notes used by generated Help are requested.
        Parts.GetNotes("Message Type ori"::"Clockify.TimeEntry.SyncAllUsers", Notes);
        // [THEN] All paging fields and the exact Foundation limits are documented.
        Assert.IsTrue(HasParameter(Parameters, 'skip'), 'skip must be discoverable.');
        Assert.IsTrue(HasParameter(Parameters, 'take'), 'take must be discoverable.');
        Assert.IsTrue(Notes.Contains('## Pagination Limits'), 'Pagination Limits chapter required.');
        Assert.IsTrue(Notes.Contains('skip defaults to 0 and rejects negative values. take defaults to 100 when omitted or zero, rejects negative values, and is clamped to the hard maximum of 1000.'), 'Exact Foundation limits required.');
        Assert.IsTrue(Notes.Contains('repeat the same request with skip 100'), 'Concrete caller-loop example required.');
        Assert.IsTrue(Notes.Contains('until hasMore is false'), 'Caller must know when to stop.');
        Response.WriteTo(ContractText);
        Assert.IsTrue(ContractText.Contains('totalUsers') and ContractText.Contains('nextSkip') and ContractText.Contains('hasMore'), 'Response contract must expose continuation.');
        Examples.WriteTo(ContractText);
        Assert.IsTrue(ContractText.Contains('nextSkip') and ContractText.Contains('hasMore'), 'Response example must expose continuation.');
        Workflow.WriteTo(ContractText);
        Assert.IsTrue(ContractText.Contains('nextSkip'), 'Workflow must explain resumption.');
    end;

    [Test]
    procedure ClockifyListsKeepTheirOwnPaging()
    var
        Parts: Codeunit "Clockify Contract Parts ori";
        Types: List of [Enum "Message Type ori"];
        MessageType: Enum "Message Type ori";
        Parameters: JsonArray;
    begin
        // [GIVEN] Four API passthrough lists, outside the local mapped-user paging contract.
        Types.Add("Message Type ori"::"Clockify.TimeEntry.List");
        Types.Add("Message Type ori"::"Clockify.User.List");
        Types.Add("Message Type ori"::"Clockify.Project.List");
        Types.Add("Message Type ori"::"Clockify.Task.List");
        // [WHEN] Their parameter contracts are inspected.
        foreach MessageType in Types do begin
            Clear(Parameters);
            Parts.GetParameters(MessageType, Parameters);
            // [THEN] Clockify query paging remains; Foundation skip/take is not added.
            Assert.IsTrue(HasParameter(Parameters, 'query'), 'Clockify query remains available.');
            Assert.IsFalse(HasParameter(Parameters, 'skip'), 'No local skip on a passthrough list.');
            Assert.IsFalse(HasParameter(Parameters, 'take'), 'No local take on a passthrough list.');
        end;
    end;

    local procedure Initialize(UserCount: Integer)
    var
        Integration: Record "Clockify Integration ori";
        Setup: Record "Clockify Setup ori";
        UserIndex: Integer;
    begin
        // Native tests run in an owned isolated test transaction; no shared/customer fixtures.
        Integration.DeleteAll();
        MockState.Reset();
        MockState.SetNextResponse(true, 200, '[]');
        if not Setup.Get() then begin
            Setup.Init();
            Setup.Insert();
        end;
        Setup."API Version" := Setup."API Version"::Mock;
        Setup.Modify();
        // Insert backwards to prove paging uses the driver key, not insertion order.
        for UserIndex := UserCount downto 1 do
            AddMapping(UserIdFor(UserIndex), 'USER', false);
    end;

    local procedure AddMapping(ClockifyId: Text[50]; ClockifyType: Code[20]; Reversed: Boolean)
    var
        Integration: Record "Clockify Integration ori";
    begin
        Integration.Init();
        Integration."Clockify Type" := ClockifyType;
        Integration."Clockify Id" := ClockifyId;
        Integration.Reversed := Reversed;
        Integration."BC SystemId" := CreateGuid();
        Integration.Insert(true);
    end;

    local procedure UserIdFor(UserIndex: Integer): Text[50]
    begin
        exit(CopyStr('ZZTEST-' + PadStr('', 6 - StrLen(Format(UserIndex, 0, 9)), '0') + Format(UserIndex, 0, 9), 1, 50));
    end;

    local procedure MakeRequest() Request: JsonObject
    begin
        Request.Add('workspaceId', 'ZZTEST-WORKSPACE');
        Request.Add('start', '2026-06-01T00:00:00Z');
        Request.Add('end', '2026-06-30T23:59:59Z');
    end;

    local procedure Execute(Request: JsonObject): JsonObject
    var
        TempArgument: Record "Message Argument ori" temporary;
        Implementation: Interface "Msg Interface ori";
    begin
        TempArgument.Init();
        TempArgument.Type := "Message Type ori"::"Clockify.TimeEntry.SyncAllUsers";
        TempArgument.Insert();
        TempArgument.SetRequestJson(Request);
        Implementation := TempArgument.GetMessageTypeInterface();
        Implementation.ExecuteBifrostTask(TempArgument);
        exit(TempArgument.GetResponseJson());
    end;

    local procedure AssertPage(Response: JsonObject; Users: Integer; TotalUsers: Integer; NextSkip: Integer; HasMore: Boolean)
    var
        Token: JsonToken;
    begin
        Assert.AreEqual(Users, IntegerValue(Response, 'users'), 'Processed user count.');
        Assert.AreEqual(TotalUsers, IntegerValue(Response, 'totalUsers'), 'Unpaginated active user count.');
        Assert.AreEqual(NextSkip, IntegerValue(Response, 'nextSkip'), 'Continuation offset.');
        Assert.IsTrue(Response.Get('hasMore', Token), 'hasMore is required.');
        Assert.AreEqual(HasMore, Token.AsValue().AsBoolean(), 'Continuation flag.');
        Assert.IsTrue(Response.Get('userResults', Token), 'userResults is required.');
        Assert.AreEqual(Users, Token.AsArray().Count(), 'One result per processed user.');
    end;

    local procedure IntegerValue(Value: JsonObject; Name: Text): Integer
    var
        Token: JsonToken;
    begin
        Assert.IsTrue(Value.Get(Name, Token), 'Expected integer field ' + Name);
        exit(Token.AsValue().AsInteger());
    end;

    local procedure UserAt(Response: JsonObject; Index: Integer): JsonObject
    var
        Token: JsonToken;
    begin
        Response.Get('userResults', Token);
        Token.AsArray().Get(Index, Token);
        exit(Token.AsObject());
    end;

    local procedure AssertUser(Response: JsonObject; Index: Integer; ExpectedId: Text)
    var
        UserResult: JsonObject;
        Token: JsonToken;
    begin
        UserResult := UserAt(Response, Index);
        UserResult.Get('userId', Token);
        Assert.AreEqual(ExpectedId, Token.AsValue().AsText(), 'Stable user order at this offset.');
    end;

    local procedure HasParameter(Parameters: JsonArray; Name: Text): Boolean
    var
        Parameter: JsonToken;
        NameToken: JsonToken;
    begin
        foreach Parameter in Parameters do
            if Parameter.AsObject().Get('name', NameToken) then
                if NameToken.AsValue().AsText() = Name then
                    exit(true);
        exit(false);
    end;
}
