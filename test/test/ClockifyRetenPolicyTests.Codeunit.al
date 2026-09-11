namespace Origo.Bifrost.Timesheets.Test;

using Origo.Bifrost.Timesheets;
using System.DataAdministration;
using System.TestLibraries.Utilities;

/// <summary>
/// Locks <c>EnableDefaultPolicy</c> Get/Insert/Modify behaviour (TC001–TC002).
/// Runs as SUPER so these tests cannot prove the codeunit <c>Permissions</c> grant;
/// that proof is a green Deploy to Bifrost install.
/// </summary>
codeunit 95607 "Clockify Reten. Policy Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryAssert: Codeunit "Library Assert";

    [Test]
    procedure TC001_EnableDefaultPolicyInsertsEnabledRow()
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
        RetenPolicy: Codeunit "Clockify Reten. Policy ori";
    begin
        // [SCENARIO] EnableDefaultPolicy with no existing row inserts one with Enabled = true.
        Initialize();
        ClearPolicyForIntegrationTable();
        RetenPolicy.AddAllowedTable();

        // [WHEN] The default policy is enabled
        RetenPolicy.EnableDefaultPolicy();

        // [THEN] A single enabled Retention Policy Setup row exists for the integration table
        LibraryAssert.IsTrue(
            RetentionPolicySetup.Get(Database::"Clockify Integration ori"),
            'EnableDefaultPolicy should insert Retention Policy Setup for Clockify Integration.');
        LibraryAssert.IsTrue(
            RetentionPolicySetup.Enabled,
            'The inserted default policy should be Enabled.');
        LibraryAssert.IsFalse(
            RetentionPolicySetup."Apply to all records",
            'The default policy must not apply to all records (locked Reversed filter).');
    end;

    [Test]
    procedure TC002_EnableDefaultPolicyReRunIsIdempotent()
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
        RetenPolicy: Codeunit "Clockify Reten. Policy ori";
        CountBefore: Integer;
        CountAfter: Integer;
    begin
        // [SCENARIO] EnableDefaultPolicy re-run with the row present does not insert a second row.
        Initialize();
        ClearPolicyForIntegrationTable();
        RetenPolicy.AddAllowedTable();
        RetenPolicy.EnableDefaultPolicy();
        LibraryAssert.IsTrue(
            RetentionPolicySetup.Get(Database::"Clockify Integration ori"),
            'Precondition: default policy row must exist.');
        RetentionPolicySetup.SetRange("Table Id", Database::"Clockify Integration ori");
        CountBefore := RetentionPolicySetup.Count();

        // [WHEN] EnableDefaultPolicy runs again
        RetenPolicy.EnableDefaultPolicy();

        // [THEN] Still exactly one row; no second insert
        RetentionPolicySetup.Reset();
        RetentionPolicySetup.SetRange("Table Id", Database::"Clockify Integration ori");
        CountAfter := RetentionPolicySetup.Count();
        LibraryAssert.AreEqual(CountBefore, CountAfter, 'Re-run must not insert a second Retention Policy Setup row.');
        LibraryAssert.AreEqual(1, CountAfter, 'Exactly one Retention Policy Setup row should exist for the table.');
        LibraryAssert.IsTrue(
            RetentionPolicySetup.Get(Database::"Clockify Integration ori"),
            'The existing Retention Policy Setup row should still be gettable.');
    end;

    local procedure Initialize()
    begin
        Clear(LibraryAssert);
    end;

    local procedure ClearPolicyForIntegrationTable()
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
    begin
        if RetentionPolicySetup.Get(Database::"Clockify Integration ori") then
            RetentionPolicySetup.Delete(true);
    end;
}
