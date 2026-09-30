namespace Origo.Bifrost.Timesheets.Test;

using Origo.Bifrost;
using Origo.Bifrost.Timesheets;
using System.TestLibraries.Utilities;

/// <summary>Contract and discovery conformance tests for issue #36 batch 2.</summary>
codeunit 95609 "Message Contract Batch 2 Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    [Test]
    procedure Batch2TypesDeclareContractAndDiscovery()
    var
        Ordinal: Integer;
    begin
        foreach Ordinal in BatchOrdinals() do
            AssertContract(Ordinal);
    end;

    local procedure AssertContract(Ordinal: Integer)
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Parts: Codeunit "Clockify Contract Parts ori";
        MessageType: Enum "Message Type ori";
        Contract: JsonObject;
        Discovery: Interface "Msg Discovery ori";
        Chapter: Text;
        Chapters: List of [Text];
        TypeName: Text;
    begin
        MessageType := Enum::"Message Type ori".FromInteger(Ordinal);
        TypeName := Parts.MessageTypeName(MessageType);
        Assert.IsTrue(ContractMgt.GetContract(MessageType, Contract), TypeName + ' contract');
        Chapters.Add('envelope');
        Chapters.Add('response');
        Chapters.Add('errors');
        Chapters.Add('effect');
        Chapters.Add('related');
        foreach Chapter in Chapters do
            Assert.IsTrue(Contract.Contains(Chapter), TypeName + ' ' + Chapter);
        Discovery := MessageType;
        Assert.IsTrue(Discovery.GetKeywords() <> '', TypeName + ' keywords');
        Assert.IsTrue(Discovery.GetSelectionDescription() <> '', TypeName + ' selection');
    end;

    local procedure BatchOrdinals() Ordinals: List of [Integer]
    begin
        Ordinals.Add(10036794);
        Ordinals.Add(10036795);
        Ordinals.Add(10036796);
        Ordinals.Add(10036797);
        Ordinals.Add(10036798);
        Ordinals.Add(10036799);
        Ordinals.Add(10036800);
        Ordinals.Add(10036801);
        Ordinals.Add(10036802);
        Ordinals.Add(10036803);
        Ordinals.Add(10036804);
        Ordinals.Add(10036805);
        Ordinals.Add(10036806);
    end;
}
