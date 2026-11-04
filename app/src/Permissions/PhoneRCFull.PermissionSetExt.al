namespace Origo.Bifrost.Timesheets;

using Origo.Bifrost;

/// <summary>
/// Grants the phone Role Center, including the sales-invoice add, to holders of
/// BIFROST Full ori. Decision handlers require the separately assigned Timesheets native permissions.
/// Read-only holders use the separate read extension.
/// </summary>
permissionsetextension 10036866 "Phone RC Full Ext ori" extends "BIFROST Full ori"
{
    Permissions =
        codeunit "TS Native Mgt ori" = X,
        codeunit "TS Contract Parts ori" = X,
        codeunit "TS Native Context ori" = X,
        codeunit "TS Native Runner ori" = X,
        codeunit "TS Sheet Restrict ori" = X,
        codeunit "TS Sheet Approve Impl ori" = X,
        codeunit "TS Sheet Reject Impl ori" = X,
        codeunit "TS Sheet Create Impl ori" = X,
        codeunit "TS Create Contract ori" = X,
        codeunit "TS Create Writer ori" = X,
        codeunit "TS Create Restrict ori" = X,
        codeunit "TS Pending Approval ori" = X,
        tabledata "Phone Cust Buffer ori" = RIMD,
        codeunit "Phone Cust Buffer Mgt ori" = X,
        codeunit "Phone Sales Quick Add ori" = X,
        page "Phone Role Center ori" = X,
        page "Phone Current Cust Part ori" = X,
        page "Phone Today Cust Part ori" = X,
        page "Phone LastDay Cust Part ori" = X,
        page "Phone Add Service Item ori" = X;
}
