namespace Origo.Bifrost.Timesheets.Test;

/// <summary>Runs the owner-scoped absence fixture through an authenticated Web Client session.</summary>
page 95620 "TS Absence Fixtures"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Absence verification fixtures', Locked = true;

    actions
    {
        area(Processing)
        {
            action(CreateFixtures)
            {
                ApplicationArea = All;
                Caption = 'Create owned absence fixtures', Locked = true;
                ToolTip = 'Creates isolated absence data in the named verification company.', Locked = true;
                Image = New;

                trigger OnAction()
                begin
                    Codeunit.Run(Codeunit::"TS Absence MCP Fixture");
                end;
            }
        }
    }
}
