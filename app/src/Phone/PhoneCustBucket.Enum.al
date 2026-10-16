namespace Origo.Bifrost.Timesheets;

/// <summary>
/// Groups the phone Role Center customer rows. Current comes from My Customers.
/// Today and LastWorkday come from the signed-in user's Clockify time entries.
/// </summary>
enum 10036856 "Phone Cust Bucket ori"
{
    Extensible = false;

    value(0; Current)
    {
        Caption = 'Current', Comment = 'is-IS=Núverandi';
    }
    value(1; Today)
    {
        Caption = 'Today', Comment = 'is-IS=Í dag';
    }
    value(2; LastWorkday)
    {
        Caption = 'Last workday', Comment = 'is-IS=Síðasti virki dagur';
    }
}
