namespace Origo.Bifrost.Timesheets.Test;

using Origo.Bifrost.Timesheets;
using System.DataAdministration;
using System.TestLibraries.Utilities;

/// <summary>
/// Proves the retention-policy install skip. Runs in its own codeunit so the
/// restrictive permission scope cannot leak into <c>Clockify Reten. Policy Tests</c>.
/// </summary>
codeunit 95608 "Clockify Reten Perm Tests"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    var
        LibraryAssert: Codeunit "Library Assert";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";

    [Test]
    procedure TC003_SkipWithoutPermissionThenLazyEnsureInserts()
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
        Install: Codeunit "Clockify Install ori";
    begin
        // [GIVEN] No retention policy row, then a permission set that cannot write it.
        LibraryLowerPermissions.SetOutsideO365Scope();
        ClearPolicyForIntegrationTable();
        LibraryLowerPermissions.SetO365Basic();

        // [WHEN] Install retries the policy without write permission.
        Install.EnsureRetentionPolicy();

        // [THEN] The skip does not throw and does not insert a row.
        LibraryLowerPermissions.SetOutsideO365Scope();
        RetentionPolicySetup.SetRange("Table Id", Database::"Clockify Integration ori");
        LibraryAssert.AreEqual(
            0,
            RetentionPolicySetup.Count(),
            'Missing permission must skip the retention policy without inserting a row.');

        // [WHEN] The same ensure runs once permission exists (Timesheets Setup open).
        Install.EnsureRetentionPolicy();

        // [THEN] The default policy is created once.
        LibraryAssert.IsTrue(
            RetentionPolicySetup.Get(Database::"Clockify Integration ori"),
            'Lazy ensure should insert the retention policy once permission exists.');
        LibraryAssert.IsTrue(RetentionPolicySetup.Enabled, 'The inserted default policy should be Enabled.');
        LibraryAssert.IsFalse(
            RetentionPolicySetup."Apply to all records",
            'The default policy must not apply to all records.');
    end;

    local procedure ClearPolicyForIntegrationTable()
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
    begin
        if RetentionPolicySetup.Get(Database::"Clockify Integration ori") then
            RetentionPolicySetup.Delete(true);
    end;
}
