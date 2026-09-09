namespace Origo.Bifrost.Timesheets;

/// <summary>
/// Stores and retrieves the company Clockify API key in IsolatedStorage
/// (<c>Company</c> scope). All connector calls authenticate as the single Clockify
/// identity that owns this key. The key is handled as <c>SecretText</c> end to end
/// so it is never exposed to the debugger.
/// </summary>
codeunit 10036828 "Clockify Secret Mgt ori"
{
    Access = Public;

    var
        CompanyKeyTok: Label 'CLOCKIFY-APIKEY-COMPANY', Locked = true;

    /// <summary>Stores the company Clockify API key.</summary>
    /// <param name="ApiKey">The API key to store.</param>
    procedure SetCompanyApiKey(ApiKey: SecretText)
    begin
        IsolatedStorage.Set(CompanyKeyTok, ApiKey, DataScope::Company);
    end;

    /// <summary>
    /// Resolves the company Clockify API key for the current request.
    /// </summary>
    /// <param name="ApiKey">Out: the resolved API key.</param>
    /// <returns>True when a key is stored; false when none is stored.</returns>
    procedure TryGetApiKey(var ApiKey: SecretText): Boolean
    begin
        if IsolatedStorage.Contains(CompanyKeyTok, DataScope::Company) then
            exit(IsolatedStorage.Get(CompanyKeyTok, DataScope::Company, ApiKey));
        exit(false);
    end;

    /// <summary>Returns true when a company API key is stored.</summary>
    procedure HasCompanyApiKey(): Boolean
    begin
        exit(IsolatedStorage.Contains(CompanyKeyTok, DataScope::Company));
    end;

    /// <summary>Removes the company API key.</summary>
    procedure ClearCompanyApiKey()
    begin
        if IsolatedStorage.Contains(CompanyKeyTok, DataScope::Company) then
            IsolatedStorage.Delete(CompanyKeyTok, DataScope::Company);
    end;
}
