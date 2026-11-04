namespace Origo.Bifrost.Timesheets;

/// <summary>
/// Phone role center. It shows My Customers plus the customers this user worked
/// for today and on the last workday, and lets the user add a service item as a
/// sales invoice line.
/// </summary>
page 10036860 "Phone Role Center ori"
{
    ApplicationArea = All;
    Caption = 'Phone', Comment = 'is-IS=Sími';
    ContextSensitiveHelpPage = 'timesheets-phone-role-center';
    PageType = RoleCenter;

    layout
    {
        area(RoleCenter)
        {
            part(CurrentCustomers; "Phone Current Cust Part ori")
            {
                ApplicationArea = All;
                Caption = 'Current customers', Comment = 'is-IS=Núverandi viðskiptavinir';
            }
            part(TodayCustomers; "Phone Today Cust Part ori")
            {
                ApplicationArea = All;
                Caption = 'Today', Comment = 'is-IS=Í dag';
            }
            part(LastWorkdayCustomers; "Phone LastDay Cust Part ori")
            {
                ApplicationArea = All;
                Caption = 'Last workday', Comment = 'is-IS=Síðasti virki dagur';
            }
        }
    }
}
