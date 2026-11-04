namespace Origo.Bifrost.Timesheets.Test;

using Origo.Bifrost.Timesheets;

/// <summary>Seeds only the isolated paging scenario in the named verification company.</summary>
page 95619 "Clockify Paging Fixtures"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Paging verification fixtures', Comment = 'is-IS=Prófunargögn síðuskiptingar';

    layout
    {
        area(Content)
        {
            group(OwnedData)
            {
                Caption = 'Owned data', Comment = 'is-IS=Eigin gögn';
                field(UserCount; UserCount)
                {
                    ApplicationArea = All;
                    Caption = 'Mapped users', Comment = 'is-IS=Tengdir notendur';
                    ToolTip = 'Specifies the number of isolated user mappings to create.', Comment = 'is-IS=Tilgreinir fjölda einangraðra notendatenginga sem á að stofna.';
                    MinValue = 0;
                    MaxValue = 1002;
                }
                field(ActiveCount; ActiveCount)
                {
                    ApplicationArea = All;
                    Caption = 'Created mappings', Comment = 'is-IS=Stofnaðar tengingar';
                    ToolTip = 'Specifies how many owned mappings exist.', Comment = 'is-IS=Tilgreinir hversu margar eigin tengingar eru til.';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CreateFixtures)
            {
                ApplicationArea = All;
                Caption = 'Create owned fixtures', Comment = 'is-IS=Stofna eigin prófunargögn';
                ToolTip = 'Creates mappings and selects the network-free test client.', Comment = 'is-IS=Stofnar tengingar og velur prófunarbiðlara án nettengingar.';
                Image = New;
                trigger OnAction()
                begin
                    Seed();
                end;
            }
            action(CleanFixtures)
            {
                ApplicationArea = All;
                Caption = 'Clean owned fixtures', Comment = 'is-IS=Hreinsa eigin prófunargögn';
                ToolTip = 'Removes the owned mappings and restores the production client.', Comment = 'is-IS=Fjarlægir eigin tengingar og endurstillir venjulegan biðlara.';
                Image = Delete;
                trigger OnAction()
                begin
                    Cleanup();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        AssertCompany();
        UserCount := 1002;
        RefreshCount();
    end;

    var
        UserCount: Integer;
        ActiveCount: Integer;
        WrongCompanyErr: Label 'Use the isolated CRONUS SINDRI23 Verification company.', Comment = 'is-IS=Notaðu einangraða fyrirtækið CRONUS SINDRI23 Verification.';
        ExistingErr: Label 'Inspect existing mappings before creating fixtures.', Comment = 'is-IS=Skoðaðu fyrirliggjandi tengingar áður en prófunargögn eru stofnuð.';

    local procedure AssertCompany()
    begin
        if CompanyName() <> 'CRONUS SINDRI23 Verification' then
            Error(WrongCompanyErr);
    end;

    local procedure Seed()
    var
        Integration: Record "Clockify Integration ori";
        Setup: Record "Clockify Setup ori";
        UserIndex: Integer;
    begin
        AssertCompany();
        Integration.ReadIsolation := IsolationLevel::UpdLock;
        if not Integration.IsEmpty() then
            Error(ExistingErr);
        if not Setup.Get() then begin
            Setup.Init();
            Setup.Insert(true);
        end;
        if (Setup."API Version" <> Setup."API Version"::"Version 1") or
           (Setup."Default Workspace" <> '')
        then
            Error(ExistingErr);
        Setup."API Version" := Setup."API Version"::Mock;
        Setup.Modify(true);
        for UserIndex := UserCount downto 1 do begin
            Integration.Init();
            Integration."Entry No." := 0;
            Integration."Clockify Type" := 'USER';
            Integration."Clockify Id" := CopyStr('XSINDRI23-' + Format(UserIndex, 6, '<Integer,6><Filler Character,0>'), 1, MaxStrLen(Integration."Clockify Id"));
            Integration."Clockify Workspace Id" := 'XSINDRI23';
            Integration."BC SystemId" := CreateGuid();
            Integration.Insert(true);
        end;
        RefreshCount();
    end;

    local procedure Cleanup()
    var
        Integration: Record "Clockify Integration ori";
        Setup: Record "Clockify Setup ori";
    begin
        AssertCompany();
        Integration.SetRange("Clockify Workspace Id", 'XSINDRI23');
        Integration.SetFilter("Clockify Id", 'XSINDRI23-*');
        Integration.DeleteAll(true);
        if Setup.Get() then begin
            if Setup."API Version" <> Setup."API Version"::Mock then
                Error(ExistingErr);
            Setup."API Version" := Setup."API Version"::"Version 1";
            Setup.Modify(true);
        end;
        RefreshCount();
    end;

    local procedure RefreshCount()
    var
        Integration: Record "Clockify Integration ori";
    begin
        Integration.ReadIsolation := IsolationLevel::ReadCommitted;
        Integration.SetRange("Clockify Workspace Id", 'XSINDRI23');
        Integration.SetFilter("Clockify Id", 'XSINDRI23-*');
        ActiveCount := Integration.Count();
    end;
}
