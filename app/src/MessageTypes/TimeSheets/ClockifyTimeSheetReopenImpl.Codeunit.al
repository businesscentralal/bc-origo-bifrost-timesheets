namespace Origo.PTE.CloudEvents.Clockify;

using Microsoft.Projects.TimeSheet;
using Origo.APP.CloudEvents;

/// <summary>
/// Implementation of the <c>Clockify.TimeSheet.Reopen</c> message type. Reopens submitted or
/// approved time-sheet lines back to Open, up to a cut-off ending date. BC-side operation —
/// does not call the Clockify API.
/// </summary>
/// <remarks>Runs the base time-sheet approval engine; no Clockify API call.</remarks>
codeunit 70009259 "Clockify TimeSheetReopen Impl" implements "Cloud Event Msg Interface ori"
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
        exit('Reopens submitted or approved time-sheet lines back to Open, up to a cut-off date.');
    end;

    internal procedure GetMessageDirection(): Enum "Cloud Event Msg Direction ori"
    begin
        exit(Enum::"Cloud Event Msg Direction ori"::Inbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "CE Message Argument ori")
    var
        Help: Codeunit "Clockify TimeSheet Help";
    begin
        Argument.SetResponseMarkdown(Help.GetReopenHelp(GetDescription()));
    end;

    internal procedure ExecuteCloudEventTask(var Argument: Record "CE Message Argument ori")
    var
        TimeSheetMgt: Codeunit "Clockify TimeSheet Mgt";
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
        JsonToken: JsonToken;
        EndingDateTo: Date;
        ReopenedLineCount: Integer;
    begin
        Argument.AssertVersion1();
        RequestJson := Argument.GetRequestJson();
        if RequestJson.Get('endingDateTo', JsonToken) then
            if JsonToken.IsValue() then
                if not Evaluate(EndingDateTo, JsonToken.AsValue().AsText(), 9) then
                    EndingDateTo := 0D;

        ReopenedLineCount := TimeSheetMgt.ReopenTimeSheets(EndingDateTo);

        ResponseJson.Add('status', 'Success');
        ResponseJson.Add('reopenedLines', ReopenedLineCount);
        Argument.SetResponseJson(ResponseJson);
    end;
}
