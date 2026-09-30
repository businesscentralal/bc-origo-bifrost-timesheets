namespace Origo.Bifrost.Timesheets;

using Origo.Bifrost;

/// <summary>Residual Markdown compatibility help for issue #36 batch 3.</summary>
codeunit 10036858 "Clockify Contract Help 3 ori"
{
    Access = Internal;

    procedure GetHelp(MessageType: Enum "Message Type ori"; Description: Text): Text
    var
        Parts: Codeunit "Clockify Contract Parts ori";
    begin
        // Former Markdown help now lives in the contract chapters. Nothing residual remains.
        if (Parts.MessageTypeName(MessageType) = '') or (Description = '') then
            exit('');
        exit('');
    end;
}
