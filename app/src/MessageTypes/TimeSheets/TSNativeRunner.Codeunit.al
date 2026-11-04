namespace Origo.Bifrost.Timesheets;

/// <summary>Executes the existing time sheet engine inside a captured Codeunit.Run transaction.</summary>
codeunit 10036871 "TS Native Runner ori"
{
    Access = Internal;

    trigger OnRun()
    var
        Context: Codeunit "TS Native Context ori";
    begin
        RunBulkTimeSheetOperation(Context);
    end;

    local procedure RunBulkTimeSheetOperation(Context: Codeunit "TS Native Context ori")
    var
        TimeSheetMgt: Codeunit "Clockify TimeSheet Mgt ori";
        Response: JsonObject;
        ResponseText: Text;
    begin
        Response.Add('status', 'Success');
        case Context.GetOperation() of
            8:
                Response.Add('reopenedLines', TimeSheetMgt.ReopenTimeSheets(Context.GetStartDate()));
            9:
                Response.Add('postedLines', TimeSheetMgt.PostApprovedTimeSheets(Context.GetJournalTemplate(), Context.GetJournalBatch()));
            10:
                Response.Add('archived', TimeSheetMgt.ArchivePostedTimeSheets());
        end;
        Response.WriteTo(ResponseText);
        Context.SetResult(ResponseText);
    end;
}
