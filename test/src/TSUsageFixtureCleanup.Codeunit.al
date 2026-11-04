namespace Origo.Bifrost.Timesheets.Test;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Resources.Journal;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.TimeSheet;
using Origo.Bifrost.Timesheets;

/// <summary>Removes only ledger and register rows proven to belong to a nonce-isolated usage fixture.</summary>
codeunit 95638 "TS Usage Fixture Cleanup"
{
    /// <summary>Checks every register range for foreign rows before deleting an owned resource's posting evidence.</summary>
    procedure DeleteResourceLedger(ResourceNo: Code[20])
    var
        Ledger: Record "Res. Ledger Entry";
        ForeignLedger: Record "Res. Ledger Entry";
        ResourceRegister: Record "Resource Register";
    begin
        if CopyStr(ResourceNo, 1, 5) <> 'ZZU84' then
            Error('Cleanup accepts only usage-test resource numbers.');
        Ledger.SetLoadFields("Entry No.", "Resource No.");
        Ledger.SetRange("Resource No.", ResourceNo);
        if Ledger.FindSet() then
            repeat
                ResourceRegister.SetFilter("From Entry No.", '<=%1', Ledger."Entry No.");
                ResourceRegister.SetFilter("To Entry No.", '>=%1', Ledger."Entry No.");
                if ResourceRegister.FindSet(true) then
                    repeat
                        ForeignLedger.SetRange("Entry No.", ResourceRegister."From Entry No.", ResourceRegister."To Entry No.");
                        ForeignLedger.SetFilter("Resource No.", '<>%1', ResourceNo);
                        if not ForeignLedger.IsEmpty() then
                            Error('The register includes foreign ledger rows; preserve it for the owner.');
                        ResourceRegister.Delete(false);
                    until ResourceRegister.Next() = 0;
            until Ledger.Next() = 0;
        Ledger.DeleteAll(false);
    end;
    /// <summary>Removes failed native-test fixtures whose unique numbers and exact fixture descriptions identify this test source.</summary>
    procedure DeleteNativeFixtures()
    var
        Resource: Record Resource;
        ResourceUnit: Record "Resource Unit of Measure";
        Item: Record Item;
        ItemUnit: Record "Item Unit of Measure";
        Header: Record "Time Sheet Header";
        Line: Record "Time Sheet Line";
        Usage: Record "TS Usage Line ori";
        Journal: Record "Res. Journal Line";
        Batch: Record "Res. Journal Batch";
        JournalTemplate: Record "Res. Journal Template";
        UnitOfMeasure: Record "Unit of Measure";
        PostingGroup: Record "Gen. Product Posting Group";
        UnitCode: Code[10];
    begin
        if not CompanyName().ToUpper().StartsWith('CRONUS') then
            Error('Native fixture cleanup requires the CRONUS development company.');
        Resource.SetFilter("No.", 'ZZU84*');
        Resource.SetRange(Name, 'Usage test resource');
        if Resource.FindSet(true) then
            repeat
                Header.SetRange("Resource No.", Resource."No.");
                Header.SetFilter("No.", 'ZZU84*');
                if Header.FindSet(true) then
                    repeat
                        Usage.SetRange("Time Sheet No.", Header."No.");
                        if Usage.FindSet(true) then
                            repeat
                                if Usage."Journal Table No." = Database::"Res. Journal Line" then
                                    if Journal.Get(Usage."Journal Template", Usage."Journal Batch", Usage."Journal Line No.") then begin
                                        Journal.TestField("Resource No.", Resource."No.");
                                        Journal.Delete(true);
                                        if Batch.Get(Usage."Journal Template", Usage."Journal Batch") then
                                            Batch.Delete(false);
                                        if JournalTemplate.Get(Usage."Journal Template") then
                                            JournalTemplate.Delete(false);
                                    end;
                            until Usage.Next() = 0;
                        Usage.DeleteAll(false);
                        Line.SetRange("Time Sheet No.", Header."No.");
                        Line.DeleteAll(false);
                        Header.Delete(false);
                    until Header.Next() = 0;
                DeleteResourceLedger(Resource."No.");
                ResourceUnit.SetRange("Resource No.", Resource."No.");
                ResourceUnit.DeleteAll(false);
                Resource.Delete(false);
            until Resource.Next() = 0;
        Item.SetFilter("No.", 'ZZU84*');
        Item.SetRange(Description, 'Usage test item');
        if Item.FindSet(true) then
            repeat
                UnitCode := Item."Base Unit of Measure";
                ItemUnit.SetRange("Item No.", Item."No.");
                ItemUnit.DeleteAll(false);
                Item.Delete(false);
                Resource.Reset();
                Resource.SetRange("Base Unit of Measure", UnitCode);
                if Resource.IsEmpty() then begin
                    if PostingGroup.Get(UnitCode) then
                        PostingGroup.Delete(false);
                    if UnitOfMeasure.Get(UnitCode) then
                        UnitOfMeasure.Delete(false);
                end;
            until Item.Next() = 0;
    end;
}
