namespace Origo.Bifrost.Timesheets;

/// <summary>Runs a usage write in one commit-or-rollback transaction.</summary>
codeunit 10036851 "TS Usage Runner ori"
{
    Access = Internal;
    trigger OnRun()
    var
        Management: Codeunit "TS Usage Mgt ori";
    begin
        Management.ApplyRequest();
    end;
}
