namespace Origo.Bifrost.Timesheets;

using Microsoft.Sales.Document;

/// <summary>
/// Marks a sales invoice created by the phone Role Center so a later Add for the
/// same customer appends a line to that still-open invoice.
/// </summary>
tableextension 10036865 "Phone Sales Header ori" extends "Sales Header"
{
    fields
    {
        /// <summary>True when the phone Role Center created this invoice.</summary>
        field(10036856; "Phone RC Document ori"; Boolean)
        {
            Caption = 'Phone Role Center document', Comment = 'is-IS=Skjal síma-hlutverkamiðju';
            DataClassification = SystemMetadata;
        }
    }
}
