namespace Origo.Bifrost.Timesheets;

using Microsoft.Projects.TimeSheet;

/// <summary>Explicit read-only usage access without journal or state-change writes.</summary>
permissionset 10036878 "TS Usage Read ori"
{
    Assignable = true;
    Caption = 'Time Sheet Usage Read', Comment = 'is-IS=Lesa notkun tímaskýrslu';
    Permissions =
        tabledata "TS Usage Line ori" = R,
        table "TS Usage Line ori" = X,
        tabledata "Time Sheet Header" = R,
        tabledata "Time Sheet Line" = R,
        codeunit "TS Usage List ori" = X,
        codeunit "TS Usage Register ori" = X,
        codeunit "TS Usage Submit ori" = X,
        codeunit "TS Usage Approve ori" = X,
        codeunit "TS Usage Reject ori" = X,
        codeunit "TS Usage Transfer ori" = X,
        codeunit "TS Usage Reverse ori" = X,

        codeunit "TS Usage Mgt ori" = X,
        codeunit "TS Usage Context ori" = X,
        codeunit "TS Usage Contract ori" = X,
        codeunit "TS Usage Restrict ori" = X,
        page "TS Usage Lines ori" = X;
}
