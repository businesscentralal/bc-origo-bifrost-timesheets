namespace Origo.Bifrost.Timesheets.Test;

using Origo.Bifrost;
using Origo.Bifrost.Timesheets;
using System.TestLibraries.Utilities;

/// <summary>Contract and discovery conformance tests for issue #36 batch 1.</summary>
codeunit 95608 "Message Contract Batch 1 Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    [Test]
    procedure Batch1TypesDeclareContractAndDiscovery()
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
        MsgContract: Interface "Msg Contract ori";
        Discovery: Interface "Msg Discovery ori";
        Chapter: Text;
        Chapters: List of [Text];
        Metering: JsonObject;
        TypeName: Text;
    begin
        MessageType := Enum::"Message Type ori".FromInteger(Ordinal);
        TypeName := Parts.MessageTypeName(MessageType);
        Assert.IsTrue(ContractMgt.GetContract(MessageType, Contract), TypeName + ' contract');
        Chapters.Add('envelope');
        Chapters.Add('response');
        if Ordinal <> 10036785 then
            Chapters.Add('errors');
        Chapters.Add('effect');
        Chapters.Add('related');
        foreach Chapter in Chapters do
            Assert.IsTrue(Contract.Contains(Chapter), TypeName + ' ' + Chapter);
        MsgContract := MessageType;
        Discovery := MessageType;
        Assert.IsTrue(Discovery.GetKeywords() <> '', TypeName + ' keywords');
        Assert.IsTrue(Discovery.GetSelectionDescription() <> '', TypeName + ' selection');
        Assert.IsFalse(MsgContract.GetMetering(Metering), TypeName + ' app metering');
    end;

    local procedure BatchOrdinals() Ordinals: List of [Integer]
    begin
        Ordinals.Add(10036785);
        Ordinals.Add(10036786);
        Ordinals.Add(10036787);
        Ordinals.Add(10036788);
        Ordinals.Add(10036789);
        Ordinals.Add(10036790);
        Ordinals.Add(10036791);
        Ordinals.Add(10036792);
        Ordinals.Add(10036793);
        Ordinals.Add(10036812);
        Ordinals.Add(10036813);
        Ordinals.Add(10036814);
    end;
}
