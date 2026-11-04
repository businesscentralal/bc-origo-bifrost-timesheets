namespace Origo.Bifrost.Timesheets.Test;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Setup;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Posting;
using Microsoft.Projects.Resources.Journal;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.TimeSheet;
using Microsoft.Sales.Customer;
using Origo.Bifrost.Timesheets;
using Origo.Bifrost;
using System.TestLibraries.Utilities;

/// <summary>Owned-fixture usage lifecycle, authorization and transaction regressions for issue 84.</summary>
codeunit 95635 "TS Usage Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    var
        Assert: Codeunit "Library Assert";

    /// <summary>Register ties a positive item quantity to the caller and exact native line.</summary>
    [Test]
    procedure RegisterItemCreatesOwnedOpenUsage()
    var
        Usage: Record "TS Usage Line ori";
        Request: JsonObject;
        Response: JsonObject;
        SheetNo: Code[20];
        ItemNo: Code[20];
    begin
        Fixture(Request, SheetNo, ItemNo);
        Response := Execute('Register', Request);
        Assert.AreEqual('Success', TextValue(Response, 'status'), 'Register succeeds.');
        Usage.SetRange("Time Sheet No.", SheetNo);
        Usage.FindFirst();
        Assert.AreEqual(Usage.Status::Open, Usage.Status, 'New usage is Open.');
        Assert.AreEqual(2, Usage.Quantity, 'Requested quantity is retained.');
        Assert.AreEqual(10000, Usage."Time Sheet Line No.", 'Exact native line is linked.');
        Assert.AreEqual(UpperCase(UserId()), Usage."Owner User ID", 'Caller owns the line.');
        Cleanup(SheetNo, ItemNo);
    end;

    /// <summary>Resource usage follows the same link and validation path.</summary>
    [Test]
    procedure RegisterResourceCreatesOpenUsage()
    var
        Header: Record "Time Sheet Header";
        Request: JsonObject;
        Response: JsonObject;
        SheetNo: Code[20];
        ItemNo: Code[20];
    begin
        Fixture(Request, SheetNo, ItemNo);
        Header.Get(SheetNo);
        Request.Replace('type', 'Resource');
        Request.Replace('no', Header."Resource No.");
        Response := Execute('Register', Request);
        Assert.AreEqual('Success', TextValue(Response, 'status'), 'Resource registration succeeds.');
        Cleanup(SheetNo, ItemNo);
    end;
    /// <summary>Refuses MissingSheet without creating usage.</summary>
    [Test]
    procedure RegisterRefusesMissingSheet()
    var
        Usage: Record "TS Usage Line ori";
        Request: JsonObject;
        Response: JsonObject;
        SheetNo: Code[20];
        ItemNo: Code[20];
    begin
        Fixture(Request, SheetNo, ItemNo);
        Request.Remove('timeSheetNo');
        Response := Execute('Register', Request);
        Assert.AreEqual('Error', TextValue(Response, 'status'), 'Invalid registration is refused.');
        Assert.AreEqual('timeSheetNo', TextValue(Response, 'parameter'), 'Refusal names the offending key.');
        Usage.SetRange("Time Sheet No.", SheetNo);
        Assert.IsTrue(Usage.IsEmpty(), 'Refusal leaves no usage.');
        Cleanup(SheetNo, ItemNo);
    end;
    /// <summary>Refuses UnknownSheet without creating usage.</summary>
    [Test]
    procedure RegisterRefusesUnknownSheet()
    var
        Usage: Record "TS Usage Line ori";
        Request: JsonObject;
        Response: JsonObject;
        SheetNo: Code[20];
        ItemNo: Code[20];
    begin
        Fixture(Request, SheetNo, ItemNo);
        Request.Replace('timeSheetNo', 'MISSING84');
        Response := Execute('Register', Request);
        Assert.AreEqual('Error', TextValue(Response, 'status'), 'Invalid registration is refused.');
        Assert.AreEqual('timeSheetNo', TextValue(Response, 'parameter'), 'Refusal names the offending key.');
        Usage.SetRange("Time Sheet No.", SheetNo);
        Assert.IsTrue(Usage.IsEmpty(), 'Refusal leaves no usage.');
        Cleanup(SheetNo, ItemNo);
    end;
    /// <summary>Refuses UnknownLine without creating usage.</summary>
    [Test]
    procedure RegisterRefusesUnknownLine()
    var
        Usage: Record "TS Usage Line ori";
        Request: JsonObject;
        Response: JsonObject;
        SheetNo: Code[20];
        ItemNo: Code[20];
    begin
        Fixture(Request, SheetNo, ItemNo);
        Request.Replace('lineNo', 20000);
        Response := Execute('Register', Request);
        Assert.AreEqual('Error', TextValue(Response, 'status'), 'Invalid registration is refused.');
        Assert.AreEqual('lineNo', TextValue(Response, 'parameter'), 'Refusal names the offending key.');
        Usage.SetRange("Time Sheet No.", SheetNo);
        Assert.IsTrue(Usage.IsEmpty(), 'Refusal leaves no usage.');
        Cleanup(SheetNo, ItemNo);
    end;
    /// <summary>Refuses ZeroQuantity without creating usage.</summary>
    [Test]
    procedure RegisterRefusesZeroQuantity()
    var
        Usage: Record "TS Usage Line ori";
        Request: JsonObject;
        Response: JsonObject;
        SheetNo: Code[20];
        ItemNo: Code[20];
    begin
        Fixture(Request, SheetNo, ItemNo);
        Request.Replace('quantity', 0);
        Response := Execute('Register', Request);
        Assert.AreEqual('Error', TextValue(Response, 'status'), 'Invalid registration is refused.');
        Assert.AreEqual('quantity', TextValue(Response, 'parameter'), 'Refusal names the offending key.');
        Usage.SetRange("Time Sheet No.", SheetNo);
        Assert.IsTrue(Usage.IsEmpty(), 'Refusal leaves no usage.');
        Cleanup(SheetNo, ItemNo);
    end;
    /// <summary>Refuses NegativeQuantity without creating usage.</summary>
    [Test]
    procedure RegisterRefusesNegativeQuantity()
    var
        Usage: Record "TS Usage Line ori";
        Request: JsonObject;
        Response: JsonObject;
        SheetNo: Code[20];
        ItemNo: Code[20];
    begin
        Fixture(Request, SheetNo, ItemNo);
        Request.Replace('quantity', -1);
        Response := Execute('Register', Request);
        Assert.AreEqual('Error', TextValue(Response, 'status'), 'Invalid registration is refused.');
        Assert.AreEqual('quantity', TextValue(Response, 'parameter'), 'Refusal names the offending key.');
        Usage.SetRange("Time Sheet No.", SheetNo);
        Assert.IsTrue(Usage.IsEmpty(), 'Refusal leaves no usage.');
        Cleanup(SheetNo, ItemNo);
    end;
    /// <summary>Refuses StringQuantity without creating usage.</summary>
    [Test]
    procedure RegisterRefusesStringQuantity()
    var
        Usage: Record "TS Usage Line ori";
        Request: JsonObject;
        Response: JsonObject;
        SheetNo: Code[20];
        ItemNo: Code[20];
    begin
        Fixture(Request, SheetNo, ItemNo);
        Request.Replace('quantity', '2');
        Response := Execute('Register', Request);
        Assert.AreEqual('Error', TextValue(Response, 'status'), 'Invalid registration is refused.');
        Assert.AreEqual('quantity', TextValue(Response, 'parameter'), 'Refusal names the offending key.');
        Usage.SetRange("Time Sheet No.", SheetNo);
        Assert.IsTrue(Usage.IsEmpty(), 'Refusal leaves no usage.');
        Cleanup(SheetNo, ItemNo);
    end;
    /// <summary>Refuses UnknownType without creating usage.</summary>
    [Test]
    procedure RegisterRefusesUnknownType()
    var
        Usage: Record "TS Usage Line ori";
        Request: JsonObject;
        Response: JsonObject;
        SheetNo: Code[20];
        ItemNo: Code[20];
    begin
        Fixture(Request, SheetNo, ItemNo);
        Request.Replace('type', 'Service');
        Response := Execute('Register', Request);
        Assert.AreEqual('Error', TextValue(Response, 'status'), 'Invalid registration is refused.');
        Assert.AreEqual('type', TextValue(Response, 'parameter'), 'Refusal names the offending key.');
        Usage.SetRange("Time Sheet No.", SheetNo);
        Assert.IsTrue(Usage.IsEmpty(), 'Refusal leaves no usage.');
        Cleanup(SheetNo, ItemNo);
    end;
    /// <summary>Refuses UnknownItem without creating usage.</summary>
    [Test]
    procedure RegisterRefusesUnknownItem()
    var
        Usage: Record "TS Usage Line ori";
        Request: JsonObject;
        Response: JsonObject;
        SheetNo: Code[20];
        ItemNo: Code[20];
    begin
        Fixture(Request, SheetNo, ItemNo);
        Request.Replace('no', 'MISSING84');
        Response := Execute('Register', Request);
        Assert.AreEqual('Error', TextValue(Response, 'status'), 'Invalid registration is refused.');
        Assert.AreEqual('no', TextValue(Response, 'parameter'), 'Refusal names the offending key.');
        Usage.SetRange("Time Sheet No.", SheetNo);
        Assert.IsTrue(Usage.IsEmpty(), 'Refusal leaves no usage.');
        Cleanup(SheetNo, ItemNo);
    end;
    /// <summary>Refuses NullDate without creating usage.</summary>
    [Test]
    procedure RegisterRefusesNullDate()
    var
        Usage: Record "TS Usage Line ori";
        NullValue: JsonValue;
        Request: JsonObject;
        Response: JsonObject;
        SheetNo: Code[20];
        ItemNo: Code[20];
    begin
        Fixture(Request, SheetNo, ItemNo);
        NullValue.SetValueToNull();
        Request.Replace('date', NullValue);
        Response := Execute('Register', Request);
        Assert.AreEqual('Error', TextValue(Response, 'status'), 'Invalid registration is refused.');
        Assert.AreEqual('date', TextValue(Response, 'parameter'), 'Refusal names the offending key.');
        Usage.SetRange("Time Sheet No.", SheetNo);
        Assert.IsTrue(Usage.IsEmpty(), 'Refusal leaves no usage.');
        Cleanup(SheetNo, ItemNo);
    end;
    /// <summary>Refuses ForeignSheet without creating usage.</summary>
    [Test]
    procedure RegisterRefusesForeignSheet()
    var
        Usage: Record "TS Usage Line ori";
        Header: Record "Time Sheet Header";
        Request: JsonObject;
        Response: JsonObject;
        SheetNo: Code[20];
        ItemNo: Code[20];
    begin
        Fixture(Request, SheetNo, ItemNo);
        Header.Get(SheetNo);
        Header."Owner User ID" := 'ZZFOREIGN84';
        Header.Modify(false);
        Response := Execute('Register', Request);
        Assert.AreEqual('Error', TextValue(Response, 'status'), 'Invalid registration is refused.');
        Assert.AreEqual('timeSheetNo', TextValue(Response, 'parameter'), 'Refusal names the offending key.');
        Usage.SetRange("Time Sheet No.", SheetNo);
        Assert.IsTrue(Usage.IsEmpty(), 'Refusal leaves no usage.');
        Cleanup(SheetNo, ItemNo);
    end;
    /// <summary>Refuses BlockedItem without creating usage.</summary>
    [Test]
    procedure RegisterRefusesBlockedItem()
    var
        Usage: Record "TS Usage Line ori";
        Item: Record Item;
        Request: JsonObject;
        Response: JsonObject;
        SheetNo: Code[20];
        ItemNo: Code[20];
    begin
        Fixture(Request, SheetNo, ItemNo);
        Item.Get(ItemNo);
        Item.Blocked := true;
        Item.Modify(false);
        Response := Execute('Register', Request);
        Assert.AreEqual('Error', TextValue(Response, 'status'), 'Invalid registration is refused.');
        Assert.AreEqual('no', TextValue(Response, 'parameter'), 'Refusal names the offending key.');
        Usage.SetRange("Time Sheet No.", SheetNo);
        Assert.IsTrue(Usage.IsEmpty(), 'Refusal leaves no usage.');
        Cleanup(SheetNo, ItemNo);
    end;
    /// <summary>Refuses DateOutsideWeek without creating usage.</summary>
    [Test]
    procedure RegisterRefusesDateOutsideWeek()
    var
        Usage: Record "TS Usage Line ori";
        Request: JsonObject;
        Response: JsonObject;
        SheetNo: Code[20];
        ItemNo: Code[20];
    begin
        Fixture(Request, SheetNo, ItemNo);
        Request.Replace('date', WorkDate() + 7);
        Response := Execute('Register', Request);
        Assert.AreEqual('Error', TextValue(Response, 'status'), 'Invalid registration is refused.');
        Assert.AreEqual('date', TextValue(Response, 'parameter'), 'Refusal names the offending key.');
        Usage.SetRange("Time Sheet No.", SheetNo);
        Assert.IsTrue(Usage.IsEmpty(), 'Refusal leaves no usage.');
        Cleanup(SheetNo, ItemNo);
    end;
    /// <summary>Refuses UnknownKey without creating usage.</summary>
    [Test]
    procedure RegisterRefusesUnknownKey()
    var
        Usage: Record "TS Usage Line ori";
        Request: JsonObject;
        Response: JsonObject;
        SheetNo: Code[20];
        ItemNo: Code[20];
    begin
        Fixture(Request, SheetNo, ItemNo);
        Request.Add('bogus', true);
        Response := Execute('Register', Request);
        Assert.AreEqual('Error', TextValue(Response, 'status'), 'Invalid registration is refused.');
        Assert.AreEqual('bogus', TextValue(Response, 'parameter'), 'Refusal names the offending key.');
        Usage.SetRange("Time Sheet No.", SheetNo);
        Assert.IsTrue(Usage.IsEmpty(), 'Refusal leaves no usage.');
        Cleanup(SheetNo, ItemNo);
    end;
    /// <summary>Only Open or Rejected usage may be submitted; repeated submission cannot mutate it.</summary>
    [Test]
    procedure SubmitOpenThenRefuseRepeatedSubmit()
    var
        Usage: Record "TS Usage Line ori";
        Request: JsonObject;
        Response: JsonObject;
        SheetNo: Code[20];
        ItemNo: Code[20];
    begin
        CreateUsage(Usage, SheetNo, ItemNo, false);
        Request.Add('entryNo', Usage."Entry No.");
        Response := Execute('Submit', Request);
        Assert.AreEqual('Success', TextValue(Response, 'status'), 'Open usage is submitted.');
        Usage.Get(Usage."Entry No.");
        Assert.AreEqual(Usage.Status::Submitted, Usage.Status, 'New state is Submitted.');
        Response := Execute('Submit', Request);
        Assert.AreEqual('Error', TextValue(Response, 'status'), 'Submitted usage cannot be submitted again.');
        Cleanup(SheetNo, ItemNo);
    end;

    /// <summary>The owner cannot approve their own usage even when named as sheet approver.</summary>
    [Test]
    procedure SelfApprovalRefused()
    var
        Usage: Record "TS Usage Line ori";
        Request: JsonObject;
        Response: JsonObject;
        SheetNo: Code[20];
        ItemNo: Code[20];
    begin
        CreateUsage(Usage, SheetNo, ItemNo, false);
        Usage.Status := Usage.Status::Submitted;
        Usage.Modify(false);
        Request.Add('entryNo', Usage."Entry No.");
        Response := Execute('Approve', Request);
        Assert.AreEqual('PermissionDenied', TextValue(Response, 'code'), 'Self-approval is denied.');
        Usage.Get(Usage."Entry No.");
        Assert.AreEqual(Usage.Status::Submitted, Usage.Status, 'Refused approval leaves state unchanged.');
        Cleanup(SheetNo, ItemNo);
    end;

    /// <summary>The independent sheet approver can approve submitted usage.</summary>
    [Test]
    procedure ApproverApprovesSubmittedUsage()
    var
        Usage: Record "TS Usage Line ori";
        Request: JsonObject;
        Response: JsonObject;
        SheetNo: Code[20];
        ItemNo: Code[20];
    begin
        CreateUsage(Usage, SheetNo, ItemNo, true);
        Usage.Status := Usage.Status::Submitted;
        Usage.Modify(false);
        Request.Add('entryNo', Usage."Entry No.");
        Response := Execute('Approve', Request);
        Assert.AreEqual('Success', TextValue(Response, 'status'), 'Approver can approve.');
        Usage.Get(Usage."Entry No.");
        Assert.AreEqual(Usage.Status::Approved, Usage.Status, 'State is Approved.');
        Assert.AreEqual(UpperCase(UserId()), Usage."Approved By", 'Approval identity retained.');
        Assert.IsTrue(Usage."Approved At" <> 0DT, 'Approval time retained.');
        Cleanup(SheetNo, ItemNo);
    end;

    /// <summary>Reject stores a bounded comment and cannot reject unsubmitted usage.</summary>
    [Test]
    procedure RejectStoresCommentAndRefusesRepeatedDecision()
    var
        Usage: Record "TS Usage Line ori";
        Request: JsonObject;
        Response: JsonObject;
        SheetNo: Code[20];
        ItemNo: Code[20];
    begin
        CreateUsage(Usage, SheetNo, ItemNo, true);
        Usage.Status := Usage.Status::Submitted;
        Usage.Modify(false);
        Request.Add('entryNo', Usage."Entry No.");
        Request.Add('comment', 'Please correct quantity');
        Response := Execute('Reject', Request);
        Assert.AreEqual('Success', TextValue(Response, 'status'), 'Reject succeeds.');
        Usage.Get(Usage."Entry No.");
        Assert.AreEqual(Usage.Status::Rejected, Usage.Status, 'State is Rejected.');
        Assert.AreEqual('Please correct quantity', Usage."Rejection Comment", 'Comment stored.');
        Response := Execute('Reject', Request);
        Assert.AreEqual('InvalidLine', TextValue(Response, 'code'), 'Repeated rejection refused.');
        Cleanup(SheetNo, ItemNo);
    end;

    /// <summary>An overlong comment rolls back the whole decision.</summary>
    [Test]
    procedure RejectOverlongCommentRollsBack()
    var
        Usage: Record "TS Usage Line ori";
        Request: JsonObject;
        Response: JsonObject;
        SheetNo: Code[20];
        ItemNo: Code[20];
    begin
        CreateUsage(Usage, SheetNo, ItemNo, true);
        Usage.Status := Usage.Status::Submitted;
        Usage.Modify(false);
        Request.Add('entryNo', Usage."Entry No.");
        Request.Add('comment', PadStr('X', 81, 'X'));
        Response := Execute('Reject', Request);
        Assert.AreEqual('comment', TextValue(Response, 'parameter'), 'Comment refusal identifies key.');
        Usage.Get(Usage."Entry No.");
        Assert.AreEqual(Usage.Status::Submitted, Usage.Status, 'Failed rejection rolls back.');
        Cleanup(SheetNo, ItemNo);
    end;

    /// <summary>Posted usage can be flagged reversed once; no journal is created unless requested.</summary>
    [Test]
    procedure ReversePostedOnce()
    var
        Usage: Record "TS Usage Line ori";
        Request: JsonObject;
        Response: JsonObject;
        SheetNo: Code[20];
        ItemNo: Code[20];
    begin
        CreateUsage(Usage, SheetNo, ItemNo, true);
        Usage.Status := Usage.Status::Posted;
        Usage.Modify(false);
        Request.Add('entryNo', Usage."Entry No.");
        Response := Execute('Reverse', Request);
        Assert.AreEqual('Success', TextValue(Response, 'status'), 'Posted usage can be reversed.');
        Usage.Get(Usage."Entry No.");
        Assert.IsTrue(Usage.Reversed, 'Reversal flag retained.');
        Response := Execute('Reverse', Request);
        Assert.AreEqual('InvalidLine', TextValue(Response, 'code'), 'Second reversal refused.');
        Cleanup(SheetNo, ItemNo);
    end;

    /// <summary>List visibility excludes foreign owners and accepts only submitted lines for an approver.</summary>
    [Test]
    procedure ListApproverSeesOnlySubmittedUsage()
    var
        Usage: Record "TS Usage Line ori";
        Request: JsonObject;
        Response: JsonObject;
        LinesToken: JsonToken;
        SheetNo: Code[20];
        ItemNo: Code[20];
    begin
        CreateUsage(Usage, SheetNo, ItemNo, true);
        Request.Add('timeSheetNo', SheetNo);
        Response := Execute('List', Request);
        Response.Get('lines', LinesToken);
        Assert.AreEqual(0, LinesToken.AsArray().Count(), 'Approver cannot read foreign open usage.');
        Usage.Status := Usage.Status::Submitted;
        Usage.Modify(false);
        Response := Execute('List', Request);
        Response.Get('lines', LinesToken);
        Assert.AreEqual(1, LinesToken.AsArray().Count(), 'Approver sees submitted usage.');
        Usage.Get(Usage."Entry No.");
        Assert.AreEqual(Usage.Status::Submitted, Usage.Status, 'List never changes state.');
        Cleanup(SheetNo, ItemNo);
    end;

    /// <summary>Read-only List never commits the caller's pending transaction.</summary>
    [Test]
    procedure ListKeepsPendingWriteTransaction()
    var
        Usage: Record "TS Usage Line ori";
        Request: JsonObject;
        Response: JsonObject;
        SheetNo: Code[20];
        ItemNo: Code[20];
    begin
        CreateUsage(Usage, SheetNo, ItemNo, false);
        Usage.Description := 'Uncommitted caller change';
        Usage.Modify(false);
        Request.Add('timeSheetNo', SheetNo);
        Response := Execute('List', Request);
        Assert.AreEqual('Success', TextValue(Response, 'status'), 'List succeeds.');
        Assert.IsTrue(Database.IsInWriteTransaction(), 'List must not commit caller writes.');
        Cleanup(SheetNo, ItemNo);
    end;

    /// <summary>Transfer creates one Item Journal line and a repeat creates no duplicate.</summary>
    [Test]
    procedure TransferItemOnceThenJournalDeletionReleasesLink()
    var
        Usage: Record "TS Usage Line ori";
        Journal: Record "Item Journal Line";
        JournalTemplate: Record "Item Journal Template";
        Batch: Record "Item Journal Batch";
        Request: JsonObject;
        Response: JsonObject;
        SheetNo: Code[20];
        ItemNo: Code[20];
    begin
        CreateUsage(Usage, SheetNo, ItemNo, true);
        Usage.Status := Usage.Status::Approved;
        Usage.Modify(false);
        ItemJournalFixture(JournalTemplate, Batch);
        Request.Add('entryNo', Usage."Entry No.");
        Request.Add('journalTemplate', JournalTemplate.Name);
        Request.Add('journalBatch', Batch.Name);
        Response := Execute('Transfer', Request);
        Assert.AreEqual('Success', TextValue(Response, 'status'), 'Item Transfer succeeds.');
        Usage.Get(Usage."Entry No.");
        Journal.Get(Usage."Journal Template", Usage."Journal Batch", Usage."Journal Line No.");
        Assert.AreEqual(ItemNo, Journal."Item No.", 'Item mapped to journal.');
        Assert.AreEqual(Usage.Quantity, Journal.Quantity, 'Quantity mapped.');
        Response := Execute('Transfer', Request);
        Assert.AreEqual('Success', TextValue(Response, 'status'), 'Repeat Transfer is unchanged.');
        Journal.SetRange("Journal Template Name", JournalTemplate.Name);
        Journal.SetRange("Journal Batch Name", Batch.Name);
        Assert.AreEqual(1, Journal.Count(), 'Repeat creates no duplicate.');
        Journal.Delete(true);
        Usage.Get(Usage."Entry No.");
        Assert.AreEqual(0, Usage."Journal Line No.", 'Native delete event clears journal link.');
        Assert.AreEqual(Usage.Status::Approved, Usage.Status, 'Unposted deleted usage remains Approved.');
        Batch.Delete(false);
        JournalTemplate.Delete(false);
        Cleanup(SheetNo, ItemNo);
    end;

    /// <summary>A failing later entry rolls back the earlier journal creation and its usage link.</summary>
    [Test]
    procedure TransferBatchFailureRollsBackAllRows()
    var
        Usage: Record "TS Usage Line ori";
        Journal: Record "Item Journal Line";
        JournalTemplate: Record "Item Journal Template";
        Batch: Record "Item Journal Batch";
        Request: JsonObject;
        Response: JsonObject;
        Entries: JsonArray;
        SheetNo: Code[20];
        ItemNo: Code[20];
    begin
        CreateUsage(Usage, SheetNo, ItemNo, true);
        Usage.Status := Usage.Status::Approved;
        Usage.Modify(false);
        ItemJournalFixture(JournalTemplate, Batch);
        Entries.Add(Usage."Entry No.");
        Entries.Add(2147483646);
        Request.Add('entryNos', Entries);
        Request.Add('journalTemplate', JournalTemplate.Name);
        Request.Add('journalBatch', Batch.Name);
        Response := Execute('Transfer', Request);
        Assert.AreEqual('Error', TextValue(Response, 'status'), 'Invalid second entry fails Transfer.');
        Journal.SetRange("Journal Template Name", JournalTemplate.Name);
        Journal.SetRange("Journal Batch Name", Batch.Name);
        Assert.IsTrue(Journal.IsEmpty(), 'No first journal survives the failed batch.');
        Usage.Get(Usage."Entry No.");
        Assert.AreEqual(0, Usage."Journal Line No.", 'No first usage link survives rollback.');
        Assert.AreEqual(Usage.Status::Approved, Usage.Status, 'State is preserved.');
        Batch.Delete(false);
        JournalTemplate.Delete(false);
        Cleanup(SheetNo, ItemNo);
    end;

    /// <summary>Nonposted usage cannot be reversed and remains unchanged.</summary>
    [Test]
    procedure ReverseRequiresPostedUsage()
    var
        Usage: Record "TS Usage Line ori";
        Request: JsonObject;
        Response: JsonObject;
        SheetNo: Code[20];
        ItemNo: Code[20];
    begin
        CreateUsage(Usage, SheetNo, ItemNo, true);
        Request.Add('entryNo', Usage."Entry No.");
        Response := Execute('Reverse', Request);
        Assert.AreEqual('InvalidLine', TextValue(Response, 'code'), 'Only Posted can be reversed.');
        Usage.Get(Usage."Entry No.");
        Assert.IsFalse(Usage.Reversed, 'Refusal leaves reversal flag false.');
        Cleanup(SheetNo, ItemNo);
    end;

    /// <summary>Generic writes are refused at the actual Data.Records.Set entry point.</summary>
    [Test]
    procedure GenericWriterCannotChangeStatus()
    var
        Usage: Record "TS Usage Line ori";
        TempArgument: Record "Message Argument ori" temporary;
        Dispatcher: Codeunit "Dispatcher ori";
        RequestContent: BigText;
        ResponseContent: BigText;
        ResponseContentType: Text[100];
        RequestText: Text;
        ResponseText: Text;
        Request: JsonObject;
        Row: JsonObject;
        Fields: JsonObject;
        Keys: JsonObject;
        Data: JsonArray;
        Response: JsonObject;
        SheetNo: Code[20];
        ItemNo: Code[20];
    begin
        CreateUsage(Usage, SheetNo, ItemNo, false);
        Keys.Add('EntryNo', Usage."Entry No.");
        Fields.Add('Status', 'Approved');
        Row.Add('primaryKey', Keys);
        Row.Add('fields', Fields);
        Data.Add(Row);
        Request.Add('tableId', Database::"TS Usage Line ori");
        Request.Add('data', Data);
        TempArgument.ID := CreateGuid();
        TempArgument.Type := TempArgument.Type::"Data.Records.Set";
        TempArgument.Version := TempArgument.Version::"1.0";
        TempArgument.Insert();
        TempArgument.SetRequestJson(Request);
        Request.WriteTo(RequestText);
        RequestContent.AddText(RequestText);
        Dispatcher.Execute(Enum::"Message Type ori"::"Data.Records.Set", Enum::"Message Version ori"::"1.0", '', 'ZZU84', 'application/json', RequestContent, ResponseContent, ResponseContentType);
        ResponseContent.GetSubText(ResponseText, 1);
        Response.ReadFrom(ResponseText);
        Assert.AreEqual('Error', TextValue(Response, 'status'), 'Generic usage writes are refused.');
        Assert.IsTrue(TextValue(Response, 'nextStep').Contains('Timesheets.Usage'), 'Refusal points to dedicated messages.');
        Usage.Get(Usage."Entry No.");
        Assert.AreEqual(Usage.Status::Open, Usage.Status, 'Generic writer changed nothing.');
        Cleanup(SheetNo, ItemNo);
    end;

    /// <summary>Continuation advances visible rows while retaining the owner and sheet filters.</summary>
    [Test]
    procedure ListContinuationReturnsNextVisibleUsage()
    var
        First: Record "TS Usage Line ori";
        Second: Record "TS Usage Line ori";
        Request: JsonObject;
        Response: JsonObject;
        Token: JsonToken;
        Lines: JsonArray;
        SheetNo: Code[20];
        ItemNo: Code[20];
    begin
        CreateUsage(First, SheetNo, ItemNo, false);
        Second := First;
        Second."Entry No." := 0;
        Second.Insert(true);
        Request.Add('timeSheetNo', SheetNo);
        Request.Add('limit', 1);
        Response := Execute('List', Request);
        Response.Get('hasMore', Token);
        Assert.IsTrue(Token.AsValue().AsBoolean(), 'First bounded page advertises continuation.');
        Response.Get('afterEntryNo', Token);
        Assert.AreEqual(First."Entry No.", Token.AsValue().AsInteger(), 'Cursor follows first visible row.');
        Request.Add('afterEntryNo', First."Entry No.");
        Response := Execute('List', Request);
        Response.Get('lines', Token);
        Lines := Token.AsArray();
        Assert.AreEqual(1, Lines.Count(), 'Next page has one row.');
        Lines.Get(0, Token);
        Token.AsObject().Get('entryNo', Token);
        Assert.AreEqual(Second."Entry No.", Token.AsValue().AsInteger(), 'Next visible row returned.');
        Cleanup(SheetNo, ItemNo);
    end;

    /// <summary>Resource transfer and native posting fire the usage subscriber; Reverse creates a negative journal once.</summary>
    [Test]
    procedure ResourcePostingTracksLedgerAndReverseCreatesNegativeJournal()
    var
        Usage: Record "TS Usage Line ori";
        Header: Record "Time Sheet Header";
        Journal: Record "Res. Journal Line";
        JournalTemplate: Record "Res. Journal Template";
        Batch: Record "Res. Journal Batch";
        PostLine: Codeunit "Res. Jnl.-Post Line";
        Request: JsonObject;
        Response: JsonObject;
        SheetNo: Code[20];
        ItemNo: Code[20];
    begin
        CreateUsage(Usage, SheetNo, ItemNo, true);
        Header.Get(SheetNo);
        Usage.Type := Usage.Type::Resource;
        Usage."No." := Header."Resource No.";
        Usage.Status := Usage.Status::Approved;
        Usage.Modify(false);
        JournalTemplate.Init();
        JournalTemplate.Name := CopyStr(UniqueNo(), 6, 10);
        JournalTemplate.Insert(false);
        Batch.Init();
        Batch."Journal Template Name" := JournalTemplate.Name;
        Batch.Name := CopyStr(UniqueNo(), 6, 10);
        Batch.Insert(false);
        Request.Add('entryNo', Usage."Entry No.");
        Request.Add('journalTemplate', JournalTemplate.Name);
        Request.Add('journalBatch', Batch.Name);
        Response := Execute('Transfer', Request);
        Assert.AreEqual('Success', TextValue(Response, 'status'), 'Resource Transfer succeeds.');
        Usage.Get(Usage."Entry No.");
        Journal.Get(Usage."Journal Template", Usage."Journal Batch", Usage."Journal Line No.");
        PostLine.RunWithCheck(Journal);
        Usage.Get(Usage."Entry No.");
        Assert.AreEqual(Usage.Status::Posted, Usage.Status, 'Native posting event marks usage Posted.');
        Assert.IsTrue(Usage."Ledger Entry No." > 0, 'Actual ledger entry number retained.');
        Journal.Delete(true);
        Usage.Get(Usage."Entry No.");
        Assert.AreEqual(Usage.Status::Posted, Usage.Status, 'Deleting posted journal cannot release Posted usage.');
        Request.Add('createJournal', true);
        Response := Execute('Reverse', Request);
        Assert.AreEqual('Success', TextValue(Response, 'status'), 'Reverse creates journal.');
        Usage.Get(Usage."Entry No.");
        Assert.IsTrue(Usage.Reversed, 'Reversed flag retained.');
        Journal.SetRange("Journal Template Name", JournalTemplate.Name);
        Journal.SetRange("Journal Batch Name", Batch.Name);
        Journal.FindFirst();
        Assert.AreEqual(-Usage.Quantity, Journal.Quantity, 'Reversal quantity is negative.');
        Response := Execute('Reverse', Request);
        Assert.AreEqual('InvalidLine', TextValue(Response, 'code'), 'Second reversal refused.');
        Journal.DeleteAll(true);
        Batch.Delete(false);
        JournalTemplate.Delete(false);
        Cleanup(SheetNo, ItemNo);
    end;

    /// <summary>Project-linked Item usage routes to a Job Journal.</summary>
    [Test]
    procedure ProjectItemUsageRoutesToJobJournal()
    begin
        AssertJobJournalTransfer(false);
    end;

    /// <summary>Project-linked Resource usage routes to a Job Journal.</summary>
    [Test]
    procedure ProjectResourceUsageRoutesToJobJournal()
    begin
        AssertJobJournalTransfer(true);
    end;

    /// <summary>Registration refuses a blocked resource without creating usage.</summary>
    [Test]
    procedure Scenario_AC02_BlockedResourceRefusesWithoutWrite()
    var
        Resource: Record Resource;
        Usage: Record "TS Usage Line ori";
        Request: JsonObject;
        Response: JsonObject;
        SheetNo: Code[20];
        ItemNo: Code[20];
    begin
        // Story #84, AC02 | Time: fixture WorkDate | Risk: None
        Fixture(Request, SheetNo, ItemNo);
        Resource."No." := UniqueNo();
        Resource.Name := 'Usage blocked resource';
        Resource.Blocked := true;
        Resource.Insert(false);
        Request.Replace('type', 'Resource');
        Request.Replace('no', Resource."No.");
        Response := Execute('Register', Request);
        Assert.AreEqual('Error', TextValue(Response, 'status'), 'Blocked resource is refused.');
        Assert.AreEqual('no', TextValue(Response, 'parameter'), 'Refusal names the resource key.');
        Usage.SetRange("Time Sheet No.", SheetNo);
        Assert.IsTrue(Usage.IsEmpty(), 'No usage is created.');
        Resource.Delete(false);
        Cleanup(SheetNo, ItemNo);
    end;

    /// <summary>Real native item posting records the exact ledger and preserves Posted after journal deletion.</summary>
    [Test]
    procedure Scenario_AC07_ItemPostingTracksActualLedger()
    var
        Usage: Record "TS Usage Line ori";
        Item: Record Item;
        PostingGroup: Record "Inventory Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        Account: Record "G/L Account";
        GeneralLedger: Record "G/L Entry";
        Journal: Record "Item Journal Line";
        JournalTemplate: Record "Item Journal Template";
        Batch: Record "Item Journal Batch";
        Ledger: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        Application: Record "Item Application Entry";
        ItemRegister: Record "Item Register";
        PostLine: Codeunit "Item Jnl.-Post Line";
        Request: JsonObject;
        Response: JsonObject;
        SheetNo: Code[20];
        ItemNo: Code[20];
    begin
        // Story #84, AC07 | Time: fixture WorkDate | Risk: native zero-cost inventory posting
        CreateUsage(Usage, SheetNo, ItemNo, true);
        Item.Get(ItemNo);
        PostingGroup.Code := Item."Base Unit of Measure";
        PostingGroup.Insert(false);
        Account."No." := UniqueNo();
        Account.Name := 'Usage zero-cost inventory account';
        Account."Account Type" := Account."Account Type"::Posting;
        Account."Direct Posting" := true;
        Account.Insert(false);
        GeneralPostingSetup."Gen. Prod. Posting Group" := PostingGroup.Code;
        GeneralPostingSetup."Inventory Adjmt. Account" := Account."No.";
        GeneralPostingSetup."COGS Account" := Account."No.";
        GeneralPostingSetup."COGS Account (Interim)" := Account."No.";
        GeneralPostingSetup."Direct Cost Applied Account" := Account."No.";
        GeneralPostingSetup."Overhead Applied Account" := Account."No.";
        GeneralPostingSetup.Insert(false);
        InventoryPostingSetup."Invt. Posting Group Code" := PostingGroup.Code;
        InventoryPostingSetup."Inventory Account" := Account."No.";
        InventoryPostingSetup."Inventory Account (Interim)" := Account."No.";
        InventoryPostingSetup.Insert(false);
        Item."Inventory Posting Group" := PostingGroup.Code;
        Item."Gen. Prod. Posting Group" := PostingGroup.Code;
        Item."Prevent Negative Inventory" := Item."Prevent Negative Inventory"::No;
        Item.Modify(false);
        Usage.Status := Usage.Status::Approved;
        Usage.Modify(false);
        ItemJournalFixture(JournalTemplate, Batch);
        Request.Add('entryNo', Usage."Entry No.");
        Request.Add('journalTemplate', JournalTemplate.Name);
        Request.Add('journalBatch', Batch.Name);
        Response := Execute('Transfer', Request);
        Assert.AreEqual('Success', TextValue(Response, 'status'), 'Item Transfer succeeds.');
        Usage.Get(Usage."Entry No.");
        Journal.Get(Usage."Journal Template", Usage."Journal Batch", Usage."Journal Line No.");
        PostLine.RunWithCheck(Journal);
        Usage.Get(Usage."Entry No.");
        Assert.AreEqual(Usage.Status::Posted, Usage.Status, 'Native item event marks usage Posted.');
        Ledger.Get(Usage."Ledger Entry No.");
        Assert.AreEqual(ItemNo, Ledger."Item No.", 'Actual ledger belongs to owned item.');
        Assert.AreEqual(-Usage.Quantity, Ledger.Quantity, 'Negative adjustment consumes the usage quantity.');
        Journal.Delete(true);
        Usage.Get(Usage."Entry No.");
        Assert.AreEqual(Usage.Status::Posted, Usage.Status, 'Deleting posted item journal preserves Posted.');
        ItemRegister.SetRange("From Entry No.", Ledger."Entry No.");
        ItemRegister.SetRange("To Entry No.", Ledger."Entry No.");
        Assert.AreEqual(1, ItemRegister.Count(), 'Single-entry owned register is isolated.');
        ValueEntry.SetRange("Item Ledger Entry No.", Ledger."Entry No.");
        ValueEntry.DeleteAll(false);
        Application.SetRange("Item Ledger Entry No.", Ledger."Entry No.");
        Application.DeleteAll(false);
        ItemRegister.DeleteAll(false);
        Ledger.Delete(false);
        Batch.Delete(false);
        JournalTemplate.Delete(false);
        InventoryPostingSetup.Delete(false);
        GeneralPostingSetup.Delete(false);
        PostingGroup.Delete(false);
        GeneralLedger.SetRange("G/L Account No.", Account."No.");
        Assert.IsTrue(GeneralLedger.IsEmpty(), 'Zero-cost owned inventory posts no financial amount.');
        Account.Delete(false);
        Cleanup(SheetNo, ItemNo);
    end;

    /// <summary>Rejected usage can be corrected and submitted again by its owner.</summary>
    [Test]
    procedure Scenario_AC03_RejectedUsageCanBeSubmitted()
    var
        Usage: Record "TS Usage Line ori";
        Request: JsonObject;
        Response: JsonObject;
        SheetNo: Code[20];
        ItemNo: Code[20];
    begin
        // Story #84, AC03 | Time: fixture WorkDate | Risk: None
        CreateUsage(Usage, SheetNo, ItemNo, false);
        Usage.Status := Usage.Status::Rejected;
        Usage.Modify(false);
        Request.Add('entryNo', Usage."Entry No.");
        Response := Execute('Submit', Request);
        Assert.AreEqual('Success', TextValue(Response, 'status'), 'Owner resubmits Rejected usage.');
        Usage.Get(Usage."Entry No.");
        Assert.AreEqual(Usage.Status::Submitted, Usage.Status, 'Rejected transitions to Submitted.');
        Cleanup(SheetNo, ItemNo);
    end;

    /// <summary>Week and status filters intersect and List leaves all rows unchanged.</summary>
    [Test]
    procedure Scenario_AC10_WeekAndStatusFiltersIntersect()
    var
        First: Record "TS Usage Line ori";
        Other: Record "TS Usage Line ori";
        Request: JsonObject;
        Response: JsonObject;
        Token: JsonToken;
        Lines: JsonArray;
        SheetNo: Code[20];
        ItemNo: Code[20];
    begin
        // Story #84, AC10 | Time: fixture WorkDate and following week | Risk: None
        CreateUsage(First, SheetNo, ItemNo, false);
        Other := First;
        Other."Entry No." := 0;
        Other.Status := Other.Status::Rejected;
        Other.Insert(true);
        Other := First;
        Other."Entry No." := 0;
        Other.Date := First.Date + 7;
        Other.Insert(true);
        Request.Add('timeSheetNo', SheetNo);
        Request.Add('week', First.Date);
        Request.Add('status', 'Open');
        Response := Execute('List', Request);
        Assert.AreEqual('Success', TextValue(Response, 'status'), 'Filtered List succeeds.');
        Response.Get('lines', Token);
        Lines := Token.AsArray();
        Assert.AreEqual(1, Lines.Count(), 'Other status and other week are excluded.');
        Lines.Get(0, Token);
        Token.AsObject().Get('entryNo', Token);
        Assert.AreEqual(First."Entry No.", Token.AsValue().AsInteger(), 'Exact matching row returned.');
        Other.SetRange("Time Sheet No.", SheetNo);
        Assert.AreEqual(3, Other.Count(), 'List deletes no rows.');
        First.Get(First."Entry No.");
        Assert.AreEqual(First.Status::Open, First.Status, 'List changes no status.');
        Cleanup(SheetNo, ItemNo);
    end;

    /// <summary>The approver page exposes read-only usage for an addressed sheet.</summary>
    [Test]
    procedure ApproverPageIsReadOnlyAndScoped()
    var
        Usage: Record "TS Usage Line ori";
        UsagePage: TestPage "TS Usage Lines ori";
        SheetNo: Code[20];
        ItemNo: Code[20];
    begin
        CreateUsage(Usage, SheetNo, ItemNo, true);
        UsagePage.OpenView();
        Assert.IsTrue(UsagePage.GoToRecord(Usage), 'Approver can see the addressed usage.');
        Assert.IsFalse(UsagePage.Status.Editable(), 'Status is read-only in the worklist.');
        Assert.IsFalse(UsagePage.Quantity.Editable(), 'Quantity is read-only in the worklist.');
        UsagePage.Close();
        Cleanup(SheetNo, ItemNo);
    end;

    local procedure AssertJobJournalTransfer(ResourceUsage: Boolean)
    var
        Usage: Record "TS Usage Line ori";
        Header: Record "Time Sheet Header";
        SheetLine: Record "Time Sheet Line";
        Job: Record Job;
        Customer: Record Customer;
        JobTask: Record "Job Task";
        JournalTemplate: Record "Job Journal Template";
        Batch: Record "Job Journal Batch";
        Journal: Record "Job Journal Line";
        Ledger: Record "Job Ledger Entry";
        JobRegister: Record "Job Register";
        PostLine: Codeunit "Job Jnl.-Post Line";
        Request: JsonObject;
        Response: JsonObject;
        SheetNo: Code[20];
        ItemNo: Code[20];
    begin
        CreateUsage(Usage, SheetNo, ItemNo, true);
        Header.Get(SheetNo);
        if ResourceUsage then begin
            Usage.Type := Usage.Type::Resource;
            Usage."No." := Header."Resource No.";
        end;
        Usage.Status := Usage.Status::Approved;
        Usage.Modify(false);
        Customer."No." := UniqueNo();
        Customer.Name := 'Usage test customer';
        Customer.Insert(false);
        Job."Bill-to Customer No." := Customer."No.";
        Job."No." := UniqueNo();
        Job.Description := 'Usage test project';
        Job.Status := Job.Status::Open;
        Job.Insert(false);
        JobTask."Job No." := Job."No.";
        JobTask."Job Task No." := 'TASK';
        JobTask."Job Task Type" := JobTask."Job Task Type"::Posting;
        JobTask.Insert(false);
        SheetLine.Get(SheetNo, 10000);
        SheetLine.Type := SheetLine.Type::Job;
        SheetLine."Job No." := Job."No.";
        SheetLine."Job Task No." := JobTask."Job Task No.";
        SheetLine.Modify(false);
        JournalTemplate.Name := CopyStr(UniqueNo(), 6, 10);
        JournalTemplate.Description := 'Usage test project journal';
        JournalTemplate.Insert(false);
        Batch."Journal Template Name" := JournalTemplate.Name;
        Batch.Name := CopyStr(UniqueNo(), 6, 10);
        Batch.Insert(false);
        Request.Add('entryNo', Usage."Entry No.");
        Request.Add('journalTemplate', JournalTemplate.Name);
        Request.Add('journalBatch', Batch.Name);
        Response := Execute('Transfer', Request);
        Assert.AreEqual('Success', TextValue(Response, 'status'), 'Project Transfer succeeds: ' + TextValue(Response, 'error'));
        Usage.Get(Usage."Entry No.");
        Assert.AreEqual(Database::"Job Journal Line", Usage."Journal Table No.", 'Project mapping wins over usage type.');
        Journal.Get(JournalTemplate.Name, Batch.Name, Usage."Journal Line No.");
        Assert.AreEqual(Job."No.", Journal."Job No.", 'Project preserved.');
        Assert.AreEqual(JobTask."Job Task No.", Journal."Job Task No.", 'Task preserved.');
        Assert.AreEqual(Usage."No.", Journal."No.", 'Usage entity preserved.');
        if ResourceUsage then begin
            // Story #84, AC07 | Time: fixture WorkDate | Risk: native project/resource posting prerequisites
            PostLine.RunWithCheck(Journal);
            Usage.Get(Usage."Entry No.");
            Assert.AreEqual(Usage.Status::Posted, Usage.Status, 'Native project posting marks usage Posted.');
            Ledger.Get(Usage."Ledger Entry No.");
            Assert.AreEqual(Job."No.", Ledger."Job No.", 'Stored ledger belongs to the exact owned project.');
            Assert.AreEqual(Usage.Quantity, Ledger.Quantity, 'Stored project ledger carries usage quantity.');
            JobRegister.Get(Ledger."Job Register No.");
            JobRegister.TestField("From Entry No.", Ledger."Entry No.");
            JobRegister.TestField("To Entry No.", Ledger."Entry No.");
            Ledger.Delete(false);
            JobRegister.Delete(false);
        end;
        Journal.Delete(true);
        Usage.Get(Usage."Entry No.");
        if ResourceUsage then
            Assert.AreEqual(Usage.Status::Posted, Usage.Status, 'Deleting posted project journal retains Posted state.')
        else begin
            Assert.AreEqual(Usage.Status::Approved, Usage.Status, 'Unposted project deletion retains Approved state.');
            Assert.AreEqual(0, Usage."Journal Line No.", 'Unposted project deletion clears link.');
        end;
        Batch.Delete(false);
        JournalTemplate.Delete(false);
        JobTask.Delete(false);
        Job.Delete(false);
        Customer.Delete(false);
        Cleanup(SheetNo, ItemNo);
    end;

    /// <summary>All usage types expose typed related entries and executable discovery contracts.</summary>
    [Test]
    procedure AllUsageTypesHaveValidContractsAndDiscovery()
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        MessageType: Enum "Message Type ori";
        Discovery: Interface "Msg Discovery ori";
        Contract: JsonObject;
        RelatedToken: JsonToken;
        Entry: JsonToken;
        Ordinal: Integer;
        Index: Integer;
    begin
        for Ordinal := 10036830 to 10036836 do begin
            MessageType := Enum::"Message Type ori".FromInteger(Ordinal);
            Clear(Contract);
            Assert.IsTrue(ContractMgt.GetContract(MessageType, Contract), 'Usage contract exists.');
            Contract.Get('related', RelatedToken);
            for Index := 0 to RelatedToken.AsArray().Count() - 1 do begin
                RelatedToken.AsArray().Get(Index, Entry);
                Assert.IsTrue(Entry.IsObject(), 'Related messages must use the typed contract-entry shape.');
            end;
            Discovery := MessageType;
            Assert.IsTrue(Discovery.GetKeywords() <> '', 'Usage discovery keywords are available.');
            Assert.IsTrue(Discovery.GetSelectionDescription() <> '', 'Usage selection descriptions are available.');
        end;
    end;

    local procedure ItemJournalFixture(var JournalTemplate: Record "Item Journal Template"; var Batch: Record "Item Journal Batch")
    begin
        JournalTemplate.Init();
        JournalTemplate.Name := CopyStr(UniqueNo(), 1, 10);
        JournalTemplate.Insert(false);
        Batch.Init();
        Batch."Journal Template Name" := JournalTemplate.Name;
        Batch.Name := CopyStr(UniqueNo(), 1, 10);
        Batch.Insert(false);
    end;

    local procedure Fixture(var Request: JsonObject; var SheetNo: Code[20]; var ItemNo: Code[20])
    var
        Header: Record "Time Sheet Header";
        Line: Record "Time Sheet Line";
        Resource: Record Resource;
        PostingGroup: Record "Gen. Product Posting Group";
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        ResourceUnit: Record "Resource Unit of Measure";
        ItemUnit: Record "Item Unit of Measure";
    begin
        UnitOfMeasure.Init();
        UnitOfMeasure.Code := CopyStr(UniqueNo(), 6, 10);
        UnitOfMeasure.Insert(false);
        PostingGroup.Code := UnitOfMeasure.Code;
        PostingGroup.Insert(false);
        Resource.Init();
        Resource."No." := UniqueNo();
        Resource."Gen. Prod. Posting Group" := PostingGroup.Code;
        Resource.Name := 'Usage test resource';
        Resource."Base Unit of Measure" := UnitOfMeasure.Code;
        Resource."Time Sheet Owner User ID" := CopyStr(UserId(), 1, 50);
        Resource.Insert(false);
        ResourceUnit.Init();
        ResourceUnit."Resource No." := Resource."No.";
        ResourceUnit.Code := UnitOfMeasure.Code;
        ResourceUnit."Qty. per Unit of Measure" := 1;
        ResourceUnit.Insert(false);
        Header.Init();
        Header."No." := UniqueNo();
        Header."Resource No." := Resource."No.";
        Header."Owner User ID" := CopyStr(UserId(), 1, 50);
        Header."Approver User ID" := Header."Owner User ID";
        Header."Starting Date" := WorkDate();
        Header."Ending Date" := WorkDate() + 6;
        Header.Insert(false);
        Line.Init();
        Line."Time Sheet No." := Header."No.";
        Line."Line No." := 10000;
        Line.Type := Line.Type::Resource;
        Line.Insert(false);
        Item.Init();
        Item."No." := UniqueNo();
        Item.Description := 'Usage test item';
        Item.Type := Item.Type::Inventory;
        Item."Base Unit of Measure" := UnitOfMeasure.Code;
        Item.Insert(false);
        ItemUnit.Init();
        ItemUnit."Item No." := Item."No.";
        ItemUnit.Code := UnitOfMeasure.Code;
        ItemUnit."Qty. per Unit of Measure" := 1;
        ItemUnit.Insert(false);
        SheetNo := Header."No.";
        ItemNo := Item."No.";
        Request.Add('timeSheetNo', SheetNo);
        Request.Add('lineNo', 10000);
        Request.Add('type', 'Item');
        Request.Add('no', ItemNo);
        Request.Add('date', WorkDate());
        Request.Add('quantity', 2);
    end;

    local procedure CreateUsage(var Usage: Record "TS Usage Line ori"; var SheetNo: Code[20]; var ItemNo: Code[20]; ForApprover: Boolean)
    var
        Header: Record "Time Sheet Header";
        Request: JsonObject;
        Response: JsonObject;
    begin
        Fixture(Request, SheetNo, ItemNo);
        Response := Execute('Register', Request);
        Assert.AreEqual('Success', TextValue(Response, 'status'), 'Owned usage fixture registers.');
        Usage.SetRange("Time Sheet No.", SheetNo);
        Usage.FindFirst();
        if ForApprover then begin
            Header.Get(SheetNo);
            Header."Owner User ID" := 'ZZFOREIGN84';
            Header.Modify(false);
            Usage."Owner User ID" := Header."Owner User ID";
            Usage.Modify(false);
        end;
    end;

    local procedure Execute(Operation: Text; Request: JsonObject): JsonObject
    var
        TempArgument: Record "Message Argument ori" temporary;
        Implementation: Interface "Msg Interface ori";
    begin
        TempArgument.Init();
        TempArgument.ID := CreateGuid();
        TempArgument."Version" := TempArgument."Version"::"1.0";
        case Operation of
            'Register':
                TempArgument.Type := TempArgument.Type::"Timesheets.Usage.Register";
            'List':
                TempArgument.Type := TempArgument.Type::"Timesheets.Usage.List";
            'Submit':
                TempArgument.Type := TempArgument.Type::"Timesheets.Usage.Submit";
            'Approve':
                TempArgument.Type := TempArgument.Type::"Timesheets.Usage.Approve";
            'Reject':
                TempArgument.Type := TempArgument.Type::"Timesheets.Usage.Reject";
            'Transfer':
                TempArgument.Type := TempArgument.Type::"Timesheets.Usage.Transfer";
            'Reverse':
                TempArgument.Type := TempArgument.Type::"Timesheets.Usage.Reverse";
        end;
        TempArgument.Insert();
        TempArgument.SetRequestJson(Request);
        Implementation := TempArgument.GetMessageTypeInterface();
        Implementation.ExecuteBifrostTask(TempArgument);
        exit(TempArgument.GetResponseJson());
    end;

    local procedure TextValue(Response: JsonObject; KeyName: Text): Text
    var
        Token: JsonToken;
    begin
        if not Response.Get(KeyName, Token) then
            exit('');
        exit(Token.AsValue().AsText());
    end;

    local procedure UniqueNo(): Code[20]
    begin
        exit(CopyStr('ZZU84' + DelChr(Format(CreateGuid(), 0, 4), '=', '{}-'), 1, 20));
    end;

    local procedure Cleanup(SheetNo: Code[20]; ItemNo: Code[20])
    var
        Usage: Record "TS Usage Line ori";
        Header: Record "Time Sheet Header";
        Line: Record "Time Sheet Line";
        Resource: Record Resource;
        Item: Record Item;
        PostingGroup: Record "Gen. Product Posting Group";
        UnitOfMeasure: Record "Unit of Measure";
        ResourceUnit: Record "Resource Unit of Measure";
        ItemUnit: Record "Item Unit of Measure";
        FixtureCleanup: Codeunit "TS Usage Fixture Cleanup";
    begin
        Usage.SetRange("Time Sheet No.", SheetNo);
        Usage.DeleteAll(false);
        Line.SetRange("Time Sheet No.", SheetNo);
        Line.DeleteAll(false);
        Header.Get(SheetNo);
        Resource.Get(Header."Resource No.");
        Header.Delete(false);
        FixtureCleanup.DeleteResourceLedger(Resource."No.");
        ResourceUnit.SetRange("Resource No.", Resource."No.");
        ResourceUnit.DeleteAll(false);
        Resource.Delete(false);
        Item.Get(ItemNo);
        UnitOfMeasure.Get(Item."Base Unit of Measure");
        ItemUnit.SetRange("Item No.", ItemNo);
        ItemUnit.DeleteAll(false);
        Item.Delete(false);
        PostingGroup.Get(UnitOfMeasure.Code);
        PostingGroup.Delete(false);
        UnitOfMeasure.Delete(false);
        Commit();
    end;
}
