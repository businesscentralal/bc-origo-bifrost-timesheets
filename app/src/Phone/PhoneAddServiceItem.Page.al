namespace Origo.Bifrost.Timesheets;

using Microsoft.Inventory.Item;

/// <summary>
/// Small dialog that asks for a service item from My Items and a quantity, then
/// adds a sales invoice line for the customer chosen on the phone Role Center.
/// </summary>
page 10036864 "Phone Add Service Item ori"
{
    ApplicationArea = All;
    Caption = 'Add service item', Comment = 'is-IS=Bæta við þjónustuvöru';
    ContextSensitiveHelpPage = 'timesheets-phone-role-center';
    PageType = StandardDialog;

    layout
    {
        area(Content)
        {
            group(Item)
            {
                Caption = 'Service item', Comment = 'is-IS=Þjónustuvara';
                field(ItemNo; ItemNo)
                {
                    ApplicationArea = All;
                    Caption = 'Item No.', Comment = 'is-IS=Vörunúmer';
                    TableRelation = Item."No." where(Type = const(Service));
                    ToolTip = 'Specifies the service item from your My Items list.', Comment = 'is-IS=Tilgreinir þjónustuvöru af lista Mínar vörur.';

                    trigger OnValidate()
                    var
                        QuickAdd: Codeunit "Phone Sales Quick Add ori";
                    begin
                        if ItemNo <> '' then
                            QuickAdd.AssertMyServiceItem(ItemNo);
                    end;
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = All;
                    Caption = 'Quantity', Comment = 'is-IS=Magn';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity to put on the sales invoice line.', Comment = 'is-IS=Tilgreinir magnið sem fer á sölureikningslínuna.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if Quantity = 0 then
            Quantity := 1;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        QuickAdd: Codeunit "Phone Sales Quick Add ori";
    begin
        if CloseAction <> Action::OK then
            exit(true);
        QuickAdd.AddServiceItemLine(CustomerNo, JobNo, JobTaskNo, ItemNo, Quantity);
        exit(true);
    end;

    /// <summary>
    /// Sets the customer and optional job chosen on the role center before the dialog opens.
    /// </summary>
    /// <param name="NewCustomerNo">Sell-to customer.</param>
    /// <param name="NewJobNo">Job number. May be blank.</param>
    /// <param name="NewJobTaskNo">Job task number. May be blank.</param>
    procedure SetContext(NewCustomerNo: Code[20]; NewJobNo: Code[20]; NewJobTaskNo: Code[20])
    begin
        CustomerNo := NewCustomerNo;
        JobNo := NewJobNo;
        JobTaskNo := NewJobTaskNo;
    end;

    var
        CustomerNo: Code[20];
        JobNo: Code[20];
        JobTaskNo: Code[20];
        ItemNo: Code[20];
        Quantity: Decimal;
}
