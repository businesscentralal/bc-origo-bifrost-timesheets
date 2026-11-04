namespace Origo.Bifrost.Timesheets;

/// <summary>Stable usage status values.</summary>
enum 10036878 "TS Usage Status ori"
{
    /// <summary>Open usage.</summary>
    value(0; Open)
    {
        Caption = 'Open', Comment = 'is-IS=Opin';
    }
    /// <summary>Submitted usage.</summary>
    value(1; Submitted)
    {
        Caption = 'Submitted', Comment = 'is-IS=Innsend';
    }
    /// <summary>Approved usage.</summary>
    value(2; Approved)
    {
        Caption = 'Approved', Comment = 'is-IS=Samþykkt';
    }
    /// <summary>Rejected usage.</summary>
    value(3; Rejected)
    {
        Caption = 'Rejected', Comment = 'is-IS=Hafnað';
    }
    /// <summary>Posted usage.</summary>
    value(4; Posted)
    {
        Caption = 'Posted', Comment = 'is-IS=Bókuð';
    }
}
