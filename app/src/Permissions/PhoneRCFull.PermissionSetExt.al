namespace Origo.Bifrost.Timesheets;

using Origo.Bifrost;

/// <summary>
/// Grants the phone Role Center and native time sheet actions to holders of
/// BIFROST Full ori. Standard BC data permissions remain the caller's responsibility.
/// </summary>
permissionsetextension 10036866 "Phone RC Full Ext ori" extends "BIFROST Full ori"
{
    Permissions =
        codeunit "TS Sheet Reopen Impl ori" = X,
        codeunit "TS Sheet Post Impl ori" = X,
        codeunit "TS Sheet Archive Impl ori" = X,
        codeunit "TS Contract Parts ori" = X,
        codeunit "TS Native Mgt ori" = X,
        codeunit "TS Native Context ori" = X,
        codeunit "TS Native Runner ori" = X,
        codeunit "Clockify TimeSheet Mgt ori" = X,
        codeunit "Clockify Setup Mgt ori" = X,
        tabledata "Clockify Setup ori" = R,
        tabledata "Phone Cust Buffer ori" = RIMD,
        codeunit "Phone Cust Buffer Mgt ori" = X,
        codeunit "Phone Sales Quick Add ori" = X,
        page "Phone Role Center ori" = X,
        page "Phone Current Cust Part ori" = X,
        page "Phone Today Cust Part ori" = X,
        page "Phone LastDay Cust Part ori" = X,
        page "Phone Add Service Item ori" = X;
}
