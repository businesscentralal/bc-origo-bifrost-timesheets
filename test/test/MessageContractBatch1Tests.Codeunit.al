namespace Origo.Bifrost.Timesheets.Test;

using Origo.Bifrost;
using Origo.Bifrost.Timesheets;
using System.TestLibraries.Utilities;

/// <summary>Contract and discovery conformance tests for issue #36 batch 1.</summary>
codeunit 95608 "Message Contract Batch 1 Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    [Test]
    procedure Batch1TypesDeclareContractAndDiscovery()
    var
        Ordinal: Integer;
    begin
        foreach Ordinal in BatchOrdinals() do
            AssertContract(Ordinal);
    end;

    local procedure AssertContract(Ordinal: Integer)
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Parts: Codeunit "Clockify Contract Parts ori";
        MessageType: Enum "Message Type ori";
        Contract: JsonObject;
        MsgContract: Interface "Msg Contract ori";
        Discovery: Interface "Msg Discovery ori";
        Chapter: Text;
        Chapters: List of [Text];
        Metering: JsonObject;
        TypeName: Text;
    begin
        MessageType := Enum::"Message Type ori".FromInteger(Ordinal);
        TypeName := Parts.MessageTypeName(MessageType);
        Assert.IsTrue(ContractMgt.GetContract(MessageType, Contract), TypeName + ' contract');
        Chapters.Add('envelope');
        Chapters.Add('response');
        if Ordinal <> 10036785 then
            Chapters.Add('errors');
        Chapters.Add('effect');
        Chapters.Add('related');
        foreach Chapter in Chapters do
            Assert.IsTrue(Contract.Contains(Chapter), TypeName + ' ' + Chapter);
        MsgContract := MessageType;
        Discovery := MessageType;
        Assert.IsTrue(Discovery.GetKeywords() <> '', TypeName + ' keywords');
        Assert.IsTrue(Discovery.GetSelectionDescription() <> '', TypeName + ' selection');
        Assert.IsFalse(MsgContract.GetMetering(Metering), TypeName + ' app metering');
    end;

    local procedure BatchOrdinals() Ordinals: List of [Integer]
    begin
        Ordinals.Add(10036785);
        Ordinals.Add(10036786);
        Ordinals.Add(10036787);
        Ordinals.Add(10036788);
        Ordinals.Add(10036789);
        Ordinals.Add(10036790);
        Ordinals.Add(10036791);
        Ordinals.Add(10036792);
        Ordinals.Add(10036793);
        Ordinals.Add(10036812);
        Ordinals.Add(10036813);
        Ordinals.Add(10036814);
    end;

    /// <summary>Every Clockify message type declares the parameter names fixed in this test.</summary>
    [Test]
    procedure Scenario_AC08_EveryType_DeclaresOnlyItsOwnParameterNames()
    var
        Parts: Codeunit "Clockify Contract Parts ori";
        MessageType: Enum "Message Type ori";
        Contract: Interface "Msg Contract ori";
        Parameters: JsonArray;
        Expected: Text;
        Name: Text;
        Ordinals: List of [Integer];
        Ordinal: Integer;
    begin
        // Story #46, AC08 | Time: independent of Today()/WorkDate() | Risk: None
        Ordinals := Enum::"Message Type ori".Ordinals();
        foreach Ordinal in Ordinals do begin
            MessageType := Enum::"Message Type ori".FromInteger(Ordinal);
            Name := Parts.MessageTypeName(MessageType);
            if not IsClockifyType(Name) then
                continue;
            Expected := ExpectedNames(MessageType);
            Clear(Parameters);
            Contract := MessageType;
            if Expected = '' then
                Assert.IsFalse(Contract.GetParameters(Parameters), Name + ' should declare no parameters.')
            else
                Assert.IsTrue(Contract.GetParameters(Parameters), Name + ' should declare parameters.');
            Assert.AreEqual(Expected, JoinNames(Parameters), Name);
        end;
    end;

    local procedure IsClockifyType(Name: Text): Boolean
    begin
        exit(Name.StartsWith('Clockify.') or Name.StartsWith('Help.Clockify.'));
    end;

    local procedure ExpectedNames(MessageType: Enum "Message Type ori"): Text
    begin
        case MessageType of
            MessageType::"Help.Clockify.Get":
                exit('');
            MessageType::"Clockify.Workspace.List":
                exit('query');
            MessageType::"Clockify.User.GetCurrent":
                exit('');
            MessageType::"Clockify.User.List":
                exit('query, workspaceId');
            MessageType::"Clockify.Client.List":
                exit('query, workspaceId');
            MessageType::"Clockify.Client.Get":
                exit('clientId, workspaceId');
            MessageType::"Clockify.Client.Create":
                exit('body, workspaceId');
            MessageType::"Clockify.Client.Update":
                exit('body, clientId, workspaceId');
            MessageType::"Clockify.Client.Delete":
                exit('clientId, workspaceId');
            MessageType::"Clockify.Project.List":
                exit('query, workspaceId');
            MessageType::"Clockify.Project.Get":
                exit('projectId, workspaceId');
            MessageType::"Clockify.Project.Create":
                exit('body, workspaceId');
            MessageType::"Clockify.Project.Update":
                exit('body, projectId, workspaceId');
            MessageType::"Clockify.Project.Delete":
                exit('projectId, workspaceId');
            MessageType::"Clockify.Task.List":
                exit('projectId, query, workspaceId');
            MessageType::"Clockify.Task.Create":
                exit('body, projectId, workspaceId');
            MessageType::"Clockify.Task.Update":
                exit('body, projectId, taskId, workspaceId');
            MessageType::"Clockify.Task.Delete":
                exit('projectId, taskId, workspaceId');
            MessageType::"Clockify.Tag.List":
                exit('query, workspaceId');
            MessageType::"Clockify.Tag.Create":
                exit('body, workspaceId');
            MessageType::"Clockify.Tag.Update":
                exit('body, tagId, workspaceId');
            MessageType::"Clockify.Tag.Delete":
                exit('tagId, workspaceId');
            MessageType::"Clockify.TimeEntry.List":
                exit('query, userId, workspaceId');
            MessageType::"Clockify.TimeEntry.Get":
                exit('timeEntryId, workspaceId');
            MessageType::"Clockify.TimeEntry.Create":
                exit('body, userId, workspaceId');
            MessageType::"Clockify.TimeEntry.Update":
                exit('body, timeEntryId, workspaceId');
            MessageType::"Clockify.TimeEntry.Delete":
                exit('timeEntryId, workspaceId');
            MessageType::"Clockify.Currency.List":
                exit('workspaceId');
            MessageType::"Clockify.UserGroup.List":
                exit('query, workspaceId');
            MessageType::"Clockify.CustomField.List":
                exit('query, workspaceId');
            MessageType::"Clockify.TimeEntry.Sync":
                exit('billable, description, end, entryId, journalBatch, journalTemplate, projectId, start, tagIds, taskId, userId, workspaceId');
            MessageType::"Clockify.TimeEntry.SyncRange":
                exit('end, journalBatch, journalTemplate, start, userId, workspaceId');
            MessageType::"Clockify.TimeSheet.Create":
                exit('weeksAhead');
            MessageType::"Clockify.TimeSheet.Approve":
                exit('endingDateTo');
            MessageType::"Clockify.TimeSheet.Reject":
                exit('endingDateTo');
            MessageType::"Clockify.TimeSheet.Reopen":
                exit('endingDateTo');
            MessageType::"Clockify.TimeSheet.Post":
                exit('journalBatch, journalTemplate');
            MessageType::"Clockify.TimeSheet.Archive":
                exit('');
            MessageType::"Clockify.TimeEntry.SyncToTimeSheet":
                exit('billable, description, end, entryId, projectId, start, tagIds, taskId, userId, workspaceId');
            MessageType::"Clockify.TimeEntry.SyncRangeToTimeSheet":
                exit('end, start, userId, workspaceId');
            MessageType::"Clockify.TimeEntry.SyncAllUsers":
                exit('end, journalBatch, journalTemplate, skip, start, take, target, workspaceId');
            else
                Error('No expected parameter list is fixed for %1.', MessageType.AsInteger());
        end;
    end;

    local procedure JoinNames(Parameters: JsonArray): Text
    var
        Names: List of [Text];
        Index: Integer;
        EntryToken: JsonToken;
        Entry: JsonObject;
        NameToken: JsonToken;
        Joined: Text;
        Name: Text;
    begin
        for Index := 0 to Parameters.Count() - 1 do
            if Parameters.Get(Index, EntryToken) then begin
                Entry := EntryToken.AsObject();
                if Entry.Get('name', NameToken) then
                    Names.Add(NameToken.AsValue().AsText());
            end;
        SortNames(Names);
        foreach Name in Names do
            if Joined = '' then
                Joined := Name
            else
                Joined += ', ' + Name;
        exit(Joined);
    end;

    local procedure SortNames(var Names: List of [Text])
    var
        Index: Integer;
        Later: Integer;
        Current: Text;
        Candidate: Text;
    begin
        for Index := 1 to Names.Count() - 1 do
            for Later := Index + 1 to Names.Count() do
                if Names.Get(Later) < Names.Get(Index) then begin
                    Current := Names.Get(Index);
                    Candidate := Names.Get(Later);
                    Names.Set(Index, Candidate);
                    Names.Set(Later, Current);
                end;
    end;

    /// <summary>Both single-entry sync contracts describe their optional data consistently.</summary>
    [Test]
    procedure Scenario_AC06_SyncContracts_DescribeOptionalBillableAndDescription()
    var
        MessageType: Enum "Message Type ori";
    begin
        // Story #46, AC06 | Time: independent of Today()/WorkDate() | Risk: None
        AssertOptionalSyncParameter(MessageType::"Clockify.TimeEntry.Sync", 'billable', 'boolean', 'Whether the time entry is billable. Omitted means billable.');
        AssertOptionalSyncParameter(MessageType::"Clockify.TimeEntry.Sync", 'description', 'string', 'Time-entry description copied onto the Business Central line. Omitted leaves the description blank.');
        AssertOptionalSyncParameter(MessageType::"Clockify.TimeEntry.SyncToTimeSheet", 'billable', 'boolean', 'Whether the time entry is billable. Omitted means billable.');
        AssertOptionalSyncParameter(MessageType::"Clockify.TimeEntry.SyncToTimeSheet", 'description', 'string', 'Time-entry description copied onto the Business Central line. Omitted leaves the description blank.');
    end;

    local procedure AssertOptionalSyncParameter(MessageType: Enum "Message Type ori"; ParameterName: Text; DataType: Text; Description: Text)
    var
        Contract: Interface "Msg Contract ori";
        Parameters: JsonArray;
        ParameterToken: JsonToken;
        Parameter: JsonObject;
        PropertyToken: JsonToken;
    begin
        Contract := MessageType;
        Assert.IsTrue(Contract.GetParameters(Parameters), 'Sync parameters must be present.');
        foreach ParameterToken in Parameters do begin
            Parameter := ParameterToken.AsObject();
            Parameter.Get('name', PropertyToken);
            if PropertyToken.AsValue().AsText() = ParameterName then begin
                Parameter.Get('type', PropertyToken);
                Assert.AreEqual(DataType, PropertyToken.AsValue().AsText(), ParameterName + ' type');
                Parameter.Get('required', PropertyToken);
                Assert.IsFalse(PropertyToken.AsValue().AsBoolean(), ParameterName + ' optional');
                Parameter.Get('description', PropertyToken);
                Assert.AreEqual(Description, PropertyToken.AsValue().AsText(), ParameterName + ' description');
                exit;
            end;
        end;
        Assert.Fail('Sync contract parameter is absent: ' + ParameterName);
    end;
}
