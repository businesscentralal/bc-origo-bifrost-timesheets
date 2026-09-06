namespace Origo.PTE.CloudEvents.Clockify;

using Microsoft.Projects.TimeSheet;
using Origo.APP.CloudEvents;

/// <summary>
/// Implementation of the <c>Clockify.TimeSheet.Create</c> message type. Ensures every
/// time-sheet resource has upcoming weekly time sheets. BC-side operation — does not
/// call the Clockify API.
/// </summary>
codeunit 70009249 "Clockify TimeSheetCreate Impl" implements "Cloud Event Msg Interface ori"
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

    internal procedure GetMessageDirection(): Enum "Cloud Event Msg Direction ori"
    begin
        exit(Enum::"Cloud Event Msg Direction ori"::Inbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "CE Message Argument ori")
    var
        Help: Codeunit "Clockify TimeSheet Help";
    begin
        Argument.SetResponseMarkdown(Help.GetCreateHelp(GetDescription()));
    end;

    internal procedure ExecuteCloudEventTask(var Argument: Record "CE Message Argument ori")
    var
        TimeSheetMgt: Codeunit "Clockify TimeSheet Mgt";
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
