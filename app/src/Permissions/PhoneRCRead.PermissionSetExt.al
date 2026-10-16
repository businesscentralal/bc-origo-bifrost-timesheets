namespace Origo.Bifrost.Timesheets;

using Origo.Bifrost;

/// <summary>
/// Grants the phone Role Center lists to holders of BIFROST Read ori.
/// The add action and the sales-invoice codeunit stay on the Full extension.
/// </summary>
permissionsetextension 10036867 "Phone RC Read Ext ori" extends "BIFROST Read ori"
{
    Permissions =
        tabledata "Phone Cust Buffer ori" = R,
        codeunit "Phone Cust Buffer Mgt ori" = X,
        page "Phone Role Center ori" = X,
        page "Phone Current Cust Part ori" = X,
        page "Phone Today Cust Part ori" = X,
        page "Phone LastDay Cust Part ori" = X;
}
