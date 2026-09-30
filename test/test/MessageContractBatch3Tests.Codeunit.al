namespace Origo.Bifrost.Timesheets.Test;

using Origo.Bifrost;
using System.TestLibraries.Utilities;

/// <summary>Contract and discovery conformance tests for issue #36 batch 3.</summary>
codeunit 95610 "Message Contract Batch 3 Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    [Test]
    procedure Batch3TypesDeclareContractAndDiscovery()
    var
        Ordinal: Integer;
    begin
        foreach Ordinal in BatchOrdinals() do
            AssertContract(Ordinal);
    end;

    local procedure AssertContract(Ordinal: Integer)
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        MessageType: Enum "Message Type ori";
        Contract: JsonObject;
        Discovery: Interface "Msg Discovery ori";
        Chapter: Text;
        Chapters: List of [Text];
    begin
        MessageType := Enum::"Message Type ori".FromInteger(Ordinal);
        Assert.IsTrue(ContractMgt.GetContract(MessageType, Contract), TypeName(MessageType) + ' contract');
        Chapters.Add('envelope');
        Chapters.Add('response');
        Chapters.Add('errors');
        Chapters.Add('effect');
        Chapters.Add('related');
        foreach Chapter in Chapters do
            Assert.IsTrue(Contract.Contains(Chapter), TypeName(MessageType) + ' ' + Chapter);
        Discovery := MessageType;
        Assert.IsTrue(Discovery.GetKeywords() <> '', TypeName(MessageType) + ' keywords');
        Assert.IsTrue(Discovery.GetSelectionDescription() <> '', TypeName(MessageType) + ' selection');
    end;

    local procedure BatchOrdinals() Ordinals: List of [Integer]
    begin
        Ordinals.Add(10036807);
        Ordinals.Add(10036808);
        Ordinals.Add(10036809);
        Ordinals.Add(10036810);
        Ordinals.Add(10036811);
        Ordinals.Add(10036815);
        Ordinals.Add(10036816);
        Ordinals.Add(10036817);
        Ordinals.Add(10036818);
        Ordinals.Add(10036819);
        Ordinals.Add(10036820);
        Ordinals.Add(10036821);
        Ordinals.Add(10036822);
        Ordinals.Add(10036823);
        Ordinals.Add(10036824);
        Ordinals.Add(10036825);
    end;
}
