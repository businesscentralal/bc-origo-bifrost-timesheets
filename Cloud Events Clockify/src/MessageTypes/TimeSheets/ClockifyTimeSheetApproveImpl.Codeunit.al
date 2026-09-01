namespace Origo.PTE.CloudEvents.Clockify;

using Microsoft.Projects.TimeSheet;
using Origo.APP.CloudEvents;

/// <summary>
/// Implementation of the <c>Clockify.TimeSheet.Approve</c> message type. Submits and
/// approves open time-sheet lines up to a cut-off ending date. BC-side operation —
/// does not call the Clockify API.
/// </summary>
codeunit 70009250 "Clockify TimeSheetApprove Impl" implements "Cloud Event Msg Interface ori"
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
        exit('Submits and approves open time-sheet lines whose sheet ends on or before a cut-off date.');
    end;

    internal procedure GetMessageDirection(): Enum "Cloud Event Msg Direction ori"
    begin
        exit(Enum::"Cloud Event Msg Direction ori"::Inbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "CE Message Argument ori")
    var
        Help: Codeunit "Clockify TimeSheet Help";
    begin
        Argument.SetResponseMarkdown(Help.GetApproveHelp(GetDescription()));
    end;

    internal procedure ExecuteCloudEventTask(var Argument: Record "CE Message Argument ori")
    var
        TimeSheetMgt: Codeunit "Clockify TimeSheet Mgt";
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
        JsonToken: JsonToken;
        EndingDateTo: Date;
        ApprovedLineCount: Integer;
    begin
        Argument.AssertVersion1();
        RequestJson := Argument.GetRequestJson();
        if RequestJson.Get('endingDateTo', JsonToken) then
            if JsonToken.IsValue() then
                if not Evaluate(EndingDateTo, JsonToken.AsValue().AsText(), 9) then
                    EndingDateTo := 0D;

        ApprovedLineCount := TimeSheetMgt.ApprovePendingTimeSheets(EndingDateTo);

        ResponseJson.Add('status', 'Success');
        ResponseJson.Add('approvedLines', ApprovedLineCount);
        Argument.SetResponseJson(ResponseJson);
    end;
}
