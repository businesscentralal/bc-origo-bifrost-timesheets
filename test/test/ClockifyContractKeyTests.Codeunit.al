namespace Origo.Bifrost.Timesheets.Test;

using Origo.Bifrost;
using Origo.Bifrost.Timesheets;
using System.TestLibraries.Utilities;

/// <summary>
/// Asserts that each Clockify message contract declares exactly the parameter names its implementation reads.
/// The expectation is a fixed list, not a copy of the contract under test (timesheets#46).
/// </summary>
codeunit 95614 "Clockify Contract Key Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryAssert: Codeunit "Library Assert";

    /// <summary>Every Clockify message type declares the parameter names fixed in this test.</summary>
    [Test]
    procedure EveryType_DeclaresOnlyItsOwnParameterNames()
    var
        MessageType: Enum "Message Type ori";
        Contract: Interface "Msg Contract ori";
        Parameters: JsonArray;
        Expected: Text;
        Name: Text;
        Ordinals: List of [Integer];
        Ordinal: Integer;
    begin
        Ordinals := Enum::"Message Type ori".Ordinals();
        foreach Ordinal in Ordinals do begin
            MessageType := Enum::"Message Type ori".FromInteger(Ordinal);
            Name := Format(MessageType);
            if not IsClockifyType(Name) then
                continue;
            Expected := ExpectedNames(MessageType);
            Clear(Parameters);
            Contract := MessageType;
            if Expected = '' then
                LibraryAssert.IsFalse(Contract.GetParameters(Parameters), Name + ' should declare no parameters.')
            else
                LibraryAssert.IsTrue(Contract.GetParameters(Parameters), Name + ' should declare parameters.');
            LibraryAssert.AreEqual(Expected, JoinNames(Parameters), Name);
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
                exit('end, journalBatch, journalTemplate, start, target, userId, workspaceId');
            else
                Error('No expected parameter list is fixed for %1.', MessageType);
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
}
