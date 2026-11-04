namespace Origo.Bifrost.Timesheets.Test;

using Microsoft.Inventory.Item;
using Microsoft.Projects.Resources.Journal;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.TimeSheet;
using Origo.Bifrost;
using Origo.Bifrost.Timesheets;
using System.Security.User;

/// <summary>Mock role with usage maintenance but deliberately read-only destination journals.</summary>
permissionset 95640 "TS USAGE NO JNL"
{
    Assignable = false;
    Access = Internal;
    Permissions =
        tabledata "Message Argument ori" = RIMD,
        tabledata "TS Usage Line ori" = RIMD,
        tabledata "Time Sheet Header" = R,
        tabledata "Time Sheet Line" = R,
        tabledata Resource = R,
        tabledata Item = R,
        tabledata "User Setup" = R,
        tabledata "Res. Journal Line" = R,
        tabledata "Res. Journal Batch" = R,
        codeunit "TS Usage Transfer ori" = X,
        codeunit "TS Usage Mgt ori" = X,
        codeunit "TS Usage Context ori" = X,
        codeunit "TS Usage Runner ori" = X,
        codeunit "TS Usage Journals ori" = X;
}
