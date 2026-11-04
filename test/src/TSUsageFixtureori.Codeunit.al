namespace Origo.Bifrost.Timesheets.Test;

using Microsoft.Foundation.UOM;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Resources.Journal;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.TimeSheet;
using Origo.Bifrost;
using Origo.Bifrost.Timesheets;

/// <summary>Creates, prepares and removes nonce-isolated usage fixtures only in an owned CRONUS development company.</summary>
codeunit 95637 "TS Usage Fixture ori" implements "Msg Interface ori"
{
    /// <summary>Requires a CRONUS company and direct fixture table write permissions.</summary>
    procedure IsEnabled(): Boolean
    var
        Header: Record "Time Sheet Header";
        Usage: Record "TS Usage Line ori";
    begin
        exit(CompanyName().ToUpper().StartsWith('CRONUS') and Header.WritePermission() and Usage.WritePermission());
    end;

    /// <summary>Does not expose a filter table.</summary>
    procedure GetFilterTableNo(): Integer
    begin
        exit(0);
    end;

    /// <summary>Identifies a test-app-only operation.</summary>
    procedure GetDescription(): Text[250]
    begin
        exit('Test extension only: self-seeded usage acceptance data and exact owned cleanup.');
    end;

    /// <summary>Fixture operations write their own test data.</summary>
    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit("Msg Direction ori"::Inbound);
    end;

    /// <summary>Manages only the fixture identified by a bounded hexadecimal nonce.</summary>
    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    var
        FixtureCleanup: Codeunit "TS Usage Fixture Cleanup";
        Request: JsonObject;
        Response: JsonObject;
        Token: JsonToken;
        KeyName: Text;
        Action: Text;
        Nonce: Text;
        Prefix: Code[20];
        ShortName: Code[10];
    begin
        Argument.AssertVersion1();
        if not IsEnabled() then
            Error('Usage fixtures require a CRONUS development company and direct write permissions.');
        Request := Argument.GetRequestJson();
        foreach KeyName in Request.Keys() do
            if not (KeyName in ['action', 'nonce']) then
                Error('Unknown fixture key.');
        if not Request.Get('nonce', Token) then
            Error('Fixture nonce is required.');
        Nonce := Token.AsValue().AsText().ToUpper();
        if (StrLen(Nonce) <> 10) or (DelChr(Nonce, '=', '0123456789ABCDEF') <> '') then
            Error('Fixture nonce must contain exactly ten hexadecimal characters.');
        Prefix := CopyStr('ZZU84' + Nonce, 1, 20);
        ShortName := CopyStr(Nonce, 1, 10);
        Action := Request.GetText('action');
        case Action of
            'seed':
                Seed(Prefix, ShortName);
            'cleanupNative':
                FixtureCleanup.DeleteNativeFixtures();
            'handover':
                Handover(Prefix);
            'post':
                PostResource(Prefix);
            'cleanup':
                Cleanup(Prefix, ShortName);
            else
                Error('Unknown usage fixture action.');
        end;
        Response.Add('status', 'Success');
        Response.Add('timeSheetNo', Prefix + 'S');
        Response.Add('resourceNo', Prefix + 'R');
        Response.Add('itemNo', Prefix + 'I');
        Response.Add('lineNo', 10000);
        Response.Add('journalTemplate', ShortName);
        Response.Add('journalBatch', ShortName);
        Argument.SetResponseJson(Response);
    end;

    local procedure Seed(Prefix: Code[20]; ShortName: Code[10])
    var
        Resource: Record Resource;
        PostingGroup: Record "Gen. Product Posting Group";
        ResourceUnit: Record "Resource Unit of Measure";
        Item: Record Item;
        ItemUnit: Record "Item Unit of Measure";
        UnitOfMeasure: Record "Unit of Measure";
        Header: Record "Time Sheet Header";
        Line: Record "Time Sheet Line";
        JournalTemplate: Record "Res. Journal Template";
        Batch: Record "Res. Journal Batch";
    begin
        if Resource.Get(Prefix + 'R') or Item.Get(Prefix + 'I') or Header.Get(Prefix + 'S') or UnitOfMeasure.Get(ShortName) or JournalTemplate.Get(ShortName) then
            Error('Fixture collision: inspect existing data before retrying seed.');
        UnitOfMeasure.Code := ShortName;
        UnitOfMeasure.Description := 'Issue 84 self-seeded unit';
        UnitOfMeasure.Insert(false);
        PostingGroup.Code := ShortName;
        PostingGroup.Insert(false);
        Resource."No." := CopyStr(Prefix + 'R', 1, 20);
        Resource."Gen. Prod. Posting Group" := PostingGroup.Code;
        Resource.Name := 'Issue 84 self-seeded resource';
        Resource."Base Unit of Measure" := ShortName;
        Resource."Time Sheet Owner User ID" := CopyStr(UserId(), 1, 50);
        Resource.Insert(false);
        ResourceUnit."Resource No." := Resource."No.";
        ResourceUnit.Code := ShortName;
        ResourceUnit."Qty. per Unit of Measure" := 1;
        ResourceUnit.Insert(false);
        Item."No." := CopyStr(Prefix + 'I', 1, 20);
        Item.Description := 'Issue 84 self-seeded item';
        Item."Base Unit of Measure" := ShortName;
        Item.Insert(false);
        ItemUnit."Item No." := Item."No.";
        ItemUnit.Code := ShortName;
        ItemUnit."Qty. per Unit of Measure" := 1;
        ItemUnit.Insert(false);
        Header."No." := CopyStr(Prefix + 'S', 1, 20);
        Header."Resource No." := Resource."No.";
        Header."Owner User ID" := CopyStr(UserId(), 1, 50);
        Header."Approver User ID" := Header."Owner User ID";
        Header."Starting Date" := 20261102D;
        Header."Ending Date" := 20261108D;
        Header.Insert(false);
        Line."Time Sheet No." := Header."No.";
        Line."Line No." := 10000;
        Line.Type := Line.Type::Resource;
        Line.Insert(false);
        JournalTemplate.Name := ShortName;
        JournalTemplate.Insert(false);
        Batch."Journal Template Name" := ShortName;
        Batch.Name := ShortName;
        Batch.Insert(false);
    end;

    local procedure Handover(Prefix: Code[20])
    var
        Header: Record "Time Sheet Header";
        Resource: Record Resource;
        Usage: Record "TS Usage Line ori";
    begin
        Header.Get(Prefix + 'S');
        Resource.Get(Prefix + 'R');
        Header.TestField("Resource No.", Resource."No.");
        Header.TestField("Approver User ID", UpperCase(UserId()));
        // Simulates the other actor in owned fixtures without creating users or changing credentials.
        Header."Owner User ID" := 'ZZU84-OTHER';
        Header.Modify(false);
        Resource."Time Sheet Owner User ID" := Header."Owner User ID";
        Resource.Modify(false);
        Usage.SetRange("Time Sheet No.", Header."No.");
        Usage.ModifyAll("Owner User ID", Header."Owner User ID");
    end;

    local procedure PostResource(Prefix: Code[20])
    var
        Usage: Record "TS Usage Line ori";
        Journal: Record "Res. Journal Line";
        PostLine: Codeunit "Res. Jnl.-Post Line";
    begin
        Usage.SetRange("Time Sheet No.", Prefix + 'S');
        Usage.SetRange(Status, Usage.Status::Approved);
        Usage.SetRange("Journal Table No.", Database::"Res. Journal Line");
        if Usage.FindSet() then
            repeat
                Journal.Get(Usage."Journal Template", Usage."Journal Batch", Usage."Journal Line No.");
                PostLine.RunWithCheck(Journal);
                Journal.Delete(true);
            until Usage.Next() = 0;
    end;

    local procedure Cleanup(Prefix: Code[20]; ShortName: Code[10])
    var
        Resource: Record Resource;
        ResourceUnit: Record "Resource Unit of Measure";
        PostingGroup: Record "Gen. Product Posting Group";
        Item: Record Item;
        ItemUnit: Record "Item Unit of Measure";
        UnitOfMeasure: Record "Unit of Measure";
        Header: Record "Time Sheet Header";
        Line: Record "Time Sheet Line";
        Usage: Record "TS Usage Line ori";
        Journal: Record "Res. Journal Line";
        JournalTemplate: Record "Res. Journal Template";
        Batch: Record "Res. Journal Batch";
        FixtureCleanup: Codeunit "TS Usage Fixture Cleanup";
    begin
        Resource.Get(Prefix + 'R');
        Resource.TestField(Name, 'Issue 84 self-seeded resource');
        Item.Get(Prefix + 'I');
        Item.TestField(Description, 'Issue 84 self-seeded item');
        Header.Get(Prefix + 'S');
        Header.TestField("Resource No.", Resource."No.");
        Usage.SetRange("Time Sheet No.", Header."No.");
        Usage.DeleteAll(false);
        Journal.SetRange("Journal Template Name", ShortName);
        Journal.SetRange("Journal Batch Name", ShortName);
        Journal.DeleteAll(true);
        Batch.Get(ShortName, ShortName);
        Batch.Delete(false);
        JournalTemplate.Get(ShortName);
        JournalTemplate.Delete(false);
        FixtureCleanup.DeleteResourceLedger(Resource."No.");
        ResourceUnit.SetRange("Resource No.", Resource."No.");
        ResourceUnit.DeleteAll(false);
        ItemUnit.SetRange("Item No.", Item."No.");
        ItemUnit.DeleteAll(false);
        Line.SetRange("Time Sheet No.", Header."No.");
        Line.DeleteAll(false);
        Header.Delete(false);
        Resource.Delete(false);
        Item.Delete(false);
        UnitOfMeasure.Get(ShortName);
        PostingGroup.Get(ShortName);
        PostingGroup.Delete(false);
        UnitOfMeasure.Delete(false);
    end;
}
