namespace Origo.Bifrost.Timesheets;

using Microsoft.Inventory.Item;
using Microsoft.Projects.Project.Job;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;

/// <summary>
/// Creates or extends an open sales invoice for a phone user. The invoice is a
/// sales invoice, not a sales order and not a project journal. A later Add for
/// the same customer appends a line to the still-open phone invoice. There is
/// no licence check; a Team Member user may still be stopped by standard
/// Business Central permissions on the sales tables.
/// </summary>
codeunit 10036859 "Phone Sales Quick Add ori"
{
    Access = Internal;

    var
        CustomerMissingErr: Label 'Customer %1 does not exist.', Comment = '%1 = customer number. is-IS=Viðskiptavinur %1 er ekki til.';
        ItemNotServiceErr: Label 'Item %1 is not a service item in your My Items list.', Comment = '%1 = item number. is-IS=Vara %1 er ekki þjónustuvara á Mínum vörum.';
        QuantityErr: Label 'Quantity must be greater than zero.', Comment = 'is-IS=Magn verður að vera stærra en núll.';
        JobTaskMissingErr: Label 'Job %1 has no job task to put on the sales line.', Comment = '%1 = job number. is-IS=Verk %1 hefur engan verkþátt til að setja á sölulínuna.';

    /// <summary>
    /// Adds one service-item line to the customer's open phone sales invoice.
    /// </summary>
    /// <param name="CustomerNo">Sell-to customer.</param>
    /// <param name="JobNo">Job written on the line. Blank when the row has no job.</param>
    /// <param name="JobTaskNo">Job task written on the line. The first task of the job is used when this is blank.</param>
    /// <param name="ItemNo">Service item from the user's My Items list.</param>
    /// <param name="Quantity">Quantity on the new line.</param>
    procedure AddServiceItemLine(CustomerNo: Code[20]; JobNo: Code[20]; JobTaskNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        ResolvedTaskNo: Code[20];
    begin
        if not Customer.Get(CustomerNo) then
            Error(CustomerMissingErr, CustomerNo);
        AssertMyServiceItem(ItemNo);
        if Quantity <= 0 then
            Error(QuantityErr);
        ResolvedTaskNo := JobTaskNo;
        if JobNo <> '' then begin
            if ResolvedTaskNo = '' then
                ResolvedTaskNo := FirstJobTaskNo(JobNo);
            if ResolvedTaskNo = '' then
                Error(JobTaskMissingErr, JobNo);
        end;
        FindOrCreatePhoneInvoice(CustomerNo, SalesHeader);
        InsertItemLine(SalesHeader, JobNo, ResolvedTaskNo, ItemNo, Quantity);
    end;

    /// <summary>
    /// Checks that the item exists, is a service item, and is on the signed-in user's My Items list.
    /// </summary>
    /// <param name="ItemNo">Item number to check.</param>
    procedure AssertMyServiceItem(ItemNo: Code[20])
    var
        Item: Record Item;
        MyItem: Record "My Item";
    begin
        if not Item.Get(ItemNo) then
            Error(ItemNotServiceErr, ItemNo);
        if Item.Type <> Item.Type::Service then
            Error(ItemNotServiceErr, ItemNo);
        MyItem.SetRange("User ID", UserId());
        MyItem.SetRange("Item No.", ItemNo);
        if MyItem.IsEmpty() then
            Error(ItemNotServiceErr, ItemNo);
    end;

    local procedure FindOrCreatePhoneInvoice(CustomerNo: Code[20]; var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.SetRange("Sell-to Customer No.", CustomerNo);
        SalesHeader.SetRange(Status, SalesHeader.Status::Open);
        SalesHeader.SetRange("Phone RC Document ori", true);
        if SalesHeader.FindLast() then
            exit;
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
        SalesHeader.Insert(true);
        SalesHeader.SetHideValidationDialog(true);
        SalesHeader.Validate("Sell-to Customer No.", CustomerNo);
        SalesHeader."Phone RC Document ori" := true;
        SalesHeader.Modify(true);
    end;

    local procedure InsertItemLine(SalesHeader: Record "Sales Header"; JobNo: Code[20]; JobTaskNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
        NextLineNo: Integer;
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindLast() then
            NextLineNo := SalesLine."Line No." + 10000
        else
            NextLineNo := 10000;
        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := NextLineNo;
        SalesLine.Insert(true);
        SalesLine.SetHideValidationDialog(true);
        SalesLine.Validate(Type, SalesLine.Type::Item);
        SalesLine.Validate("No.", ItemNo);
        SalesLine.Validate(Quantity, Quantity);
        if JobNo <> '' then begin
            SalesLine.Validate("Job No.", JobNo);
            SalesLine.Validate("Job Task No.", JobTaskNo);
        end;
        SalesLine.Modify(true);
    end;

    local procedure FirstJobTaskNo(JobNo: Code[20]): Code[20]
    var
        JobTask: Record "Job Task";
    begin
        JobTask.SetLoadFields("Job No.", "Job Task No.");
        JobTask.SetRange("Job No.", JobNo);
        if JobTask.FindFirst() then
            exit(JobTask."Job Task No.");
        exit('');
    end;
}
