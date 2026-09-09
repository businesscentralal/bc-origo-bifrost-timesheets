namespace Origo.Bifrost.Timesheets.Providers.Clockify;

/// <summary>
/// Represents the outcome of synchronizing a Clockify time entry to Business Central.
/// </summary>
enum 10036786 "Clockify Sync Result ori"
{
    Extensible = false;
    Access = Internal;

    /// <summary>A new Job Journal Line was created.</summary>
    value(0; Created)
    {
        Caption = 'Created', Comment = 'is-IS=Stofnað';
    }
    /// <summary>The time entry was already synced and unchanged — no action taken.</summary>
    value(1; Skipped)
    {
        Caption = 'Skipped', Comment = 'is-IS=Sleppt';
    }
    /// <summary>The time entry was already synced but had changed — reversal + new line created.</summary>
    value(2; Corrected)
    {
        Caption = 'Corrected', Comment = 'is-IS=Leiðrétt';
    }
    /// <summary>The time entry was already synced and its unposted journal line was updated in place.</summary>
    value(3; Updated)
    {
        Caption = 'Updated', Comment = 'is-IS=Uppfært';
    }
    /// <summary>The sync failed due to a missing mapping or other error.</summary>
    value(4; Error)
    {
        Caption = 'Error', Comment = 'is-IS=Villa';
    }
}
