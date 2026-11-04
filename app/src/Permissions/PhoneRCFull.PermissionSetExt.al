namespace Origo.Bifrost.Timesheets;

using Origo.Bifrost;

/// <summary>
/// Grants the phone Role Center, including the sales-invoice add, to holders of
/// BIFROST Full ori. Read-only holders use the separate read extension.
/// </summary>
permissionsetextension 10036866 "Phone RC Full Ext ori" extends "BIFROST Full ori"
{
    Permissions =
        tabledata "Phone Cust Buffer ori" = RIMD,
        codeunit "Phone Cust Buffer Mgt ori" = X,
        codeunit "Phone Sales Quick Add ori" = X,
        page "Phone Role Center ori" = X,
        page "Phone Current Cust Part ori" = X,
        page "Phone Today Cust Part ori" = X,
        page "Phone LastDay Cust Part ori" = X,
        page "Phone Add Service Item ori" = X;
}
