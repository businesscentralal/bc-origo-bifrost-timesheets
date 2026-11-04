namespace Origo.Bifrost.Timesheets;

using Origo.Bifrost;
using Microsoft.HumanResources.Absence;
using Microsoft.HumanResources.Employee;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.Resources.Setup;
using Microsoft.Projects.TimeSheet;

/// <summary>
/// Grants the phone Role Center, including the sales-invoice add, to holders of
/// BIFROST Full ori. Read-only holders use the separate read extension.
/// </summary>
permissionsetextension 10036866 "Phone RC Full Ext ori" extends "BIFROST Full ori"
{
    Permissions =
        codeunit "TS Native Mgt ori" = X,
        codeunit "TS Contract Parts ori" = X,
        codeunit "TS Native Context ori" = X,
        codeunit "TS Native Runner ori" = X,
        codeunit "TS Absence Reg Impl ori" = X,
        codeunit "Clockify Field Restrict ori" = X,
        tabledata "Time Sheet Header" = RIMD,
        tabledata "Time Sheet Line" = RIMD,
        tabledata "Time Sheet Detail" = RIMD,
        tabledata "Cause of Absence" = R,
        tabledata Employee = R,
        tabledata Resource = R,
        tabledata "Resources Setup" = R,
        tabledata "Phone Cust Buffer ori" = RIMD,
        codeunit "Phone Cust Buffer Mgt ori" = X,
        codeunit "Phone Sales Quick Add ori" = X,
        page "Phone Role Center ori" = X,
        page "Phone Current Cust Part ori" = X,
        page "Phone Today Cust Part ori" = X,
        page "Phone LastDay Cust Part ori" = X,
        page "Phone Add Service Item ori" = X;
}
