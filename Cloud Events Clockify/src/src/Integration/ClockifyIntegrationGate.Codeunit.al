namespace Origo.PTE.CloudEvents.Clockify;

using Origo.APP.CloudEvents;

/// <summary>
/// Access gate for the Clockify connector. Every Clockify message type except
/// <c>Help.Clockify.Get</c> must pass <see cref="AssertCanWriteIntegration"/>
/// before it runs, because operating the connector implies maintaining the
/// <see cref="Table.ClockifyIntegration"/> links. The gate is enforced centrally
/// in <c>Clockify Request Mgt.Execute</c>, so it cannot be forgotten when new
/// message types are added. On failure it writes the standard error envelope to
/// the argument and returns <c>false</c>, mirroring the base posting-gate pattern.
/// </summary>
codeunit 71419 "Clockify Integration Gate"
{
    Access = Internal;

    var
        NoWritePermissionErr: Label 'You do not have write permission to the Clockify Integration table, which is required to run Clockify connector operations. Ask your administrator to assign the Clockify - Full permission set.', Comment = 'is-IS=Þú hefur ekki skrifréttindi á Clockify tengitöfluna sem er nauðsynleg til að keyra Clockify aðgerðir. Biddu kerfisstjóra um að úthluta Clockify - Full réttindasettinu.';

    /// <summary>
    /// Verifies the current user can write to the Clockify Integration table. On
    /// failure it sets an error response on the argument and returns false.
    /// </summary>
    /// <param name="Argument">The Cloud Event argument (receives the error response on failure).</param>
    /// <returns>True when the user has write permission to the Clockify Integration table.</returns>
    procedure AssertCanWriteIntegration(var Argument: Record "CE Message Argument ori"): Boolean
    var
        ClockifyIntegration: Record "Clockify Integration";
    begin
        if ClockifyIntegration.WritePermission() then
            exit(true);
        Argument.RespondWithError(NoWritePermissionErr);
        exit(false);
    end;
}
