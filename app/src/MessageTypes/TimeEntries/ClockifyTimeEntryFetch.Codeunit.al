namespace Origo.Bifrost.Clockify;

using System.Reflection;

/// <summary>
/// Fetches a Clockify user's finished time entries for a date range from the Clockify API,
/// following pagination. Used by the range/all-users sync message types.
/// </summary>
codeunit 70009260 "Clockify TimeEntry Fetch ori"
{
    Access = Internal;

    var
        HttpErrTok: Label 'HTTP %1: %2', Comment = '%1 = status code, %2 = body', Locked = true;

    /// <summary>
    /// Reads every finished time entry for the user/range. Returns false with a message on HTTP error.
    /// </summary>
    procedure TryFetchUserEntries(WorkspaceId: Text; UserId: Text; StartText: Text; EndText: Text; var Entries: JsonArray; var ErrorMessage: Text): Boolean
    var
        RequestMgt: Codeunit "Clockify Request Mgt ori";
        TypeHelper: Codeunit "Type Helper";
        ApiClient: Interface "Clockify API Client ori";
        PageArray: JsonArray;
        PageToken: JsonToken;
        EntryToken: JsonToken;
        ResourcePath: Text;
        ResponseBody: Text;
        StatusCode: Integer;
        PageNo: Integer;
        PageSize: Integer;
    begin
        Clear(Entries);
        ErrorMessage := '';
        PageSize := 200;
        ApiClient := RequestMgt.GetApiClient();
        PageNo := 0;
        repeat
            PageNo += 1;
            ResourcePath :=
                '/workspaces/' + WorkspaceId + '/user/' + UserId + '/time-entries' +
                '?start=' + TypeHelper.UrlEncode(StartText) +
                '&end=' + TypeHelper.UrlEncode(EndText) +
                '&in-progress=false' +
                '&page-size=' + Format(PageSize, 0, 9) +
                '&page=' + Format(PageNo, 0, 9);
            if not ApiClient.Send('GET', ResourcePath, false, '', ResponseBody, StatusCode) then begin
                ErrorMessage := StrSubstNo(HttpErrTok, StatusCode, ResponseBody);
                exit(false);
            end;
            Clear(PageArray);
            if (ResponseBody <> '') and PageToken.ReadFrom(ResponseBody) and PageToken.IsArray() then
                PageArray := PageToken.AsArray();
            foreach EntryToken in PageArray do
                Entries.Add(EntryToken);
        until PageArray.Count() < PageSize;
        exit(true);
    end;
}
