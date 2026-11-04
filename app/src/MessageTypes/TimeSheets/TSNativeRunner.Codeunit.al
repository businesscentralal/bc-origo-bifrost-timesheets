namespace Origo.Bifrost.Timesheets;

using Microsoft.Projects.TimeSheet;

/// <summary>
/// Write isolation for the native time-sheet message types. OnRun is started with
/// Codeunit.Run. A platform error rolls the write back and the caller maps it to a
/// clean refusal. This codeunit does not re-check the request; the manager did that.
/// </summary>
codeunit 10036871 "TS Native Runner ori"
{
    Access = Internal;

    trigger OnRun()
    var
        Context: Codeunit "TS Native Context ori";
    begin
        Submit(Context);
    end;

    local procedure Submit(Context: Codeunit "TS Native Context ori")
    var
        TimeSheetLine: Record "Time Sheet Line";
        ApprovalMgt: Codeunit "Time Sheet Approval Management";
        Lines: JsonArray;
    begin
        SelectLines(Context, TimeSheetLine);
        if TimeSheetLine.FindSet(true) then
            repeat
                if TimeSheetLine.Status = TimeSheetLine.Status::Open then begin
                    ApprovalMgt.Submit(TimeSheetLine);
                    TimeSheetLine.Get(TimeSheetLine."Time Sheet No.", TimeSheetLine."Line No.");
                    Lines.Add(LineNode(TimeSheetLine, TimeSheetLine.Status = TimeSheetLine.Status::Submitted));
                end else
                    Lines.Add(LineNode(TimeSheetLine, false));
            until TimeSheetLine.Next() = 0;
        StoreLines(Context, Lines);
    end;

    local procedure SelectLines(Context: Codeunit "TS Native Context ori"; var TimeSheetLine: Record "Time Sheet Line")
    begin
        TimeSheetLine.SetRange("Time Sheet No.", Context.GetSheetNo());
        if Context.GetLineFilter() <> '*' then
            TimeSheetLine.SetFilter("Line No.", Context.GetLineFilter());
    end;

    local procedure LineNode(TimeSheetLine: Record "Time Sheet Line"; Changed: Boolean) Node: JsonObject
    begin
        Node.Add('timeSheetNo', TimeSheetLine."Time Sheet No.");
        Node.Add('lineNo', TimeSheetLine."Line No.");
        Node.Add('status', TimeSheetLine.Status.Names().Get(TimeSheetLine.Status.Ordinals().IndexOf(TimeSheetLine.Status.AsInteger())));
        Node.Add('changed', Changed);
        Node.Add('lineType', TimeSheetLine.Type.Names().Get(TimeSheetLine.Type.Ordinals().IndexOf(TimeSheetLine.Type.AsInteger())));
    end;

    local procedure StoreLines(Context: Codeunit "TS Native Context ori"; Lines: JsonArray)
    var
        Response: JsonObject;
    begin
        Response.Add('status', 'Success');
        Response.Add('lines', Lines);
        Context.SetResult(JsonText(Response));
    end;

    local procedure JsonText(Response: JsonObject): Text
    var
        Result: Text;
    begin
        Response.WriteTo(Result);
        exit(Result);
    end;
}
