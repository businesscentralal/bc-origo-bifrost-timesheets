namespace Origo.Bifrost.Timesheets;

using Origo.Bifrost;

/// <summary>Residual Markdown compatibility help for issue #36 batch 2.</summary>
codeunit 10036857 "Clockify Contract Help 2 ori"
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
