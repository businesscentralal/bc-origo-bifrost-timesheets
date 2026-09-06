namespace Origo.PTE.CloudEvents.Clockify;

/// <summary>
/// Backs the default-workspace picker on the <c>Cloud Events Setup</c> card.
/// Fetches the workspaces accessible to the company API key from
/// <c>GET /workspaces</c> through the configured
/// <see cref="Interface.ClockifyApiClient"/>, parses them, and runs the
/// <see cref="Page.ClockifyWorkspaceLookup"/> picker. Requires the company API key
/// to be set first.
/// </summary>
codeunit 70009246 "Clockify Workspace Mgt"
{
    Access = Internal;

    var
        NoApiKeyErr: Label 'Set the company Clockify API key before selecting a workspace.', Comment = 'is-IS=Skráðu Clockify API lykil fyrirtækis áður en þú velur vinnusvæði.';
        FetchFailedErr: Label 'The Clockify workspaces could not be retrieved: %1', Comment = '%1 = error text. is-IS=Ekki tókst að sækja Clockify vinnusvæði: %1';
        NoWorkspacesErr: Label 'No Clockify workspaces are available for the configured API key.', Comment = 'is-IS=Engin Clockify vinnusvæði eru tiltæk fyrir skráðan API lykil.';

    /// <summary>
    /// Lets the user pick a Clockify workspace from the live list for the company
    /// API key.
    /// </summary>
    /// <param name="WorkspaceId">Out: the selected workspace ID (unchanged when cancelled).</param>
    /// <param name="WorkspaceName">Out: the selected workspace name (unchanged when cancelled).</param>
    /// <returns>True when the user selected a workspace.</returns>
    procedure LookupWorkspace(var WorkspaceId: Text; var WorkspaceName: Text): Boolean
    var
        TempWorkspaceBuffer: Record "Clockify Workspace Buffer" temporary;
        SecretMgt: Codeunit "Clockify Secret Mgt";
        RequestMgt: Codeunit "Clockify Request Mgt";
        WorkspaceLookup: Page "Clockify Workspace Lookup";
        ApiClient: Interface "Clockify API Client";
        ResponseBody: Text;
        StatusCode: Integer;
    begin
        if not SecretMgt.HasCompanyApiKey() then
            Error(NoApiKeyErr);

        ApiClient := RequestMgt.GetApiClient();
        if not ApiClient.Send('GET', '/workspaces', false, '', ResponseBody, StatusCode) then
            Error(FetchFailedErr, ResponseBody);

        ParseWorkspaces(ResponseBody, TempWorkspaceBuffer);
        if TempWorkspaceBuffer.IsEmpty() then
            Error(NoWorkspacesErr);

        Commit();
        WorkspaceLookup.LoadWorkspaces(TempWorkspaceBuffer);
        WorkspaceLookup.LookupMode(true);
        if WorkspaceLookup.RunModal() <> Action::LookupOK then
            exit(false);

        Clear(TempWorkspaceBuffer);
        WorkspaceLookup.GetSelectedWorkspace(TempWorkspaceBuffer);
        WorkspaceId := TempWorkspaceBuffer."Workspace ID";
        WorkspaceName := TempWorkspaceBuffer."Name";
        exit(WorkspaceId <> '');
    end;

    /// <summary>
    /// Parses a Clockify <c>GET /workspaces</c> response body (a JSON array of
    /// workspace objects) into the buffer. Existing buffer rows are cleared first.
    /// </summary>
    /// <param name="ResponseBody">The raw JSON array returned by Clockify.</param>
    /// <param name="TempWorkspaceBuffer">Out: the parsed workspaces.</param>
    internal procedure ParseWorkspaces(ResponseBody: Text; var TempWorkspaceBuffer: Record "Clockify Workspace Buffer" temporary)
    var
        RequestMgt: Codeunit "Clockify Request Mgt";
        RootToken: JsonToken;
        WorkspaceToken: JsonToken;
        WorkspaceObject: JsonObject;
    begin
        TempWorkspaceBuffer.Reset();
        TempWorkspaceBuffer.DeleteAll();

        if not RootToken.ReadFrom(ResponseBody) then
            exit;
        if not RootToken.IsArray() then
            exit;

        foreach WorkspaceToken in RootToken.AsArray() do
            if WorkspaceToken.IsObject() then begin
                WorkspaceObject := WorkspaceToken.AsObject();
                TempWorkspaceBuffer.Init();
                TempWorkspaceBuffer."Workspace ID" := CopyStr(RequestMgt.GetText(WorkspaceObject, 'id'), 1, MaxStrLen(TempWorkspaceBuffer."Workspace ID"));
                TempWorkspaceBuffer."Name" := CopyStr(RequestMgt.GetText(WorkspaceObject, 'name'), 1, MaxStrLen(TempWorkspaceBuffer."Name"));
                if TempWorkspaceBuffer."Workspace ID" <> '' then
                    if TempWorkspaceBuffer.Insert() then;
            end;
    end;
}
