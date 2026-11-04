namespace Origo.Bifrost.Timesheets;

using Origo.Bifrost;

/// <summary>Blocks generic creation or mutation that would bypass usage ownership and transitions.</summary>
codeunit 10036861 "TS Usage Restrict ori"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Table, Database::"Message Argument ori", OnAfterIsTableWriteRestrictedForDataRecords, '', false, false)]
    local procedure RestrictUsage(TableNo: Integer; var IsRestricted: Boolean)
    begin
        if TableNo = Database::"TS Usage Line ori" then
            IsRestricted := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Message Argument ori", OnGetDedicatedMessageTypeHintForWrite, '', false, false)]
    local procedure UsageHint(TableNo: Integer; var Hint: Text)
    begin
        if TableNo = Database::"TS Usage Line ori" then
            Hint := 'Timesheets.Usage.Register, Timesheets.Usage.Submit, Timesheets.Usage.Approve, Timesheets.Usage.Reject, Timesheets.Usage.Transfer, Timesheets.Usage.Reverse';
    end;
}
