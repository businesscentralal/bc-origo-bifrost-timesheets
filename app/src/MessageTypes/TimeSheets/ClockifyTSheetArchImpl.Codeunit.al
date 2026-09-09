namespace Origo.Bifrost.Timesheets;

using Microsoft.Projects.TimeSheet;
using Origo.Bifrost;

/// <summary>
/// Implementation of the <c>Clockify.TimeSheet.Archive</c> message type. Archives fully
/// posted time sheets and removes empty posted sheets. BC-side operation — does not call
/// the Clockify API.
/// </summary>
codeunit 10036837 "Clockify TSheetArch Impl ori" implements "Msg Interface ori"
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

    internal procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit(Enum::"Msg Direction ori"::Inbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "Message Argument ori")
    var
        Help: Codeunit "Clockify TimeSheet Help ori";
    begin
        Argument.SetResponseMarkdown(Help.GetHelp(Enum::"Message Type ori"::"Clockify.TimeSheet.Archive", GetDescription()));
    end;

    internal procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    var
        TimeSheetMgt: Codeunit "Clockify TimeSheet Mgt ori";
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
