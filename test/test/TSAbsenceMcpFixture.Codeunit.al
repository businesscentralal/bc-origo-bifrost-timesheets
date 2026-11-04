namespace Origo.Bifrost.Timesheets.Test;

using Microsoft.Foundation.UOM;
using Microsoft.HumanResources.Absence;
using Microsoft.HumanResources.Employee;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.TimeSheet;
using System.Security.User;

/// <summary>
/// Creates isolated native records for Timesheets.Absence.Register MCP verification.
/// Invoked explicitly by the owner in an ephemeral development environment. It does
/// not change generic write guards, licensing, consent or Foundation setup.
/// </summary>
codeunit 95618 "TS Absence MCP Fixture"
{
    Access = Internal;

    trigger OnRun()
    var
        UnitOfMeasure: Record "Unit of Measure";
        HumanResourceUnitOfMeasure: Record "Human Resource Unit of Measure";
        Cause: Record "Cause of Absence";
        Employee: Record Employee;
        UserSetup: Record "User Setup";
    begin
        // Refuse an existing fixture rather than silently replaying a setup write.
        if UnitOfMeasure.Get('W2A65') then
            Error(FixtureExistsErr);
        UnitOfMeasure.Init();
        UnitOfMeasure.Code := 'W2A65';
        UnitOfMeasure.Description := 'Brokkr65 own hours';
        UnitOfMeasure.Insert(true);
        HumanResourceUnitOfMeasure.Init();
        HumanResourceUnitOfMeasure.Validate(Code, UnitOfMeasure.Code);
        HumanResourceUnitOfMeasure.Validate("Qty. per Unit of Measure", 1);
        HumanResourceUnitOfMeasure.Insert(true);
        Cause.Init();
        Cause.Code := 'W2A65';
        Cause.Description := 'Brokkr65 owned absence';
        Cause.Insert(true);
        // The owner identity is confirmed by the owned MCP preflight; service OnRun has a different session identity.
        if not UserSetup.Get('CODEXW2') then begin
            UserSetup.Init();
            UserSetup.Validate("User ID", 'CODEXW2');
            UserSetup.Insert(true);
        end;
        CreateResource('W2A65-MCP');
        CreateResource('W2A65-MCPN');
        Employee.Init();
        Employee."No." := 'W2A65-MCP';
        Employee."First Name" := 'Brokkr65';
        Employee.Validate("Resource No.", 'W2A65-MCP');
        Employee.Insert(true);
        CreateSheet('W2ABS65-MCP', 'W2A65-MCP');
        CreateSheet('W2ABS65-MCPN', 'W2A65-MCPN');
    end;

    var
        FixtureExistsErr: Label 'The owned absence fixture already exists. Inspect it before continuing.', Locked = true;

    local procedure CreateResource(ResourceNo: Code[20])
    var
        Resource: Record Resource;
    begin
        Resource.Init();
        Resource."No." := ResourceNo;
        Resource.Name := 'Brokkr65 isolated resource';
        Resource.Insert(true);
        Resource.Validate(Type, Resource.Type::Person);
        Resource.Validate("Base Unit of Measure", 'W2A65');
        Resource."Time Sheet Owner User ID" := 'CODEXW2';
        Resource."Time Sheet Approver User ID" := Resource."Time Sheet Owner User ID";
        Resource.Validate("Use Time Sheet", true);
        Resource.Modify(true);
    end;

    local procedure CreateSheet(SheetNo: Code[20]; ResourceNo: Code[20])
    var
        Header: Record "Time Sheet Header";
    begin
        Header.Init();
        Header."No." := SheetNo;
        Header.Validate("Resource No.", ResourceNo);
        Header.Validate("Starting Date", 20261102D);
        Header.Validate("Ending Date", 20261108D);
        Header.Insert(true);
    end;
}
