namespace Origo.PTE.CloudEvents.Clockify;

/// <summary>
/// Read-only lookup over the Clockify workspaces accessible to the configured
/// company API key. Populated by <see cref="Codeunit.ClockifyWorkspaceMgt"/> via
/// <see cref="LoadWorkspaces"/> and run in lookup mode so the Setup card can pick
/// a default workspace by name.
/// </summary>
page 71414 "Clockify Workspace Lookup"
{
    PageType = List;
    SourceTable = "Clockify Workspace Buffer";
    SourceTableTemporary = true;
    Editable = false;
    UsageCategory = None;
    Caption = 'Clockify Workspaces', Comment = 'is-IS=Clockify vinnusvæði';

    layout
    {
        area(Content)
        {
            repeater(Workspaces)
            {
                field("Name"; Rec."Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the Clockify workspace.', Comment = 'is-IS=Tilgreinir heiti Clockify vinnusvæðisins.';
                }
                field("Workspace ID"; Rec."Workspace ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Clockify workspace identifier.', Comment = 'is-IS=Tilgreinir kenni Clockify vinnusvæðisins.';
                }
            }
        }
    }

    /// <summary>Loads the workspaces to choose from into the page's temporary record.</summary>
    /// <param name="TempWorkspaceBuffer">The workspaces to display.</param>
    procedure LoadWorkspaces(var TempWorkspaceBuffer: Record "Clockify Workspace Buffer" temporary)
    begin
        if TempWorkspaceBuffer.FindSet() then
            repeat
                Rec := TempWorkspaceBuffer;
                Rec.Insert();
            until TempWorkspaceBuffer.Next() = 0;
    end;

    /// <summary>Returns the workspace the user selected.</summary>
    /// <param name="TempWorkspaceBuffer">Out: receives the selected workspace.</param>
    procedure GetSelectedWorkspace(var TempWorkspaceBuffer: Record "Clockify Workspace Buffer" temporary)
    begin
        TempWorkspaceBuffer := Rec;
    end;
}
