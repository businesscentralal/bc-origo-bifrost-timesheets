namespace Origo.Bifrost.Timesheets;

using Microsoft.Projects.Project.Job;
using Microsoft.Sales.Customer;

/// <summary>
/// Temporary rows for the phone Role Center customer lists. The buffer holds no
/// persisted customer content. Each list part rebuilds it when the page opens.
/// </summary>
table 10036857 "Phone Cust Buffer ori"
{
    Caption = 'Phone Customer Buffer', Comment = 'is-IS=Viðskiptavinabiðminni síma';
    DataClassification = SystemMetadata;
    TableType = Temporary;

    fields
    {
        /// <summary>Row number inside one list part.</summary>
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.', Comment = 'is-IS=Færslunúmer';
            DataClassification = SystemMetadata;
        }
        /// <summary>Which list this row belongs to.</summary>
        field(2; Bucket; Enum "Phone Cust Bucket ori")
        {
            Caption = 'Bucket', Comment = 'is-IS=Listi';
            DataClassification = SystemMetadata;
        }
        /// <summary>Customer to charge.</summary>
        field(3; "Customer No."; Code[20])
        {
            Caption = 'Customer No.', Comment = 'is-IS=Viðskiptavinur';
            DataClassification = SystemMetadata;
            TableRelation = Customer."No.";
        }
        /// <summary>Customer name shown on the phone list.</summary>
        field(4; "Customer Name"; Text[100])
        {
            Caption = 'Customer Name', Comment = 'is-IS=Nafn viðskiptavinar';
            DataClassification = SystemMetadata;
        }
        /// <summary>Open job for this customer, when one is known.</summary>
        field(5; "Job No."; Code[20])
        {
            Caption = 'Job No.', Comment = 'is-IS=Verknúmer';
            DataClassification = SystemMetadata;
            TableRelation = Job."No.";
        }
        /// <summary>Job task written on the sales invoice line for job costing.</summary>
        field(6; "Job Task No."; Code[20])
        {
            Caption = 'Job Task No.', Comment = 'is-IS=Verkþáttur';
            DataClassification = SystemMetadata;
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
        }
        /// <summary>Hours logged today for this customer. Zero on the other lists and on a running timer.</summary>
        field(7; "Hours Today"; Decimal)
        {
            Caption = 'Hours', Comment = 'is-IS=Klukkustundir';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 2;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(BucketCustomer; Bucket, "Customer No.")
        {
        }
    }
}
