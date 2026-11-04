namespace Origo.Bifrost.Timesheets;

using Origo.Bifrost;

/// <summary>
/// Grants the phone Role Center lists to holders of BIFROST Read ori.
/// The add action and the sales-invoice codeunit stay on the Full extension.
/// </summary>
permissionsetextension 10036867 "Phone RC Read Ext ori" extends "BIFROST Read ori"
{
    Permissions =
        codeunit "TS Sheet Reopen Impl ori" = X,
        codeunit "TS Sheet Post Impl ori" = X,
        codeunit "TS Sheet Archive Impl ori" = X,
        codeunit "TS Native Mgt ori" = X,
        codeunit "TS Contract Parts ori" = X,
        codeunit "TS Native Context ori" = X,
        codeunit "TS Native Runner ori" = X,
        codeunit "TS Sheet Restrict ori" = X,
        codeunit "TS Sheet Approve Impl ori" = X,
        codeunit "TS Sheet Reject Impl ori" = X,
        codeunit "TS Sheet Create Impl ori" = X,
        codeunit "TS Create Contract ori" = X,
        codeunit "TS Create Restrict ori" = X,
        codeunit "TS Pending Approval ori" = X,
        tabledata "Phone Cust Buffer ori" = R,
        codeunit "Phone Cust Buffer Mgt ori" = X,
        page "Phone Role Center ori" = X,
        page "Phone Current Cust Part ori" = X,
        page "Phone Today Cust Part ori" = X,
        page "Phone LastDay Cust Part ori" = X;
}
