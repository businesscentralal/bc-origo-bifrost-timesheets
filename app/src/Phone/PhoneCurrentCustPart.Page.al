namespace Origo.Bifrost.Timesheets;

/// <summary>
/// Current customers on the phone Role Center. The rows are the signed-in user's My Customers.
/// </summary>
page 10036861 "Phone Current Cust Part ori"
{
    ApplicationArea = All;
    Caption = 'Current customers', Comment = 'is-IS=Núverandi viðskiptavinir';
    ContextSensitiveHelpPage = 'timesheets-phone-role-center';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
    SourceTable = "Phone Cust Buffer ori";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            repeater(Customers)
            {
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the customer number.', Comment = 'is-IS=Tilgreinir númer viðskiptavinar.';
                }
                field("Customer Name"; Rec."Customer Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the customer name.', Comment = 'is-IS=Tilgreinir nafn viðskiptavinar.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Add)
            {
                ApplicationArea = All;
                Caption = 'Add', Comment = 'is-IS=Bæta við';
                Image = Add;
                Scope = Repeater;
                ToolTip = 'Add a service item to an open sales invoice for this customer.', Comment = 'is-IS=Bætir þjónustuvöru á opinn sölureikning fyrir þennan viðskiptavin.';

                trigger OnAction()
                begin
                    OpenAddDialog();
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        BufferMgt: Codeunit "Phone Cust Buffer Mgt ori";
    begin
        BufferMgt.PopulateCurrentCustomers(Rec);
        if Rec.FindFirst() then;
    end;

    local procedure OpenAddDialog()
    var
        AddPage: Page "Phone Add Service Item ori";
    begin
        if Rec."Customer No." = '' then
            exit;
        AddPage.SetContext(Rec."Customer No.", Rec."Job No.", Rec."Job Task No.");
        AddPage.RunModal();
    end;
}
