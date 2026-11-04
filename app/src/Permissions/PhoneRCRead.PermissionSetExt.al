namespace Origo.Bifrost.Timesheets;

using Origo.Bifrost;
using Microsoft.HumanResources.Absence;
using Microsoft.HumanResources.Employee;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.Resources.Setup;
using Microsoft.Projects.TimeSheet;

/// <summary>
/// Grants the phone Role Center lists to holders of BIFROST Read ori.
/// The add action and the sales-invoice codeunit stay on the Full extension.
/// </summary>
permissionsetextension 10036867 "Phone RC Read Ext ori" extends "BIFROST Read ori"
{
    Permissions =
        codeunit "TS Native Mgt ori" = X,
        codeunit "TS Contract Parts ori" = X,
        codeunit "TS Absence Reg Impl ori" = X,
        codeunit "Clockify Field Restrict ori" = X,
        tabledata "Time Sheet Header" = R,
        tabledata "Time Sheet Line" = R,
        tabledata "Time Sheet Detail" = R,
        tabledata "Cause of Absence" = R,
        tabledata Employee = R,
        tabledata Resource = R,
        tabledata "Resources Setup" = R,
        tabledata "Phone Cust Buffer ori" = R,
        codeunit "Phone Cust Buffer Mgt ori" = X,
        page "Phone Role Center ori" = X,
        page "Phone Current Cust Part ori" = X,
        page "Phone Today Cust Part ori" = X,
        page "Phone LastDay Cust Part ori" = X;
}
