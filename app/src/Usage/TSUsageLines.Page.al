namespace Origo.Bifrost.Timesheets;

using Microsoft.Projects.TimeSheet;

/// <summary>Read-only usage worklist limited to sheets addressed to the authenticated approver.</summary>
page 10036878 "TS Usage Lines ori"
{
    PageType = List;
    SourceTable = "TS Usage Line ori";
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'Time Sheet Usage Lines', Comment = 'is-IS=Notkunarlínur tímaskýrslu';
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
                field("Time Sheet No."; Rec."Time Sheet No.")
                {
                    ApplicationArea = All;
                }
                field("Time Sheet Line No."; Rec."Time Sheet Line No.")
                {
                    ApplicationArea = All;
                }
                field("Resource No."; Rec."Resource No.")
                {
                    ApplicationArea = All;
                }
                field("Type"; Rec."Type")
                {
                    ApplicationArea = All;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field("Date"; Rec."Date")
                {
                    ApplicationArea = All;
                }
                field("Quantity"; Rec."Quantity")
                {
                    ApplicationArea = All;
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = All;
                }
                field("Description"; Rec."Description")
                {
                    ApplicationArea = All;
                }
                field("Status"; Rec."Status")
                {
                    ApplicationArea = All;
                }
                field("Reversed"; Rec."Reversed")
                {
                    ApplicationArea = All;
                }
                field("Approved By"; Rec."Approved By")
                {
                    ApplicationArea = All;
                }
                field("Approved At"; Rec."Approved At")
                {
                    ApplicationArea = All;
                }
                field("Journal Template"; Rec."Journal Template")
                {
                    ApplicationArea = All;
                }
                field("Journal Batch"; Rec."Journal Batch")
                {
                    ApplicationArea = All;
                }
                field("Journal Line No."; Rec."Journal Line No.")
                {
                    ApplicationArea = All;
                }
                field("Ledger Entry No."; Rec."Ledger Entry No.")
                {
                    ApplicationArea = All;
                }
                field("Rejection Comment"; Rec."Rejection Comment")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
    trigger OnOpenPage()
    var
        Header: Record "Time Sheet Header";
        SheetFilter: Text;
    begin
        Header.ReadIsolation := IsolationLevel::ReadCommitted;
        Header.SetLoadFields("No.", "Approver User ID");
        Header.SetRange("Approver User ID", UserId());
        if Header.FindSet() then
            repeat
                if SheetFilter <> '' then
                    SheetFilter += '|';
                SheetFilter += Header."No.";
            until Header.Next() = 0;
        Rec.FilterGroup(2);
        if SheetFilter = '' then
            Rec.SetRange("Entry No.", -1)
        else
            Rec.SetFilter("Time Sheet No.", SheetFilter);
        Rec.FilterGroup(0);
    end;
}
