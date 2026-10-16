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
            "Help.Clockify.Get":
                exit('');
            "Clockify.Workspace.List":
                exit('query');
            "Clockify.User.GetCurrent":
                exit('');
            "Clockify.User.List":
                exit('query, workspaceId');
            "Clockify.Client.List":
                exit('query, workspaceId');
            "Clockify.Client.Get":
                exit('clientId, workspaceId');
            "Clockify.Client.Create":
                exit('body, workspaceId');
            "Clockify.Client.Update":
                exit('body, clientId, workspaceId');
            "Clockify.Client.Delete":
                exit('clientId, workspaceId');
            "Clockify.Project.List":
                exit('query, workspaceId');
            "Clockify.Project.Get":
                exit('projectId, workspaceId');
            "Clockify.Project.Create":
                exit('body, workspaceId');
            "Clockify.Project.Update":
                exit('body, projectId, workspaceId');
            "Clockify.Project.Delete":
                exit('projectId, workspaceId');
            "Clockify.Task.List":
                exit('projectId, query, workspaceId');
            "Clockify.Task.Create":
                exit('body, projectId, workspaceId');
            "Clockify.Task.Update":
                exit('body, projectId, taskId, workspaceId');
            "Clockify.Task.Delete":
                exit('projectId, taskId, workspaceId');
            "Clockify.Tag.List":
                exit('query, workspaceId');
            "Clockify.Tag.Create":
                exit('body, workspaceId');
            "Clockify.Tag.Update":
                exit('body, tagId, workspaceId');
            "Clockify.Tag.Delete":
                exit('tagId, workspaceId');
            "Clockify.TimeEntry.List":
                exit('query, userId, workspaceId');
            "Clockify.TimeEntry.Get":
                exit('timeEntryId, workspaceId');
            "Clockify.TimeEntry.Create":
                exit('body, userId, workspaceId');
            "Clockify.TimeEntry.Update":
                exit('body, timeEntryId, workspaceId');
            "Clockify.TimeEntry.Delete":
                exit('timeEntryId, workspaceId');
            "Clockify.Currency.List":
                exit('workspaceId');
            "Clockify.UserGroup.List":
                exit('query, workspaceId');
            "Clockify.CustomField.List":
                exit('query, workspaceId');
            "Clockify.TimeEntry.Sync":
                exit('billable, description, end, entryId, journalBatch, journalTemplate, projectId, start, tagIds, taskId, userId, workspaceId');
            "Clockify.TimeEntry.SyncRange":
                exit('end, journalBatch, journalTemplate, start, userId, workspaceId');
            "Clockify.TimeSheet.Create":
                exit('weeksAhead');
            "Clockify.TimeSheet.Approve":
                exit('endingDateTo');
            "Clockify.TimeSheet.Reject":
                exit('endingDateTo');
            "Clockify.TimeSheet.Reopen":
                exit('endingDateTo');
            "Clockify.TimeSheet.Post":
                exit('journalBatch, journalTemplate');
            "Clockify.TimeSheet.Archive":
                exit('');
            "Clockify.TimeEntry.SyncToTimeSheet":
                exit('billable, description, end, entryId, projectId, start, tagIds, taskId, userId, workspaceId');
            "Clockify.TimeEntry.SyncRangeToTimeSheet":
                exit('end, start, userId, workspaceId');
            "Clockify.TimeEntry.SyncAllUsers":
                exit('end, journalBatch, journalTemplate, start, target, userId, workspaceId');
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
        Names.Sort();
        foreach Name in Names do
            if Joined = '' then
                Joined := Name
            else
                Joined += ', ' + Name;
        exit(Joined);
    end;
}
