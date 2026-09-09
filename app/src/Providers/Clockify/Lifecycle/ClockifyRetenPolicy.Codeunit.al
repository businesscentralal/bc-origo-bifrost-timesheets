namespace Origo.Bifrost.Timesheets.Providers.Clockify;

using System.DataAdministration;

/// <summary>
/// Registers <see cref="Table.ClockifyIntegration"/> with the Business Central
/// retention-policy framework and enables a default policy that removes reversed
/// links about one month after they were reversed.
///
/// The filter <c>Reversed = true</c> is registered as a locked (mandatory) filter
/// on <c>Reversed At</c>, so the framework forbids switching the policy to
/// "Apply to all records" — active (non-reversed) links can never be purged.
/// </summary>
codeunit 10036793 "Clockify Reten. Policy ori"
{
    Access = Internal;

    /// <summary>
    /// Adds the Clockify Integration table to the allowed retention tables with a
    /// locked one-month filter on reversed rows. Safe to call repeatedly.
    /// </summary>
    procedure AddAllowedTable()
    var
        ClockifyIntegration: Record "Clockify Integration ori";
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
        RecRef: RecordRef;
        TableFilters: JsonArray;
    begin
        if RetenPolAllowedTables.IsAllowedTable(Database::"Clockify Integration ori") then
            exit;

        ClockifyIntegration.SetRange(Reversed, true);
        RecRef.GetTable(ClockifyIntegration);
        RetenPolAllowedTables.AddTableFilterToJsonArray(
            TableFilters,
            "Retention Period Enum"::"1 Month",
            ClockifyIntegration.FieldNo("Reversed At"),
            true,
            true,
            RecRef);
        RetenPolAllowedTables.AddAllowedTable(
            Database::"Clockify Integration ori",
            ClockifyIntegration.FieldNo("Reversed At"),
            TableFilters);
    end;

    /// <summary>
    /// Creates and enables the default retention policy for the Clockify Integration
    /// table if none exists. The locked <c>Reversed = true</c> / one-month filter line
    /// is created automatically when the setup is inserted.
    /// </summary>
    procedure EnableDefaultPolicy()
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
    begin
        if RetentionPolicySetup.Get(Database::"Clockify Integration ori") then
            exit;

        RetentionPolicySetup.Validate("Table Id", Database::"Clockify Integration ori");
        RetentionPolicySetup.Validate("Apply to all records", false);
        RetentionPolicySetup.Insert(true);

        RetentionPolicySetup.Validate(Enabled, true);
        RetentionPolicySetup.Modify(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reten. Pol. Allowed Tables", 'OnRefreshAllowedTables', '', false, false)]
    local procedure HandleOnRefreshAllowedTables()
    begin
        AddAllowedTable();
    end;
}
