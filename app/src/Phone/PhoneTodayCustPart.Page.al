namespace Origo.Bifrost.Timesheets;

/// <summary>
/// Customers the signed-in user logged Clockify time against on the work date,
/// including a still-running timer.
/// </summary>
page 10036862 "Phone Today Cust Part ori"
{
    ApplicationArea = All;
    Caption = 'Today', Comment = 'is-IS=Í dag';
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
                field("Hours Today"; Rec."Hours Today")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the finished hours logged against this customer today. A running timer adds the customer with zero hours.', Comment = 'is-IS=Tilgreinir kláraðar klukkustundir skráðar á þennan viðskiptavin í dag. Klukka í gangi bætir viðskiptavininum við með núll klukkustundum.';
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
        BufferMgt.PopulateTodayCustomers(Rec);
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
