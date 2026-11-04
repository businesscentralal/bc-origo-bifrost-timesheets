namespace Origo.Bifrost.Timesheets.Test;

using Origo.Bifrost;

/// <summary>Test-app-only fixture preparation and cleanup for owned usage acceptance.</summary>
enumextension 95637 "TS Usage Fixture Types ori" extends "Message Type ori"
{
    /// <summary>Creates and cleans only nonce-isolated CRONUS verification records.</summary>
    value(95637; "Test.UsageFixture.Manage")
    {
        Caption = 'Test.UsageFixture.Manage', Locked = true;
        Implementation = "Msg Interface ori" = "TS Usage Fixture ori", "Msg Contract ori" = "TS Usage Fixture Contract ori";
    }
}
