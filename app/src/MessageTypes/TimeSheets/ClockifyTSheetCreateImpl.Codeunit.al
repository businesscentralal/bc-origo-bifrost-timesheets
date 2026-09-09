namespace Origo.Bifrost.Timesheets;

using Microsoft.Projects.TimeSheet;
using Origo.Bifrost;

/// <summary>
/// Implementation of the <c>Clockify.TimeSheet.Create</c> message type. Ensures every
/// time-sheet resource has upcoming weekly time sheets. BC-side operation — does not
/// call the Clockify API.
/// </summary>
codeunit 10036834 "Clockify TSheetCreate Impl ori" implements "Msg Interface ori"
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
        exit('Creates upcoming weekly time sheets for every time-sheet resource (No. Series + owner + period handled).');
    end;

    internal procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit(Enum::"Msg Direction ori"::Inbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "Message Argument ori")
    var
        Help: Codeunit "Clockify TimeSheet Help ori";
    begin
        Argument.SetResponseMarkdown(Help.GetHelp(Enum::"Message Type ori"::"Clockify.TimeSheet.Create", GetDescription()));
    end;

    internal procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    var
        TimeSheetMgt: Codeunit "Clockify TimeSheet Mgt ori";
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
        JsonToken: JsonToken;
        WeeksAhead: Integer;
        CreatedCount: Integer;
    begin
        Argument.AssertVersion1();
        RequestJson := Argument.GetRequestJson();
        if RequestJson.Get('weeksAhead', JsonToken) then
            if JsonToken.IsValue() then
                WeeksAhead := JsonToken.AsValue().AsInteger();

        CreatedCount := TimeSheetMgt.CreateUpcomingTimeSheets(WeeksAhead);

        ResponseJson.Add('status', 'Success');
        ResponseJson.Add('created', CreatedCount);
        Argument.SetResponseJson(ResponseJson);
    end;
}
