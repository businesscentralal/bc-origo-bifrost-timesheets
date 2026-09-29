namespace Origo.Bifrost.Timesheets;

using Origo.Bifrost;

/// <summary>Residual Markdown compatibility help for issue #36 batch 2.</summary>
codeunit 10036857 "Clockify Contract Help 2 ori"
{
    Access = Internal;

    procedure GetHelp(MessageType: Enum "Message Type ori"; Description: Text): Text
    var
        Builder: TextBuilder;
    begin
        Builder.AppendLine('# ' + MessageTypeName(MessageType));
        Builder.AppendLine('');
        Builder.AppendLine(Description);
        Builder.AppendLine('');
        Builder.AppendLine('The structured contract chapters are authoritative for envelope, parameters, response, errors, effect and related operations.');
        exit(Builder.ToText());
    end;

    local procedure MessageTypeName(MessageType: Enum "Message Type ori"): Text
    begin
        exit(Enum::"Message Type ori".Names().Get(Enum::"Message Type ori".Ordinals().IndexOf(MessageType.AsInteger())));
    end;
}
