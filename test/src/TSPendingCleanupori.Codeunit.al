namespace Origo.Bifrost.Timesheets.Test;

/// <summary>Runs explicit cleanup of owned issue 62 live-verification records.</summary>
codeunit 95632 "TS Pending Cleanup ori"
{
    trigger OnRun()
    var
        Fixture: Codeunit "TS Pending Fixture ori";
    begin
        Fixture.Cleanup();
    end;
}
