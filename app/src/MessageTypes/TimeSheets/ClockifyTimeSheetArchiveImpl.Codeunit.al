namespace Origo.PTE.CloudEvents.Clockify;

using Microsoft.Projects.TimeSheet;
using Origo.APP.CloudEvents;

/// <summary>
/// Implementation of the <c>Clockify.TimeSheet.Archive</c> message type. Archives fully
/// posted time sheets and removes empty posted sheets. BC-side operation — does not call
/// the Clockify API.
/// </summary>
codeunit 70009252 "Clockify TimeSheetArchive Impl" implements "Cloud Event Msg Interface ori"
{
    Access = Internal;

    internal procedure IsEnabled(): Boolean
    var
        TimeSheetHeader: Record "Time Sheet Header";
    begin
        exit(TimeSheetHeader.WritePermission());
    end;

    internal procedure GetFilterTableNo(): Integer
    begin
        exit(0);
    end;

    internal procedure GetDescription(): Text[250]
    begin
        exit('Archives fully posted time sheets and removes empty posted sheets ending before the work date.');
    end;

    internal procedure GetMessageDirection(): Enum "Cloud Event Msg Direction ori"
    begin
        exit(Enum::"Cloud Event Msg Direction ori"::Inbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "CE Message Argument ori")
    var
        Help: Codeunit "Clockify TimeSheet Help";
    begin
        Argument.SetResponseMarkdown(Help.GetArchiveHelp(GetDescription()));
    end;

    internal procedure ExecuteCloudEventTask(var Argument: Record "CE Message Argument ori")
    var
        TimeSheetMgt: Codeunit "Clockify TimeSheet Mgt";
        ResponseJson: JsonObject;
        ArchivedCount: Integer;
    begin
        Argument.AssertVersion1();
        ArchivedCount := TimeSheetMgt.ArchivePostedTimeSheets();

        ResponseJson.Add('status', 'Success');
        ResponseJson.Add('archived', ArchivedCount);
        Argument.SetResponseJson(ResponseJson);
    end;
}
